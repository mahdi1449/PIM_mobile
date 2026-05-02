import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../ui/navigation/app_routes.dart';
import '../../core/theme.dart';
import '../../providers/events_provider.dart';
import 'event_player_picker_screen.dart';

class EventConvocationsScreen extends StatefulWidget {
  final String eventId;
  const EventConvocationsScreen({super.key, required this.eventId});

  @override
  State<EventConvocationsScreen> createState() => _EventConvocationsScreenState();
}

class _EventConvocationsScreenState extends State<EventConvocationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EventsProvider>(context, listen: false);
      provider.fetchParticipants(widget.eventId);
      provider.fetchPresenceReport(widget.eventId);
    });
  }

  Widget _buildStatCircle({
    required String title,
    required String value,
    required Color color,
    required double percentage,
  }) {
    return Column(
      children: [
        SizedBox(
          height: 100,
          width: 100,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percentage,
                strokeWidth: 8,
                backgroundColor: OdinTheme.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            color: OdinTheme.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showStatusDialog(dynamic participant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: OdinTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Modifier le statut', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _statusOption(ctx, participant, 'invited', Icons.access_time_rounded, OdinTheme.textSecondary, 'En attente'),
              _statusOption(ctx, participant, 'confirmed', Icons.check_circle_rounded, OdinTheme.accentGreen, 'Présent / Confirmé'),
              _statusOption(ctx, participant, 'declined', Icons.cancel_rounded, OdinTheme.accentRed, 'Absent / Refusé'),
            ],
          ),
        );
      },
    );
  }

  Widget _statusOption(BuildContext ctx, dynamic participant, String status, IconData icon, Color color, String label) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () async {
        Navigator.pop(ctx);
        final provider = Provider.of<EventsProvider>(context, listen: false);
        await provider.updateParticipantStatus(widget.eventId, participant.participantId, status);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventsProvider>(context);
    final stats = provider.presenceStats;
    final loading = provider.isLoading;

    int confirmationRate = stats?['confirmationRate'] ?? 0;
    int confirmed = stats?['confirmed'] ?? 0;
    int total = stats?['total'] ?? 0;
    
    // Fallback manually if stats not fully loaded
    if (stats == null && provider.participants.isNotEmpty) {
      total = provider.participants.length;
      confirmed = provider.participants.where((p) => p.status == 'confirmed').length;
      confirmationRate = total > 0 ? (confirmed / total * 100).round() : 0;
    }

    return Scaffold(
      backgroundColor: OdinTheme.background,
      appBar: AppBar(
        title: const Text('Convocations & Présences', style: TextStyle(fontSize: 16)),
        backgroundColor: OdinTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded, color: OdinTheme.primaryBlue),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EventPlayerPickerScreen(eventId: widget.eventId),
                settings: RouteSettings(arguments: widget.eventId),
              ),
            ),
            tooltip: 'Modifier la sélection',
          ),
        ],
      ),
      body: loading && provider.participants.isEmpty
          ? const Center(child: CircularProgressIndicator(color: OdinTheme.primaryBlue))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    decoration: BoxDecoration(
                      color: OdinTheme.surface,
                      border: const Border(bottom: BorderSide(color: OdinTheme.cardBorder)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCircle(
                          title: 'Taux Confirm.',
                          value: '$confirmationRate%',
                          color: OdinTheme.primaryBlue,
                          percentage: confirmationRate / 100,
                        ),
                        _buildStatCircle(
                          title: 'Joueurs ok',
                          value: '$confirmed/$total',
                          color: OdinTheme.accentOrange,
                          percentage: total > 0 ? confirmed / total : 0,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CONVOCATIONS',
                          style: TextStyle(
                            color: OdinTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (provider.participants.isEmpty)
                          const Center(child: Text('Aucun participant', style: TextStyle(color: OdinTheme.textTertiary)))
                        else ...[
                          _buildGroup(
                            title: 'En attente de confirmation',
                            color: OdinTheme.accentOrange,
                            icon: Icons.hourglass_empty_rounded,
                            participants: provider.participants.where((p) => p.status == 'invited' || p.status == 'pending').toList(),
                          ),
                          _buildGroup(
                            title: 'Confirmés / Présents',
                            color: OdinTheme.accentGreen,
                            icon: Icons.check_circle_rounded,
                            participants: provider.participants.where((p) => p.status == 'confirmed').toList(),
                          ),
                          _buildGroup(
                            title: 'Absents / Déclinés',
                            color: OdinTheme.accentRed,
                            icon: Icons.cancel_rounded,
                            participants: provider.participants.where((p) => p.status == 'declined').toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGroup({
    required String title,
    required Color color,
    required IconData icon,
    required List<dynamic> participants,
  }) {
    if (participants.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 8),
              Text(
                '${title.toUpperCase()} (${participants.length})',
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
        ...participants.map((p) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: OdinTheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: OdinTheme.cardBorder.withOpacity(0.5)),
            ),
            child: ListTile(
              onTap: () => _showStatusDialog(p),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: OdinTheme.surfaceLight,
                child: const Icon(Icons.person, color: OdinTheme.textSecondary, size: 20),
              ),
              title: Text(
                p.participantName ?? p.participantId.substring(0, 8),
                style: const TextStyle(color: OdinTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 14),
              ),
              subtitle: Text(
                'Joueur',
                style: const TextStyle(color: OdinTheme.textTertiary, fontSize: 12),
              ),
              trailing: Icon(icon, color: color.withOpacity(0.5), size: 18),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
  }


