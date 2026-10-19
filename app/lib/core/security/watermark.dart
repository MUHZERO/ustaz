import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class Watermark extends StatefulWidget {
  const Watermark({
    required this.studentName,
    required this.studentPhone,
    required this.child,
    super.key,
    this.random = Random.new,
  });

  final String studentName;
  final String studentPhone;
  final Widget child;
  final Random Function() random;

  @override
  State<Watermark> createState() => _WatermarkState();
}

class _WatermarkState extends State<Watermark> {
  late final Timer _timer;
  late Alignment _alignment;

  @override
  void initState() {
    super.initState();
    _alignment = _nextAlignment();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _alignment = _nextAlignment());
    });
  }

  Alignment _nextAlignment() => const [
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
  ][widget.random().nextInt(4)];

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      widget.child,
      Align(
        alignment: _alignment,
        child: IgnorePointer(
          child: Opacity(
            opacity: .25,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('${widget.studentName}\n${widget.studentPhone}'),
            ),
          ),
        ),
      ),
    ],
  );
}
