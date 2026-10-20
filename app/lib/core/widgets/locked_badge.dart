import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_badge.dart';

class LockedBadge extends StatelessWidget {
  const LockedBadge({this.onImage = false, super.key});
  final bool onImage;

  @override
  Widget build(BuildContext context) => AppBadge(
    label: 'home.locked'.tr,
    icon: Icons.lock_outline,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    onImage: onImage,
  );
}
