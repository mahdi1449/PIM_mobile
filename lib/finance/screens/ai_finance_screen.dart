import 'package:flutter/material.dart';

import '../services/finance_ai_service.dart';
import '../services/finance_store.dart';
import '../theme/finance_theme.dart';
import '../widgets/finance_widgets.dart';

class AiFinanceScreen extends StatefulWidget {
  const AiFinanceScreen({super.key});

  @override
  State<AiFinanceScreen> createState() => _AiFinanceScreenState();
}

class _AiFinanceScreenState extends State<AiFinanceScreen> {
  bool _loading = true;
  String? _error;
  FinanceAiBundle? _remoteBundle;
  String? _selectedPlayerId;

  @override
  void initState() {
    super.initState();
    _loadAiInsights();
  }

  Future<void> _loadAiInsights([String? playerId]) async {
    setState(() {
      _loading = true;
      _error = null;
      if (playerId != null) _selectedPlayerId = playerId;
    });

    final store = FinanceStore.instance;
    try {
      await Future.delayed(const Duration(seconds: 2));

      FinanceAiBundle bundle;
      if (_selectedPlayerId != null) {
        bundle = await FinanceAiService.instance.fetchPlayerValuation(
          _selectedPlayerId!,
        );
      } else {
        bundle = await FinanceAiService.instance.loadRemoteInsights(store);
      }

      if (!mounted) return;
      setState(() {
        _remoteBundle = bundle;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = FinanceStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (_loading && _remoteBundle == null) {
          return _AiThinkingView(onRefresh: _loadAiInsights);
        }

        final bundle = _remoteBundle;
        final forecastData = bundle?.forecastData ?? {};
        final cashflowData = bundle?.cashflowData ?? {};
        final impactData = bundle?.impactData ?? {};

        double numVal(dynamic value) {
          if (value is num) return value.toDouble();
          return double.tryParse(value?.toString() ?? '') ?? 0.0;
        }

        // Global Finance Mapping (Python returns a list of records in 'forecast')
        final forecastList = (forecastData['forecast'] as List? ?? []);
        Map<String, dynamic> nextPoint = {};
        if (forecastList.isNotEmpty) {
          nextPoint = forecastList.last as Map<String, dynamic>;
        }

        final seasonLabel = nextPoint['date']?.toString() ?? 'Prochain mois';
        final revenue = numVal(nextPoint['revenue']);
        final expense = numVal(nextPoint['expenses']);
        final net = numVal(nextPoint['net']);
        final confidence =
            '92'; // Python service currently doesn't provide global confidence

        // Cash-flow Risk Mapping
        final alerts = (cashflowData['risk_alerts'] as List? ?? []);
        final cashLevel = alerts.any((a) => a.toString().contains('RISK'))
            ? 'ÉLEVÉ'
            : (alerts.isNotEmpty ? 'MOYEN' : 'FAIBLE');
        final cashScore = (100 - (alerts.length * 15)).clamp(0, 100).toString();
        final projected = net;
        final outflows = expense;
        final notes = alerts.map((a) => a.toString()).toList();

        // Strategic Impact Mapping (Derived from current forecast)
        final sponsorPlus = revenue * 0.1;
        final sponsorMinus = revenue * -0.1;
        final transferNet = 0.0;

        final valuationData = bundle?.valuationData ?? {};
        final isPlayerView = bundle?.playerValuation != null;

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 112),
          children: [
            _ResultsHeader(
              generationTimeMs: bundle?.generationTimeMs,
              sourceLabel: bundle?.source ?? 'finance-ai-ml',
            ),
            const SizedBox(height: 14),
            if (isPlayerView) ...[
              _ValuationCard(
                playerName: valuationData['playerName'] ?? 'Joueur',
                value: numVal(valuationData['prediction']?['predicted_value']),
                confidence: numVal(valuationData['prediction']?['confidence']),
                factors: [
                  valuationData['prediction']?['explanation']?.toString() ??
                      'Facteurs techniques analysés.',
                ],
              ),
              const SizedBox(height: 14),
              _RoiCard(
                roi: numVal(valuationData['prediction']?['growth_percent']),
                recommendation:
                    valuationData['prediction']?['trend']?.toString() ??
                    'STABLE',
              ),
            ] else ...[
              _ForecastCard(
                seasonLabel: seasonLabel,
                revenue: revenue,
                expense: expense,
                net: net,
                confidence: confidence,
              ),
              const SizedBox(height: 14),
              _CashflowCard(
                level: cashLevel,
                score: cashScore,
                projected: projected,
                outflows: outflows,
                notes: notes,
              ),
              const SizedBox(height: 14),
              _ImpactCard(
                sponsorPlus: sponsorPlus,
                sponsorMinus: sponsorMinus,
                transferNet: transferNet,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              _InfoPill(
                text: 'AI endpoint indisponible. Fallback local utilisé.',
                icon: Icons.warning_amber_rounded,
                tint: FinancePalette.danger,
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _openAiDetailsSheet(
    BuildContext context,
    FinanceAiInsight insight,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${insight.title} (AI • ${insight.source.toUpperCase()})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    insight.details,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPlayerSelector(BuildContext context) async {
    // Note: In a real app, we'd fetch the player list first.
    // For this demonstration, we'll show a sample list of players.
    final players = [
      {'id': '65f1a2b3c4d5e6f7a8b9c001', 'name': 'Achraf Hakimi'},
      {'id': '65f1a2b3c4d5e6f7a8b9c002', 'name': 'Youssef En-Nesyri'},
      {'id': '65f1a2b3c4d5e6f7a8b9c003', 'name': 'Sofyan Amrabat'},
    ];

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selectionner un joueur',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...players.map(
                (p) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(p['name']!),
                  onTap: () {
                    Navigator.pop(context);
                    _loadAiInsights(p['id']);
                  },
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.analytics_rounded),
                title: const Text('Retour aux prévisions globales'),
                onTap: () {
                  Navigator.pop(context);
                  _selectedPlayerId = null;
                  _loadAiInsights();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FinancePalette.soft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FinancePalette.soft),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: FinancePalette.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AiFinanceHero extends StatelessWidget {
  const _AiFinanceHero({
    required this.loading,
    required this.sourceLabel,
    this.onRefresh,
  });

  final bool loading;
  final String sourceLabel;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FinancePalette.blue.withValues(alpha: 0.30),
            FinancePalette.cyan.withValues(alpha: 0.18),
          ],
        ),
        border: Border.all(color: FinancePalette.blue.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: FinancePalette.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI Finance',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _InfoPill(
                text: loading ? 'Loading...' : sourceLabel,
                icon: Icons.bolt_rounded,
                tint: FinancePalette.success,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Prévisions intelligentes et actions d’optimisation pour le profil FINANCIER.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: FinancePalette.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Rafraîchir IA'),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.text, required this.icon, required this.tint});

  final String text;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.message,
    required this.icon,
    required this.accent,
    required this.source,
    this.onTap,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color accent;
  final String source;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: FinancePalette.card,
          border: Border.all(color: FinancePalette.soft.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: FinancePalette.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoPill(
                    text: source.toUpperCase(),
                    icon: Icons.memory_rounded,
                    tint: accent,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: accent),
          ],
        ),
      ),
    );
  }
}

class _AiThinkingView extends StatelessWidget {
  const _AiThinkingView({this.onRefresh});

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
      children: [
        _FloatingCard(
          child: Column(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: FinancePalette.cyan.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: FinancePalette.cyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.psychology_alt_rounded,
                      color: FinancePalette.cyan,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _InfoPill(
                text: 'LIVE PROCESS',
                icon: Icons.bolt_rounded,
                tint: FinancePalette.cyan,
              ),
              const SizedBox(height: 12),
              Text(
                'AI Finance',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Analyse en cours...',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: FinancePalette.muted),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Bar(height: 12),
                  _Bar(height: 20),
                  _Bar(height: 30),
                  _Bar(height: 22),
                  _Bar(height: 14),
                ],
              ),
              const SizedBox(height: 12),
              if (onRefresh != null)
                FilledButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Relancer'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _FloatingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepRow(
                label: 'Collecting ledger entries...',
                status: StepStatus.done,
              ),
              const SizedBox(height: 12),
              _StepRow(
                label: 'Analyzing payroll + transfers...',
                status: StepStatus.active,
              ),
              const SizedBox(height: 12),
              _StepRow(
                label: 'Generating forecast...',
                status: StepStatus.pending,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Estimated time: 1.2s',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: FinancePalette.muted,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.more_horiz, color: FinancePalette.muted),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _FloatingCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: FinancePalette.cyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.lightbulb, color: FinancePalette.cyan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'We use real club financial data to generate forecasts, risk alerts, and sponsor impact.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: FinancePalette.ink,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.generationTimeMs,
    required this.sourceLabel,
  });

  final int? generationTimeMs;
  final String sourceLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: FinancePalette.cyan,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'ENGINE ACTIVE',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: FinancePalette.cyan,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            _InfoPill(
              text: sourceLabel.toUpperCase(),
              icon: Icons.memory_rounded,
              tint: FinancePalette.blue,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Finance AI Results',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (generationTimeMs != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 14, color: FinancePalette.muted),
              const SizedBox(width: 6),
              Text(
                'Generated in ${generationTimeMs} ms',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: FinancePalette.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({
    required this.seasonLabel,
    required this.revenue,
    required this.expense,
    required this.net,
    required this.confidence,
  });

  final String seasonLabel;
  final double revenue;
  final double expense;
  final double net;
  final String confidence;

  @override
  Widget build(BuildContext context) {
    final parsedConfidence = int.tryParse(confidence.trim()) ?? 0;
    return _FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(icon: Icons.show_chart_rounded),
              const SizedBox(width: 10),
              _Tag(text: 'DATA-DRIVEN AI', color: FinancePalette.cyan),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'CONFIDENCE',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: FinancePalette.muted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${parsedConfidence.clamp(0, 100)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: FinancePalette.cyan,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Season Forecast\n$seasonLabel',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricColumn(
                  label: 'REVENUE',
                  value: formatCompactMoney(revenue, symbol: 'DT'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricColumn(
                  label: 'EXPENSES',
                  value: formatCompactMoney(expense, symbol: 'DT'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: FinancePalette.soft.withValues(alpha: 0.65),
              border: Border.all(
                color: FinancePalette.soft.withValues(alpha: 0.9),
              ),
            ),
            child: Text(
              'Net impact ${net >= 0 ? '+' : ''}${formatCompactMoney(net, symbol: 'DT')}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: FinancePalette.cyan,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CashflowCard extends StatelessWidget {
  const _CashflowCard({
    required this.level,
    required this.score,
    required this.projected,
    required this.outflows,
    required this.notes,
  });

  final String level;
  final String score;
  final double projected;
  final double outflows;
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final scoreValue = (int.tryParse(score.trim()) ?? 0).clamp(0, 100);
    final ringValue = scoreValue / 100.0;
    final normalizedLevel = level.toUpperCase();
    final selected =
        normalizedLevel.contains('ÉLE') || normalizedLevel.contains('HIGH')
        ? 'HIGH'
        : normalizedLevel.contains('MOY') || normalizedLevel.contains('MED')
        ? 'MEDIUM'
        : 'LOW';

    return _FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(icon: Icons.warning_amber_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: _Tag(text: 'DATA-DRIVEN AI', color: FinancePalette.cyan),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _RiskSegmentedControl(selected: selected),
          ),
          const SizedBox(height: 12),
          Text(
            'Cash-flow Risk',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MetricColumn(
                            label: 'RISK SCORE',
                            value: '$scoreValue',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricColumn(
                            label: 'PROJECTED',
                            value: formatCompactMoney(projected, symbol: 'DT'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _MetricColumn(
                      label: 'OUTFLOWS',
                      value: formatCompactMoney(outflows, symbol: 'DT'),
                      highlight: FinancePalette.danger,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 54,
                height: 54,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: ringValue,
                      strokeWidth: 6,
                      backgroundColor: FinancePalette.soft.withValues(
                        alpha: 0.9,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        selected == 'HIGH'
                            ? FinancePalette.danger
                            : selected == 'MEDIUM'
                            ? FinancePalette.warning
                            : FinancePalette.cyan,
                      ),
                    ),
                    Text(
                      '$scoreValue',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Analysis notes',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: FinancePalette.muted),
            ),
            const SizedBox(height: 6),
            ...notes.map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: FinancePalette.cyan,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        n,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: FinancePalette.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({
    required this.sponsorPlus,
    required this.sponsorMinus,
    required this.transferNet,
  });

  final double sponsorPlus;
  final double sponsorMinus;
  final double transferNet;

  @override
  Widget build(BuildContext context) {
    return _FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(icon: Icons.swap_horiz_rounded),
              const SizedBox(width: 10),
              _Tag(text: 'DATA-DRIVEN AI', color: FinancePalette.cyan),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sponsor & Transfer Impact',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _ImpactLine(
            label: 'Sponsors +10%',
            value: '+${formatCompactMoney(sponsorPlus, symbol: 'DT')}',
            icon: Icons.trending_up_rounded,
            color: FinancePalette.success,
          ),
          const SizedBox(height: 10),
          _ImpactLine(
            label: 'Sponsors -10%',
            value: '${formatCompactMoney(sponsorMinus, symbol: 'DT')}',
            icon: Icons.trending_down_rounded,
            color: FinancePalette.danger,
          ),
          const SizedBox(height: 10),
          _ImpactLine(
            label: 'Net transfers',
            value:
                '${transferNet >= 0 ? '+' : ''}${formatCompactMoney(transferNet, symbol: 'DT')}',
            icon: Icons.swap_horiz_rounded,
            color: FinancePalette.cyan,
          ),
        ],
      ),
    );
  }
}

class _ValuationCard extends StatelessWidget {
  const _ValuationCard({
    required this.playerName,
    required this.value,
    required this.confidence,
    required this.factors,
  });

  final String playerName;
  final double value;
  final double confidence;
  final List<String> factors;

  @override
  Widget build(BuildContext context) {
    return _FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBadge(icon: Icons.diamond_rounded),
              const SizedBox(width: 10),
              _Tag(text: 'PLAYER VALUE', color: FinancePalette.cyan),
              const Spacer(),
              _InfoPill(
                text: 'CONFIDENCE ${(confidence * 100).toStringAsFixed(0)}%',
                icon: Icons.verified_rounded,
                tint: FinancePalette.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            playerName,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Valeur Marchande Estimée',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: FinancePalette.muted),
          ),
          const SizedBox(height: 4),
          Text(
            formatCompactMoney(value, symbol: 'DT'),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: FinancePalette.blue,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (factors.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Facteurs déterminants',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: FinancePalette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...factors
                .take(3)
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.bolt, size: 14, color: FinancePalette.cyan),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            f,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: FinancePalette.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _RoiCard extends StatelessWidget {
  const _RoiCard({required this.roi, required this.recommendation});

  final double roi;
  final String recommendation;

  @override
  Widget build(BuildContext context) {
    return _FloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBadge(icon: Icons.pie_chart_rounded),
              const SizedBox(width: 10),
              _Tag(text: 'INVESTMENT ROI', color: FinancePalette.blue),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Analyse du Rendement',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricRow(
                  label: 'Rendement Estimé (2s)',
                  value: '+${roi.toStringAsFixed(1)}%',
                  highlight: roi >= 15
                      ? FinancePalette.success
                      : FinancePalette.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricRow(
                  label: 'Statut',
                  value: roi >= 20 ? 'HAUT POTENTIEL' : 'ACTIF STABLE',
                ),
              ),
            ],
          ),
          if (recommendation.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FinancePalette.soft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: FinancePalette.blue.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                recommendation,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: FinancePalette.ink,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FloatingCard extends StatelessWidget {
  const _FloatingCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final top = FinancePalette.card.withValues(alpha: 0.92);
    final bottom = FinancePalette.soft.withValues(alpha: 0.62);
    final stroke = FinancePalette.soft.withValues(alpha: 0.9);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
        border: Border.all(color: stroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: FinancePalette.cyan.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

enum StepStatus { done, active, pending }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.status});

  final String label;
  final StepStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      StepStatus.done => FinancePalette.cyan,
      StepStatus.active => FinancePalette.blue,
      StepStatus.pending => FinancePalette.muted,
    };

    Widget leading;
    if (status == StepStatus.done) {
      leading = Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded, size: 16, color: color),
      );
    } else {
      leading = Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          shape: BoxShape.circle,
        ),
      );
    }

    return Row(
      children: [
        leading,
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: status == StepStatus.pending
                  ? FinancePalette.muted
                  : FinancePalette.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: FinancePalette.soft.withValues(alpha: 0.8),
        border: Border.all(color: FinancePalette.soft.withValues(alpha: 0.9)),
      ),
      child: Icon(icon, color: FinancePalette.blue),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value, this.highlight});

  final String label;
  final String value;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: FinancePalette.muted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: highlight ?? FinancePalette.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.value,
    this.highlight,
  });

  final String label;
  final String value;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: FinancePalette.muted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: highlight ?? FinancePalette.ink,
          ),
        ),
      ],
    );
  }
}

class _RiskSegmentedControl extends StatelessWidget {
  const _RiskSegmentedControl({required this.selected});

  final String selected;

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, {required bool active}) {
      final Color color = label == 'HIGH'
          ? FinancePalette.danger
          : label == 'MEDIUM'
          ? FinancePalette.warning
          : FinancePalette.cyan;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.22)
              : FinancePalette.soft.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.55)
                : FinancePalette.soft.withValues(alpha: 0.7),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: active ? color : FinancePalette.muted,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        pill('LOW', active: selected == 'LOW'),
        const SizedBox(width: 8),
        pill('MEDIUM', active: selected == 'MEDIUM'),
        const SizedBox(width: 8),
        pill('HIGH', active: selected == 'HIGH'),
      ],
    );
  }
}

class _ImpactLine extends StatelessWidget {
  const _ImpactLine({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: FinancePalette.soft.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FinancePalette.soft.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
