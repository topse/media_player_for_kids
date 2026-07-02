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

/// The **first (root-cause)** unhandled error currently on screen, or `null`
/// when none is showing. Global (not scoped to a subtree) so an error
/// originating anywhere — even before the widget tree mounts — is retained
/// until the overlay can paint it. Deliberately latched: see [_publish].
final ValueNotifier<AppErrorReport?> appErrorNotifier =
    ValueNotifier<AppErrorReport?>(null);

/// Count of *additional* distinct errors that fired while [appErrorNotifier]
/// already had a report on screen. A broken state usually throws a cascade
/// (e.g. the GUI failing to build after a failed bootstrap); we keep the first
/// error latched and only count the rest so the displayed stack trace doesn't
/// flip out from under the reader while they scroll it.
final ValueNotifier<int> suppressedErrorCount = ValueNotifier<int>(0);

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

/// Public entry point for code that catches an error itself but still wants it
/// surfaced on screen. Use this where an exception would otherwise be
/// **swallowed** by a library `try/catch` (notably `DbStateProxyWidget`'s
/// `onLogin` handler, which eats throws and renders its child against a
/// half-initialised app — the original "black screen" cause) or where it fires
/// before `runApp()` and so never reaches a mounted overlay.
void reportAppError(Object error, StackTrace? stack, {String? context}) {
  _publish(
    summary: error.toString(),
    details: _composeDetails(error, stack, contextLabel: context),
  );
}

/// Pushes a report into [appErrorNotifier], deferred to a microtask so we
/// never mutate the notifier (and thus trigger a listener rebuild) during the
/// framework's own build/layout phase — which is exactly when a synchronous
/// error fires.
///
/// **Latching:** once a report is showing, later errors do NOT overwrite it —
/// the first error is almost always the root cause and the rest are fallout
/// (a build that throws every frame, or the GUI collapsing after a failed
/// bootstrap). Identical re-fires are ignored; distinct follow-ups bump
/// [suppressedErrorCount] so the reader still knows more happened. The panel is
/// cleared (and the count reset) only on explicit dismiss.
void _publish({required String summary, required String details}) {
  scheduleMicrotask(() {
    final current = appErrorNotifier.value;
    if (current != null) {
      if (current.details != details) suppressedErrorCount.value++;
      return;
    }
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
                // Absorb every pointer so taps on empty panel areas can't fall
                // through to the (often broken) UI underneath and trigger a
                // fresh cascade of errors — the cause of the panel appearing to
                // "change on tap".
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: _ErrorPanel(
                    report: report,
                    onDismiss: () {
                      appErrorNotifier.value = null;
                      suppressedErrorCount.value = 0;
                    },
                  ),
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
              ValueListenableBuilder<int>(
                valueListenable: suppressedErrorCount,
                builder: (context, count, _) {
                  if (count == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ $count weitere Fehler unterdrückt '
                      '(der erste wird gezeigt)',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
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
