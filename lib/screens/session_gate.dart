import 'package:flutter/material.dart';

import '../services/energy_api_client.dart';
import '../services/session_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import 'dashboard_screen.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({
    required this.api,
    required this.sessionStorage,
    super.key,
  });

  final EnergyApiClient api;
  final SessionStorage sessionStorage;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  bool _isCheckingSession = true;
  String? _userName;
  String? _userEmail;
  String? _sessionError;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final token = await widget.sessionStorage.readToken();
      if (token == null) {
        if (!mounted) return;
        setState(() => _isCheckingSession = false);
        return;
      }
      widget.api.setToken(token);
      final session = await widget.api.verifySession(token);
      if (!mounted) return;
      setState(() {
        _userName = session.name;
        _userEmail = session.email;
        _isCheckingSession = false;
      });
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await widget.sessionStorage.clearToken();
        widget.api.setToken(null);
        if (!mounted) return;
        setState(() {
          _sessionError = 'Your session expired. Sign in again.';
          _isCheckingSession = false;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _sessionError = error.message;
        _isCheckingSession = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sessionError = 'Could not restore your session: $error';
        _isCheckingSession = false;
      });
    }
  }

  Future<void> _onAuthenticated(AuthSession session) async {
    try {
      await widget.sessionStorage.saveToken(session.token);
      widget.api.setToken(session.token);
      if (!mounted) return;
      setState(() {
        _userName = session.name;
        _userEmail = session.email;
        _sessionError = null;
      });
    } catch (error) {
      widget.api.setToken(null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not securely save your sign-in: $error')),
      );
    }
  }

  Future<void> _signOut() async {
    Object? signOutError;
    try {
      await widget.api.logout();
    } catch (error) {
      signOutError = error;
    }
    try {
      await widget.sessionStorage.clearToken();
    } catch (error) {
      signOutError ??= error;
    }
    widget.api.setToken(null);
    if (!mounted) return;
    setState(() {
      _userName = null;
      _userEmail = null;
      _sessionError = signOutError == null
          ? null
          : 'Signed out on this device; server sign-out failed: $signOutError';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userName = _userName;
    if (userName != null) {
      return DashboardScreen(
        api: widget.api,
        userName: userName,
        userEmail: _userEmail!,
        onLogout: _signOut,
      );
    }

    return SignInScreen(
      api: widget.api,
      message: _sessionError,
      onAuthenticated: _onAuthenticated,
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    required this.api,
    required this.onAuthenticated,
    this.message,
    super.key,
  });

  final EnergyApiClient api;
  final Future<void> Function(AuthSession) onAuthenticated;
  final String? message;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isRegistering = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.blue, AppColors.navy],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 23),
                  Text(
                    _isRegistering ? 'Create your account' : 'Welcome back',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _isRegistering
                        ? 'Create a secure account for your meter records.'
                        : 'Sign in to view your energy account.',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_isRegistering) ...[
                            TextFormField(
                              key: const Key('auth-name'),
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Enter your name.'
                                  : null,
                            ),
                            const SizedBox(height: 13),
                          ],
                          TextFormField(
                            key: const Key('auth-email'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (!email.contains('@') ||
                                  !email.split('@').last.contains('.')) {
                                return 'Enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 13),
                          TextFormField(
                            key: const Key('auth-password'),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) => (value?.length ?? 0) < 8
                                ? 'Use at least 8 characters.'
                                : null,
                          ),
                          if (_isRegistering) ...[
                            const SizedBox(height: 13),
                            TextFormField(
                              key: const Key('auth-confirm-password'),
                              controller: _confirmationController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon: Icon(Icons.lock_outline_rounded),
                              ),
                              validator: (value) =>
                                  value != _passwordController.text
                                  ? 'Passwords do not match.'
                                  : null,
                            ),
                          ],
                          if (_error != null || widget.message != null) ...[
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _error ?? widget.message!,
                                style: const TextStyle(
                                  color: Color(0xFFB42318),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isRegistering
                                          ? 'Create account'
                                          : 'Sign in',
                                    ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(() {
                                    _isRegistering = !_isRegistering;
                                    _error = null;
                                  }),
                            child: Text(
                              _isRegistering
                                  ? 'Already have an account? Sign in'
                                  : 'New to Smart Energy? Create account',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Your account data is stored in the Smart Energy database. Meter records and transfer entries are not connected to TANESCO.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final session = _isRegistering
          ? await widget.api.register(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              passwordConfirmation: _confirmationController.text,
            )
          : await widget.api.login(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      if (mounted) await widget.onAuthenticated(session);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Sign-in failed: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
