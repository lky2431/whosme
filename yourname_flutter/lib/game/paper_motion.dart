import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

/// Small, one-shot entrances. Keep the key stable during room status updates;
/// change it only when a new question or phase arrives.
class PaperEntrance extends StatelessWidget {
  const PaperEntrance({super.key, required this.child, this.reveal = false});

  final Widget child;
  final bool reveal;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    if (reveal) {
      return FadeIn(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        child: child,
      );
    }
    return FadeInUp(
      from: 12,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: child,
    );
  }
}
