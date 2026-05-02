import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/events_provider.dart';
import 'widgets/match_summary_card.dart';
import 'ai_match_debrief_screen.dart';

class TeamStatsSummaryScreen extends StatefulWidget {
  final String eventId;
  const TeamStatsSummaryScreen({super.key, required this.eventId});

  @override
  State<TeamStatsSummaryScreen> createState() => _TeamStatsSummaryScreenState();
}

class _TeamStatsSummaryScreenState extends State<TeamStatsSummaryScreen> {
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _stats;

  // Manual input controllers
  final TextEditingController _possessionController = TextEditingController(text: '50');
  final TextEditingController _accuracyController = TextEditingController(text: '70');
  final TextEditingController _cornersController = TextEditingController(text: '0');
  final TextEditingController _foulsCommittedController = TextEditingController(text: '0');
  final TextEditingController _foulsReceivedController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final provider = Provider.of<EventsProvider>(context, listen: false);
    await provider.fetchEvent(widget.eventId);
    final data = await provider.getTeamStats(widget.eventId);
    
    if (mounted) {
      setState(() {
        _stats = data;
        if (data != null && data['performance'] != null) {
          _possessionController.text = data['performance']['possession'].toString();
          _accuracyController.text = data['performance']['passAccuracy'].toString();
          _cornersController.text = data['performance']['corners'].toString();
          _foulsCommittedController.text = data['performance']['foulsCommitted'].toString();
          _foulsReceivedController.text = data['performance']['foulsReceived'].toString();
        }
        _loading = false;
      });
      
      if (provider.selectedEvent?.aiDebrief == null) {
        Future.delayed(const Duration(seconds: 3), () async {
          if (mounted) {
            await provider.fetchEvent(widget.eventId);
            setState(() {});
          }
        });
      }
    }
  }

  Future<void> _saveManualStats() async {
    setState(() => _saving = true);
    final provider = Provider.of<EventsProvider>(context, listen: false);
    
    final success = await provider.updateTeamStats(widget.eventId, {
      'possession': int.tryParse(_possessionController.text) ?? 50,
      'passAccuracy': int.tryParse(_accuracyController.text) ?? 70,
      'corners': int.tryParse(_cornersController.text) ?? 0,
      'foulsCommitted': int.tryParse(_foulsCommittedController.text) ?? 0,
      'foulsReceived': int.tryParse(_foulsReceivedController.text) ?? 0,
    });

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stats collectives mises à jour !'), backgroundColor: OdinTheme.accentGreen));
        _loadStats(); // Reload to refresh AI if needed
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventsProvider>(context);
    final event = provider.selectedEvent;

    return Scaffold(
      backgroundColor: OdinTheme.background,
      appBar: AppBar(
        title: const Text('RÉSUMÉ COLLECTIF', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: OdinTheme.primaryBlue),
            onPressed: () {
              setState(() => _loading = true);
              _loadStats();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event != null) MatchSummaryCard(event: event),
                  const SizedBox(height: 32),
                  
                  _sectionTitle('PERFORMANCE COLLECTIVE (Saisie manuelle)'),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(child: _manualStatInput('POSSESSION %', _possessionController, Icons.pie_chart_outline_rounded)),
                      const SizedBox(width: 16),
                      Expanded(child: _manualStatInput('PRÉCISION %', _accuracyController, Icons.bolt_rounded)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _manualStatInput('CORNERS', _cornersController, Icons.flag_outlined)),
                      const SizedBox(width: 16),
                      Expanded(child: _manualStatInput('FAUTES COMM.', _foulsCommittedController, Icons.warning_amber_rounded)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _manualStatInput('FAUTES REÇUES', _foulsReceivedController, Icons.accessibility_new_rounded),
                  
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _saving ? null : _saveManualStats,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OdinTheme.primaryBlue,
                        side: const BorderSide(color: OdinTheme.primaryBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('ENREGISTRER LES SCORES COLLECTIFS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 32),
                  _sectionTitle('OFFENSIF (Auto)'),
                  _statsRow('Tirs cadrés totaux', '${_stats?['offensive']?['shotsOnTarget'] ?? 0}'),
                  _statsRow('Passes décisives', '${_stats?['offensive']?['assists'] ?? 0}'),
                  if (_stats?['offensive']?['topScorer'] != null)
                    _statsRow('Meilleur buteur', '${_stats?['offensive']?['topScorer']?['name']} (${_stats?['offensive']?['topScorer']?['goals']})'),
                  if (_stats?['offensive']?['bestAssister'] != null)
                    _statsRow('Meilleur passeur', '${_stats?['offensive']?['bestAssister']?['name']} (${_stats?['offensive']?['bestAssister']?['assists']})'),
                  
                  const SizedBox(height: 24),
                  _sectionTitle('DÉFENSIF (Auto)'),
                  _statsRow('Tacles réussis', '${_stats?['defensive']?['tackles'] ?? 0}'),
                  _statsRow('Interceptions', '${_stats?['defensive']?['interceptions'] ?? 0}'),
                  _statsRow('Clean Sheet', _stats?['defensive']?['cleanSheet'] == true ? 'OUI' : 'NON'),
                  
                  const SizedBox(height: 24),
                  _sectionTitle('SQUAD (Auto)'),
                  _statsRow('Note moyenne équipe', '${_stats?['squad']?['avgRating']}/10'),
                  if (_stats?['squad']?['mvp'] != null)
                    _statsRow('MVP du match', '${_stats?['squad']?['mvp']?['name']} (${_stats?['squad']?['mvp']?['rating']}/10)'),
                  _statsRow('Minutes distribuées', '${_stats?['squad']?['totalMinutes']}\''),
                  _statsRow('Match complet (90\')', '${_stats?['squad']?['fullGameCount']} joueurs'),
                  _statsRow('Remplacements (Out/In)', '${_stats?['squad']?['subOutCount']} / ${_stats?['squad']?['subInCount']}'),
                  
                  const SizedBox(height: 24),

                  // AI Debrief CTA
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [OdinTheme.primaryBlue.withOpacity(0.15), Colors.transparent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: OdinTheme.primaryBlue.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.psychology_rounded, color: OdinTheme.primaryBlue, size: 36),
                        const SizedBox(height: 12),
                        const Text(
                          'DÉBRIEF IA DISPONIBLE',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'L\'IA analyse les performances\nde chaque joueur pour toi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: OdinTheme.textSecondary, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => AiMatchDebriefScreen(eventId: widget.eventId)),
                            ),
                            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                            label: const Text('VOIR L\'ANALYSE IA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: OdinTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OdinTheme.textSecondary,
                        side: const BorderSide(color: Color(0xFF1E2A3A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('RETOUR', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: OdinTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2),
    );
  }

  Widget _manualStatInput(String label, TextEditingController controller, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: OdinTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: OdinTheme.primaryBlue, size: 14),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: OdinTheme.textTertiary, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4)),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: OdinTheme.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
