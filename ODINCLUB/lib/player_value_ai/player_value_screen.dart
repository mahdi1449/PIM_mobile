import 'package:flutter/material.dart';

import '../finance/theme/finance_theme.dart';
import '../ui/components/app_card.dart';
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
  final _age = TextEditingController(text: '24');
  final _minutes = TextEditingController(text: '2850');
  final _goals = TextEditingController(text: '12');
  final _assists = TextEditingController(text: '8');
  final _marketValue = TextEditingController(text: '45000000');
  int _injuries = 0;
  bool _loading = false;
  String? _error;
  PlayerValueResponse? _result;

  @override
  void dispose() {
    _age.dispose();
    _minutes.dispose();
    _goals.dispose();
    _assists.dispose();
    _marketValue.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _api.predict(
        PlayerValueRequest(
          age: int.parse(_age.text.trim()),
          minutesPlayed: int.parse(_minutes.text.trim()),
          goals: int.parse(_goals.text.trim()),
          assists: int.parse(_assists.text.trim()),
          injuriesLastSeason: _injuries,
          currentMarketValue: double.parse(_marketValue.text.trim()),
        ),
      );

      if (!mounted) return;
      setState(() {
        _result = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Player Value AI',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Estimate player market value from performance indicators.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: FinancePalette.muted,
              ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field('Age', _age),
                _field('Minutes played', _minutes),
                _field('Goals', _goals),
                _field('Assists', _assists),
                _field('Current market value', _marketValue, prefixText: 'EUR '),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _injuries,
                  decoration: const InputDecoration(labelText: 'Injuries last season'),
                  items: List.generate(
                    6,
                    (index) => DropdownMenuItem(
                      value: index,
                      child: Text(index.toString()),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _injuries = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: const Icon(Icons.auto_graph),
                    label: Text(_loading ? 'Predicting...' : 'Predict value'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        if (_result != null) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prediction', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text('Predicted value: ${_result!.predictedValue.toStringAsFixed(2)}'),
                Text('Growth: ${_result!.growthPercent.toStringAsFixed(2)}%'),
                Text('Trend: ${_result!.trend}'),
                Text('Confidence: ${(_result!.confidence * 100).toStringAsFixed(0)}%'),
                const SizedBox(height: 10),
                Text(
                  _result!.explanation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: FinancePalette.muted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _field(String label, TextEditingController controller, {String? prefixText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, prefixText: prefixText),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Required';
          }
          return double.tryParse(value.trim()) == null ? 'Number required' : null;
        },
      ),
    );
  }
}
