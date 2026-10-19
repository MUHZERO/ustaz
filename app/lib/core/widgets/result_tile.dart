import 'package:flutter/material.dart';

/// One assessment row: title, a status line and the percent once graded.
class ResultTile extends StatelessWidget {
  const ResultTile({
    required this.title,
    required this.subtitle,
    this.percent,
    this.onTap,
    super.key,
  });
  final String title;
  final String subtitle;
  final num? percent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: percent == null
        ? null
        : Text('$percent%', style: Theme.of(context).textTheme.titleMedium),
    onTap: onTap,
  );
}
