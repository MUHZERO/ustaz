import 'package:flutter/material.dart';

/// Corner radii shared by every surface.
abstract final class AppRadii {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

/// The spacing scale; paddings and gaps use these values only.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Semantic colors that do not change with the brand.
abstract final class AppColors {
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFB45309);
  static const error = Color(0xFFDC2626);

  /// Green from 85%, amber from 50%, red below.
  static Color forPercent(num percent) => percent >= 85
      ? success
      : percent >= 50
      ? warning
      : error;
}

/// Harmonious gradients for covers and category cards; a content id picks
/// one, so the same lecture always gets the same color.
abstract final class AppGradients {
  static const _pairs = [
    (Color(0xFF4338CA), Color(0xFF7C3AED)),
    (Color(0xFF0E7490), Color(0xFF2563EB)),
    (Color(0xFFDB2777), Color(0xFFF97316)),
    (Color(0xFF047857), Color(0xFF0D9488)),
    (Color(0xFFB45309), Color(0xFFE11D48)),
    (Color(0xFF1E40AF), Color(0xFF0891B2)),
  ];

  static LinearGradient of(int seed) {
    final (start, end) = _pairs[seed.abs() % _pairs.length];
    return LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: [start, end],
    );
  }

  /// The gradient's first color, for tints that match the card.
  static Color base(int seed) => _pairs[seed.abs() % _pairs.length].$1;
}
