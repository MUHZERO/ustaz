import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LockedBadge extends StatelessWidget {
  const LockedBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_outline, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Text('home.locked'.tr, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );
}
