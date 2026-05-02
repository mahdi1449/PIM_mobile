import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme.dart';
import '../../../models/event.dart';

class MatchSummaryCard extends StatefulWidget {
  final Event event;
  const MatchSummaryCard({super.key, required this.event});

  @override
  State<MatchSummaryCard> createState() => _MatchSummaryCardState();
}

class _MatchSummaryCardState extends State<MatchSummaryCard> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _shareCard() async {
    final image = await _screenshotController.capture();
    if (image == null) return;

    final directory = await getTemporaryDirectory();
    final imagePath = await File('${directory.path}/match_summary.png').create();
    await imagePath.writeAsBytes(image);

    await Share.shareXFiles(
      [XFile(imagePath.path)],
      text: 'Résumé du match : ODIN FC ${widget.event.homeScore} - ${widget.event.awayScore} ${widget.event.opponentName ?? 'Adv'} ⚽',
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    if (event.homeScore == null || event.awayScore == null) return const SizedBox.shrink();

    final isWin = (event.homeScore ?? 0) > (event.awayScore ?? 0);
    final isDraw = event.homeScore == event.awayScore;
    final statusColor = isWin ? OdinTheme.accentGreen : (isDraw ? OdinTheme.accentOrange : OdinTheme.accentRed);
    final statusLabel = isWin ? 'VICTOIRE' : (isDraw ? 'MATCH NUL' : 'DÉFAITE');

    return Screenshot(
      controller: _screenshotController,
      child: Container(
        width: double.infinity,
        decoration: OdinTheme.glassCard,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header with Status
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: statusColor.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
                  ),
                  Text(
                    'DURÉE : ${event.matchDuration}\'',
                    style: const TextStyle(color: OdinTheme.textTertiary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Score Board
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _teamInfo('MON CLUB', true),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '${event.homeScore} - ${event.awayScore}',
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                      ),
                      _teamInfo(event.opponentName ?? 'ADV', false),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(color: OdinTheme.cardBorder),
                  const SizedBox(height: 16),

                  // Team Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _miniStat('BUTS', '${event.matchSummary?['goals'] ?? event.homeScore ?? 0}'),
                      _miniStat('PASSES', '${event.matchSummary?['assists'] ?? 0}'),
                      _miniStat('LIEU', event.isHome ? 'DOM' : 'EXT'),
                    ],
                  ),

                  if (event.aiDebrief != null) ...[
                    const SizedBox(height: 24),
                    _buildAiDebriefSection(event.aiDebrief),
                  ] else if (event.homeScore != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: OdinTheme.primaryBlue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: OdinTheme.primaryBlue.withOpacity(0.1)),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: OdinTheme.primaryBlue),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'GÉNÉRATION DE L\'ANALYSE IA...',
                            style: TextStyle(color: OdinTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Share Button
            InkWell(
              onTap: _shareCard,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white.withOpacity(0.03),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share_rounded, color: OdinTheme.textTertiary, size: 16),
                    SizedBox(width: 8),
                    Text('PARTAGER LE RÉSUMÉ', style: TextStyle(color: OdinTheme.textTertiary, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiDebriefSection(dynamic debrief) {
    if (debrief is String) {
      return _aiCardWrapper(
        child: Text(
          debrief,
          style: const TextStyle(color: OdinTheme.textSecondary, fontSize: 12, height: 1.5, fontStyle: FontStyle.italic),
        ),
      );
    }

    if (debrief is! Map) return const SizedBox.shrink();

    final summary = debrief['summary'] ?? '';
    final mvp = debrief['mvp'] ?? {};
    final strengths = List<String>.from(debrief['strengths'] ?? []);
    final improvements = List<String>.from(debrief['improvements'] ?? []);
    final motivation = debrief['motivationalNote'] ?? '';

    return _aiCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📝 RÉSUMÉ', style: TextStyle(color: OdinTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(summary, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
          
          if (mvp['name'] != null && mvp['name'] != 'N/A') ...[
            const SizedBox(height: 16),
            const Text('⭐ JOUEUR DU MATCH', style: TextStyle(color: OdinTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text(mvp['name'], style: const TextStyle(color: OdinTheme.accentOrange, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(mvp['reason'] ?? '', style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],

          if (strengths.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('💪 POINTS FORTS', style: TextStyle(color: OdinTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            ...strengths.map((s) => _bulletPoint(s, OdinTheme.accentGreen)),
          ],

          if (improvements.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('📈 À AMÉLIORER', style: TextStyle(color: OdinTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            ...improvements.map((s) => _bulletPoint(s, OdinTheme.accentRed)),
          ],

          if (motivation.isNotEmpty) ...[
            const SizedBox(height: 20),
            Center(
              child: Text(
                '🔥 "$motivation"',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _aiCardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OdinTheme.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OdinTheme.primaryBlue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: OdinTheme.primaryBlue, size: 16),
              const SizedBox(width: 8),
              const Text('ANALYSE IA', style: TextStyle(color: OdinTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _bulletPoint(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white60, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _teamInfo(String name, bool isHome) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isHome ? OdinTheme.primaryBlue.withOpacity(0.2) : OdinTheme.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isHome ? Icons.shield_rounded : Icons.shield_outlined,
            color: isHome ? OdinTheme.primaryBlue : OdinTheme.textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name.toUpperCase(),
          style: const TextStyle(color: OdinTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: OdinTheme.textTertiary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }
}
