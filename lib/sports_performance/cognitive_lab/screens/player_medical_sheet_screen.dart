import 'dart:math';
import 'package:flutter/material.dart';
import '../../../ui/theme/medical_theme.dart';
import '../models/nutrition_models.dart';
import '../services/nutrition_api_service.dart';

class PlayerMedicalSheetScreen extends StatefulWidget {
  final String playerId;
  final String playerName;
  final String playerPosition;

  PlayerMedicalSheetScreen({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.playerPosition,
  });

  @override
  State<PlayerMedicalSheetScreen> createState() =>
      _PlayerMedicalSheetScreenState();
}

class _PlayerMedicalSheetScreenState extends State<PlayerMedicalSheetScreen>
    with SingleTickerProviderStateMixin {
  final NutritionApiService _api = NutritionApiService();
  late AnimationController _animController;

  PhysicalProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _showSuccess = false;

  // Form values (doubles for sliders)
  double _currentWeight = 75.0;
  double _currentHeight = 180.0;
  double _currentWaist = 80.0;
  double _currentNeck = 38.0;
  DateTime _birthDate = DateTime(2000, 1, 1);
  String _selectedPosition = 'Midfielder';

  // Calculated values for realtime display
  double _localBmi = 0;
  double _localFat = 0;
  double _localMuscle = 0;
  double _localWater = 0;
  int _localBmr = 0;

  MetabolicStatus? _metabolicStatus;

  final List<String> _positions = [
    'Goalkeeper',
    'Defender',
    'Midfielder',
    'Forward',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await _api.getPhysicalProfile(widget.playerId);
    final status = await _api.getMetabolicStatus(widget.playerId);

    setState(() {
      _profile = profile;
      _metabolicStatus = status;
      _isLoading = false;
      if (profile != null) {
        _currentWeight = profile.weightKg;
        _currentHeight = profile.heightCm;
        _currentWaist = profile.tourTaille;
        _currentNeck = profile.tourCou;
        _birthDate = profile.dateNaissance;
        _selectedPosition = profile.position;
        _calculateLocalStatus();
      }
      _animController.forward();
    });
  }

  void _calculateLocalStatus() {
    // 1. BMI
    _localBmi = _currentWeight / (pow(_currentHeight / 100, 2));

    // 2. Body Fat (US Navy)
    double log10(double x) => log(x) / ln10;
    double diff = _currentWaist - _currentNeck;
    if (diff > 5) {
      double logTaille = log10(_currentHeight);
      double logDiff = log10(diff);
      double graisseRaw =
          495 / (1.0324 - 0.19077 * logDiff + 0.15456 * logTaille) - 450;
      _localFat = graisseRaw.clamp(3, 40);
    } else {
      _localFat = 0;
    }

    // 3. Muscle Mass (0.85 pro athlete coefficient)
    _localMuscle = _currentWeight * (1 - _localFat / 100) * 0.85;

    // 4. BMR (Mifflin-St Jeor)
    int age = DateTime.now().year - _birthDate.year;
    _localBmr =
        ((10 * _currentWeight) + (6.25 * _currentHeight) - (5 * age) + 5)
            .round();

    // 5. Water (Base 0.035L/kg)
    _localWater = _currentWeight * 0.035;
  }

  Future<void> _saveProfile() async {
    final profile = PhysicalProfile(
      userId: widget.playerId,
      weightKg: _currentWeight,
      heightCm: _currentHeight,
      tourTaille: _currentWaist,
      tourCou: _currentNeck,
      dateNaissance: _birthDate,
      position: _selectedPosition,
    );

    setState(() {
      _isSaving = true;
      _showSuccess = false;
    });

    try {
      final error = await _api.savePhysicalProfile(profile);

      if (error == null) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
          _showSuccess = true;
        });

        // Show success animation for 2 seconds
        Future.delayed(Duration(milliseconds: 2000), () {
          if (mounted) setState(() => _showSuccess = false);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fiche médicale sauvegardée ✓'),
            backgroundColor: MedicalTheme.success,
          ),
        );
        _loadProfile();
      } else if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ERREUR : $error'),
            backgroundColor: MedicalTheme.danger,
            duration: Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ERREUR RÉSEAU : $e'),
            backgroundColor: MedicalTheme.danger,
            duration: Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MedicalThemeScope(
      applyBackground: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(gradient: MedicalTheme.appGradient),
          child: CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(height: 24),
                    if (_isLoading) _buildSkeleton(),
                    if (!_isLoading && _profile == null && !_isEditing)
                      _buildEmptyState(),
                    if (!_isLoading && (_profile != null || _isEditing)) ...[
                      FadeTransition(
                        opacity: _animController,
                        child: Column(
                          children: [
                            if (_metabolicStatus?.error != null)
                              _buildDataConsistencyAlert(
                                _metabolicStatus!.error!,
                              ),
                            _buildPhysicalStats(),
                            SizedBox(height: 24),
                            _buildBodyCompositionRings(),
                            SizedBox(height: 24),
                            _buildEditForm(),
                          ],
                        ),
                      ),
                      SizedBox(height: 100),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: [StretchMode.blurBackground, StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(gradient: MedicalTheme.appGradient),
            ),
            // Decorative elements
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MedicalTheme.accentBlue.withOpacity(0.08),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: MedicalTheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: MedicalTheme.accentBlue.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: MedicalTheme.softShadow,
                      ),
                      child: Center(
                        child: Text(
                          widget.playerName.isNotEmpty
                              ? widget.playerName
                                    .substring(
                                      0,
                                      min(2, widget.playerName.length),
                                    )
                                    .toUpperCase()
                              : 'JR',
                          style: TextStyle(
                            color: MedicalTheme.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            letterSpacing: 1,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.playerName.toUpperCase(),
                            style: TextStyle(
                              color: MedicalTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: MedicalTheme.accentBlue.withOpacity(
                                    0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: MedicalTheme.accentBlue.withOpacity(
                                      0.25,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  widget.playerPosition,
                                  style: TextStyle(
                                    color: MedicalTheme.primaryBlue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '• FICHE BIOMÉTRIQUE',
                                style: TextStyle(
                                  color: MedicalTheme.textMuted,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: MedicalTheme.textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (!_isLoading && _profile != null)
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.tune,
              color: _isEditing ? MedicalTheme.danger : MedicalTheme.success,
            ),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
      ],
    );
  }

  Widget _buildPhysicalStats() {
    if (_profile == null) return SizedBox.shrink();

    final bmi = _profile!.bmi;
    String bmiStatus;
    Color bmiColor;

    if (bmi < 18.5) {
      bmiStatus = 'DÉFICIT PONDÉRAL';
      bmiColor = MedicalTheme.warning;
    } else if (bmi < 25) {
      bmiStatus = 'ATHLÈTE OPTIMAL';
      bmiColor = MedicalTheme.success;
    } else if (bmi < 30) {
      bmiStatus = 'SURPOIDS LÉGER';
      bmiColor = MedicalTheme.warning;
    } else {
      bmiStatus = 'RISQUE MÉTABOLIQUE';
      bmiColor = MedicalTheme.danger;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PARAMÈTRES PHYSIQUES',
          style: TextStyle(
            color: MedicalTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            decoration: TextDecoration.none,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'MASSE TOTALE',
                _profile!.weightKg.toStringAsFixed(1),
                'KG',
                MedicalTheme.primaryBlue,
                Icons.scale,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'STATURE',
                _profile!.heightCm.toStringAsFixed(1),
                'CM',
                MedicalTheme.accentTeal,
                Icons.height,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _buildBmiCard(bmi, bmiStatus, bmiColor),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: MedicalTheme.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: MedicalTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  decoration: TextDecoration.none,
                ),
              ),
              Icon(icon, color: color.withOpacity(0.5), size: 14),
            ],
          ),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: MedicalTheme.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4),
              Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBmiCard(double bmi, String status, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), MedicalTheme.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MedicalTheme.cardBorder),
        boxShadow: MedicalTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.analytics_outlined, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IMC / INDICE DE MASSE CORPORELLE',
                  style: TextStyle(
                    color: MedicalTheme.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    decoration: TextDecoration.none,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      bmi.toStringAsFixed(1),
                      style: TextStyle(
                        color: MedicalTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataConsistencyAlert(String message) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: MedicalTheme.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MedicalTheme.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: MedicalTheme.warning,
            size: 24,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: MedicalTheme.warning,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyCompositionRings() {
    if (_profile == null) return SizedBox.shrink();

    // Utilisation des données calculées par le backend si disponibles
    final profileWithCalculations = _metabolicStatus?.profileData ?? _profile!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMPOSITION TISSULAIRE (IA ESTIMATE)',
          style: TextStyle(
            color: MedicalTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            decoration: TextDecoration.none,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildRingCard(
                'MUSCLE',
                profileWithCalculations.masseMuscul ?? 0,
                profileWithCalculations.weightKg,
                'KG',
                MedicalTheme.success,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildRingCard(
                'GRASSE',
                _metabolicStatus?.error != null
                    ? 0
                    : (profileWithCalculations.graissePercent ?? 0),
                100,
                '%',
                MedicalTheme.warning,
                showNoValue: _metabolicStatus?.error != null,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildRingCard(
                'EAU',
                (_metabolicStatus?.targets['hydrationMl'] ?? 0) / 1000,
                5,
                'L',
                MedicalTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRingCard(
    String label,
    double value,
    double max,
    String unit,
    Color color, {
    bool showNoValue = false,
  }) {
    final pct = (value / max).clamp(0.0, 1.0);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MedicalTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: showNoValue ? 0 : pct,
                  strokeWidth: 4,
                  backgroundColor: color.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      showNoValue ? '—' : value.toStringAsFixed(0),
                      style: TextStyle(
                        color: MedicalTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    Text(
                      unit,
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MedicalTheme.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    if (!_isEditing) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MedicalTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MedicalTheme.cardBorder),
        boxShadow: MedicalTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ÉDITION DU PROFIL ATHLÈTE',
                style: TextStyle(
                  color: MedicalTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  decoration: TextDecoration.none,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _isEditing = false),
                icon: Icon(
                  Icons.close,
                  color: MedicalTheme.textMuted,
                  size: 18,
                ),
              ),
            ],
          ),
          SizedBox(height: 32),

          _buildSliderField(
            'Poids (KG)',
            _currentWeight,
            50,
            120,
            (val) => setState(() {
              _currentWeight = val;
              _calculateLocalStatus();
            }),
            'kg',
            'Glissez pour modifier',
            MedicalTheme.success,
          ),

          _buildSliderField(
            'Taille (CM)',
            _currentHeight,
            155,
            210,
            (val) => setState(() {
              _currentHeight = val;
              _calculateLocalStatus();
            }),
            'cm',
            '',
            MedicalTheme.primaryBlue,
          ),

          _buildSliderField(
            'Tour de taille (CM)',
            _currentWaist,
            60,
            120,
            (val) => setState(() {
              _currentWaist = val;
              _calculateLocalStatus();
            }),
            'cm',
            'Mesuré au niveau du nombril',
            MedicalTheme.warning,
          ),

          _buildSliderField(
            'Tour de cou (CM)',
            _currentNeck,
            30,
            55,
            (val) => setState(() {
              _currentNeck = val;
              _calculateLocalStatus();
            }),
            'cm',
            'À la base du cou',
            MedicalTheme.accentTeal,
          ),

          SizedBox(height: 8),

          // Date of birth picker
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _birthDate,
                firstDate: DateTime(1970),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _birthDate = picked;
                  _calculateLocalStatus();
                });
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              margin: EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: MedicalTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DATE DE NAISSANCE',
                        style: TextStyle(
                          color: MedicalTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "${_birthDate.day}/${_birthDate.month}/${_birthDate.year}",
                        style: TextStyle(
                          color: MedicalTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: MedicalTheme.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          DropdownButtonFormField<String>(
            value: _selectedPosition,
            dropdownColor: MedicalTheme.surface,
            icon: Icon(Icons.expand_more, color: MedicalTheme.textMuted),
            style: TextStyle(
              color: MedicalTheme.textPrimary,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
            decoration: InputDecoration(
              labelText: 'POSTE SUR LE TERRAIN',
              labelStyle: TextStyle(
                color: MedicalTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
              filled: true,
              fillColor: MedicalTheme.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            onChanged: (val) =>
                setState(() => _selectedPosition = val ?? 'Midfielder'),
            items: _positions
                .map(
                  (p) =>
                      DropdownMenuItem(value: p, child: Text(p.toUpperCase())),
                )
                .toList(),
          ),

          SizedBox(height: 40),
          Text(
            'Calculé automatiquement par l\'IA',
            style: TextStyle(
              color: MedicalTheme.success,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 20),

          _buildIAStatusGrid(),

          SizedBox(height: 40),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: _showSuccess
                  ? MedicalTheme.success
                  : MedicalTheme.primaryBlue,
              foregroundColor: MedicalTheme.surface,
              padding: EdgeInsets.symmetric(vertical: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
              shadowColor:
                  (_showSuccess
                          ? MedicalTheme.success
                          : MedicalTheme.primaryBlue)
                      .withOpacity(0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSaving)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: MedicalTheme.surface,
                    ),
                  )
                else if (_showSuccess)
                  Icon(Icons.check, size: 24)
                else
                  Icon(Icons.lock_outline, size: 20),
                SizedBox(width: 12),
                Text(
                  _isSaving
                      ? 'SAUVEGARDE EN COURS...'
                      : (_showSuccess
                            ? 'DONNÉES SÉCURISÉES'
                            : 'SÉCURISER LES DONNÉES'),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.5,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderField(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    String unit,
    String help,
    Color color,
  ) {
    final effectiveMin = value < min ? value : min;
    final effectiveMax = value > max ? value : max;
    final safeValue = value.clamp(effectiveMin, effectiveMax).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: MedicalTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  safeValue.toStringAsFixed(0),
                  style: TextStyle(
                    color: MedicalTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(width: 4),
                Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    unit,
                    style: TextStyle(
                      color: MedicalTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            activeTrackColor: color,
            inactiveTrackColor: MedicalTheme.cardBorder,
            thumbColor: MedicalTheme.surface,
            overlayColor: color.withOpacity(0.1),
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: 10,
              pressedElevation: 8,
            ),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: safeValue,
            min: effectiveMin,
            max: effectiveMax,
            onChanged: (val) => onChanged(val),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${effectiveMin.toInt()} $unit',
                style: TextStyle(
                  color: MedicalTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (help.isNotEmpty)
                Text(
                  help,
                  style: TextStyle(
                    color: MedicalTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                '${effectiveMax.toInt()} $unit',
                style: TextStyle(
                  color: MedicalTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildIAStatusGrid() {
    String fatStatus;
    if (_localBmi < 18.5)
      fatStatus = 'Déficit';
    else if (_localBmi < 25)
      fatStatus = 'Optimal';
    else
      fatStatus = 'Surpoids';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildRealtimeCard(
                'IMC',
                _localBmi.toStringAsFixed(1),
                fatStatus,
                MedicalTheme.primaryBlue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildRealtimeCard(
                '% Graisse',
                '${_localFat.toStringAsFixed(1)}%',
                'US Navy',
                MedicalTheme.warning,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRealtimeCard(
                'Muscle',
                '${_localMuscle.toStringAsFixed(1)} kg',
                'estimé',
                MedicalTheme.success,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildRealtimeCard(
                'Eau repos',
                '${_localWater.toStringAsFixed(2)} L',
                '/ jour',
                MedicalTheme.accentTeal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRealtimeCard(
    String label,
    String value,
    String subValue,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: MedicalTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 2),
          Text(
            subValue,
            style: TextStyle(
              color: MedicalTheme.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 80),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: MedicalTheme.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: MedicalTheme.cardBorder),
            ),
            child: Icon(
              Icons.person_add_outlined,
              color: MedicalTheme.textMuted,
              size: 40,
            ),
          ),
          SizedBox(height: 32),
          Text(
            'INITIALISATION REQUISE',
            style: TextStyle(
              color: MedicalTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Les paramètres biométriques sont nécessaires pour calibrer les algorithmes nutritionnels.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MedicalTheme.textSecondary,
                fontSize: 11,
                height: 1.5,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() => _isEditing = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MedicalTheme.primaryBlue,
              foregroundColor: MedicalTheme.surface,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'CRÉER LA FICHE BIOMÉTRIQUE',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          margin: EdgeInsets.only(bottom: 16),
          height: 100,
          decoration: BoxDecoration(
            color: MedicalTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return SizedBox.shrink();
  }
}
