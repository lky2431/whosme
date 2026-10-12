import 'package:flutter/material.dart';

/// Base breakpoints on available space, leaving room for enlarged text.
abstract final class PaperLayout {
  static bool columns(BuildContext context, double width) =>
      width >= 960 && MediaQuery.textScalerOf(context).scale(16) <= 21;

  static double gutter(double width) => width < 360
      ? 12
      : width < 600
      ? 20
      : width < 1000
      ? 32
      : 48;
}

/// Natural-height tiles keep long answers readable at any text size.
class PaperAnswerLayout extends StatelessWidget {
  const PaperAnswerLayout({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final paired =
          constraints.maxWidth >= 560 &&
          MediaQuery.textScalerOf(context).scale(16) <= 21;
      final width = paired
          ? (constraints.maxWidth - 12) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}
