import 'package:flutter/material.dart';

/// Generic card wrapper for consistent look & padding.
class CardBox extends StatelessWidget {
  final Widget child;
  final double padding;
  final double elevation;

  const CardBox({
    super.key,
    required this.child,
    this.padding = 18,
    this.elevation = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: child,
      ),
    );
  }
}
