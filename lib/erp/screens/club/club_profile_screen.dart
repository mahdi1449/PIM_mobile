import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clubs_provider.dart';

class ClubProfileScreen extends StatefulWidget {
  const ClubProfileScreen({super.key});

  @override
  State<ClubProfileScreen> createState() => _ClubProfileScreenState();
}

class _ClubProfileScreenState extends State<ClubProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null && user.clubId != null) {
        _loadClub(user.clubId!);
      }
      _isInit = true;
    }
  }

  Future<void> _loadClub(String clubId) async {
    final provider = Provider.of<ClubsProvider>(context, listen: false);
    await provider.fetchClub(clubId);
    final club = provider.currentClub;
    if (club != null) {
      setState(() {
        _nameController.text = club.name;
        _addressController.text = club.address ?? '';
        _cityController.text = club.city ?? '';
        _countryController.text = club.country ?? '';
        _emailController.text = club.email ?? '';
        _phoneController.text = club.phone ?? '';
        _websiteController.text = club.website ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null || user.clubId == null) return;

    final clubData = {
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'country': _countryController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'website': _websiteController.text.trim(),
    };

    final provider = Provider.of<ClubsProvider>(context, listen: false);
    final success = await provider.updateClub(user.clubId!, clubData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Fiche club mise à jour !' : 'Erreur lors de la mise à jour'),
          backgroundColor: success ? OdinTheme.accentGreen : OdinTheme.accentRed,
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ClubsProvider>(context);
    final isLoading = provider.isLoading;

    return Scaffold(
      backgroundColor: OdinTheme.background,
      appBar: AppBar(
        title: const Text('Fiche Club', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('Informations Générales'),
              const SizedBox(height: 16),
              _field(
                controller: _nameController,
                label: 'Nom du Club',
                icon: Icons.shield_rounded,
                validator: (v) => v!.isEmpty ? 'Le nom est requis' : null,
              ),
              const SizedBox(height: 24),
              
              _sectionHeader('Localisation (Base de transport)'),
              const SizedBox(height: 8),
              const Text(
                'Ces informations sont utilisées pour calculer les itinéraires et les heures de départ du bus pour vos matchs à l\'extérieur.',
                style: TextStyle(color: OdinTheme.textTertiary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _field(
                controller: _addressController,
                label: 'Adresse du Stade/Siège',
                icon: Icons.location_on_rounded,
                validator: (v) => v!.isEmpty ? 'L\'adresse est requise' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _cityController,
                      label: 'Ville',
                      icon: Icons.location_city_rounded,
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: _countryController,
                      label: 'Pays',
                      icon: Icons.public_rounded,
                      validator: (v) => v!.length > 3 ? 'Code max 3 char' : (v.isEmpty ? 'Requis' : null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _sectionHeader('Contact'),
              const SizedBox(height: 16),
              _field(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _phoneController,
                label: 'Téléphone',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _websiteController,
                label: 'Site Web',
                icon: Icons.language_rounded,
                keyboardType: TextInputType.url,
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OdinTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ENREGISTRER LES MODIFICATIONS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: OdinTheme.primaryBlue,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(color: OdinTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: OdinTheme.textSecondary),
        prefixIcon: Icon(icon, color: OdinTheme.primaryBlue, size: 20),
        filled: true,
        fillColor: OdinTheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: OdinTheme.primaryBlue, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
