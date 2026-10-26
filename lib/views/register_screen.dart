import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/api_client.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _api = ApiClient();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final email = _email.text.trim();
    try {
      await _api.register(
        email: email,
        password: _password.text,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
      );
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => VerifyEmailScreen(email: email),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = _api.errorMessage(error);
      final isDuplicateEmail =
          message.toLowerCase().contains('email') &&
          [
            'already',
            'exist',
            'registered',
            'taken',
          ].any(message.toLowerCase().contains);
      if (_api.statusCode(error) == 500 || isDuplicateEmail) {
        await _showAccountRecovery(email, message, isDuplicateEmail);
      } else {
        _showMessage(message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAccountRecovery(
    String email,
    String apiMessage,
    bool isDuplicateEmail,
  ) async {
    final shouldVerify = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isDuplicateEmail ? 'Email already registered' : 'Check your email',
        ),
        content: Text(
          isDuplicateEmail
              ? '$apiMessage\n\nIf this account is not verified yet, you can request a new verification code.'
              : 'The server returned an error, but your account may have been created. Try verifying $email or request a fresh code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('LATER'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('VERIFY EMAIL'),
          ),
        ],
      ),
    );
    if (shouldVerify != true || !mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => VerifyEmailScreen(email: email)),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F7),
        surfaceTintColor: Colors.transparent,
        title: const Text('Create account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 34.sp,
                      color: const Color(0xFF7B5D36),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Join AURA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Create your account to save your favorites and shop.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF77716C),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstName,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.givenName],
                            decoration: _registerDecoration('First name'),
                            validator: _required,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: TextFormField(
                            controller: _lastName,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.familyName],
                            decoration: _registerDecoration('Last name'),
                            validator: _required,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: _registerDecoration('Email address'),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty || !email.contains('@')) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: _registerDecoration('Password').copyWith(
                        suffixIcon: IconButton(
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
                      validator: (value) {
                        if ((value?.length ?? 0) < 8) {
                          return 'Use at least 8 characters.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    TextFormField(
                      controller: _confirmPassword,
                      obscureText: _obscureConfirmation,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _createAccount(),
                      decoration: _registerDecoration('Confirm password')
                          .copyWith(
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscureConfirmation =
                                    !_obscureConfirmation,
                              ),
                              icon: Icon(
                                _obscureConfirmation
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                      validator: (value) => value != _password.text
                          ? 'Passwords do not match.'
                          : null,
                    ),
                    SizedBox(height: 22.h),
                    SizedBox(
                      height: 52.h,
                      child: FilledButton(
                        onPressed: _loading ? null : _createAccount,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF171719),
                          foregroundColor: Colors.white,
                        ),
                        child: _loading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('CREATE ACCOUNT'),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => const LoginScreen(),
                              ),
                            ),
                      child: const Text('Already have an account? Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class ResendVerificationScreen extends StatefulWidget {
  const ResendVerificationScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ResendVerificationScreen> createState() =>
      _ResendVerificationScreenState();
}

class _ResendVerificationScreenState extends State<ResendVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _api = ApiClient();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _email.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final email = _email.text.trim();
    try {
      await _api.resendOtp(email);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => VerifyEmailScreen(email: email),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_api.errorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAF9F7),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFAF9F7),
      surfaceTintColor: Colors.transparent,
      title: const Text('Verify your email'),
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 44.sp,
                    color: const Color(0xFF7B5D36),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    'Get a new verification code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Enter the email you used to register. We will send a new code if the account needs verification.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF77716C),
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    onFieldSubmitted: (_) => _sendCode(),
                    decoration: _registerDecoration('Email address'),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty || !email.contains('@')) {
                        return 'Enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 18.h),
                  SizedBox(
                    height: 52.h,
                    child: FilledButton(
                      onPressed: _loading ? null : _sendCode,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF171719),
                        foregroundColor: Colors.white,
                      ),
                      child: _loading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('SEND VERIFICATION CODE'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  final _api = ApiClient();
  bool _loading = false;
  bool _resending = false;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _api.verifyEmail(widget.email, _otp.text.trim());
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          builder: (_) => LoginScreen(initialEmail: widget.email),
        ),
        (route) => route.isFirst,
      );
    } catch (error) {
      if (mounted) _showMessage(_api.errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _resending = true);
    try {
      await _api.resendOtp(widget.email);
      if (mounted) _showMessage('A new verification code was sent.');
    } catch (error) {
      if (mounted) _showMessage(_api.errorMessage(error));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F7),
        surfaceTintColor: Colors.transparent,
        title: const Text('Verify your email'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.mark_email_read_outlined,
                      size: 44.sp,
                      color: const Color(0xFF7B5D36),
                    ),
                    SizedBox(height: 18.h),
                    Text(
                      'Check your inbox',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Enter the verification code sent to ${widget.email}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF77716C),
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    TextFormField(
                      controller: _otp,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onFieldSubmitted: (_) => _verify(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22.sp,
                        letterSpacing: 8,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _registerDecoration('Verification code'),
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Enter the code from your email.'
                          : null,
                    ),
                    SizedBox(height: 18.h),
                    SizedBox(
                      height: 52.h,
                      child: FilledButton(
                        onPressed: _loading ? null : _verify,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF171719),
                          foregroundColor: Colors.white,
                        ),
                        child: _loading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('VERIFY EMAIL'),
                      ),
                    ),
                    TextButton(
                      onPressed: _resending ? null : _resendCode,
                      child: Text(
                        _resending ? 'Sending…' : 'Resend verification code',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _required(String? value) =>
    (value?.trim().isEmpty ?? true) ? 'This field is required.' : null;

InputDecoration _registerDecoration(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12.r),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12.r),
    borderSide: const BorderSide(color: Color(0xFFE9E4DE)),
  ),
);
