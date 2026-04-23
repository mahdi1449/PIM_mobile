import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../sports_performance/cognitive_lab/screens/cognitive_dashboard_screen.dart';
import '../../ui/shell/app_shell.dart';
import '../../finance/theme/finance_theme.dart';
import '../../finance/services/finance_ai_service.dart';

class PlayerDetailsScreen extends StatefulWidget {
  final String playerId;
  const PlayerDetailsScreen({super.key, required this.playerId});

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen> {
  final _apiService = ApiService();
  Map<String, dynamic>? _player;
  List<dynamic> _analyses = [];
  bool _isLoading = false;
  Map<String, dynamic>? _aiValuation;
  bool _loadingAi = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
    });
    final playerRes = await _apiService.getPlayer(widget.playerId);
    final analysesRes = await _apiService.getPlayerAnalyses(widget.playerId);

    if (playerRes['success'] && mounted) {
      setState(() {
        _player = playerRes['data']['data'];
        _analyses = analysesRes['success'] ? analysesRes['data']['data'] ?? [] : [];
        _isLoading = false;
      });
      _loadAiValuation();
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(playerRes['message'] ?? 'Failed to load player')),
      );
    }
  }

  Future<void> _loadAiValuation() async {
    setState(() => _loadingAi = true);
    try {
      final res = await _apiService.getAiPlayerValuePrediction(widget.playerId);
      if (res['success'] && mounted) {
        setState(() {
          _aiValuation = res['data']['prediction'];
          _loadingAi = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAi = false);
    }
  }

  String _formatDate(String value) {
    final date = DateTime.parse(value);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Player Details'),
        backgroundColor: AppTheme.odinDarkBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _player == null
              ? const Center(child: Text('No player found'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      '${_player!['firstName']} ${_player!['lastName']}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.odinDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _detailRow('Age', _player!['age'].toString()),
                    _detailRow('Position', _player!['position']),
                    _detailRow('Contract end', _formatDate(_player!['contractEndDate'])),
                    _detailRow('Injured', _player!['isInjured'] == true ? 'Yes' : 'No'),
                    if ((_player!['injuryDetails'] ?? '').toString().isNotEmpty)
                      _detailRow('Injury details', _player!['injuryDetails']),
                    const SizedBox(height: 32),
                    
                    // Labo Cognitif Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.odinDarkBlue, const Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.psychology, color: Colors.cyanAccent, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                'LABO COGNITIF IA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Évaluer la fatigue mentale et la préparation cognitive du joueur.',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                final shell = AppShellScope.of(context);
                                if (shell != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CognitiveDashboardScreen(
                                        session: shell.session,
                                        targetPlayerId: widget.playerId,
                                        targetPlayerName: '${_player!['firstName']} ${_player!['lastName']}',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent,
                                foregroundColor: const Color(0xFF0F172A),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('OUVRIR LE LABO', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // --- PROFILE FINANCIER IA ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: FinancePalette.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_graph_rounded, color: FinancePalette.blue, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                'PROFIL FINANCIER IA',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_loadingAi)
                            const LinearProgressIndicator(color: Colors.blue)
                          else if (_aiValuation != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('VALEUR ACTUELLE', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                    Text(
                                      '${(_aiValuation!['predicted_value'] ?? 0).toString()} DT',
                                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: FinancePalette.success.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+${_aiValuation!['growth_percent']}%',
                                    style: TextStyle(color: FinancePalette.success, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _aiValuation!['explanation'] ?? 'Analyse financière en cours...',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4),
                            ),
                          ] else
                            const Text('No financial data available.', style: TextStyle(color: Colors.white60)),
                          
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                // Navigator could go to Finance shell here if needed
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: FinancePalette.blue),
                                foregroundColor: FinancePalette.blue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('VOIR DÉTAILS FINANCIERS', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    Text(
                      'Analyses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.odinDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_analyses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.odinSkyBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('No analyses available yet.'),
                      )
                    else
                      ..._analyses.map((item) => ListTile(title: Text(item.toString()))),
                  ],
                ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
