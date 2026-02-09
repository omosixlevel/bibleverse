import 'package:flutter/material.dart';
import 'dart:math' as math;

class TaskCompletionAnimation extends StatefulWidget {
  final Widget child;
  final bool isCompleted;
  final VoidCallback? onAnimationComplete;

  const TaskCompletionAnimation({
    super.key,
    required this.child,
    required this.isCompleted,
    this.onAnimationComplete,
  });

  @override
  State<TaskCompletionAnimation> createState() =>
      _TaskCompletionAnimationState();
}

class _TaskCompletionAnimationState extends State<TaskCompletionAnimation>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.isCompleted) {
      _checkController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TaskCompletionAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _checkController.forward().then((_) {
        _confettiController.forward(from: 0.0);
        widget.onAnimationComplete?.call();
      });
    } else if (!widget.isCompleted && oldWidget.isCompleted) {
      _checkController.reverse();
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isCompleted || _checkController.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Center(
                    child: CustomPaint(
                      size: const Size(100, 100),
                      painter: CheckmarkPainter(_checkController.value),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _confettiController,
                    builder: (context, child) {
                      if (_confettiController.value == 0 ||
                          _confettiController.value == 1) {
                        return const SizedBox.shrink();
                      }
                      return CustomPaint(
                        size: Size.infinite,
                        painter: ConfettiPainter(_confettiController.value),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class CheckmarkPainter extends CustomPainter {
  final double progress;

  CheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = Colors.green.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.45, size.height * 0.75);
    path.lineTo(size.width * 0.8, size.height * 0.3);

    final metrics = path.computeMetrics().first;
    final extractPath = metrics.extractPath(0, metrics.length * progress);

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.progress)
    : particles = List.generate(30, (i) => ConfettiParticle(i));

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42);
    for (var particle in particles) {
      particle.update(progress, size);
      final paint = Paint()..color = particle.color.withOpacity(1 - progress);
      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class ConfettiParticle {
  late double x, y, size;
  late Color color;
  late double vx, vy;

  ConfettiParticle(int index) {
    final rand = math.Random(index);
    color = Colors.primaries[rand.nextInt(Colors.primaries.length)];
    size = rand.nextDouble() * 4 + 2;
    vx = (rand.nextDouble() - 0.5) * 400;
    vy = (rand.nextDouble() - 0.7) * 400;
  }

  void update(double progress, Size screenSize) {
    x = screenSize.width / 2 + vx * progress;
    y =
        screenSize.height / 2 +
        vy * progress +
        (9.8 * 100 * progress * progress); // Gravity
  }
}
