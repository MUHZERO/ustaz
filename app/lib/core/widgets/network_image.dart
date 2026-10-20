import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class NetworkImageView extends StatelessWidget {
  const NetworkImageView({
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholder,
    super.key,
  });

  final String? url;
  final BoxFit fit;

  /// Shown while loading, on error and without a URL; a plain tint by default.
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final fallback =
        placeholder ??
        ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHigh);
    if (url == null || url!.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}
