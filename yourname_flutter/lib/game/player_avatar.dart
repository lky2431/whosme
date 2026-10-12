import '../l10n/app_language.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'paper_theme.dart';

const avatarNames = [
  'Cat',
  'Rabbit',
  'Bear',
  'Fox',
  'Dog',
  'Panda',
  'Frog',
  'Owl',
  'Duck',
  'Penguin',
];
const _colors = [
  Color(0xFFEBC9A9),
  Color(0xFFF1D9DC),
  Color(0xFFD9BD9D),
  Color(0xFFEDA978),
  Color(0xFFE6D2AA),
  Color(0xFFE4E9E5),
  Color(0xFFB9D6AB),
  Color(0xFFD1C4E0),
  Color(0xFFF3DB8B),
  Color(0xFFBFCFD9),
];

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, this.index = 0, this.photo, this.size = 44});
  final int index;
  final String? photo;
  final double size;
  @override
  Widget build(BuildContext context) {
    final safe = index.clamp(0, 9);
    Widget fallback() =>
        CustomPaint(size: Size.square(size), painter: _AnimalPainter(safe));
    Widget child = fallback();
    if (photo != null) {
      try {
        child = Image.memory(
          base64Decode(photo!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, error, stack) => fallback(),
        );
      } catch (_) {
        /* Malformed old photo: show the selected built-in avatar. */
      }
    }
    return Semantics(
      label: photo == null
          ? context.tr('{0} avatar', [context.tr(avatarNames[safe])])
          : context.tr('Profile photo'),
      image: true,
      child: ClipOval(
        child: SizedBox.square(dimension: size, child: child),
      ),
    );
  }
}

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final int? selected;
  final ValueChanged<int>? onSelected;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var i = 0; i < avatarNames.length; i++)
        Semantics(
          selected: selected == i,
          child: Tooltip(
            message: context.tr(avatarNames[i]),
            child: OutlinedButton(
              key: ValueKey('avatar-$i'),
              onPressed: onSelected == null ? null : () => onSelected!(i),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(5),
                minimumSize: const Size(56, 56),
                backgroundColor: selected == i ? mint : Colors.transparent,
                side: BorderSide(
                  color: selected == i ? forest : Colors.transparent,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  PlayerAvatar(index: i),
                  if (selected == i)
                    const Positioned(
                      right: -4,
                      bottom: -4,
                      child: Icon(Icons.check_circle, color: forest, size: 18),
                    ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

/// Ten small vector animal portraits, matching the game's paper illustrations.
class _AnimalPainter extends CustomPainter {
  const _AnimalPainter(this.index);
  final int index;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64);
    final color = _colors[index];
    final pen = Paint()
      ..color = ink
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    void oval(double x, double y, double w, double h, Color c) =>
        canvas.drawOval(Rect.fromLTWH(x, y, w, h), Paint()..color = c);
    void triangle(List<Offset> points, Color c) {
      final path = Path()..moveTo(points[0].dx, points[0].dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path..close(), Paint()..color = c);
    }

    canvas.drawCircle(
      const Offset(32, 32),
      32,
      Paint()..color = const Color(0xFFF5F0E6),
    );
    if (index == 1) {
      oval(15, 1, 12, 34, color);
      oval(37, 1, 12, 34, color);
      oval(19, 5, 4, 22, const Color(0xFFD99EA8));
      oval(41, 5, 4, 22, const Color(0xFFD99EA8));
    } else if ([0, 3, 7].contains(index)) {
      triangle([
        const Offset(10, 29),
        const Offset(10, 7),
        const Offset(29, 22),
      ], color);
      triangle([
        const Offset(35, 22),
        const Offset(54, 7),
        const Offset(54, 29),
      ], color);
    } else if ([2, 5].contains(index)) {
      oval(8, 10, 19, 20, index == 5 ? ink : color);
      oval(37, 10, 19, 20, index == 5 ? ink : color);
    } else if (index == 4) {
      oval(5, 19, 17, 34, const Color(0xFFA18269));
      oval(42, 19, 17, 34, const Color(0xFFA18269));
    } else if (index == 6) {
      oval(10, 12, 19, 22, color);
      oval(35, 12, 19, 22, color);
    }
    oval(10, index == 1 ? 22 : 18, 44, index == 1 ? 36 : 40, color);
    if ([3, 9].contains(index)) oval(18, 28, 28, 27, const Color(0xFFFFF9EA));
    if (index == 5) {
      oval(17, 29, 12, 15, ink);
      oval(35, 29, 12, 15, ink);
    }
    if (index == 7) {
      oval(14, 25, 18, 21, const Color(0xFFFFF9EA));
      oval(32, 25, 18, 21, const Color(0xFFFFF9EA));
    }
    final eye = Paint()..color = index == 5 ? Colors.white : ink;
    canvas.drawCircle(Offset(23, index == 6 ? 25 : 35), 2.1, eye);
    canvas.drawCircle(Offset(41, index == 6 ? 25 : 35), 2.1, eye);
    if ([7, 8, 9].contains(index)) {
      oval(26, 40, 12, 7, const Color(0xFFC58A3F));
    } else {
      canvas.drawCircle(const Offset(32, 41), 2, pen);
      pen.style = PaintingStyle.stroke;
      canvas.drawArc(
        const Rect.fromLTWH(26, 41, 12, 9),
        0,
        math.pi,
        false,
        pen,
      );
    }
    if (index == 0) {
      canvas.drawLine(const Offset(9, 40), const Offset(19, 42), pen);
      canvas.drawLine(const Offset(45, 42), const Offset(55, 40), pen);
    }
  }

  @override
  bool shouldRepaint(_AnimalPainter oldDelegate) => oldDelegate.index != index;
}
