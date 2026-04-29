import 'package:flutter/material.dart';
import '../finance/theme/finance_theme.dart';

class AiScanningOverlay extends StatefulWidget {
  const AiScanningOverlay({super.key});

  @override
  State<AiScanningOverlay> createState() => _AiScanningOverlayState();
}

class _AiScanningOverlayState extends State<AiScanningOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _messageIndex = 0;
  final List<String> _stages = [
    '[CONNECTING TO ODIN MAPPING...]',
    '[ANALYZING PHYSICAL TELEMETRY...]',
    '[CORRELATING GLOBAL MARKET TRENDS...]',
    '[FINALIZING VALUATION MATRIX...]',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _startMessageCycle();
  }

  void _startMessageCycle() async {
    for (int i = 0; i < _stages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      setState(() {
        _messageIndex = i;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _ScannerPainter(_controller.value),
              child: Container(),
            );
          },
        ),
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              _stages[_messageIndex],
              style: TextStyle(
                color: FinancePalette.blue.withValues(alpha: 0.8),
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScannerPainter extends CustomPainter {
  final double progress;

  _ScannerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          FinancePalette.blue.withValues(alpha: 0.1),
          FinancePalette.blue,
          FinancePalette.blue.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
      ).createShader(
        Rect.fromLTWH(0, (progress * size.height) - 40, size.width, 80),
      );

    final linePaint = Paint()
      ..color = FinancePalette.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final y = progress * size.height;

    // Draw the scanning line
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      linePaint,
    );

    // Draw the glow
    canvas.drawRect(
      Rect.fromLTWH(0, y - 20, size.width, 40),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
