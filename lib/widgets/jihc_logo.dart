import 'package:flutter/material.dart';

class JihcLogo extends StatelessWidget {
  const JihcLogo({super.key, this.size = 96});

  static const assetPath = 'assets/images/jihc_logo.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.school_rounded, size: size * 0.62);
      },
    );
  }
}
