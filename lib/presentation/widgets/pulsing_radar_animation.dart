import 'package:flutter/material.dart';

/// Animasi radar pulsing untuk mengindikasikan sesi NFC sedang aktif.
///
/// Menampilkan 3 lingkaran konsentris yang memudar dan mengembang
/// secara bergantian, menciptakan efek sonar/radar.
class PulsingRadarAnimation extends StatefulWidget {
  const PulsingRadarAnimation({super.key, this.size = 100, this.color});

  final double size;
  final Color? color;

  @override
  State<PulsingRadarAnimation> createState() => _PulsingRadarAnimationState();
}

class _PulsingRadarAnimationState extends State<PulsingRadarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final size = widget.size;

    return SizedBox(
      width: size * 2.4,
      height: size * 2.4,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            _buildPulse(color, size, 1.0, 0.0),
            _buildPulse(color, size, 0.8, 0.3),
            _buildPulse(color, size, 0.6, 0.6),
            child!,
          ],
        ),
        child: _NfcIcon(size: size * 0.55, color: color),
      ),
    );
  }

  Widget _buildPulse(
    Color color,
    double size,
    double opacityFactor,
    double delay,
  ) {
    final progress = (_animation.value - delay).clamp(0.0, 1.0);
    return Container(
      width: size * (1 + progress),
      height: size * (1 + progress),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: (1 - progress) * opacityFactor * 0.35),
        border: Border.all(
          color: color.withValues(alpha: (1 - progress) * opacityFactor * 0.6),
          width: 1.5,
        ),
      ),
    );
  }
}

class _NfcIcon extends StatelessWidget {
  const _NfcIcon({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: 0.15),
      border: Border.all(color: color, width: 2),
    ),
    child: Icon(Icons.nfc_rounded, color: color, size: size * 0.55),
  );
}
