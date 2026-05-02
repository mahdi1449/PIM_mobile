import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../finance/theme/finance_theme.dart';
import '../finance/widgets/finance_widgets.dart';
import 'ai_scanning_overlay.dart';
import 'dart:math' as math;

class AiValuationResultScreen extends StatefulWidget {
  final dynamic player;
  const AiValuationResultScreen({super.key, required this.player});

  @override
  State<AiValuationResultScreen> createState() =>
      _AiValuationResultScreenState();
}

class _AiValuationResultScreenState extends State<AiValuationResultScreen> {
  bool _isScanning = true;
  bool _showResult = false;

  double _asDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString()) ?? fallback;
  }

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {
    // 1. Scanning phase (Animation duration) - Upscaled for more intensive feel
    await Future.delayed(const Duration(milliseconds: 7000));
    if (!mounted) return;

    setState(() {
      _isScanning = false;
    });

    // 2. Result transition
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    setState(() {
      _showResult = true;
    });
  }

  String _formatMoney(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final ai = widget.player['aiAnalysis'] ?? {};
    final nextValue = _asDouble(ai['nextSeasonValue']);
    final predictedValue = _asDouble(
      ai['predictedValue'] ?? ai['predicted_value'],
    );
    final currentValue = _asDouble(ai['currentValue']);
    final confidence = _asDouble(
      ai['confidenceScore'] ?? ai['confidence_score'],
    );
    final currency = (ai['currency'] ?? 'DT').toString();
    final keyFactors =
        (ai['keyFactors'] ?? ai['key_factors'] ?? const []) as List<dynamic>;
    final explanation =
        (ai['explanation'] ?? 'Market trend analysis completed.').toString();

    final first = (widget.player['firstName'] ?? '').toString();
    final last = (widget.player['lastName'] ?? '').toString();
    final fallback = (widget.player['name'] ?? 'Unknown Player').toString();
    final name = ('$first $last'.trim().isNotEmpty ? '$first $last' : fallback)
        .trim();

    final growth = currentValue > 0
        ? ((nextValue - currentValue) / currentValue) * 100
        : 0.0;
    final trend = growth.abs() < 1 ? 'STABLE' : (growth > 0 ? 'UP' : 'DOWN');
    final trendColor = trend == 'UP'
        ? FinancePalette.success
        : trend == 'DOWN'
        ? FinancePalette.danger
        : FinancePalette.muted;

    // Stats for Radar Chart
    final double speed = (widget.player['speed'] ?? 0).toDouble();
    final double endurance = (widget.player['endurance'] ?? 0).toDouble();
    final double dribbles = (widget.player['dribbles'] ?? 0).toDouble();
    final double shots = (widget.player['shots'] ?? 0).toDouble();
    final double physical = (widget.player['baseFitness'] ?? 75).toDouble();

    final isInjured = widget.player['isInjured'] == true;
    final injuryType = (widget.player['lastInjuryType'] ?? '-').toString();
    final recoveryDays = _asInt(widget.player['lastRecoveryDays'], fallback: 0);

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Deep space blue
      bottomNavigationBar: _showResult ? _buildAuthenticityFooter() : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isScanning ? 'ODIN NEURAL ANALYSIS' : 'VALUATION CERTIFIED',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: _isScanning ? FinancePalette.blue : FinancePalette.success,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. Background Content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Hero(
                  tag: 'player_${widget.player['_id']}',
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: FinancePalette.blue, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: FinancePalette.blue.withValues(alpha: 0.2),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: widget.player['photo'] != null
                          ? Image.network(
                              widget.player['photo'],
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 30),

                if (_showResult) ...[
                  // Injury summary (shown before the valuation result)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: FinancePalette.card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: FinancePalette.soft),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isInjured
                                  ? Icons.healing_rounded
                                  : Icons.health_and_safety_rounded,
                              color: isInjured
                                  ? FinancePalette.danger
                                  : FinancePalette.success,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'INJURY INPUT',
                              style: TextStyle(
                                color: FinancePalette.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _miniStat(
                                label: 'STATUS',
                                value: isInjured ? 'INJURED' : 'AVAILABLE',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _miniStat(
                                label: 'TYPE',
                                value: injuryType,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _miniStat(label: 'DAYS MISSED', value: '$recoveryDays'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Predict Player Value-style header (value + next season + confidence)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: FinancePalette.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: FinancePalette.soft),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: trendColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    trend == 'UP'
                                        ? Icons.trending_up_rounded
                                        : trend == 'DOWN'
                                        ? Icons.trending_down_rounded
                                        : Icons.trending_flat_rounded,
                                    size: 14,
                                    color: trendColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${growth.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: trendColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'CONFIDENCE ${(confidence * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: FinancePalette.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'PREDICTED VALUE',
                          style: TextStyle(
                            color: FinancePalette.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_formatMoney(predictedValue)} $currency',
                          style: TextStyle(
                            color: FinancePalette.blue,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _miniStat(
                                label: 'BASE MARKET',
                                value:
                                    '${_formatMoney(currentValue)} $currency',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _miniStat(
                                label: 'NEXT SEASON',
                                value: '${_formatMoney(nextValue)} $currency',
                                highlight: true,
                              ),
                            ),
                          ],
                        ),
                        if (keyFactors.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: keyFactors
                                .take(8)
                                .map(
                                  (k) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: FinancePalette.soft,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      k.toString(),
                                      style: TextStyle(
                                        color: FinancePalette.muted,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Text(
                          explanation,
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.6,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Radar Chart for "REAL DATA" feel
                  SizedBox(
                    height: 200,
                    child: RadarChart(
                      RadarChartData(
                        radarShape: RadarShape.polygon,
                        dataSets: [
                          RadarDataSet(
                            fillColor: FinancePalette.blue.withValues(
                              alpha: 0.3,
                            ),
                            borderColor: FinancePalette.blue,
                            entryRadius: 3,
                            dataEntries: [
                              RadarEntry(value: speed),
                              RadarEntry(value: endurance),
                              RadarEntry(value: dribbles),
                              RadarEntry(value: shots),
                              RadarEntry(value: physical),
                            ],
                          ),
                        ],
                        radarBorderData: const BorderSide(
                          color: Colors.white10,
                        ),
                        titlePositionPercentageOffset: 0.2,
                        titleTextStyle: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                        getTitle: (index, angle) {
                          switch (index) {
                            case 0:
                              return RadarChartTitle(text: 'SPEED');
                            case 1:
                              return RadarChartTitle(text: 'ENDUR');
                            case 2:
                              return RadarChartTitle(text: 'DRIBL');
                            case 3:
                              return RadarChartTitle(text: 'SHOT');
                            case 4:
                              return RadarChartTitle(text: 'PHYS');
                            default:
                              return const RadarChartTitle(text: '');
                          }
                        },
                        tickCount: 1,
                        ticksTextStyle: const TextStyle(
                          color: Colors.transparent,
                        ),
                        gridBorderData: const BorderSide(
                          color: Colors.white10,
                          width: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: FinancePalette.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: FinancePalette.soft),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              color: FinancePalette.success,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'VALUATION RATIONALE',
                              style: TextStyle(
                                color: FinancePalette.success,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          explanation,
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.6,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildDataSources(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          ),

          // 2. The Scanning Overlay
          if (_isScanning) const AiScanningOverlay(),

          if (_isScanning)
            Positioned(
              top: 150,
              left: 0,
              right: 0,
              child: Center(child: _buildLiveTicker()),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveTicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: FinancePalette.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: FinancePalette.blue,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'DATA POINTS: ${(math.Random().nextInt(9000) + 1000)}',
            style: TextStyle(
              color: FinancePalette.blue,
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FinancePalette.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? FinancePalette.blue.withValues(alpha: 0.5)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: FinancePalette.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: highlight ? FinancePalette.blue : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticityFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ODIN NEURAL HASH',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '0x${math.Random().nextInt(999999).toString().padLeft(6, '0')}f7a2c...',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 8,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataSources() {
    return Row(
      children: [
        _sourceBadge('OPTA DATA'),
        const SizedBox(width: 8),
        _sourceBadge('TRANSFERMARKT'),
        const SizedBox(width: 8),
        _sourceBadge('MEDICAL LAB 04'),
      ],
    );
  }

  Widget _sourceBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _priceColumn(
    String label,
    double value,
    Color color, {
    bool isNew = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_formatMoney(value)} DT',
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            shadows: isNew
                ? [
                    BoxShadow(
                      color: FinancePalette.blue.withValues(alpha: 0.5),
                      blurRadius: 15,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}
