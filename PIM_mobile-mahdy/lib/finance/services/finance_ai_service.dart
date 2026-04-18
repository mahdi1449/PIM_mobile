import 'dart:math' as math;

import '../../services/api_service.dart';
import '../services/finance_store.dart';

class FinanceAiInsight {
  final String title;
  final String summary;
  final String details;
  final String source;

  const FinanceAiInsight({
    required this.title,
    required this.summary,
    required this.details,
    this.source = 'local',
  });
}

class FinanceAiBundle {
  final FinanceAiInsight forecast;
  final FinanceAiInsight cashflowRisk;
  final FinanceAiInsight sponsorTransferImpact;
  final FinanceAiInsight? playerValuation;
  final String source;
  final int? generationTimeMs;
  final Map<String, dynamic>? forecastData;
  final Map<String, dynamic>? cashflowData;
  final Map<String, dynamic>? impactData;
  final Map<String, dynamic>? valuationData;

  const FinanceAiBundle({
    required this.forecast,
    required this.cashflowRisk,
    required this.sponsorTransferImpact,
    this.playerValuation,
    this.source = 'local',
    this.generationTimeMs,
    this.forecastData,
    this.cashflowData,
    this.impactData,
    this.valuationData,
  });
}

class FinanceAiService {
  FinanceAiService._();
  static final FinanceAiService instance = FinanceAiService._();
  final ApiService _apiService = ApiService();

  Future<FinanceAiBundle> fetchPlayerValuation(String playerId) async {
    final response = await _apiService.getAiPlayerValuePrediction(playerId);

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Valuation AI error');
    }

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final prediction = data['prediction'] as Map<String, dynamic>? ?? {};
    final finances = data['finances'] as Map<String, dynamic>? ?? {};
    final playerName = data['playerName']?.toString() ?? 'Player';

    // Python model returns 'predicted_value' and 'confidence'
    final value = (prediction['predicted_value'] ?? 0).toDouble();
    final confidence = (prediction['confidence'] ?? prediction['confidence_score'] ?? 0).toDouble();
    final roi = (finances['roi_percentage'] ?? 0).toDouble();
    final trend = prediction['trend']?.toString() ?? 'STABLE';

    final insight = FinanceAiInsight(
      title: 'Évaluation Marché: $playerName',
      summary: 'Valeur predite: ${_fmtMoney(value)} DT (Confiance ${(confidence * 100).toStringAsFixed(0)}%)',
      details: [
        'Analyse basée sur stats performance, médical et historique transferts.',
        'Valeur marchande estimée: ${_fmtMoney(value)} DT',
        'Tendance: $trend',
        'ROI estimé sur 2 saisons: ${roi.toStringAsFixed(1)}%',
        if (prediction['explanation'] != null) ...[
          '',
          'Explication AI:',
          prediction['explanation'].toString(),
        ],
        if (finances['recommendation'] != null) ...[
          '',
          'Conseil Financier:',
          finances['recommendation'].toString(),
        ],
      ].join('\n'),
      source: 'player-valuation-ai',
    );

