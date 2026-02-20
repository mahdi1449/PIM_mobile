import 'package:flutter/material.dart';

import '../api/user_management_api.dart';
import '../models/user_management_models.dart';

class LoginMobilePage extends StatefulWidget {
  const LoginMobilePage({
    super.key,
    required this.api,
    required this.onSession,
    required this.onShowRegister,
  });

  final UserManagementApi api;
  final void Function(SessionModel session) onSession;
  final VoidCallback onShowRegister;

  @override
  State<LoginMobilePage> createState() => _LoginMobilePageState();
}

class _LoginMobilePageState extends State<LoginMobilePage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _rememberMe = true;
  bool _loading = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = await widget.api.login(
        _email.text.trim(),
        _password.text,
      );
      widget.onSession(session);
    } catch (error) {
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _email.text.trim());
    final codeController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    var codeRequested = false;
    var loading = false;
    String? localError;

    await showDialog<void>(
      context: context,
      builder: (context) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final dialogBg = dark ? const Color(0xFF0F2A86) : Colors.white;
        final textColor = dark ? Colors.white : const Color(0xFF0B1F3B);
        final errorColor = dark
            ? const Color(0xFFFFA5AB)
            : const Color(0xFFD64545);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> requestCode() async {
              final email = emailController.text.trim();
              if (!email.contains('@')) {
                setDialogState(() => localError = 'Email invalide.');
                return;
              }

              setDialogState(() {
                loading = true;
                localError = null;
              });

              try {
                await widget.api.requestForgotPassword(email);
                setDialogState(() {
                  codeRequested = true;
                  loading = false;
                });
              } catch (error) {
                setDialogState(() {
                  loading = false;
                  localError = error.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            Future<void> resetPassword() async {
              final email = emailController.text.trim();
              if (!email.contains('@')) {
                setDialogState(() => localError = 'Email invalide.');
                return;
              }

              if (codeController.text.trim().length != 6) {
                setDialogState(
                  () => localError = 'Le code OTP doit contenir 6 chiffres.',
                );
                return;
              }

              if (newPasswordController.text.length < 8) {
                setDialogState(
                  () => localError =
                      'Le mot de passe doit contenir au moins 8 caracteres.',
                );
                return;
              }

              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                setDialogState(
                  () => localError =
                      'La confirmation du mot de passe ne correspond pas.',
                );
                return;
              }

              setDialogState(() {
                loading = true;
                localError = null;
              });

              try {
                await widget.api.resetForgotPassword(
                  email: email,
                  code: codeController.text.trim(),
                  newPassword: newPasswordController.text,
                );

                if (!mounted) {
                  return;
                }

                Navigator.of(this.context).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Mot de passe reinitialise avec succes.'),
                  ),
                );
              } catch (error) {
                setDialogState(() {
                  loading = false;
                  localError = error.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            return AlertDialog(
              backgroundColor: dialogBg,
              title: Text(
                'Forgot password',
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: textColor),
                      decoration: _inputDecoration(context, 'Email'),
                    ),
                    const SizedBox(height: 12),
                    if (codeRequested) ...[
                      TextField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor),
                        decoration: _inputDecoration(
                          context,
                          'Code OTP (6 chiffres)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: newPasswordController,
                        obscureText: true,
                        style: TextStyle(color: textColor),
                        decoration: _inputDecoration(
                          context,
                          'Nouveau mot de passe',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        style: TextStyle(color: textColor),
                        decoration: _inputDecoration(
                          context,
                          'Confirmer mot de passe',
                        ),
                      ),
                    ],
                    if (localError != null) ...[
                      const SizedBox(height: 12),
                      Text(localError!, style: TextStyle(color: errorColor)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Fermer',
                    style: TextStyle(
                      color: dark
                          ? const Color(0xFFD4E1FF)
                          : const Color(0xFF1D7BEA),
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: loading
                      ? null
                      : (codeRequested ? resetPassword : requestCode),
                  style: FilledButton.styleFrom(
                    backgroundColor: dark
                        ? const Color(0xFF3E66E1)
                        : const Color(0xFF1D7BEA),
                  ),
                  child: Text(
                    loading
                        ? 'En cours...'
                        : (codeRequested ? 'Reset password' : 'Envoyer code'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
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
      hintStyle: TextStyle(color: hintColor),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: focusColor, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : const Color(0xFF0B1F3B);
    final muted = dark ? const Color(0xFF9CB2E3) : const Color(0xFF6A769A);
    final softBorder = dark ? const Color(0x335A82CB) : const Color(0xFFCDD8EE);
    final action = dark ? const Color(0xFF4E83FF) : const Color(0xFF1D7BEA);
    final primaryButton = dark
        ? const Color(0xFF3D66E0)
        : const Color(0xFF1D7BEA);
    final errorText = dark ? const Color(0xFFFF9FA6) : const Color(0xFFD64545);
    final gradientColors = dark
        ? const [Color(0xFF173A97), Color(0xFF0D1F70), Color(0xFF061754)]
        : const [Color(0xFFF9FBFF), Color(0xFFF1F6FF), Color(0xFFEAF3FF)];

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
                        'Login',
                        style: TextStyle(
                          color: fg,
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 42),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: fg),
                        decoration: _inputDecoration(context, 'Email'),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Email invalide'
                            : null,
                      ),
                      const SizedBox(height: 18),
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
                              suffix: GestureDetector(
                                onTap: _openForgotPasswordDialog,
                                child: Text(
                                  'Forgot?',
                                  style: TextStyle(color: action, fontSize: 14),
                                ),
                              ),
                            ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Mot de passe invalide'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) =>
                                  setState(() => _rememberMe = value ?? true),
                              side: BorderSide(
                                color: dark
                                    ? const Color(0xFF7EA2EA)
                                    : const Color(0xFF94A7D9),
                              ),
                              fillColor: WidgetStatePropertyAll(primaryButton),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Remember me', style: TextStyle(color: muted)),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!, style: TextStyle(color: errorText)),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _loading ? null : _login,
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryButton,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(_loading ? 'Loading...' : 'Login'),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(child: Divider(color: softBorder)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('OR', style: TextStyle(color: muted)),
                          ),
                          Expanded(child: Divider(color: softBorder)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: null,
                              icon: const Text(
                                'f',
                                style: TextStyle(
                                  color: Color(0xFF9CB2E3),
                                  fontSize: 18,
                                ),
                              ),
                              label: const Text('Facebook'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: fg,
                                disabledForegroundColor: fg,
                                side: BorderSide(
                                  color: dark
                                      ? const Color(0x556D90CF)
                                      : const Color(0xFFB8C6E8),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: null,
                              icon: const Text(
                                'G',
                                style: TextStyle(
                                  color: Color(0xFF9CB2E3),
                                  fontSize: 16,
                                ),
                              ),
                              label: const Text('Google'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: fg,
                                disabledForegroundColor: fg,
                                side: BorderSide(
                                  color: dark
                                      ? const Color(0x556D90CF)
                                      : const Color(0xFFB8C6E8),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('New user? ', style: TextStyle(color: muted)),
                          GestureDetector(
                            onTap: widget.onShowRegister,
                            child: Text(
                              'Register',
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
}
