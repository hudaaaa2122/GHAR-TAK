import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_routes.dart';
import '../../core/network/api_response.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets.dart';
import '../providers.dart';

bool _isValidEmail(String value) {
  final email = value.trim();
  if (email.isEmpty) return false;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
}

InputDecoration _authFieldDecoration({
  required String hint,
  required bool hasError,
  Widget? suffixIcon,
  String? labelText,
}) {
  return InputDecoration(
    hintText: hint,
    labelText: labelText,
    suffixIcon: suffixIcon,
    // Non-null errorText triggers red error borders from theme (no inline text).
    errorText: hasError ? '' : null,
    errorStyle: const TextStyle(height: 0, fontSize: 0),
  );
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _emailError = false;
  bool _passwordError = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _forgotPassword() async {
    final emailCtrl = TextEditingController(text: _email.text.trim());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'you@example.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send code'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      showAppToast(context, 'Please enter your email');
      return;
    }
    if (!_isValidEmail(email)) {
      showAppToast(context, 'Please enter a valid email');
      return;
    }
    try {
      await ref.read(accountRepositoryProvider).forgotPassword(email);
      if (!mounted) return;
      showAppToast(
        context,
        'If the email exists, a reset code was sent',
        isError: false,
      );
      await _completePasswordReset(email);
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, e);
    }
  }

  /// Website ForgotPasswordModal → OtpVerifyModal → reset-password.
  Future<void> _completePasswordReset(String email) async {
    final codeCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter reset code'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'We sent a verification code to $email',
                style: AppFonts.style(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Verification code',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset password'),
          ),
        ],
      ),
    );
    if (submitted != true || !mounted) return;

    final code = codeCtrl.text.trim();
    final pass = passCtrl.text;
    final confirm = confirmCtrl.text;
    if (code.isEmpty || pass.isEmpty || confirm.isEmpty) {
      showAppToast(context, 'Fill in code and both password fields');
      return;
    }
    if (pass != confirm) {
      showAppToast(context, 'Passwords do not match');
      return;
    }
    if (pass.length < 6) {
      showAppToast(context, 'Password must be at least 6 characters');
      return;
    }

    try {
      final repo = ref.read(accountRepositoryProvider);
      await repo.verifyResetCode(email: email, code: code);
      await repo.resetPassword(
        email: email,
        code: code,
        newPassword: pass,
        confirmPassword: confirm,
      );
      if (!mounted) return;
      showAppToast(
        context,
        'Password updated. You can sign in now.',
        isError: false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, e);
    }
  }

  bool _validateLogin() {
    final email = _email.text.trim();
    final password = _password.text;
    var emailErr = false;
    var passwordErr = false;
    String? message;

    if (email.isEmpty && password.isEmpty) {
      emailErr = true;
      passwordErr = true;
      message = 'Please enter your email and password';
    } else if (email.isEmpty) {
      emailErr = true;
      message = 'Please enter your email';
    } else if (!_isValidEmail(email)) {
      emailErr = true;
      message = 'Please enter a valid email';
    } else if (password.isEmpty) {
      passwordErr = true;
      message = 'Please enter your password';
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = passwordErr;
    });

    if (message != null) {
      showAppToast(context, message);
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validateLogin()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier).login(
            _email.text.trim(),
            _password.text,
          );
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.home);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _emailError = true;
        _passwordError = true;
      });
      final msg = friendlyUserMessage(e);
      final lower = msg.toLowerCase();
      showAppToast(
        context,
        lower.contains('invalid') ||
                lower.contains('incorrect') ||
                lower.contains('credential') ||
                lower.contains('password') ||
                lower.contains('email')
            ? msg
            : 'Invalid email or password',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _emailError = false;
      _passwordError = false;
    });
    try {
      await ref.read(authStateProvider.notifier).loginWithGoogle();
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.home);
      });
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          BrandCurveHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GherTakLogo(
                  variant: GherTakLogoVariant.onDark,
                  compact: true,
                  height: 52,
                ),
                const Spacer(),
                Text(
                  'Welcome Back!',
                  style: AppFonts.style(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in to continue',
                  style: AppFonts.style(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              children: [
                Text(
                  'EMAIL',
                  style: AppFonts.style(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_emailError) setState(() => _emailError = false);
                  },
                  decoration: _authFieldDecoration(
                    hint: 'you@example.com',
                    hasError: _emailError,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'PASSWORD',
                  style: AppFonts.style(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  onChanged: (_) {
                    if (_passwordError) setState(() => _passwordError = false);
                  },
                  decoration: _authFieldDecoration(
                    hint: '••••••••',
                    hasError: _passwordError,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: AppFonts.style(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                BrandGradientButton(
                  label: _loading ? 'Signing in…' : 'Sign In',
                  onPressed: _loading ? null : _submit,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or sign in with',
                        style: AppFonts.style(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 16),
                GoogleSignInButton(
                  loading: _loading,
                  onPressed: _googleSignIn,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New to Gher Tak? ',
                      style: AppFonts.style(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.register),
                      child: Text(
                        'Register Now!',
                        style: AppFonts.style(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
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
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _nameError = false;
  bool _emailError = false;
  bool _phoneError = false;
  bool _passwordError = false;
  bool _confirmError = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _validateRegister() {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    final password = _password.text;
    final confirm = _confirm.text;

    var nameErr = false;
    var emailErr = false;
    var phoneErr = false;
    var passwordErr = false;
    var confirmErr = false;
    String? message;

    if (name.isEmpty) {
      nameErr = true;
      message ??= 'Please enter your full name';
    }
    if (phone.isEmpty) {
      phoneErr = true;
      message ??= 'Please enter your phone number';
    }
    if (email.isEmpty) {
      emailErr = true;
      message ??= 'Please enter your email';
    } else if (!_isValidEmail(email)) {
      emailErr = true;
      message ??= 'Please enter a valid email';
    }
    if (password.isEmpty) {
      passwordErr = true;
      message ??= 'Please enter a password';
    } else if (password.length < 6) {
      passwordErr = true;
      message ??= 'Password must be at least 6 characters';
    }
    if (confirm.isEmpty) {
      confirmErr = true;
      message ??= 'Please confirm your password';
    } else if (password != confirm) {
      passwordErr = true;
      confirmErr = true;
      message ??= 'Passwords do not match';
    }

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _phoneError = phoneErr;
      _passwordError = passwordErr;
      _confirmError = confirmErr;
    });

    if (message != null) {
      showAppToast(context, message);
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validateRegister()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).register(
            name: _name.text.trim(),
            email: _email.text.trim(),
            phoneNo: _phone.text.trim(),
            password: _password.text,
            confirmPassword: _confirm.text,
          );
      if (mounted) {
        context.push(AppRoutes.verify, extra: _email.text.trim());
      }
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier).loginWithGoogle();
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.home);
      });
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _label(String text) {
    return Text(
      text.toUpperCase(),
      style: AppFonts.style(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          BrandCurveHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GherTakLogo(
                  variant: GherTakLogoVariant.onDark,
                  compact: true,
                  height: 52,
                ),
                const Spacer(),
                Text(
                  'Create Account',
                  style: AppFonts.style(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fast shopping starts here',
                  style: AppFonts.style(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              children: [
                _label('Full Name'),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  onChanged: (_) {
                    if (_nameError) setState(() => _nameError = false);
                  },
                  decoration: _authFieldDecoration(
                    hint: 'Ahmed Ali',
                    hasError: _nameError,
                  ),
                ),
                const SizedBox(height: 16),
                _label('Phone Number'),
                const SizedBox(height: 8),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) {
                    if (_phoneError) setState(() => _phoneError = false);
                  },
                  decoration: _authFieldDecoration(
                    hint: '+92 3XX XXXXXXX',
                    hasError: _phoneError,
                  ),
                ),
                const SizedBox(height: 16),
                _label('Email Address'),
                const SizedBox(height: 8),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_emailError) setState(() => _emailError = false);
                  },
                  decoration: _authFieldDecoration(
                    hint: 'you@example.com',
                    hasError: _emailError,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Password'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _password,
                            obscureText: true,
                            onChanged: (_) {
                              if (_passwordError) {
                                setState(() => _passwordError = false);
                              }
                            },
                            decoration: _authFieldDecoration(
                              hint: '••••••••',
                              hasError: _passwordError,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Confirm'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _confirm,
                            obscureText: true,
                            onChanged: (_) {
                              if (_confirmError) {
                                setState(() => _confirmError = false);
                              }
                            },
                            decoration: _authFieldDecoration(
                              hint: '••••••••',
                              hasError: _confirmError,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    style: AppFonts.style(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text: 'By creating an account you agree to our ',
                      ),
                      TextSpan(
                        text: 'Terms',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.push(AppRoutes.terms),
                      ),
                      const TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: AppFonts.style(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.push(AppRoutes.privacy),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                BrandGradientButton(
                  label: _loading ? 'Please wait…' : 'Create Account',
                  onPressed: _loading ? null : _submit,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or continue with',
                        style: AppFonts.style(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 16),
                GoogleSignInButton(
                  loading: _loading,
                  onPressed: _googleSignIn,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already registered? ',
                      style: AppFonts.style(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.login),
                      child: Text(
                        'Sign In',
                        style: AppFonts.style(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
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
}

class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  bool _codeError = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _codeError = true);
      showAppToast(context, 'Please enter the verification code');
      return;
    }
    setState(() {
      _loading = true;
      _codeError = false;
    });
    try {
      final user = await ref.read(authRepositoryProvider).verifyRegistration(
            email: widget.email,
            code: code,
          );
      ref.read(authStateProvider.notifier).setUser(user);
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      setState(() => _codeError = true);
      showAppToast(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Enter the verification code sent to ${widget.email}',
            style: AppFonts.style(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              if (_codeError) setState(() => _codeError = false);
            },
            decoration: _authFieldDecoration(
              hint: 'Verification code',
              labelText: 'Verification code',
              hasError: _codeError,
            ),
          ),
          const SizedBox(height: 20),
          BrandGradientButton(
            label: _loading ? 'Verifying…' : 'Verify & continue',
            onPressed: _loading ? null : _submit,
          ),
        ],
      ),
    );
  }
}
