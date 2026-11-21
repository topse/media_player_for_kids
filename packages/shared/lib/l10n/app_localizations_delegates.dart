import 'package:material_ui/material_ui.dart';

import 'shared_l10n.dart';

/// Localization delegates every app must pass to `MaterialApp`.
///
/// Use this instead of the generated `SharedL10n.localizationsDelegates`:
/// gen_l10n wires in `flutter_localizations`' `GlobalMaterialLocalizations`,
/// which provides the *legacy* `package:flutter/material.dart`
/// `MaterialLocalizations` type. Our widgets come from `material_ui`, whose
/// `MaterialLocalizations` is a different type — so for any locale other than
/// English (material_ui's built-in default only supports `en`) it resolved to
/// null and `showDialog` & co. crashed with "Null check operator used on a
/// null value" (first-start admin password dialog on a German device).
///
/// Consequence: every widget in the app — including dependencies such as
/// `dart_couch_widgets` — must import `material_ui`, not
/// `package:flutter/material.dart`, or it hits the same crash.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      SharedL10n.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ];
