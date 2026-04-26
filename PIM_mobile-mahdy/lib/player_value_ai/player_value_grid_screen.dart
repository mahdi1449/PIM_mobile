import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../finance/theme/finance_theme.dart';
import '../finance/widgets/finance_widgets.dart';
import 'ai_valuation_result_screen.dart';
import 'player_value_api.dart';
import 'player_value_models.dart';

class PlayerValueGridScreen extends StatefulWidget {
  const PlayerValueGridScreen({super.key});

  @override
  State<PlayerValueGridScreen> createState() => _PlayerValueGridScreenState();
}

class _PlayerValueGridScreenState extends State<PlayerValueGridScreen> {
  final _apiService = ApiService();
  final _playerValueApi = PlayerValueApi();
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _players = [];
  List<dynamic> _filteredPlayers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPlayers = _players.where((p) {
        final first = (p['firstName'] ?? '').toString();
        final last = (p['lastName'] ?? '').toString();
        final fallback = (p['name'] ?? '').toString();
        final fullName =
            ('$first $last'.trim().isNotEmpty ? '$first $last' : fallback)
                .toLowerCase();
        return fullName.contains(query);
      }).toList();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _apiService.getAiDashboardPlayers();
      if (res['success'] && mounted) {
        setState(() {
          _players = res['data']['data'] ?? [];
          _filteredPlayers = List.from(_players);
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _error = res['message'] ?? 'Failed to load AI Dashboard';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  double _computeMedicalRiskScore(
    String? injuryType,
    int injuryCount,
    int daysMissed,
  ) {
    final normalizedDays = (daysMissed / 60).clamp(0.0, 1.0); // 0..60 days
    final type = (injuryType ?? '').toLowerCase();

    double typeWeight = 0.0;
    if (type.contains('acl') || type.contains('ligament')) typeWeight = 3.5;
    if (type.contains('knee')) typeWeight = 2.5;
    if (type.contains('hamstring') || type.contains('muscle')) typeWeight = 1.8;
    if (type.contains('ankle')) typeWeight = 1.3;
    if (type.contains('concussion')) typeWeight = 1.6;
    if (type.contains('back')) typeWeight = 1.7;
    if (type.contains('other') && typeWeight == 0) typeWeight = 1.0;

    final countWeight = (injuryCount.clamp(0, 6) * 0.35);
    final daysWeight = normalizedDays * 1.5;

    return (typeWeight + countWeight + daysWeight).clamp(0.0, 5.0);
  }

  double _asDouble(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString()) ?? fallback;
  }

  Future<void> _openQuickPredict(dynamic player) async {
    final first = (player['firstName'] ?? '').toString();
    final last = (player['lastName'] ?? '').toString();
    final fallbackName = (player['name'] ?? 'Unknown Player').toString();
    final name =
        ('$first $last'.trim().isNotEmpty ? '$first $last' : fallbackName)
            .trim();

    bool isInjured = player['isInjured'] == true;
    int injuryCount = _asInt(player['injuryHistory'], fallback: 0);
    String? injuryType = (player['lastInjuryType'] ?? '').toString().trim();
    if (injuryType.isEmpty) injuryType = null;
    int daysMissed = _asInt(player['lastRecoveryDays'], fallback: 0);

    final minutesCtrl = TextEditingController(text: '2000');
    final goalsCtrl = TextEditingController(text: '5');
    final assistsCtrl = TextEditingController(text: '3');
    final ratingCtrl = TextEditingController(text: '7.2');
    final consistencyCtrl = TextEditingController(text: '80');

    bool predicting = false;
    String? err;

    const types = <String>[
      'None',
      'Muscle',
      'Hamstring',
      'Ankle',
      'Knee',
      'ACL / Ligament',
      'Concussion',
      'Back',
      'Other',
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> runPrediction() async {
              setSheetState(() {
                predicting = true;
                err = null;
              });

              try {
                final age = _asInt(player['age'], fallback: 25);
                final fitness = _asDouble(player['baseFitness'], fallback: 75);
                final speed = _asDouble(player['speed']);
                final endurance = _asDouble(player['endurance']);
                final distance = _asDouble(player['distance']);
                final dribbles = _asDouble(player['dribbles']);
                final shots = _asDouble(player['shots']);
                final heartRate = _asDouble(player['heart_rate']);

                final injuries = isInjured && injuryCount == 0
                    ? 1
                    : injuryCount;
                final effectiveDays = isInjured ? daysMissed : 0;
                final recoveryTime = effectiveDays.toDouble();

                final riskFromPlayer = _asDouble(
                  player['lastInjuryProbability'],
                  fallback: 0,
                );
                final computedRisk = _computeMedicalRiskScore(
                  injuryType,
                  injuries,
                  effectiveDays,
                );
                // Keep risk small (0-5), but allow using player's last probability as a hint.
                final medicalRiskScore =
                    (riskFromPlayer > 0
                            ? (riskFromPlayer.clamp(0, 5))
                            : computedRisk)
                        .toDouble();

                final minutes = int.tryParse(minutesCtrl.text.trim()) ?? 0;
                final goals = int.tryParse(goalsCtrl.text.trim()) ?? 0;
                final assists = int.tryParse(assistsCtrl.text.trim()) ?? 0;
                final rating =
                    double.tryParse(
                      ratingCtrl.text.trim().replaceAll(',', '.'),
                    ) ??
                    7.0;
                final consistency =
                    double.tryParse(
                      consistencyCtrl.text.trim().replaceAll(',', '.'),
                    ) ??
                    80;

                final request = PlayerValueRequest(
                  speed: speed,
                  endurance: endurance,
                  distance: distance,
                  dribbles: dribbles,
                  shots: shots,
                  injuries: injuries,
                  heartRate: heartRate,
                  age: age,
                  recoveryTime: recoveryTime,
                  fitnessLevel: fitness,
                  medicalRiskScore: medicalRiskScore,
                  minutesPlayed: minutes,
                  goals: goals,
                  assists: assists,
                  ratingPerMatch: rating,
                  consistencyScore: consistency,
                );

                final response = await _playerValueApi.predict(request);

                final existingAi = (player['aiAnalysis'] ?? {}) as Map;
                final currentValue = _asDouble(
                  existingAi['currentValue'],
                  fallback: response.predictedValue,
                );

                final mergedPlayer = <String, dynamic>{
                  ...((player as Map).cast<String, dynamic>()),
                  // Use the injury inputs from the sheet for the result UI.
                  'isInjured': isInjured,
                  'lastInjuryType': injuryType,
                  'lastRecoveryDays': effectiveDays,
                  // Override analysis with the fresh prediction.
                  'aiAnalysis': {
                    'currentValue': currentValue,
                    'predictedValue': response.predictedValue,
                    'nextSeasonValue': response.nextSeasonValue,
                    'confidenceScore': response.confidenceScore,
                    'keyFactors': response.keyFactors,
                    'explanation': response.explanation,
                    'currency': response.currency,
                  },
                };

                if (!mounted) return;
                Navigator.of(context).pop(); // close sheet
                Navigator.of(this.context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        AiValuationResultScreen(player: mergedPlayer),
                  ),
                );
              } catch (e) {
                setSheetState(() {
                  err = e.toString();
                });
              } finally {
                setSheetState(() {
                  predicting = false;
                });
              }
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.62,
              minChildSize: 0.45,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border.all(
                      color: FinancePalette.soft.withValues(alpha: 0.6),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: FinancePalette.soft,
                            child: Icon(
                              Icons.person,
                              color: FinancePalette.cyan,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (player['position'] ?? 'PRO').toString(),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: FinancePalette.muted,
                                        letterSpacing: 1.1,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(this.context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AiValuationResultScreen(player: player),
                                ),
                              );
                            },
                            child: const Text('View details'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
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
                                  Icons.healing_rounded,
                                  color: FinancePalette.cyan,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'INJURY INPUT',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: FinancePalette.muted,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: isInjured,
                              title: const Text('Currently injured'),
                              onChanged: (v) =>
                                  setSheetState(() => isInjured = v),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: injuryCount,
                                    items: List.generate(
                                      11,
                                      (i) => DropdownMenuItem<int>(
                                        value: i,
                                        child: Text(
                                          i == 0 ? '0 injuries' : '$i injuries',
                                        ),
                                      ),
                                    ),
                                    onChanged: (v) => setSheetState(
                                      () => injuryCount = v ?? 0,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Injury count',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: injuryType == null
                                        ? 'None'
                                        : injuryType,
                                    items: types
                                        .map(
                                          (t) => DropdownMenuItem<String>(
                                            value: t,
                                            child: Text(t),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) => setSheetState(() {
                                      injuryType = (v == null || v == 'None')
                                          ? null
                                          : v;
                                    }),
                                    decoration: const InputDecoration(
                                      labelText: 'Injury type',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Opacity(
                              opacity: isInjured ? 1 : 0.5,
                              child: IgnorePointer(
                                ignoring: !isInjured,
                                child: TextFormField(
                                  initialValue: daysMissed.toString(),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: false,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Days absent',
                                  ),
                                  onChanged: (v) => setSheetState(() {
                                    daysMissed = int.tryParse(v.trim()) ?? 0;
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        collapsedIconColor: FinancePalette.muted,
                        iconColor: FinancePalette.muted,
                        title: Text(
                          'Manual performance (optional)',
                          style: TextStyle(
                            color: FinancePalette.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        children: [
                          _miniField(
                            label: 'Minutes played',
                            controller: minutesCtrl,
                          ),
                          _miniField(label: 'Goals', controller: goalsCtrl),
                          _miniField(label: 'Assists', controller: assistsCtrl),
                          _miniField(
                            label: 'Rating / match',
                            controller: ratingCtrl,
                          ),
                          _miniField(
                            label: 'Consistency (0-100)',
                            controller: consistencyCtrl,
                          ),
                        ],
                      ),
                      if (err != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          err!,
                          style: TextStyle(color: FinancePalette.danger),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: predicting ? null : runPrediction,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: FinancePalette.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            predicting ? 'Predicting...' : 'Launch prediction',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tip: Change injury inputs to see value impact.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: FinancePalette.muted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    minutesCtrl.dispose();
    goalsCtrl.dispose();
    assistsCtrl.dispose();
    ratingCtrl.dispose();
    consistencyCtrl.dispose();
  }

  Widget _miniField({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: FinancePalette.blue),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: FinancePalette.danger, size: 48),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return RefreshIndicator(
          onRefresh: _loadData,
          color: FinancePalette.blue,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Odin AI Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time market value predictions & trends.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: FinancePalette.muted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search for a player...',
                          hintStyle: TextStyle(color: FinancePalette.muted),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: FinancePalette.blue,
                          ),
                          filled: true,
                          fillColor: FinancePalette.card.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              if (_filteredPlayers.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.group_off_rounded,
                            color: FinancePalette.muted,
                            size: 52,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No players found',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The API returned an empty list. Create players (or run a seed script) then pull to refresh.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: FinancePalette.muted),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final player = _filteredPlayers[index];
                      return _PlayerValueCard(
                        player: player,
                        onQuickPredict: () => _openQuickPredict(player),
                      );
                    }, childCount: _filteredPlayers.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }
}

class _PlayerValueCard extends StatelessWidget {
  final dynamic player;
  final VoidCallback onQuickPredict;
  const _PlayerValueCard({required this.player, required this.onQuickPredict});

  String _formatMoney(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final ai = player['aiAnalysis'] ?? {};
    final currentValue = (ai['currentValue'] ?? 0).toDouble();
    final predictedValue = (ai['predictedValue'] ?? 0).toDouble();
    final nextSeasonValue = (ai['nextSeasonValue'] ?? predictedValue)
        .toDouble();

    final growth = currentValue > 0
        ? ((nextSeasonValue - currentValue) / currentValue) * 100
        : 0.0;
    final trend = growth.abs() < 1 ? 'STABLE' : (growth > 0 ? 'UP' : 'DOWN');

    final first = (player['firstName'] ?? '').toString();
    final last = (player['lastName'] ?? '').toString();
    final fallback = (player['name'] ?? 'Unknown Player').toString();
    final name = ('$first $last'.trim().isNotEmpty ? '$first $last' : fallback)
        .trim();

    final isUp = trend == 'UP';
    final isDown = trend == 'DOWN';
    final trendColor = isUp
        ? FinancePalette.success
        : isDown
        ? FinancePalette.danger
        : FinancePalette.muted;
    final trendIcon = isUp
        ? Icons.trending_up_rounded
        : isDown
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onQuickPredict,
        onLongPress: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AiValuationResultScreen(player: player),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: FinancePalette.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: FinancePalette.soft.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Stack(
              children: [
                // Background Gradient for AI feel
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          FinancePalette.blue.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: trendColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(trendIcon, size: 14, color: trendColor),
                            const SizedBox(width: 4),
                            Text(
                              '${growth.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: trendColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Hero(
                        tag: 'player_${player['_id']}',
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            decoration: TextDecoration
                                .none, // Fix Hero text weight issue
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        player['position'] ?? 'PRO',
                        style: TextStyle(
                          color: FinancePalette.muted,
                          fontSize: 11,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'MARKET VALUE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '${_formatMoney(predictedValue)} DT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: FinancePalette.blue,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Progress indicator for developmental stage
                      Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: FinancePalette.soft,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (predictedValue / 50000000).clamp(
                            0.1,
                            1.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: FinancePalette.blue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
