import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Blocking dialog that asks for the kid's name at first startup.
///
/// Returns the entered name, or `null` if somehow dismissed (should not happen
/// since `barrierDismissible` is false).
Future<String?> showKidNameDialog(BuildContext context) async {
  final l10n = SharedL10n.of(context);
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(l10n.kidNameTitle),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.kidNameLabel,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.kidNamePleaseEnter;
            }
            return null;
          },
          onFieldSubmitted: (value) {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop(value.trim());
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop(controller.text.trim());
            }
          },
          child: Text(l10n.kidNameDone),
        ),
      ],
    ),
  );
}
