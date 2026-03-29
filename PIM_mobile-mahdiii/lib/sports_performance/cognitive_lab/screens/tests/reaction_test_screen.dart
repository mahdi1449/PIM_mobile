import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class ReactionTestScreen extends StatefulWidget {
  final Function(Map<String, int>) onComplete;

  const ReactionTestScreen({super.key, required this.onComplete});

  @override
  State<ReactionTestScreen> createState() => _ReactionTestScreenState();
}

class _ReactionTestScreenState extends State<ReactionTestScreen> with SingleTickerProviderStateMixin {
  final int totalRounds = 15;
  int currentRound = 0;
  List<int> reactionTimes = [];
  
  bool isWaiting = true;
  bool isGoTarget = true;
  double topPos = 0.5;
  double leftPos = 0.5;
  DateTime? showTime;
  
  int correctGo = 0;
  int missedGo = 0;
  int falseAlarms = 0;
  int correctRejections = 0;
  
  Timer? delayTimer;
  Timer? noGoTimer;
  final Random random = Random();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _startNextRound();
  }

  @override
  void dispose() {
    delayTimer?.cancel();
    noGoTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startNextRound() {
    if (!mounted) return;
    setState(() {
      isWaiting = true;
      noGoTimer?.cancel();
    });
    
    final delay = Duration(milliseconds: 800 + random.nextInt(1600));
    delayTimer = Timer(delay, () {
      if (!mounted) return;
      
      setState(() {
        isGoTarget = random.nextDouble() < 0.7;
        topPos = 0.15 + (random.nextDouble() * 0.7);
        leftPos = 0.15 + (random.nextDouble() * 0.7);
        isWaiting = false;
        showTime = DateTime.now();
      });

      if (!isGoTarget) {
        noGoTimer = Timer(const Duration(milliseconds: 1000), () {
          if (!mounted || isWaiting) return;
          _handleCorrectRejection();
        });
      }
    });
  }

  void _onTargetTap() {
    if (isWaiting || showTime == null) return;
    
    final elapsed = DateTime.now().difference(showTime!).inMilliseconds;

    if (isGoTarget) {
      reactionTimes.add(elapsed);
      correctGo++;
      _nextStep();
    } else {
      falseAlarms++;
      _nextStep();
    }
  }

  void _handleCorrectRejection() {
    correctRejections++;
    _nextStep();
  }

  void _nextStep() {
    currentRound++;
    if (currentRound >= totalRounds) {
      _finishTest();
    } else {
      _startNextRound();
    }
  }

  void _finishTest() {
    if (reactionTimes.isEmpty && correctGo == 0) {
      widget.onComplete({'avgMs': 1000, 'bestMs': 1000, 'worstMs': 1000, 'accuracy': 0});
      return;
    }
    
    int avgMs = reactionTimes.isNotEmpty 
        ? (reactionTimes.reduce((a, b) => a + b) / reactionTimes.length).round()
        : 800;
    int bestMs = reactionTimes.isNotEmpty ? reactionTimes.reduce(min) : 800;
    int worstMs = reactionTimes.isNotEmpty ? reactionTimes.reduce(max) : 1200;
    int accuracy = (((correctGo + correctRejections) / totalRounds) * 100).round();

    widget.onComplete({
      'avgMs': avgMs,
      'bestMs': bestMs,
      'worstMs': worstMs,
      'accuracy': accuracy,
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color targetColor = isGoTarget ? Colors.cyanAccent : Colors.redAccent;
    final String instructionText = isGoTarget ? "TAP NOW!" : "STAY STOP!";

    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Stack(
        children: [
          Column(
            children: [
              // Unified HUD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoColumn("ROUND", "${currentRound + 1}/$totalRounds", Colors.white70),
                    _buildInfoColumn("ACCURACY", "${(((correctGo + correctRejections) / (currentRound == 0 ? 1 : currentRound)) * 100).round()}%", Colors.cyanAccent),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Glass Instruction Card (Center when waiting)
              if (isWaiting)
                Expanded(
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: Tween(begin: 0.9, end: 1.1).animate(_pulseController),
                            child: Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 4),
                                boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 20)],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'READY FOR STIMULUS',
                            style: TextStyle(color: Colors.white24, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 4),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'CHOICE REACTION PROTOCOL',
                            style: TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
            ],
          ),

          // Target (Overlays)
          if (!isWaiting)
            Align(
              alignment: FractionalOffset(leftPos, topPos),
              child: GestureDetector(
                onTap: _onTargetTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            targetColor.withOpacity(0.3),
                            targetColor.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: targetColor.withOpacity(0.8), width: 4),
                        boxShadow: [
                          BoxShadow(color: targetColor.withOpacity(0.4), blurRadius: 40, spreadRadius: 5),
                          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isGoTarget ? Icons.bolt : Icons.block,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      instructionText,
                      style: TextStyle(
                        color: targetColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        shadows: [Shadow(color: targetColor, blurRadius: 10)],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Subtle Grid Background
          IgnorePointer(
            child: Opacity(
              opacity: 0.05,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
                itemBuilder: (c, i) => Container(decoration: BoxDecoration(border: Border.all(color: Colors.white12))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
