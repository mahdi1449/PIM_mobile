import '../../services/api_service.dart';
import 'finance_store.dart';

class FinanceAiBundle {
  const FinanceAiBundle({
    required this.source,
    this.generationTimeMs,
    this.forecastData,
    this.cashflowData,
    this.impactData,
  });

  final String source;
  final int? generationTimeMs;
  final Map<String, dynamic>? forecastData;
  final Map<String, dynamic>? cashflowData;
  final Map<String, dynamic>? impactData;
}

class FinanceAiService {
  FinanceAiService._();

  static final FinanceAiService instance = FinanceAiService._();
  final ApiService _api = ApiService();

  Future<FinanceAiBundle> loadRemoteInsights(FinanceStore store) async {
    final categories = store.expenses.map((item) => item.category).toSet().toList();
    final response = await _api.getFinanceAiInsights(focusCategories: categories);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Finance AI unavailable');
    }

    final data = (response['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    return FinanceAiBundle(
      source: (data['source']?.toString() ?? 'analytics-local'),
      generationTimeMs: int.tryParse(data['generationTimeMs']?.toString() ?? ''),
      forecastData: (data['forecast'] as Map?)?.cast<String, dynamic>(),
      cashflowData: (data['cashflowRisk'] as Map?)?.cast<String, dynamic>(),
      impactData: (data['sponsorTransferImpact'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
