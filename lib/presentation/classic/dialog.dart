import 'package:flutter/material.dart';

Future<bool?> showClassicMessage({
  required BuildContext context,
  required InlineSpan message,
  required String title,
  required String confirmText,
  required String cancelText,
  required bool cancelable,
  required bool dismissible,
  required bool destructive,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: dismissible,
  useRootNavigator: false,
  builder: (context) => AlertDialog(
    title: Text(title),
    content: SingleChildScrollView(
      child: SelectableText.rich(TextSpan(children: [message])),
    ),
    actions: [
      if (cancelable)
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
      TextButton(
        style: destructive
            ? TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              )
            : null,
        onPressed: () => Navigator.pop(context, true),
        child: Text(confirmText),
      ),
    ],
  ),
);
