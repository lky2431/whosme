import '../l10n/app_language.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'paper_theme.dart';

/// A flat selection surface with keyboard focus and a non-colour selected cue.
class PaperChoice extends StatelessWidget {
  const PaperChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.color = mint,
    this.leading,
  });
  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final Color color;
  final Widget? leading;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        backgroundColor: selected ? color : mist,
        foregroundColor: ink,
        disabledForegroundColor: ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Flexible(child: Text(label)),
          const SizedBox(width: 10),
          Icon(
            selected ? Icons.check_rounded : Icons.add_rounded,
            size: 16,
            color: selected ? forest : mutedInk,
          ),
        ],
      ),
    ),
  );
}

class FriendMark extends StatelessWidget {
  const FriendMark({super.key, this.size = 38});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: const _FriendsPainter(),
    ),
  );
}

class _FriendsPainter extends CustomPainter {
  const _FriendsPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 40);
    canvas.drawOval(const Rect.fromLTWH(0, 6, 25, 29), Paint()..color = sky);
    canvas.drawOval(const Rect.fromLTWH(16, 1, 24, 31), Paint()..color = mint);
    final pen = Paint()
      ..color = forest
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final x in [8.0, 14.0, 25.0, 31.0]) {
      canvas.drawLine(Offset(x, 15), Offset(x, 17), pen);
    }
    pen.style = PaintingStyle.stroke;
    canvas.drawArc(const Rect.fromLTWH(8, 18, 7, 6), 0, math.pi, false, pen);
    canvas.drawArc(const Rect.fromLTWH(25, 18, 7, 6), 0, math.pi, false, pen);
  }

  @override
  bool shouldRepaint(_FriendsPainter oldDelegate) => false;
}

/// Native Flutter illustration, crisp at every size and requiring no downloads.
class NameNotes extends StatelessWidget {
  const NameNotes({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 190,
      child: Center(
        child: SizedBox(
          width: 310,
          height: 190,
          child: Stack(
            children: [
              Positioned(
                left: 2,
                top: 40,
                child: Transform.rotate(
                  angle: -.14,
                  child: _note(
                    context,
                    context.tr('your friend'),
                    sky,
                    176,
                    120,
                  ),
                ),
              ),
              Positioned(
                right: 6,
                top: 14,
                child: Transform.rotate(
                  angle: .10,
                  child: _note(context, context.tr('you?'), mint, 174, 144),
                ),
              ),
              Positioned(
                left: 120,
                top: 3,
                child: Transform.rotate(
                  angle: -.05,
                  child: Container(
                    width: 58,
                    height: 18,
                    color: butter.withValues(alpha: .8),
                  ),
                ),
              ),
              Positioned(
                left: 131,
                bottom: 2,
                child: Text(
                  context.tr('a familiar face. a secret name.'),
                  style: TextStyle(fontSize: 10, color: mutedInk),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _note(
    BuildContext context,
    String name,
    Color color,
    double width,
    double height,
  ) => Container(
    width: width,
    height: height,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            context.tr('hello, today I’m'),
            style: TextStyle(fontSize: 11, color: mutedInk),
          ),
        ),
        const Spacer(),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w500,
              color: ink,
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    ),
  );
}