    return FinanceAiBundle(
      forecast: insight, 
      cashflowRisk: insight,
      sponsorTransferImpact: insight,
      playerValuation: insight,
      valuationData: data,
      source: 'player-valuation-ai',
    );
  }

  FinanceAiInsight buildBudgetForecast(FinanceStore store) {
    final revenueForecast = store.totalRevenueForecast;
    final revenueActual = store.totalRevenueActual;
    final expenses = store.totalExpenseAmount;
    final salaries = store.totalSalaryExpense;

    final forecastBase = revenueForecast > 0 ? revenueForecast : revenueActual;
    final safeBase = forecastBase <= 0 ? 1.0 : forecastBase;

    final actualVsForecastRatio = revenueForecast <= 0
        ? 1.0
        : (revenueActual / revenueForecast).clamp(0.0, 3.0);

    final net = revenueActual - expenses;
    final netPct = (net / safeBase) * 100.0;

    final salaryPct = (salaries / safeBase) * 100.0;
    final expensePct = (expenses / safeBase) * 100.0;

    final riskScore = _riskScore(
      netPct: netPct,
      actualVsForecastRatio: actualVsForecastRatio,
      salaryPct: salaryPct,
    );

    final riskLabel = switch (riskScore) {
      <= 34 => 'Faible',
      <= 67 => 'Moyen',
      _ => 'Élevé',
    };

    final summary = net < 0
        ? 'Risque de déficit détecté (risque $riskLabel).'
        : 'Trajectoire budgétaire correcte (risque $riskLabel).';

    final details = [
      'Prévision basée sur les données actuelles (revenus & dépenses).',
      '',
      'Indicateurs:',
      '- Revenus (réel): ${_fmtMoney(revenueActual)} DT',
      '- Revenus (prévu): ${_fmtMoney(revenueForecast)} DT',
      '- Dépenses (hors salaires): ${_fmtMoney(expenses - salaries)} DT',
      '- Salaires (net à payer): ${_fmtMoney(salaries)} DT',
      '',
      'Ratios:',
      '- Réel/Prévu revenus: ${(actualVsForecastRatio * 100).toStringAsFixed(0)}%',
      '- Dépenses / base: ${expensePct.toStringAsFixed(1)}%',
      '- Salaires / base: ${salaryPct.toStringAsFixed(1)}%',
      '- Résultat net: ${_fmtMoney(net)} DT (${netPct.toStringAsFixed(1)}%)',
      '',
      'Recommandation:',
      _forecastRecommendation(
        netPct: netPct,
        salaryPct: salaryPct,
        actualVsForecastRatio: actualVsForecastRatio,
      ),
    ].join('\n');

    return FinanceAiInsight(
      title: 'Prévision budget',
      summary: summary,
      details: details,
      source: 'local',
    );
  }

  FinanceAiInsight buildExpenseOptimization(FinanceStore store) {
    final byCategory = <String, double>{};
    for (final e in store.expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }

    if (byCategory.isEmpty) {
      return const FinanceAiInsight(
        title: 'Optimisation dépenses',
        summary: 'Pas assez de données pour optimiser.',
        details:
            'Ajoutez des dépenses catégorisées (avec montants) pour générer des recommandations.',
      );
    }

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = sorted.fold<double>(0.0, (s, e) => s + e.value);
    final top = sorted.take(math.min(5, sorted.length)).toList();

    final topShare = total <= 0 ? 0.0 : (top.first.value / total);
    final hasHeavyConcentration = topShare >= 0.45;

    final salaryLike = sorted.where((e) => e.key.contains('SALAIRES')).toList();
    final travelLike = sorted.where((e) => e.key.contains('TRANSPORT')).toList();
    final marketingLike =
        sorted.where((e) => e.key.contains('MARKETING')).toList();

    final summary = hasHeavyConcentration
        ? 'Dépenses très concentrées sur ${top.first.key}.'
        : 'Répartition des dépenses relativement équilibrée.';

    final details = [
      'Top catégories (montants):',
      for (final e in top)
        '- ${e.key}: ${_fmtMoney(e.value)} DT (${total <= 0 ? '—' : '${(e.value / total * 100).toStringAsFixed(0)}%'})',
      '',
      'Actions proposées (priorisées):',
      ..._optimizationActions(
        total: total,
        salaryLike: salaryLike,
        travelLike: travelLike,
        marketingLike: marketingLike,
        hasHeavyConcentration: hasHeavyConcentration,
        topCategory: top.first.key,
      ),
    ].join('\n');

    return FinanceAiInsight(
      title: 'Optimisation dépenses',
      summary: summary,
      details: details,
      source: 'local',
    );
  }

  Future<FinanceAiBundle> loadRemoteInsights(FinanceStore store) async {
    final response = await _apiService.getFinanceAiInsights();

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Finance AI endpoint error');
    }

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final forecastData = data['forecast'] as Map<String, dynamic>? ?? {};
    final riskData = data['risk'] as Map<String, dynamic>? ?? {};
    final source = (data['source']?.toString() ?? 'finance-ai-ml').toLowerCase();

    final forecastInsight = _buildForecastInsight(forecastData, source);
    final cashflowInsight = _buildCashflowInsight(riskData, source);
    
    // Impact analysis from forecast scenarios
    final impactInsight = _buildImpactInsight(forecastData, source);

    return FinanceAiBundle(
      source: source,
      forecast: forecastInsight,
      cashflowRisk: cashflowInsight,
      sponsorTransferImpact: impactInsight,
      forecastData: forecastData,
      cashflowData: riskData,
    );
  }

  FinanceAiInsight _buildForecastInsight(
    Map<String, dynamic> data,
    String source,
  ) {
    // Python model returns data['forecast'] as List<Record>
    final list = (data['forecast'] as List? ?? []);
    if (list.isEmpty) {
      return const FinanceAiInsight(
        title: 'Prévision saisonnière',
        summary: 'Pas encore de données prévisionnelles.',
        details: 'Ajoutez des écritures comptables pour générer un forecast.',
      );
    }

    final last = list.last as Map<String, dynamic>;
    final net = (last['net'] ?? 0).toDouble();
    final revenue = (last['revenue'] ?? 0).toDouble();
    final date = last['date']?.toString() ?? 'Prochain mois';

    return FinanceAiInsight(
      title: 'Prévision saisonnière',
      summary: 'Objectif $date: ${_fmtMoney(net)} DT net',
      details: [
        'Analyse de tendance basée sur l\'historique.',
        'Prochain point de contrôle: $date',
        'Revenus estimés: ${_fmtMoney(revenue)} DT',
        'Dépenses estimées: ${_fmtMoney((last['expenses'] ?? 0).toDouble())} DT',
        '',
        'Statut: Tendances ${net >= 0 ? 'positives' : 'de vigilance deficit'}',
      ].join('\n'),
      source: source,
    );
  }

  FinanceAiInsight _buildCashflowInsight(
    Map<String, dynamic> data,
    String source,
  ) {
    final alerts = (data['risk_alerts'] as List? ?? []);
    final chart = data['chart'] as Map<String, dynamic>? ?? {};
    final gaps = (chart['gap'] as List? ?? []);
    
    String level = 'FAIBLE';
    if (alerts.isNotEmpty) {
      level = alerts.any((a) => a.toString().contains('RISK')) ? 'ÉLEVÉ' : 'MOYEN';
    }

    return FinanceAiInsight(
      title: 'Analyse des Risques',
      summary: 'Risque global: $level • ${alerts.length} alertes',
      details: [
        'Analyse de l\'écart Revenus/Dépenses.',
        if (alerts.isEmpty) 'Aucun risque bloquant détecté.'
        else 'Points de vigilance:',
        ...alerts.map((a) => '- $a'),
        if (gaps.isNotEmpty) ...[
          '',
          'Écart max détecté: ${_fmtMoney(gaps.fold<double>(0.0, (m, v) => math.max(m, (v as num).toDouble().abs())))} DT',
        ],
      ].join('\n'),
      source: source,
    );
  }

  FinanceAiInsight _buildImpactInsight(
    Map<String, dynamic> data,
    String source,
  ) {
    return FinanceAiInsight(
      title: 'Simulation Stratégique',
      summary: 'Analyse d\'impact sur la marge opérationnelle',
      details: 'Utilisez les simulations pour calculer l\'impact des nouveaux sponsors ou transferts sur le résultat net.',
      source: source,
    );
  }

  int _riskScore({
    required double netPct,
    required double actualVsForecastRatio,
    required double salaryPct,
  }) {
    var score = 0.0;

    // Negative margin is a strong signal.
    if (netPct < 0) score += math.min(40, (-netPct) * 2.0);

    // Revenue underperforming forecast.
    if (actualVsForecastRatio < 0.9) {
      score += ((0.9 - actualVsForecastRatio) * 200).clamp(0, 30);
    }

    // Salary pressure.
    if (salaryPct > 55) score += ((salaryPct - 55) * 1.2).clamp(0, 30);

    return score.clamp(0, 100).round();
  }

  String _forecastRecommendation({
    required double netPct,
    required double salaryPct,
    required double actualVsForecastRatio,
  }) {
    if (netPct < -5) {
      return 'Déficit probable: geler les dépenses non essentielles, renforcer les validations, et viser une réduction 5–10% sur les postes variables (transport, équipement, marketing).';
    }
    if (actualVsForecastRatio < 0.9) {
      return 'Revenus en dessous du prévu: ajuster les plafonds par catégorie et déclencher un plan d’économies progressif tant que les encaissements ne rattrapent pas la prévision.';
    }
    if (salaryPct > 60) {
      return 'Pression salariale élevée: analyser la masse salariale (bonus/avantages), étaler certaines primes, et limiter les nouvelles charges fixes.';
    }
    if (netPct < 3) {
      return 'Marge faible: surveiller les achats récurrents, optimiser les contrats fournisseurs, et imposer un contrôle renforcé sur les dépenses > seuil.';
    }
    return 'Marge confortable: maintenir la discipline budgétaire, et réallouer une partie vers des postes à ROI (formation jeunes, médical préventif) si nécessaire.';
  }

  List<String> _optimizationActions({
    required double total,
    required List<MapEntry<String, double>> salaryLike,
    required List<MapEntry<String, double>> travelLike,
    required List<MapEntry<String, double>> marketingLike,
    required bool hasHeavyConcentration,
    required String topCategory,
  }) {
    final actions = <String>[];

    if (hasHeavyConcentration) {
      actions.add(
        '- Définir un plafond et un workflow de validation renforcé pour $topCategory (objectif: -5% sur 30 jours).',
      );
    } else {
      actions.add(
        '- Appliquer une politique “3 devis” sur les achats non récurrents et centraliser les fournisseurs pour réduire les coûts.',
      );
    }

    if (salaryLike.isNotEmpty) {
      actions.add(
        '- Masse salariale: auditer primes/avantages, limiter les bonus non liés à la performance, et renégocier certains contrats.',
      );
    }
    if (travelLike.isNotEmpty) {
      actions.add(
        '- Transport: regrouper les déplacements, négocier tarifs saisonniers, et standardiser les prestataires.',
      );
    }
    if (marketingLike.isNotEmpty) {
      actions.add(
        '- Marketing: basculer vers des campagnes mesurables (CPA/ROI), couper les canaux à faible conversion.',
      );
    }

    if (total > 0) {
      actions.add(
        '- Mettre des alertes automatiques à 80% et 95% d’utilisation des budgets par catégorie.',
      );
    }

    return actions;
  }

  String _fmtMoney(double value) {
    final abs = value.abs();
    if (abs >= 1000000) return '${(value / 1000000).toStringAsFixed(2)}M';
    if (abs >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}
