import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../services/api_service.dart';
import '../ui/components/app_card.dart';
import '../ui/theme/app_spacing.dart';
import '../finance/theme/finance_theme.dart';
import 'player_value_api.dart';
import 'player_value_models.dart';

class PlayerValueScreen extends StatefulWidget {
  const PlayerValueScreen({super.key});

  @override
  State<PlayerValueScreen> createState() => _PlayerValueScreenState();
}

class _PlayerValueScreenState extends State<PlayerValueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = PlayerValueApi();
  final _backend = ApiService();

  final _ageController = TextEditingController(text: '24');
  final _minutesController = TextEditingController(text: '2850');
  final _goalsController = TextEditingController(text: '12');
  final _assistsController = TextEditingController(text: '8');
  final _ratingController = TextEditingController(text: '7.2');
  final _consistencyController = TextEditingController(text: '80');

  final _speedController = TextEditingController(text: '70');
  final _enduranceController = TextEditingController(text: '70');
  final _distanceController = TextEditingController(text: '10');
  final _dribblesController = TextEditingController(text: '40');
  final _shotsController = TextEditingController(text: '20');
  final _heartRateController = TextEditingController(text: '65');

  final _fitnessController = TextEditingController(text: '75');
  final _medicalRiskController = TextEditingController(text: '0');

  bool _isInjuredNow = false;
  int _injuryCount = 0;
  String? _injuryType;
  final _injuryDaysController = TextEditingController(text: '0');

  // Snapshot of injury inputs used for the last prediction (so the result view
  // reflects what was submitted, even if the form changes afterwards).
  bool? _lastPredIsInjured;
  int? _lastPredInjuryCount;
  String? _lastPredInjuryType;
  int? _lastPredDaysMissed;

  bool _loading = false;
  String? _error;
  PlayerValueResponse? _result;

  bool _loadingPlayers = false;
  bool _loadingAnalyses = false;
  List<PlayerModel> _players = [];
  PlayerModel? _selectedPlayer;
  List<Map<String, dynamic>> _analyses = [];

  int _viewIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _minutesController.dispose();
    _goalsController.dispose();
    _assistsController.dispose();
    _ratingController.dispose();
    _consistencyController.dispose();
    _speedController.dispose();
    _enduranceController.dispose();
    _distanceController.dispose();
    _dribblesController.dispose();
    _shotsController.dispose();
    _heartRateController.dispose();
    _fitnessController.dispose();
    _medicalRiskController.dispose();
    _injuryDaysController.dispose();
    super.dispose();
  }

  void _applyPlayerDefaults(PlayerModel player) {
    if (player.age > 0) {
      _ageController.text = player.age.toString();
    }
    if (player.baseFitness > 0) {
      _fitnessController.text = player.baseFitness.toString();
    }

    _injuryCount = player.injuryHistory.clamp(0, 10).toInt();
    _isInjuredNow = player.isInjured == true;
    _injuryType = (player.lastInjuryType?.trim().isNotEmpty ?? false)
        ? player.lastInjuryType
        : null;
    _injuryDaysController.text =
        (player.lastRecoveryDays ?? (_isInjuredNow ? 14 : 0)).toString();

    // Optional telemetry fields (often present in Player schema)
    if (player.speed > 0)
      _speedController.text = player.speed.toStringAsFixed(0);
    if (player.endurance > 0) {
      _enduranceController.text = player.endurance.toStringAsFixed(0);
    }
    if (player.distance > 0) {
      _distanceController.text = player.distance.toStringAsFixed(0);
    }
    if (player.dribbles > 0) {
      _dribblesController.text = player.dribbles.toStringAsFixed(0);
    }
    if (player.shots > 0)
      _shotsController.text = player.shots.toStringAsFixed(0);
    if (player.heartRate > 0) {
      _heartRateController.text = player.heartRate.toStringAsFixed(0);
    }

    if (player.lastInjuryProbability != null) {
      _medicalRiskController.text = (player.lastInjuryProbability!.clamp(
        0,
        5,
      )).toStringAsFixed(2);
    }
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _loadingPlayers = true;
    });
    try {
      final response = await _backend.getPlayers(page: 1, limit: 200);
      if (response['success'] == true) {
        final data = response['data'];
        final list = data is List
            ? data
            : (data is Map && data['data'] is List ? data['data'] as List : []);
        final players = list
            .map((item) => PlayerModel.fromJson(item as Map<String, dynamic>))
            .toList();
        setState(() {
          _players = players;
          if (_selectedPlayer == null && players.isNotEmpty) {
            _selectedPlayer = players.first;
            _applyPlayerDefaults(players.first);
            _loadAnalyses(players.first.id);
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loadingPlayers = false);
      }
    }
  }

  Future<void> _loadAnalyses(String playerId) async {
    setState(() {
      _loadingAnalyses = true;
      _analyses = [];
    });
    try {
      final response = await _backend.getPlayerAnalyses(playerId);
      if (response['success'] == true) {
        final data = response['data'];
        final list = data is List
            ? data
            : (data is Map && data['data'] is List ? data['data'] as List : []);
        setState(() {
          _analyses = list
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loadingAnalyses = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final age = int.tryParse(_ageController.text.trim()) ?? 25;
      final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
      final goals = int.tryParse(_goalsController.text.trim()) ?? 0;
      final assists = int.tryParse(_assistsController.text.trim()) ?? 0;

      final speed = double.tryParse(_speedController.text.trim()) ?? 0;
      final endurance = double.tryParse(_enduranceController.text.trim()) ?? 0;
      final distance = double.tryParse(_distanceController.text.trim()) ?? 0;
      final dribbles = double.tryParse(_dribblesController.text.trim()) ?? 0;
      final shots = double.tryParse(_shotsController.text.trim()) ?? 0;
      final heartRate = double.tryParse(_heartRateController.text.trim()) ?? 0;

      final fitness = double.tryParse(_fitnessController.text.trim()) ?? 75;
      final daysMissed = _isInjuredNow
          ? (int.tryParse(_injuryDaysController.text.trim()) ?? 0)
          : 0;
      final recoveryTime = daysMissed.toDouble();

      final manualMedicalRisk = double.tryParse(
        _medicalRiskController.text.trim(),
      );
      final medicalRiskScore =
          manualMedicalRisk ??
          _computeMedicalRiskScore(_injuryType, _injuryCount, daysMissed);

      final rating = double.tryParse(_ratingController.text.trim()) ?? 7.0;
      final consistency =
          double.tryParse(_consistencyController.text.trim()) ?? 80;

      final injuries = _isInjuredNow && _injuryCount == 0 ? 1 : _injuryCount;

      _lastPredIsInjured = _isInjuredNow;
      _lastPredInjuryCount = injuries;
      _lastPredInjuryType = _injuryType;
      _lastPredDaysMissed = daysMissed;

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

      final response = await _api.predict(request);
      setState(() {
        _result = response;
        _viewIndex = 1;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    FinancePalette.setDarkMode(Theme.of(context).brightness == Brightness.dark);
    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _viewIndex == 0
                ? _buildValuationView(context)
                : _buildForecastView(context),
          ),
        ),
        _buildBottomNav(context),
      ],
    );
  }

  Widget _buildValuationView(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('valuation'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerRow(context, showBack: false),
          const SizedBox(height: 12),
          Text(
            'Market Valuation',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Enter performance metrics to calculate projected player worth via Value AI.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: FinancePalette.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _playerPicker(),
                  _metricField('AGE', _ageController),
                  _metricField('MINUTES PLAYED', _minutesController),
                  _metricField('GOALS', _goalsController),
                  _metricField('ASSISTS', _assistsController),
                  _injurySection(),
                  _metricField('RATING / MATCH (0-10)', _ratingController),
                  _metricField('CONSISTENCY (0-100)', _consistencyController),
                  _advancedMetrics(),
                  const SizedBox(height: AppSpacing.s16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: FinancePalette.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _loading ? 'Predicting...' : 'Predict Value',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'POWERED BY PROPRIETARY NEURAL SCOUT ENGINE',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: FinancePalette.muted,
                        letterSpacing: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _infoCard(
            icon: Icons.trending_up_rounded,
            title: 'Predictive Accuracy',
            body:
                'Our AI models maintain a 94.2% correlation with actual transfer fees across European Top 5 leagues.',
          ),
          const SizedBox(height: 12),
          _infoCard(
            icon: Icons.verified_user_rounded,
            title: 'Verified Data',
            body:
                'Sourced from real-time performance telemetry and historical valuation benchmarks.',
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _errorCard(context, _error!),
          ],
        ],
      ),
    );
  }

  Widget _buildForecastView(BuildContext context) {
    final latest = _analyses.isNotEmpty ? _analyses.first : null;
    return SingleChildScrollView(
      key: const ValueKey('forecast'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerRow(context, showBack: true),
          const SizedBox(height: 12),
          Text(
            'Market Selector',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: FinancePalette.cyan,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                if (_loadingPlayers)
                  const LinearProgressIndicator()
                else
                  DropdownButtonFormField<String>(
                    value: _selectedPlayer?.id,
                    items: _players
                        .map(
                          (player) => DropdownMenuItem<String>(
                            value: player.id,
                            child: Text(player.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null || _players.isEmpty) return;
                      final selected = _players.firstWhere(
                        (p) => p.id == value,
                        orElse: () => _players.first,
                      );
                      setState(() {
                        _selectedPlayer = selected;
                        // Avoid showing the previous player's prediction.
                        _result = null;
                        _error = null;
                      });
                      _applyPlayerDefaults(selected);
                      setState(() {});
                      _loadAnalyses(selected.id);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Player',
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _submit,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: FinancePalette.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Run New Prediction'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_loadingAnalyses)
            const LinearProgressIndicator()
          else if (latest == null)
            _analysisPlaceholderCard()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                if (!isWide) {
                  return Column(
                    children: [
                      _analysisForecastCard(context, latest),
                      const SizedBox(height: 16),
                      _vitalsCard(context, latest),
                    ],
                  );
                }

                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.35,
                  children: [
                    _analysisForecastCard(context, latest),
                    _vitalsCard(context, latest),
                  ],
                );
              },
            ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                if (!isWide) {
                  return Column(
                    children: [
                      _injuryResultCard(),
                      const SizedBox(height: 12),
                      _marketValuationCard(context),
                    ],
                  );
                }

                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.25,
                  children: [
                    _injuryResultCard(),
                    _marketValuationCard(context),
                  ],
                );
              },
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            _errorCard(context, _error!),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: FinancePalette.card,
        border: Border(top: BorderSide(color: FinancePalette.soft)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(Icons.sports_soccer_rounded, 'Pitch', false),
          _navItem(Icons.search_rounded, 'Scout', false),
          _navCenterItem(),
          _navItem(Icons.groups_rounded, 'Squad', false),
          _navItem(Icons.cases_rounded, 'Office', false),
        ],
      ),
    );
  }

  Widget _headerRow(BuildContext context, {required bool showBack}) {
    return Row(
      children: [
        if (showBack)
          IconButton(
            onPressed: () => setState(() => _viewIndex = 0),
            icon: const Icon(Icons.arrow_back),
          )
        else
          CircleAvatar(
            radius: 18,
            backgroundColor: FinancePalette.soft,
            child: Icon(Icons.person, color: FinancePalette.cyan),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'PLAYER VALUE AI',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              letterSpacing: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    final color = active ? FinancePalette.blue : FinancePalette.muted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 10,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _navCenterItem() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: FinancePalette.blue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: FinancePalette.blue.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            'VALUE AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricField(
    String label,
    TextEditingController controller, {
    String? prefixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: FinancePalette.cyan,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _requiredNumber,
            decoration: InputDecoration(prefixText: prefixText),
          ),
        ],
      ),
    );
  }

  double _computeMedicalRiskScore(
    String? injuryType,
    int injuryCount,
    int daysMissed,
  ) {
    // Keep the range reasonable (0-5) because the Python model expects small values.
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

  Widget _playerPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLAYER',
            style: TextStyle(
              color: FinancePalette.cyan,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPlayer?.id,
            items: _players
                .map(
                  (player) => DropdownMenuItem<String>(
                    value: player.id,
                    child: Text(player.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null || _players.isEmpty) return;
              final selected = _players.firstWhere(
                (p) => p.id == value,
                orElse: () => _players.first,
              );
              setState(() {
                _selectedPlayer = selected;
              });
              _applyPlayerDefaults(selected);
              _loadAnalyses(selected.id);
            },
            decoration: InputDecoration(
              hintText: _loadingPlayers
                  ? 'Loading players...'
                  : 'Select player',
            ),
          ),
        ],
      ),
    );
  }

  Widget _injurySection() {
    final types = <String>[
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INJURY INPUT',
            style: TextStyle(
              color: FinancePalette.cyan,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            value: _isInjuredNow,
            contentPadding: EdgeInsets.zero,
            title: const Text('Currently injured'),
            onChanged: (value) => setState(() => _isInjuredNow = value),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _injuryCount,
                  items: List.generate(
                    11,
                    (i) => DropdownMenuItem<int>(
                      value: i,
                      child: Text(i == 0 ? '0 injuries' : '$i injuries'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _injuryCount = value);
                  },
                  decoration: const InputDecoration(labelText: 'Injury count'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: (_injuryType == null || _injuryType == 'None')
                      ? 'None'
                      : _injuryType,
                  items: types
                      .map(
                        (t) =>
                            DropdownMenuItem<String>(value: t, child: Text(t)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _injuryType = value == null || value == 'None'
                          ? null
                          : value;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Injury type'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Opacity(
            opacity: _isInjuredNow ? 1 : 0.5,
            child: IgnorePointer(
              ignoring: !_isInjuredNow,
              child: _metricField(
                'DAYS MISSED (IF INJURED)',
                _injuryDaysController,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _advancedMetrics() {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      collapsedIconColor: FinancePalette.muted,
      iconColor: FinancePalette.muted,
      title: Text(
        'Advanced Metrics (manual)',
        style: TextStyle(
          color: FinancePalette.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
      children: [
        _metricField('SPEED (0-100)', _speedController),
        _metricField('ENDURANCE (0-100)', _enduranceController),
        _metricField('DISTANCE (KM)', _distanceController),
        _metricField('DRIBBLES', _dribblesController),
        _metricField('SHOTS', _shotsController),
        _metricField('HEART RATE', _heartRateController),
        _metricField('FITNESS LEVEL (0-100)', _fitnessController),
        _metricField('MEDICAL RISK (0-5)', _medicalRiskController),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FinancePalette.soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: FinancePalette.cyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: FinancePalette.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String text) {
    return AppCard(
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: FinancePalette.muted),
      ),
    );
  }

  Widget _analysisPlaceholderCard() {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FinancePalette.soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.insights_rounded,
              color: FinancePalette.blue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insights Ready',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Run a new prediction to generate an analysis snapshot for this player.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: FinancePalette.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _analysisForecastCard(
    BuildContext context,
    Map<String, dynamic> analysis,
  ) {
    final ai = analysis['aiAnalysis'] as Map<String, dynamic>? ?? {};
    final confidence = ai['confidence'];
    final cluster = ai['cluster'];
    final potential = ai['potentialScore'];
    final analyzedAt = ai['analyzedAt'];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: FinancePalette.soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_graph_rounded,
                  color: FinancePalette.cyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Performance Forecast',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last analysis computed on ${analyzedAt ?? '-'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: FinancePalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: FinancePalette.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'LIVE ENGINE ACTIVE',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: FinancePalette.blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Prediction Confidence',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: confidence is num ? confidence.toDouble() : 0.0,
            color: FinancePalette.blue,
            backgroundColor: FinancePalette.soft,
          ),
          const SizedBox(height: 12),
          Text('Tactical Cluster: ${cluster ?? '-'}'),
          Text('Potential Ceiling: ${potential ?? '-'} / 100'),
        ],
      ),
    );
  }

  Widget _vitalsCard(BuildContext context, Map<String, dynamic> analysis) {
    final ai = analysis['aiAnalysis'] as Map<String, dynamic>? ?? {};
    final metrics = ai['metrics'] as Map<String, dynamic>? ?? {};
    final items = {
      'Speed': metrics['speed'],
      'Endurance': metrics['endurance'],
      'Distance': metrics['distance'],
      'Dribbles': metrics['dribbles'],
      'Shots': metrics['shots'],
      'Injuries': metrics['injuries'],
      'Heart Rate': metrics['heart_rate'],
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vitals & Output',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 720 ? 3 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.1,
                children: items.entries
                    .map(
                      (entry) => Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FinancePalette.soft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key.toUpperCase(),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: FinancePalette.muted,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              entry.value?.toString() ?? '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _marketValuationCard(BuildContext context) {
    final confidencePct = (_result!.confidenceScore.clamp(0, 1) * 100)
        .toStringAsFixed(0);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Market Valuation',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: FinancePalette.soft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'CONF $confidencePct%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: FinancePalette.muted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${_result!.predictedValue.toStringAsFixed(2)} ${_result!.currency}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: FinancePalette.blue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.4,
            children: [
              _chipStat(
                'NEXT SEASON',
                '${_result!.nextSeasonValue.toStringAsFixed(2)} ${_result!.currency}',
              ),
              _chipStat('CURRENCY', _result!.currency),
            ],
          ),
          if (_result!.keyFactors.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _result!.keyFactors
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
                        k,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: FinancePalette.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            _result!.explanation,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: FinancePalette.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _injuryResultCard() {
    final isInjured = _lastPredIsInjured == true;
    final type = (_lastPredInjuryType == null || _lastPredInjuryType!.isEmpty)
        ? '-'
        : _lastPredInjuryType!;
    final count = _lastPredInjuryCount ?? 0;
    final days = _lastPredDaysMissed ?? 0;

    return AppCard(
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: FinancePalette.muted,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      (isInjured
                              ? FinancePalette.danger
                              : FinancePalette.success)
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isInjured ? 'INJURED' : 'AVAILABLE',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isInjured
                        ? FinancePalette.danger
                        : FinancePalette.success,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.4,
            children: [
              _chipStat('COUNT', '$count'),
              _chipStat('TYPE', type),
              _chipStat('DAYS MISSED', '$days'),
              _chipStat('RISK', isInjured ? 'HIGH' : 'LOW'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FinancePalette.soft,
        borderRadius: BorderRadius.circular(16),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(BuildContext context, String message) {
    return AppCard(
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final normalized = value.trim().replaceAll(',', '.');
    return num.tryParse(normalized) == null ? 'Number required' : null;
  }
}
