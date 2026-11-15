import 'package:flutter/material.dart';

const classicGap = 14.0;
const classicCardShape = RoundedSuperellipseBorder(
  borderRadius: BorderRadius.all(Radius.circular(14)),
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
    return Card.outlined(
      margin: EdgeInsets.zero,
      shape: classicCardShape.copyWith(
        side: BorderSide(color: colors.surfaceContainerHighest),
      ),
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(child: child),
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

class ClassicTrafficChart extends StatelessWidget {
  const ClassicTrafficChart({
    super.key,
    required this.values,
    required this.color,
  });
  final List<double> values;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 54,
    width: double.infinity,
    child: CustomPaint(painter: _TrafficPainter(values, color)),
  );
}

class _TrafficPainter extends CustomPainter {
  _TrafficPainter(this.values, this.color);
  final List<double> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.isEmpty) return;
    final peak = values.fold<double>(1, (a, b) => a > b ? a : b);
    final line = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height * (1 - values[i] / peak);
      if (i == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
    }
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.12));
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _TrafficPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class ClassicRadioChoices<T> extends StatelessWidget {
  const ClassicRadioChoices({
    super.key,
    required this.value,
    required this.options,
    required this.label,
    required this.onChanged,
  });
  final T value;
  final List<T> options;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => RadioGroup<T>(
    groupValue: value,
    onChanged: (next) {
      if (next != null) onChanged(next);
    },
    child: Column(
      children: [
        for (final item in options)
          RadioListTile<T>(value: item, title: Text(label(item))),
      ],
    ),
  );
}
