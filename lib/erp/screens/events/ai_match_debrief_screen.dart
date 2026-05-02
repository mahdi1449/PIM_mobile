import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/events_provider.dart';
import '../../models/event.dart';

class AiMatchDebriefScreen extends StatefulWidget {
  final String eventId;
  const AiMatchDebriefScreen({super.key, required this.eventId});

  @override
  State<AiMatchDebriefScreen> createState() => _AiMatchDebriefScreenState();
}

class _AiMatchDebriefScreenState extends State<AiMatchDebriefScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  bool _triggering = false;
  int _pollAttempts = 0;
  static const int _maxPolls = 8;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadDebrief();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadDebrief() async {
    setState(() => _loading = true);
    final provider = Provider.of<EventsProvider>(context, listen: false);
    await provider.fetchEvent(widget.eventId);

    if (mounted) setState(() => _loading = false);

    // If AI debrief is still null, start polling
    if (provider.selectedEvent?.aiDebrief == null && _pollAttempts < _maxPolls) {
      _startPolling();
    }
  }

  void _startPolling() {
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      _pollAttempts++;
      final provider = Provider.of<EventsProvider>(context, listen: false);
      await provider.fetchEvent(widget.eventId);
      if (mounted) setState(() {});
      if (provider.selectedEvent?.aiDebrief == null && _pollAttempts < _maxPolls) {
        _startPolling();
      }
    });
  }

  Future<void> _triggerAnalysis() async {
    setState(() => _triggering = true);
    _pollAttempts = 0;
    final provider = Provider.of<EventsProvider>(context, listen: false);
    // Re-save bulk stats with empty payload to trigger debrief re-generation
    await provider.saveBulkPlayerStats(widget.eventId, []);
    await Future.delayed(const Duration(seconds: 2));
    await provider.fetchEvent(widget.eventId);
    if (mounted) {
      setState(() => _triggering = false);
      if (provider.selectedEvent?.aiDebrief == null) _startPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = Provider.of<EventsProvider>(context).selectedEvent;
    final debrief = event?.aiDebrief;

    return Scaffold(
      backgroundColor: OdinTheme.background,
      appBar: AppBar(
        title: const Text(
          'DÉBRIEF IA',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: OdinTheme.primaryBlue),
            onPressed: () {
              _pollAttempts = 0;
              _loadDebrief();
            },
          ),
        ],
      ),
      body: _loading
          ? _buildLoadingState('Chargement...')
          : debrief == null
              ? _buildWaitingState(event)
              : _buildDebriefContent(event, debrief),
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: OdinTheme.primaryBlue),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: OdinTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildWaitingState(Event? event) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated AI brain icon
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Opacity(
                opacity: _pulseAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      OdinTheme.primaryBlue.withOpacity(0.3),
                      Colors.transparent,
                    ]),
                  ),
                  child: const Icon(Icons.psychology_rounded,
                      size: 56, color: OdinTheme.primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ANALYSE IA EN COURS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _pollAttempts < _maxPolls
                  ? 'L\'IA analyse les performances de vos joueurs...\nCela prend environ 10 secondes.'
                  : 'L\'analyse prend plus de temps que prévu.\nVérifiez votre connexion et relancez.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: OdinTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            if (_pollAttempts >= _maxPolls)
              ElevatedButton.icon(
                onPressed: _triggering ? null : _triggerAnalysis,
                icon: _triggering
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(_triggering ? 'Lancement...' : 'RELANCER L\'ANALYSE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: OdinTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            else
              Column(
                children: [
                  const SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      backgroundColor: Color(0xFF1E2A3A),
                      color: OdinTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vérification ${_pollAttempts + 1}/$_maxPolls...',
                    style: const TextStyle(color: OdinTheme.textTertiary, fontSize: 11),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebriefContent(Event? event, dynamic debrief) {
    final Map<String, dynamic> data = debrief is Map<String, dynamic>
        ? debrief
        : {'summary': debrief.toString()};

    final summary = data['summary'] ?? '';
    final mvp = data['mvp'] as Map<String, dynamic>?;
    final strengths = (data['strengths'] as List<dynamic>? ?? []).cast<String>();
    final improvements = (data['improvements'] as List<dynamic>? ?? []).cast<String>();
    final motivation = data['motivationalNote'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match header
          if (event != null) _buildMatchHeader(event),
          const SizedBox(height: 28),

          // AI Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A3A6B), Color(0xFF0D2142)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: OdinTheme.primaryBlue.withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: OdinTheme.primaryBlue, size: 14),
                  SizedBox(width: 8),
                  Text(
                    'GÉNÉRÉ PAR IA ODIN',
                    style: TextStyle(
                      color: OdinTheme.primaryBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Summary
          if (summary.isNotEmpty) ...[
            _sectionCard(
              icon: Icons.article_rounded,
              title: 'RÉSUMÉ DU MATCH',
              color: OdinTheme.primaryBlue,
              child: Text(
                summary,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.65,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // MVP
          if (mvp != null && mvp['name'] != null && mvp['name'] != 'N/A') ...[
            _sectionCard(
              icon: Icons.emoji_events_rounded,
              title: 'JOUEUR DU MATCH',
              color: OdinTheme.accentOrange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: OdinTheme.accentOrange.withOpacity(0.15),
                          border: Border.all(color: OdinTheme.accentOrange, width: 2),
                        ),
                        child: const Icon(Icons.star_rounded, color: OdinTheme.accentOrange, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mvp['name'] ?? '',
                              style: const TextStyle(
                                color: OdinTheme.accentOrange,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text('MVP DU MATCH', style: TextStyle(color: OdinTheme.textTertiary, fontSize: 10, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (mvp['reason'] != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '"${mvp['reason']}"',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Strengths
          if (strengths.isNotEmpty) ...[
            _sectionCard(
              icon: Icons.trending_up_rounded,
              title: 'POINTS FORTS',
              color: OdinTheme.accentGreen,
              child: Column(
                children: strengths
                    .map((s) => _bulletRow(s, OdinTheme.accentGreen, Icons.check_circle_rounded))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Improvements
          if (improvements.isNotEmpty) ...[
            _sectionCard(
              icon: Icons.construction_rounded,
              title: 'AXES D\'AMÉLIORATION',
              color: OdinTheme.accentRed,
              child: Column(
                children: improvements
                    .map((s) => _bulletRow(s, OdinTheme.accentRed, Icons.arrow_circle_up_rounded))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Motivation
          if (motivation.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A3A6B), Color(0xFF0D2142)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: OdinTheme.primaryBlue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 12),
                  Text(
                    '"$motivation"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Done button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text(
                'TERMINER LE DÉBRIEF',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: OdinTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHeader(Event event) {
    final homeScore = event.homeScore ?? 0;
    final awayScore = event.awayScore ?? 0;
    final isWin = event.isHome ? homeScore > awayScore : awayScore > homeScore;
    final isDraw = homeScore == awayScore;
    final resultColor = isDraw ? OdinTheme.accentOrange : isWin ? OdinTheme.accentGreen : OdinTheme.accentRed;
    final resultText = isDraw ? 'MATCH NUL' : isWin ? 'VICTOIRE' : 'DÉFAITE';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [resultColor.withOpacity(0.15), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: resultColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(resultText, style: TextStyle(color: resultColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('ODIN FC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$homeScore — $awayScore',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  event.opponentName ?? 'Adversaire',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1824),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _bulletRow(String text, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
