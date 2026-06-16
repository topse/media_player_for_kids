/// On-device error surfacing.
///
/// The target device has no reachable logs, so any unhandled error must be
/// made *visible on screen* instead of leaving a frozen black/grey page that
/// can only be cleared with a hard restart.
///
/// Two failure classes are captured:
/// - **Synchronous framework errors** (a throw during `build`/layout/paint)
///   via [FlutterError.onError]. The framework additionally swaps in
///   [ErrorWidget.builder] at the failure site — we replace its default grey
///   box with a red one.
/// - **Uncaught async errors** (e.g. an un-awaited `db.put` rejecting with a
///   409 conflict) via `PlatformDispatcher.onError`. These never reach
///   [ErrorWidget.builder], so the overlay below is the only way to see them.
///
/// Both paths funnel into [appErrorNotifier]; [GlobalErrorOverlay] (installed
/// through the root `MaterialApp.builder`) renders the latest report full
/// screen on top of whatever is — or isn't — painting underneath.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single captured error, ready to display.
@immutable
class AppErrorReport {
  final String summary;
  final String details;
  final DateTime time;

  const AppErrorReport({
    required this.summary,
    required this.details,
    required this.time,
  });
}

/// The most recent unhandled error, or `null` when none is showing.
/// Global (not scoped to a subtree) so an error originating anywhere — even
/// before the widget tree mounts — is retained until the overlay can paint it.
final ValueNotifier<AppErrorReport?> appErrorNotifier =
    ValueNotifier<AppErrorReport?>(null);

/// Installs the global error hooks. Call once in `main()` immediately after
/// `WidgetsFlutterBinding.ensureInitialized()` and before `runApp()`.
void installGlobalErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    // Preserve the default behaviour (console dump in debug, etc.).
    FlutterError.presentError(details);
    _publish(
      summary: details.exceptionAsString(),
      details: _composeDetails(
        details.exception,
        details.stack,
        library: details.library,
        contextLabel: details.context?.toString(),
      ),
    );
  };

  // Uncaught async errors that escape to the platform dispatcher. Returning
  // true marks them handled so the process is not torn down.
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    _publish(
      summary: error.toString(),
      details: _composeDetails(error, stack),
    );
    return true;
  };

  // Replace the default grey "broken" box rendered in place of a widget whose
  // build threw. Kept deliberately tiny and self-contained (no Material /
  // MediaQuery / Directionality ancestor required) so it can paint anywhere.
  ErrorWidget.builder = (FlutterErrorDetails details) =>
      _InlineErrorBox(message: details.exceptionAsString());
}

/// Pushes a report into [appErrorNotifier], deferred to a microtask so we
/// never mutate the notifier (and thus trigger a listener rebuild) during the
/// framework's own build/layout phase — which is exactly when a synchronous
/// error fires. Repeated identical errors (a build that throws every frame)
/// are coalesced so the panel is not rebuilt on every frame.
void _publish({required String summary, required String details}) {
  scheduleMicrotask(() {
    final current = appErrorNotifier.value;
    if (current != null && current.details == details) return;
    appErrorNotifier.value = AppErrorReport(
      summary: summary,
      details: details,
      time: DateTime.now(),
    );
  });
}

String _composeDetails(
  Object? error,
  StackTrace? stack, {
  String? library,
  String? contextLabel,
}) {
  final buffer = StringBuffer()..writeln(error.toString());
  if (contextLabel != null && contextLabel.isNotEmpty) {
    buffer.writeln('\nContext: $contextLabel');
  }
  if (library != null && library.isNotEmpty) {
    buffer.writeln('Library: $library');
  }
  buffer
    ..writeln('\nStack trace:')
    ..writeln(stack?.toString() ?? '<no stack trace>');
  return buffer.toString();
}

/// Wraps the app and paints [appErrorNotifier]'s latest report on top of the
/// whole UI. Install via the root `MaterialApp.builder`.
class GlobalErrorOverlay extends StatelessWidget {
  final Widget child;

  const GlobalErrorOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Stack(
        children: [
          child,
          ValueListenableBuilder<AppErrorReport?>(
            valueListenable: appErrorNotifier,
            builder: (context, report, _) {
              if (report == null) return const SizedBox.shrink();
              return Positioned.fill(
                child: _ErrorPanel(
                  report: report,
                  onDismiss: () => appErrorNotifier.value = null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Full-screen, opaque report panel. Opaque on purpose: it must hide a frozen
/// or black page underneath, not blend with it.
class _ErrorPanel extends StatelessWidget {
  final AppErrorReport report;
  final VoidCallback onDismiss;

  const _ErrorPanel({required this.report, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF4A0000),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '⚠️  Ein Fehler ist aufgetreten',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                report.time.toIso8601String(),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              SelectableText(
                report.summary,
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Divider(color: Colors.white24, height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    report.details,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.35,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => Clipboard.setData(
                      ClipboardData(
                        text: '${report.summary}\n\n${report.details}',
                      ),
                    ),
                    icon: const Icon(Icons.copy, color: Colors.white70),
                    label: const Text(
                      'Kopieren',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onDismiss,
                    child: const Text('Schließen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact in-place replacement for Flutter's default grey error box. Must be
/// renderable with no inherited Material/Directionality/MediaQuery, so styles
/// are fully explicit (including `decoration: none` to avoid the debug yellow
/// underline that appears without a `DefaultTextStyle`).
class _InlineErrorBox extends StatelessWidget {
  final String message;

  const _InlineErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFFB00020),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text(
          'Fehler:\n$message',
          textAlign: TextAlign.center,
          maxLines: 10,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
