import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../ui/navigation/app_routes.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/events_provider.dart';
import '../../widgets/status_badge.dart';
import '../../models/event.dart';
import 'event_form_screen.dart';
import 'event_convocations_screen.dart';
import 'match_sheet_screen.dart';
import 'widgets/match_summary_card.dart';
import 'event_timeline_live_screen.dart';
import 'event_match_result_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final String? eventId;
  const EventDetailScreen({super.key, this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isInit = false;
  bool _isResponding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final id = widget.eventId ?? (ModalRoute.of(context)?.settings.arguments as String?);
      if (id != null) {
        final provider = Provider.of<EventsProvider>(context, listen: false);
        provider.fetchEvent(id);
        provider.fetchParticipants(id);
      }
      _isInit = true;
    }
  }

  Future<void> _handleResponse(String status, dynamic myParticipation) async {
    final provider = Provider.of<EventsProvider>(context, listen: false);
    final event = provider.selectedEvent;
    if (event == null) return;

    setState(() => _isResponding = true);
    
    final success = await provider.respondToConvocation(
      event.id!,
      myParticipation.id, // Using unique database ID (_id) instead of participantId
      status,
    );

    if (mounted) {
      setState(() => _isResponding = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'confirmed' ? 'Présence confirmée !' : 'Convocation déclinée'),
            backgroundColor: status == 'confirmed' ? OdinTheme.accentGreen : OdinTheme.accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Erreur lors de la réponse'),
            backgroundColor: OdinTheme.accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildResponseButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: _isResponding ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: _isResponding && (label == 'Confirmer' || label == 'Décliner') 
            ? const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.user;
    final provider = Provider.of<EventsProvider>(context);
    final event = provider.selectedEvent;
    final df = DateFormat('dd/MM/yyyy HH:mm');

    if (provider.error != null && event == null) {
      return Scaffold(
        backgroundColor: OdinTheme.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: OdinTheme.accentRed, size: 48),
              const SizedBox(height: 16),
              Text(provider.error!, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final id = widget.eventId ?? (ModalRoute.of(context)?.settings.arguments as String?);
                  if (id != null) {
                    provider.fetchEvent(id);
                    provider.fetchParticipants(id);
                  }
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if ((provider.isLoading && event == null) || event == null) {
      return Scaffold(
        backgroundColor: OdinTheme.background,
        appBar: AppBar(title: const Text('Événement')),
        body: const Center(
          child: CircularProgressIndicator(color: OdinTheme.primaryBlue),
        ),
      );
    }

    final typeColors = {
      'match': OdinTheme.accentRed,
      'entrainement': OdinTheme.accentGreen,
      'reunion': OdinTheme.accentOrange,
      'detection': OdinTheme.accentCyan,
      'test_physique': OdinTheme.accentPurple,
    };
    final color = typeColors[event.eventType] ?? OdinTheme.primaryBlue;

    return Scaffold(
      backgroundColor: OdinTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: OdinTheme.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://image.pollinations.ai/prompt/${Uri.encodeComponent("professional ${event.eventType} ${event.title} cinematic high resolution sports photography landscape")}/?width=800&height=400&nologo=true&seed=${event.id.hashCode}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color.withOpacity(0.8), OdinTheme.surface],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          OdinTheme.background.withOpacity(0.8),
                          OdinTheme.background,
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.eventTypeLabel,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (event.weather != null) ...[
                              const Spacer(),
                              Text(
                                '${event.weather!.tempCelsius}°C',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            StatusBadge(status: event.status),
                            if (event.weather != null) ...[
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.network(
                                      'https://openweathermap.org/img/wn/${event.weather!.icon}@2x.png',
                                      width: 24,
                                      height: 24,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 16),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${event.weather!.tempCelsius}°C',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () {
                  final provider = Provider.of<EventsProvider>(context, listen: false);
                  provider.fetchEvent(event.id);
                  provider.fetchParticipants(event.id);
                },
              ),
              if (currentUser?.role == 'coach' || currentUser?.role == 'admin')
                PopupMenuButton<String>(
                  color: OdinTheme.surface,
                  onSelected: _handleAction,
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Text('Annuler l\'événement',
                          style: TextStyle(color: OdinTheme.accentRed)),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer',
                          style: TextStyle(color: OdinTheme.accentRed)),
                    ),
                  ],
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION CONVOCATION (Côté Joueur)
                  _buildConvocationResponse(context, event, provider),

                  // Details cards
                  _infoCard([
                    _row(Icons.calendar_today_rounded, 'Début',
                        df.format(event.startDate)),
                    _row(Icons.calendar_today_outlined, 'Fin',
                        df.format(event.endDate)),
                    if (event.location != null)
                      _row(
                        Icons.location_on_rounded, 
                        'Lieu', 
                        event.location!,
                        trailing: event.weather != null ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${event.weather!.tempCelsius}°C',
                              style: const TextStyle(color: OdinTheme.primaryBlue, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Image.network(
                              'https://openweathermap.org/img/wn/${event.weather!.icon}.png',
                              width: 32,
                              height: 32,
                              errorBuilder: (_, __, ___) => const Icon(Icons.wb_cloudy_rounded, color: OdinTheme.primaryBlue, size: 18),
                            ),
                          ],
                        ) : null,
                      ),
                    _row(Icons.visibility_rounded, 'Visibilité',
                        event.visibility.toUpperCase()),
                    if (event.teamName != null)
                      _row(Icons.groups_rounded, 'Équipe',
                          event.teamName!),
                  ]),

                  // ACTIONS DU MATCH (Visible si type Match)
                  if (event.eventType == 'match') ...[
                    const SizedBox(height: 24),
                    _sectionTitle('Actions du Match'),
                    const SizedBox(height: 12),
                    _actionButton(
                      context,
                      icon: Icons.group_add_rounded,
                      label: 'Convocations & Présences',
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventConvocationsScreen(eventId: event.id!), settings: RouteSettings(arguments: event.id)));
                      },
                    ),
                    const SizedBox(height: 8),
                    _actionButton(
                      context,
                      icon: Icons.format_list_bulleted_rounded,
                      label: 'Feuille de match',
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => MatchSheetScreen(eventId: event.id!), settings: RouteSettings(arguments: event.id)));
                      },
                    ),
                    const SizedBox(height: 8),
                    _actionButton(
                      context,
                      icon: Icons.circle,
                      iconColor: OdinTheme.accentRed,
                      label: 'Timeline Live',
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventTimelineLiveScreen(eventId: event.id!), settings: RouteSettings(arguments: event.id)));
                      },
                    ),
                    const SizedBox(height: 8),
                    _actionButton(
                      context,
                      icon: Icons.score_rounded,
                      iconColor: OdinTheme.accentOrange,
                      label: 'Publier le résultat',
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventMatchResultScreen(eventId: event.id!), settings: RouteSettings(arguments: event.id)));
                      },
                    ),
                  ],

                  if (event.homeScore != null && event.awayScore != null) ...[
                    const SizedBox(height: 24),
                    MatchSummaryCard(event: event),
                  ],

                  if (event.description != null) ...[
                    const SizedBox(height: 16),
                    _sectionTitle('Description'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: OdinTheme.glassCard,
                      child: Text(
                        event.description!,
                        style: const TextStyle(
                          color: OdinTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],

                  // SECTION MÉTÉO
                  const SizedBox(height: 20),
                  _sectionTitle('Conditions Météo'),
                  const SizedBox(height: 8),
                  if (event.weather != null) 
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: OdinTheme.glassCard,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: OdinTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.network(
                              'https://openweathermap.org/img/wn/${event.weather!.icon}@2x.png',
                              width: 40,
                              height: 40,
                              errorBuilder: (ctx, err, stack) => const Icon(Icons.wb_sunny_rounded, color: OdinTheme.accentOrange, size: 30),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.weather!.condition.toUpperCase(),
                                  style: const TextStyle(color: OdinTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'Température : ${event.weather!.tempCelsius}°C',
                                  style: const TextStyle(color: OdinTheme.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Icon(Icons.air_rounded, color: OdinTheme.textTertiary, size: 18),
                              const SizedBox(height: 4),
                              Text('${event.weather!.windKmh} km/h', style: const TextStyle(color: OdinTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: OdinTheme.glassCard,
                      child: Row(
                        children: [
                          const Icon(Icons.wb_cloudy_outlined, color: OdinTheme.textTertiary),
                          const SizedBox(width: 12),
                          Text('Calcul de la météo en cours...', style: TextStyle(color: OdinTheme.textTertiary, fontSize: 13)),
                        ],
                      ),
                    ),

                  // SECTION LOGISTIQUE
                  const SizedBox(height: 20),
                  _sectionTitle('Logistique & Itinéraire'),
                  const SizedBox(height: 8),
                  if (event.logistics != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(0),
                      clipBehavior: Clip.antiAlias,
                      decoration: OdinTheme.glassCard,
                      child: Column(
                        children: [
                          if (event.logistics!.lat != null && event.logistics!.lon != null)
                            Image.network(
                              'https://maps.locationiq.com/v3/staticmap?key=pk.8c1b2c0a58247eb6d0584fd4481caca1&center=${event.logistics!.lat},${event.logistics!.lon}&zoom=14&size=600x300&markers=icon:large-blue-cutout|${event.logistics!.lat},${event.logistics!.lon}',
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                height: 150,
                                color: OdinTheme.cardBorder,
                                child: const Icon(Icons.map_rounded, color: OdinTheme.textTertiary),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _logisticsRow(
                                  Icons.home_work_rounded, 
                                  'Lieu de départ', 
                                  event.logistics!.startAddress ?? 'Siège du Club'
                                ),
                                const Divider(color: OdinTheme.cardBorder, height: 1),
                                _logisticsRow(
                                  Icons.directions_bus_rounded, 
                                  'Départ suggéré (Bus)', 
                                  event.logistics!.departureTime != null 
                                    ? '${event.logistics!.departureTime!.toLocal().hour}h${event.logistics!.departureTime!.toLocal().minute.toString().padLeft(2, "0")}'
                                    : 'Non calculé'
                                ),
                                const Divider(color: OdinTheme.cardBorder, height: 1),
                                _logisticsRow(
                                  Icons.timer_outlined, 
                                  'Trajet estimé', 
                                  event.logistics!.travelTimeSeconds != null 
                                    ? '${(event.logistics!.travelTimeSeconds! / 3600).floor()}h ${(event.logistics!.travelTimeSeconds! % 3600 / 60).round()}min'
                                    : 'Non calculé'
                                ),
                                const Divider(color: OdinTheme.cardBorder, height: 1),
                                _logisticsRow(
                                  Icons.straighten_rounded, 
                                  'Distance totale', 
                                  event.logistics!.distanceKm != null 
                                    ? '${event.logistics!.distanceKm} km'
                                    : 'Non calculé'
                                ),
                                if (event.logistics!.itineraryUrl != null) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: OdinTheme.primaryBlue.withOpacity(0.1),
                                        foregroundColor: OdinTheme.primaryBlue,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                      label: const Text('Ouvrir dans OSM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      onPressed: () async {
                                        if (event.logistics?.itineraryUrl != null) {
                                          final url = Uri.parse(event.logistics!.itineraryUrl!);
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url, mode: LaunchMode.externalApplication);
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: OdinTheme.glassCard,
                      child: Row(
                        children: [
                          const Icon(Icons.directions_bus_outlined, color: OdinTheme.textTertiary),
                          const SizedBox(width: 12),
                          Text('Calcul de l\'itinéraire en cours...', style: TextStyle(color: OdinTheme.textTertiary, fontSize: 13)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  _sectionTitle('Participants'),
                  const SizedBox(height: 8),
                  if (provider.participants.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: OdinTheme.glassCard,
                      child: const Text(
                        'Aucun participant',
                        style: TextStyle(color: OdinTheme.textTertiary),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...provider.participants.map(_buildParticipant),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: OdinTheme.glassCard,
      child: Column(children: children),
    );
  }

  Widget _row(IconData icon, String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: OdinTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: OdinTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: OdinTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: OdinTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: OdinTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      );

  Widget _buildParticipant(dynamic p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: OdinTheme.glassCard,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                OdinTheme.primaryBlue.withOpacity(0.2),
            child: Icon(Icons.person_rounded,
                color: OdinTheme.primaryBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.participantType} #${p.participantId.substring(0, 8)}',
                  style: const TextStyle(
                      color: OdinTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (p.rating != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Note de perf. : ${p.rating}/10',
                    style: const TextStyle(
                        color: OdinTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          StatusBadge(status: p.status, fontSize: 9),
        ],
      ),
    );
  }

  Widget _logisticsRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: OdinTheme.primaryBlue, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: const TextStyle(color: OdinTheme.textSecondary, fontSize: 12)),
          ),
          Text(value, style: const TextStyle(color: OdinTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildConvocationResponse(BuildContext context, Event event, EventsProvider provider) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.user;
    if (currentUser == null) return const SizedBox.shrink();

    // Trouver si l'utilisateur actuel est un participant
    // On utilise le flag 'isMe' du backend, ou un match ID, ou un match avec le playerId lié
    final myParticipation = provider.participants.where((p) {
      final isIdMatch = p.participantId == currentUser.id;
      final isPlayerIdMatch = currentUser.playerId != null && p.participantId == currentUser.playerId;
      final isNameMatch = p.participantName?.toLowerCase().trim() == currentUser.fullName.toLowerCase().trim();
      return p.isMe || isIdMatch || isPlayerIdMatch || isNameMatch;
    }).firstOrNull;

    if (myParticipation == null) return const SizedBox.shrink();

    // Si déjà répondu
    if (myParticipation.status == 'confirmed' || myParticipation.status == 'declined') {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: OdinTheme.glassCard,
        child: Row(
          children: [
            Icon(
              myParticipation.status == 'confirmed' ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: myParticipation.status == 'confirmed' ? OdinTheme.accentGreen : OdinTheme.accentRed,
            ),
            const SizedBox(width: 12),
            Text(
              myParticipation.status == 'confirmed' 
                ? 'Vous avez confirmé votre présence.' 
                : 'Vous avez décliné cette convocation.',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [OdinTheme.primaryBlue.withOpacity(0.2), OdinTheme.primaryBlue.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OdinTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mark_email_unread_rounded, color: OdinTheme.primaryBlue, size: 20),
              const SizedBox(width: 12),
              const Text(
                'CONVOCATION À RÉPONDRE',
                style: TextStyle(
                  color: OdinTheme.primaryBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Le coach vous a convoqué pour cet événement. Merci de confirmer votre disponibilité.',
            style: TextStyle(color: OdinTheme.textPrimary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OdinTheme.accentGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  onPressed: () => provider.respondToConvocation(event.id, myParticipation.id, 'confirmed'),
                  label: const Text('Confirmer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: OdinTheme.accentRed,
                    side: const BorderSide(color: OdinTheme.accentRed),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => provider.respondToConvocation(event.id, myParticipation.id, 'declined'),
                  label: const Text('Décliner'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(String action) {
    final provider = Provider.of<EventsProvider>(context, listen: false);
    final event = provider.selectedEvent;
    if (event == null) return;

    switch (action) {
      case 'edit':
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventFormScreen(eventId: event.id), settings: RouteSettings(arguments: event.id)));
        break;
      case 'cancel':
        provider.updateEventStatus(event.id, 'cancelled');
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer ?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler')),
              TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final dialogNavigator = Navigator.of(ctx);
                    await provider.deleteEvent(event.id);
                    if (mounted) {
                      dialogNavigator.pop();
                      navigator.pop();
                    }
                  },
                  child: const Text('Supprimer',
                      style: TextStyle(color: OdinTheme.accentRed))),
            ],
          ),
        );
        break;
    }
  }

  Widget _actionButton(BuildContext context, {
    required IconData icon,
    Color? iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: OdinTheme.glassCard,
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? OdinTheme.primaryBlue, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: OdinTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: OdinTheme.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
