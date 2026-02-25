// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth.dart';
import 'patient_list_screen.dart';
import 'signup_screen.dart';
import '../ui/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  bool _rememberMe = false;
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    // run after first frame so Provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _attemptAutoLogin());
  }

  Future<void> _attemptAutoLogin() async {
    final auth = Provider.of<AuthService>(context, listen: false);

    try {
      final autoLogged = await auth.tryAutoLogin();
      if (autoLogged) {
        // already remembered — go straight to patients
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientListScreen()));
        }
        return;
      }

      // load persisted remember flag to set checkbox initial state (optional)
      final persisted = await auth.persistedRememberMe();
      setState(() {
        _rememberMe = persisted;
        _checkingAuth = false;
      });
    } catch (e) {
      // if something goes wrong just stop checking and show login
      setState(() {
        _checkingAuth = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final auth = Provider.of<AuthService>(context, listen: false);

    try {
      final ok = await auth.login(email: email, password: password, rememberMe: _rememberMe);

      setState(() => _loading = false);
      if (ok) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientListScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid email or password')));
      }
    } catch (e, st) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      // ignore: avoid_print
      print('Login error: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    // show loader while checking auto-login so UI doesn't flash
    if (_checkingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final mq = MediaQuery.of(context);
    final maxW = mq.size.width > 700 ? 500.0 : mq.size.width * 0.92;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Image.asset(
                          'assets/images/logos.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('Patient Manager', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Sign in to manage your patients', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: AppTheme.inputDecoration(label: 'Email', icon: Icons.email),
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Email is required';
                                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              decoration: AppTheme.inputDecoration(
                                label: 'Password',
                                icon: Icons.lock,
                                suffix: IconButton(
                                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _showPassword = !_showPassword),
                                ),
                              ),
                              obscureText: !_showPassword,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Password is required';
                                if (v.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Checkbox(value: _rememberMe, onChanged: (v) => setState(() => _rememberMe = v ?? false)),
                                const SizedBox(width: 6),
                                const Text('Remember me'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: _loading ? null : _submit,
                                icon: _loading
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.login),
                                label: Text(_loading ? 'Signing in...' : 'Sign In', style: const TextStyle(color: Colors.white)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Don\'t have an account?'),
                                TextButton(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                                  child: const Text('Sign up'),
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
            ),
          ),
        ),
      ),
    );
  }
}
