import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:dart_couch_widgets/dart_couch_widgets.dart';
import 'package:flutter/material.dart';
import 'package:player/main.dart';
import 'package:shared/models/datatypes.dart';
import 'package:shared/shared.dart' show MediaBaseIcon;
import 'package:watch_it/watch_it.dart';

class MediaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;
  final List<MediaBase>? ancestors;
  final Map<String, MediaBase>? allDocuments;

  const MediaAppBar({
    super.key,
    this.onBack,
    this.ancestors,
    this.allDocuments,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: onBack != null
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack)
          : null,
      title: (ancestors != null && ancestors!.isNotEmpty)
          ? _BreadcrumbTitle(
              ancestors: ancestors!,
              allDocuments: allDocuments ?? {},
            )
          : const Text('Media Player for kids'),
      actions: [
        OfflineFirstServerStateWidget(
          server: di<DartCouchServer>() as OfflineFirstServer,
          db: di<DartCouchDb>() as OfflineFirstDb,
          showPercentage: true,
        ),
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'admin') {
              final verified =
                  await AdminPasswordGate.requestPasswordVerification(context);
              if (verified && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminSettingsPage(),
                  ),
                );
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'admin',
              child: Text('Show Admin Options'),
            ),
          ],
        ),
      ],
    );
  }
}

class _BreadcrumbTitle extends StatelessWidget {
  final List<MediaBase> ancestors;
  final Map<String, MediaBase> allDocuments;

  const _BreadcrumbTitle({required this.ancestors, required this.allDocuments});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (int i = 0; i < ancestors.length; i++) {
      if (i > 0) {
        items.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Icon(Icons.chevron_right, size: 18),
          ),
        );
      }
      items.add(
        SizedBox(
          width: 32,
          height: 32,
          child: MediaBaseIcon(
            media: ancestors[i],
            allDocuments: allDocuments,
            iconSize: 24,
            showTypeBadge: false,
          ),
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: items);
  }
}
