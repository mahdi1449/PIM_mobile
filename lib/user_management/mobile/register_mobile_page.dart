import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/user_management_api.dart';
import '../models/user_management_models.dart';

class RegisterMobilePage extends StatefulWidget {
  const RegisterMobilePage({
    super.key,
    required this.api,
    required this.onShowLogin,
  });

  final UserManagementApi api;
  final VoidCallback onShowLogin;

  @override
  State<RegisterMobilePage> createState() => _RegisterMobilePageState();
}

class _RegisterMobilePageState extends State<RegisterMobilePage> {
  final ImagePicker _imagePicker = ImagePicker();

  bool _responsableMode = true;
  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  List<ClubModel> _activeClubs = [];
  String? _error;
  String? _pickedPhotoDataUrl;
  Uint8List? _pickedPhotoBytes;

  final _clubName = TextEditingController();
  final _league = TextEditingController();
  final _country = TextEditingController();
  final _city = TextEditingController();
  final _logo = TextEditingController();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  String _role = 'JOUEUR';
  String? _clubId;
  String? _position;
  String? _jobTitle;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadActiveClubs();
  }

  @override
  void dispose() {
    _clubName.dispose();
    _league.dispose();
    _country.dispose();
    _city.dispose();
    _logo.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _loadActiveClubs() async {
    try {
      final clubs = await widget.api.getActiveClubs();
      if (mounted) {
        setState(() {
          _activeClubs = clubs;
          if (clubs.isNotEmpty) {
            _clubId = clubs.first.id;
          }
        });
      }
    } catch (_) {
      // Keep register open even when club list fails initially.
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 55,
        maxWidth: 720,
      );

      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();
      final mime = _detectMimeType(file.name);
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

      setState(() {
        _pickedPhotoBytes = bytes;
        _pickedPhotoDataUrl = dataUrl;
        _error = null;
      });
    } catch (_) {
      setState(() => _error = 'Impossible de selectionner la photo.');
    }
  }

  String _detectMimeType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_pickedPhotoDataUrl == null) {
      setState(() => _error = 'Photo de profil requise.');
      return;
    }

    if (_password.text != _confirmPassword.text) {
      setState(
        () => _error = 'La confirmation du mot de passe ne correspond pas.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_responsableMode) {
        await widget.api.registerResponsable({
          'clubName': _clubName.text.trim(),
          'league': _league.text.trim(),
          'country': _country.text.trim(),
          'city': _city.text.trim(),
          'logoUrl': _logo.text.trim(),
          'photoUrl': _pickedPhotoDataUrl,
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'phone': _phone.text.trim(),
          'email': _email.text.trim(),
          'password': _password.text,
        });
      } else {
        await widget.api.registerMember({
          'photoUrl': _pickedPhotoDataUrl,
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'phone': _phone.text.trim(),
          'email': _email.text.trim(),
          'password': _password.text,
          'role': _role,
          'clubId': _clubId,
          if (_role == 'JOUEUR') 'position': _position,
          if (_role == 'STAFF_TECHNIQUE' || _role == 'STAFF_MEDICAL')
            'jobTitle': _jobTitle,
        });
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _responsableMode
                ? 'Inscription envoyee. Attendez la validation admin.'
                : 'Inscription envoyee. Attendez la validation du responsable club.',
          ),
        ),
      );

      widget.onShowLogin();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = dark ? const Color(0xFFA2B8E7) : const Color(0xFF6A769A);
    final borderColor = dark
        ? const Color(0x6688A7E1)
        : const Color(0xFFCCD7EF);
    final focusColor = dark ? const Color(0xFF5A8FFF) : const Color(0xFF1D7BEA);

    return InputDecoration(
      hintText: hint,
      labelText: hint,
      labelStyle: TextStyle(color: hintColor),
      hintStyle: TextStyle(color: hintColor),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: focusColor, width: 1.4),
      ),
    );
  }

  DropdownButtonFormField<String> _dropdownField({
    required BuildContext context,
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? Colors.white : const Color(0xFF0B1F3B);

    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: dark ? const Color(0xFF173A97) : Colors.white,
      style: TextStyle(color: foreground),
      items: options
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: _inputDecoration(context, label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : const Color(0xFF0B1F3B);
    final muted = dark ? const Color(0xFFA2B8E7) : const Color(0xFF6A769A);
    final softBorder = dark ? const Color(0x556D90CF) : const Color(0xFFBFCBEA);
    final action = dark ? const Color(0xFF4E83FF) : const Color(0xFF1D7BEA);
    final primaryButton = dark
        ? const Color(0xFF3D66E0)
        : const Color(0xFF1D7BEA);
    final panelBg = dark ? const Color(0x1AFFFFFF) : Colors.white;
    final errorText = dark ? const Color(0xFFFF9FA6) : const Color(0xFFD64545);
    final gradientColors = dark
        ? const [Color(0xFF173A97), Color(0xFF0D1F70), Color(0xFF061754)]
        : const [Color(0xFFF9FBFF), Color(0xFFF1F6FF), Color(0xFFEAF3FF)];

    const positionOptions = ['GK', 'CB', 'CM', 'ST', 'RW', 'LW'];
    const techOptions = ['Coach', 'Head Coach', 'Analyst', 'Prep Physique'];
    const medOptions = ['Docteur', 'Kine', 'Physiotherapeute'];
    const roleOptions = [
      'JOUEUR',
      'STAFF_TECHNIQUE',
      'STAFF_MEDICAL',
      'FINANCIER',
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -40,
              right: -40,
              child: Transform.rotate(
                angle: -0.35,
                child: Container(
                  height: 240,
                  color: dark
                      ? const Color(0x222E58BF)
                      : const Color(0x22BFD2F6),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: -80,
              right: -80,
              child: Transform.rotate(
                angle: -0.35,
                child: Container(
                  height: 120,
                  color: dark
                      ? const Color(0x223E6BE8)
                      : const Color(0x2292B4F7),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const SizedBox(height: 26),
                      Text(
                        'Register',
                        style: TextStyle(
                          color: fg,
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            dark ? const Color(0x221E3D96) : Colors.white,
                          ),
                          foregroundColor: WidgetStatePropertyAll(
                            dark
                                ? const Color(0xFFD2E0FF)
                                : const Color(0xFF3C4B72),
                          ),
                          side: WidgetStatePropertyAll(
                            BorderSide(color: softBorder),
                          ),
                        ),
                        segments: const [
                          ButtonSegment(
                            value: true,
                            label: Text('Responsable Club'),
                          ),
                          ButtonSegment(
                            value: false,
                            label: Text('Autre role'),
                          ),
                        ],
                        selected: {_responsableMode},
                        onSelectionChanged: (set) {
                          setState(() => _responsableMode = set.first);
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: panelBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: softBorder),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 34,
                              backgroundColor: dark
                                  ? const Color(0xFF244CBA)
                                  : const Color(0xFF7CA4F0),
                              backgroundImage: _pickedPhotoBytes != null
                                  ? MemoryImage(_pickedPhotoBytes!)
                                  : null,
                              child: _pickedPhotoBytes == null
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 34,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Photo de profil',
                                    style: TextStyle(
                                      color: fg,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Obligatoire pour inscription',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      OutlinedButton(
                                        onPressed: _pickPhoto,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: fg,
                                          side: BorderSide(color: softBorder),
                                        ),
                                        child: const Text('Choose image'),
                                      ),
                                      if (_pickedPhotoDataUrl != null)
                                        TextButton(
                                          onPressed: () => setState(() {
                                            _pickedPhotoDataUrl = null;
                                            _pickedPhotoBytes = null;
                                          }),
                                          child: Text(
                                            'Remove',
                                            style: TextStyle(color: action),
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
                      if (_responsableMode) ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _clubName,
                          style: TextStyle(color: fg),
                          decoration: _inputDecoration(context, 'Nom du club'),
                          validator: (v) => _requiredField(v, 'Nom du club'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _league,
                          style: TextStyle(color: fg),
                          decoration: _inputDecoration(context, 'Ligue'),
                          validator: (v) => _requiredField(v, 'Ligue'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _country,
                          style: TextStyle(color: fg),
                          decoration: _inputDecoration(
                            context,
                            'Pays (optionnel)',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _city,
                          style: TextStyle(color: fg),
                          decoration: _inputDecoration(
                            context,
                            'Ville (optionnel)',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _logo,
                          style: TextStyle(color: fg),
                          decoration: _inputDecoration(
                            context,
                            'Logo URL (optionnel)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          color: dark
                              ? const Color(0x335A82CB)
                              : const Color(0xFFCDD8EE),
                        ),
                      ],
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _firstName,
                        style: TextStyle(color: fg),
                        decoration: _inputDecoration(context, 'Nom'),
                        validator: (v) => _requiredField(v, 'Nom'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _lastName,
                        style: TextStyle(color: fg),
                        decoration: _inputDecoration(context, 'Prenom'),
                        validator: (v) => _requiredField(v, 'Prenom'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phone,
                        style: TextStyle(color: fg),
                        decoration: _inputDecoration(context, 'Telephone'),
                        validator: (v) => _requiredField(v, 'Telephone'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: fg),
                        decoration: _inputDecoration(context, 'Email'),
                        validator: (v) {
                          if (v == null || !v.contains('@')) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _password,
                        obscureText: _hidePassword,
                        style: TextStyle(color: fg),
                        decoration: _inputDecoration(context, 'Password')
                            .copyWith(
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _hidePassword = !_hidePassword,
                                ),
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: muted,
                                  size: 20,
                                ),
                              ),
                            ),
                        validator: (v) {
                          if (v == null || v.length < 8) {
                            return 'Minimum 8 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _confirmPassword,
                        obscureText: _hideConfirmPassword,
                        style: TextStyle(color: fg),
                        decoration:
                            _inputDecoration(
                              context,
                              'Confirm Password',
                            ).copyWith(
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _hideConfirmPassword =
                                      !_hideConfirmPassword,
                                ),
                                icon: Icon(
                                  _hideConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: muted,
                                  size: 20,
                                ),
                              ),
                            ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Confirmez le mot de passe';
                          }
                          return null;
                        },
                      ),
                      if (!_responsableMode) ...[
                        const SizedBox(height: 10),
                        _dropdownField(
                          context: context,
                          label: 'Role',
                          value: _role,
                          options: roleOptions,
                          onChanged: (value) => setState(() {
                            _role = value ?? _role;
                            _position = null;
                            _jobTitle = null;
                          }),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _clubId,
                          dropdownColor: dark
                              ? const Color(0xFF173A97)
                              : Colors.white,
                          style: TextStyle(color: fg),
                          items: _activeClubs
                              .map(
                                (club) => DropdownMenuItem(
                                  value: club.id,
                                  child: Text('${club.name} (${club.league})'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => _clubId = value),
                          decoration: _inputDecoration(context, 'Club'),
                          validator: (v) => _requiredField(v, 'Club'),
                        ),
                        if (_role == 'JOUEUR') ...[
                          const SizedBox(height: 10),
                          _dropdownField(
                            context: context,
                            label: 'Position de jeu',
                            value: _position,
                            options: positionOptions,
                            onChanged: (value) =>
                                setState(() => _position = value),
                            validator: (v) => _requiredField(v, 'Position'),
                          ),
                        ],
                        if (_role == 'STAFF_TECHNIQUE') ...[
                          const SizedBox(height: 10),
                          _dropdownField(
                            context: context,
                            label: 'Poste technique',
                            value: _jobTitle,
                            options: techOptions,
                            onChanged: (value) =>
                                setState(() => _jobTitle = value),
                            validator: (v) =>
                                _requiredField(v, 'Poste technique'),
                          ),
                        ],
                        if (_role == 'STAFF_MEDICAL') ...[
                          const SizedBox(height: 10),
                          _dropdownField(
                            context: context,
                            label: 'Poste medical',
                            value: _jobTitle,
                            options: medOptions,
                            onChanged: (value) =>
                                setState(() => _jobTitle = value),
                            validator: (v) =>
                                _requiredField(v, 'Poste medical'),
                          ),
                        ],
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!, style: TextStyle(color: errorText)),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryButton,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(_loading ? 'Envoi...' : 'Register'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Existing user? ',
                            style: TextStyle(color: muted),
                          ),
                          GestureDetector(
                            onTap: widget.onShowLogin,
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: action,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName requis';
    }
    return null;
  }
}
