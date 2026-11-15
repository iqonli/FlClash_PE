import 'package:flutter/material.dart';

const classicGap = 14.0;
const classicCardShape = RoundedSuperellipseBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
);

class ClassicCard extends StatelessWidget {
  const ClassicCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.onTap,
  });
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      shape: classicCardShape,
      color: colors.secondaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class ClassicPage extends StatelessWidget {
  const ClassicPage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottom,
  });
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions, bottom: bottom),
    floatingActionButton: floatingActionButton,
    body: body,
  );
}

Future<T?> classicPush<T>(BuildContext context, Widget child) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => child));

Future<bool?> classicConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String cancel,
  required String confirm,
}) => showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text(confirm),
      ),
    ],
  ),
);

String classicBytes(num value) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = value.toDouble();
  var index = 0;
  while (size.abs() >= 1024 && index < units.length - 1) {
    size /= 1024;
    index++;
  }
  return '${size.toStringAsFixed(index == 0 ? 0 : 1)} ${units[index]}';
}
