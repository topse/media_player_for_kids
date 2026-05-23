import 'package:flutter/material.dart';

/// Blocking dialog that asks for the kid's name at first startup.
///
/// Returns the entered name, or `null` if somehow dismissed (should not happen
/// since `barrierDismissible` is false).
Future<String?> showKidNameDialog(BuildContext context) async {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Wer benutzt dieses Gerät?'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Dein Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bitte gib deinen Namen ein';
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
          child: const Text('Fertig'),
        ),
      ],
    ),
  );
}
