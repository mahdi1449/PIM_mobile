import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/player.dart';
import '../../providers/events_provider.dart';
import '../../providers/players_provider.dart';
import '../../theme/sp_colors.dart';
import '../../theme/sp_typography.dart';
import '../event_detail/event_detail_screen.dart';
import 'widgets/event_type_card.dart';
import '../../models/test_type.dart';
import 'package:provider/provider.dart' as pub;
import '../../providers/test_types_provider.dart';
import '../../../erp/providers/auth_provider.dart';
import '../../../ui/shell/app_shell.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  final Event? eventToEdit;
  
  const CreateEventScreen({super.key, this.eventToEdit});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _searchController = TextEditingController();

  EventType _selectedType = EventType.testSession;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  bool _isSquadSelection = true;
  bool _showAllPlayers = false;
  final Set<String> _selectedPlayerIds = {};
  final Set<String> _selectedTestTypeIds = {};
  String _searchQuery = '';
  String _testSearchQuery = '';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      final e = widget.eventToEdit!;
      _titleController.text = e.title;
      _selectedType = e.type;
      _selectedDate = e.date;
      _selectedTime = TimeOfDay.fromDateTime(e.date);
      _selectedTestTypeIds.addAll(e.testTypes);
    } else {
      // Auto-select tests for default type
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoSelectTests(_selectedType);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) => _buildPickerTheme(context, child!),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => _buildPickerTheme(context, child!),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Theme _buildPickerTheme(BuildContext context, Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: SPColors.primaryBlue,
          onPrimary: Colors.white,
          surface: SPColors.backgroundSecondary,
          onSurface: SPColors.textPrimary,
        ),
      ),
      child: child,
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final auth = pub.Provider.of<AuthProvider>(context, listen: false);
      
      final coachId = auth.user?.id ?? 'unknown_coach';
      final clubId = auth.user?.clubId ?? 'unknown_club';

      setState(() => _isLoading = true);

      try {
        final DateTime eventDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        final eventModel = Event(
          id: widget.eventToEdit?.id ?? '',
          title: _titleController.text,
          type: _selectedType,
          date: eventDateTime,
          location: widget.eventToEdit?.location ?? 'Training Ground',
          status: widget.eventToEdit?.status ?? EventStatus.draft,
          coachId: coachId, 
          clubId: clubId,
          testTypes: _selectedTestTypeIds.toList(),
        );

        Event? eventResult;
        if (widget.eventToEdit != null) {
          eventResult = await ref.read(eventFormProvider.notifier).updateEvent(widget.eventToEdit!.id!, eventModel);
        } else {
          eventResult = await ref.read(eventFormProvider.notifier).createEvent(eventModel);
        }

        if (eventResult != null && mounted) {
          if (widget.eventToEdit == null) {
            for (final playerId in _selectedPlayerIds) {
              await ref.read(eventFormProvider.notifier).addPlayerToEvent(eventResult.id, playerId);
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Suivi créé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          
          if (mounted) Navigator.pop(context);
        } else if (mounted) {
          final state = ref.read(eventFormProvider);
          String errorMsg = 'Échec de l\'opération';
          if (state is AsyncError) {
             errorMsg = state.error.toString().replaceFirst('Exception: ', '');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$errorMsg (ID: ${auth.user!.id})'), 
              backgroundColor: Colors.redAccent
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${e.toString().replaceFirst('Exception: ', '')} (ID: ${auth.user?.id})'), 
              backgroundColor: Colors.redAccent
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);
    final testTypesAsync = ref.watch(activeTestTypesProvider);

    return Scaffold(
      backgroundColor: SPColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.eventToEdit != null ? 'MODIFIER LE SUIVI' : 'CRÉER UN SUIVI', style: SPTypography.h4.copyWith(letterSpacing: 2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepper(),
              const SizedBox(height: 32),
              
              _buildSectionHeader('1. CHOISIR LE TYPE DE SUIVI', isRequired: true),
              const SizedBox(height: 16),
              _buildEventTypeGrid(),
              const SizedBox(height: 32),

              _buildSectionHeader('2. DÉTAILS DU SUIVI'),
              const SizedBox(height: 16),
              _buildTitleField(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDateTimePickerField(
                    label: 'START DATE',
                    value: DateFormat('dd MMM yyyy').format(_selectedDate),
                    icon: Icons.calendar_today_outlined,
                    onTap: () => _selectDate(context),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDateTimePickerField(
                    label: 'START TIME',
                    value: _selectedTime.format(context),
                    icon: Icons.access_time_outlined,
                    onTap: () => _selectTime(context),
                  )),
                ],
              ),
              const SizedBox(height: 32),

              _buildParticipantSelection(playersAsync),
              const SizedBox(height: 32),

              _buildSectionHeader('4. TEST SELECTION'),
              const SizedBox(height: 16),
              _buildTestSelection(testTypesAsync),
              
              const SizedBox(height: 48),
              _buildActionButtons(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStep(1, isActive: true),
        _buildStepLine(),
        _buildStep(2),
        _buildStepLine(),
        _buildStep(3),
        _buildStepLine(),
        _buildStep(4),
      ],
    );
  }

  Widget _buildStep(int number, {bool isActive = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? SPColors.primaryBlue : SPColors.backgroundSecondary,
        boxShadow: isActive ? [
          BoxShadow(
            color: SPColors.primaryBlue.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ] : null,
      ),
      child: Center(
        child: Text(
          '$number',
          style: SPTypography.bodyMedium.copyWith(
            color: isActive ? Colors.white : SPColors.textTertiary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 40,
      height: 1,
      color: SPColors.borderPrimary.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildSectionHeader(String title, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          title,
          style: SPTypography.overline.copyWith(
            color: SPColors.primaryBlue,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        if (isRequired) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: SPColors.primaryBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'REQUIRED',
              style: SPTypography.overline.copyWith(color: SPColors.primaryBlue, fontSize: 8),
            ),
          ),
        ],
      ],
    );
  }

  void _onTypeChanged(EventType type) {
    setState(() {
      _selectedType = type;
    });
    _autoSelectTests(type);
  }

  void _autoSelectTests(EventType type) {
    final testTypesAsync = ref.read(activeTestTypesProvider);
    testTypesAsync.whenData((tests) {
      final defaultNames = type.defaultTestNames;
      final recommendedIds = tests
          .where((t) => defaultNames.any((name) => t.name.toLowerCase().contains(name.toLowerCase())))
          .map((t) => t.id)
          .toList();

      setState(() {
        _selectedTestTypeIds.clear();
        _selectedTestTypeIds.addAll(recommendedIds);
      });
    });
  }

  Widget _buildEventTypeGrid() {
    final types = [
      [EventType.testSession, EventType.match],
      [EventType.evaluation, EventType.detection],
      [EventType.medical, EventType.recovery],
    ];

    return Column(
      children: types.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            EventTypeCard(
              type: row[0],
              isSelected: _selectedType == row[0],
              onTap: () => _onTypeChanged(row[0]),
            ),
            const SizedBox(width: 12),
            EventTypeCard(
              type: row[1],
              isSelected: _selectedType == row[1],
              onTap: () => _onTypeChanged(row[1]),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTitleField() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SPColors.backgroundSecondary.withOpacity(0.7),
            SPColors.backgroundSecondary.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SPColors.primaryBlue.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: SPColors.primaryBlue.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.title_rounded, color: SPColors.primaryBlue, size: 14),
                const SizedBox(width: 8),
                Text(
                  'TITRE DU SUIVI',
                  style: SPTypography.overline.copyWith(
                    color: SPColors.primaryBlue, 
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
          TextFormField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'e.g. Morning Sprint Power Test',
              hintStyle: TextStyle(color: SPColors.textTertiary.withOpacity(0.5), fontWeight: FontWeight.normal, fontSize: 16),
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              fillColor: Colors.transparent,
            ),
            validator: (v) => v!.isEmpty ? 'Titre requis' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePickerField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              SPColors.backgroundSecondary.withOpacity(0.7),
              SPColors.backgroundSecondary.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SPColors.primaryBlue.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: SPColors.primaryBlue.withOpacity(0.05),
              blurRadius: 15,
              spreadRadius: 1,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: SPColors.primaryBlue, size: 14),
                const SizedBox(width: 8),
                Text(
                  label, 
                  style: SPTypography.overline.copyWith(
                    color: SPColors.primaryBlue, 
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantSelection(AsyncValue<List<Player>> playersAsync) {
    return Container(
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SPColors.primaryBlue.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: SPColors.backgroundSecondary.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SPColors.borderPrimary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  _buildToggleItem('SQUAD', _isSquadSelection, () => setState(() => _isSquadSelection = true)),
                  _buildToggleItem('CUSTOM', !_isSquadSelection, () => setState(() => _isSquadSelection = false)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: SPColors.backgroundSecondary.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SPColors.borderPrimary.withOpacity(0.3), width: 1.5),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search players...',
                  hintStyle: TextStyle(color: SPColors.textTertiary.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.search, color: SPColors.textTertiary, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          playersAsync.when(
            data: (players) {
              final filteredPlayers = players.where((p) {
                final matchSearch = p.fullName.toLowerCase().contains(_searchQuery.toLowerCase());
                return matchSearch;
              }).toList();

              return Column(
                children: [
                  ...(_showAllPlayers 
                      ? filteredPlayers 
                      : filteredPlayers.take(3)
                  ).map((player) => _buildPlayerItem(player)),
                  if (filteredPlayers.length > 3)
                    TextButton(
                      onPressed: () => setState(() => _showAllPlayers = !_showAllPlayers),
                      child: Text(
                        _showAllPlayers 
                            ? 'SHOW FEWER PLAYERS' 
                            : 'SHOW ALL ${filteredPlayers.length} PLAYERS',
                        style: SPTypography.overline.copyWith(color: SPColors.primaryBlue, letterSpacing: 1.1),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
            error: (e, s) => Padding(padding: const EdgeInsets.all(16), child: Text('Error loading players', style: TextStyle(color: SPColors.error))),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? LinearGradient(
              colors: [
                SPColors.primaryBlue,
                const Color(0xFF007AFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: SPColors.primaryBlue.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: SPTypography.overline.copyWith(
                color: isSelected ? Colors.white : SPColors.textTertiary,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerItem(Player player) {
    final isSelected = _selectedPlayerIds.contains(player.id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? SPColors.primaryBlue.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? SPColors.primaryBlue.withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    SPColors.primaryBlue.withOpacity(0.6),
                    const Color(0xFFAF52DE).withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: player.photo != null 
                  ? ClipOval(
                      child: Image.network(
                        player.photo!, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    '${player.position.toUpperCase()} • FIRST TEAM', 
                    style: SPTypography.caption.copyWith(color: SPColors.textTertiary, fontSize: 10, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: isSelected,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedPlayerIds.add(player.id);
                  } else {
                    _selectedPlayerIds.remove(player.id);
                  }
                });
              },
              checkColor: Colors.white,
              activeColor: SPColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              side: BorderSide(color: isSelected ? SPColors.primaryBlue : SPColors.borderPrimary.withOpacity(0.5), width: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSelection(AsyncValue<List<TestType>> testTypesAsync) {
    return Container(
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SPColors.primaryBlue.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: SPColors.backgroundSecondary.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SPColors.borderPrimary.withOpacity(0.3), width: 1.5),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _testSearchQuery = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search test types...',
                  hintStyle: TextStyle(color: SPColors.textTertiary.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.search, color: SPColors.textTertiary, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),
          testTypesAsync.when(
            data: (tests) {
              final recommendedCategory = _selectedType.recommendedCategory;
              
              final recommendedTests = tests.where((t) => 
                t.category == recommendedCategory && 
                t.name.toLowerCase().contains(_testSearchQuery.toLowerCase())
              ).toList();
              
              final otherTests = tests.where((t) => 
                t.category != recommendedCategory && 
                t.name.toLowerCase().contains(_testSearchQuery.toLowerCase())
              ).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recommendedTests.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        'RECOMMENDED (${_selectedType.recommendedCategory.value.toUpperCase()})',
                        style: SPTypography.overline.copyWith(color: SPColors.primaryBlue, fontSize: 8),
                      ),
                    ),
                    ...recommendedTests.map((test) => _buildTestItem(test)),
                  ],
                  if (otherTests.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        'OTHER TESTS',
                        style: SPTypography.overline.copyWith(color: SPColors.textTertiary, fontSize: 8),
                      ),
                    ),
                    ...otherTests.map((test) => _buildTestItem(test)),
                  ],
                ],
              );
            },
            loading: () => const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
            error: (e, s) => Padding(padding: const EdgeInsets.all(16), child: Text('Error loading tests', style: TextStyle(color: SPColors.error))),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTestItem(TestType test) {
    final isSelected = _selectedTestTypeIds.contains(test.id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedTestTypeIds.remove(test.id);
            } else {
              _selectedTestTypeIds.add(test.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? SPColors.primaryBlue.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? SPColors.primaryBlue.withOpacity(0.5) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getCategoryColor(test.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(test.category),
                  color: _getCategoryColor(test.category),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(test.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      test.categoryLabel, 
                      style: SPTypography.caption.copyWith(color: SPColors.textTertiary, fontSize: 9),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: SPColors.primaryBlue, size: 20)
              else
                Icon(Icons.add_circle_outline, color: SPColors.textTertiary.withOpacity(0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(TestCategory category) {
    switch (category) {
      case TestCategory.physical: return Icons.fitness_center;
      case TestCategory.technical: return Icons.sports_soccer;
      case TestCategory.medical: return Icons.medical_services_outlined;
      case TestCategory.mental: return Icons.psychology_outlined;
    }
  }

  Color _getCategoryColor(TestCategory category) {
    switch (category) {
      case TestCategory.physical: return SPColors.primaryBlue;
      case TestCategory.technical: return const Color(0xFFFFB020);
      case TestCategory.medical: return const Color(0xFFE95464);
      case TestCategory.mental: return const Color(0xFF9E77ED);
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: const BorderSide(color: SPColors.borderPrimary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('SAVE', style: SPTypography.button.copyWith(color: SPColors.textSecondary)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: SPColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 8,
              shadowColor: SPColors.primaryBlue.withOpacity(0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.eventToEdit != null ? 'METTRE À JOUR' : 'CONFIRMER LE SUIVI',
                  style: SPTypography.button.copyWith(color: Colors.white, letterSpacing: 1.2),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.bolt, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
