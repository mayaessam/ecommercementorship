import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/api_client.dart';
import '../viewmodels/home_cubit.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = ApiClient();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _api.login(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      context.read<HomeCubit>().selectTab(0);
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _showMessage(_api.errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
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
        title: const Text('Sign in'),
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
                    const _AuthBrand(),
                    SizedBox(height: 28.h),
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 27.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF171719),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Sign in to continue to your AURA account.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF77716C),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      decoration: _inputDecoration(
                        'Email address',
                        Icons.email_outlined,
                      ),
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
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _signIn(),
                      decoration:
                          _inputDecoration(
                            'Password',
                            Icons.lock_outline,
                          ).copyWith(
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
                      validator: (value) => (value?.isEmpty ?? true)
                          ? 'Enter your password.'
                          : null,
                    ),
                    SizedBox(height: 22.h),
                    SizedBox(
                      height: 52.h,
                      child: FilledButton(
                        onPressed: _loading ? null : _signIn,
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
                            : const Text('SIGN IN'),
                      ),
                    ),
                    SizedBox(height: 18.h),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ResendVerificationScreen(
                                  initialEmail: _emailController.text.trim(),
                                ),
                              ),
                            ),
                      child: const Text("Didn't receive a verification code?"),
                    ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('New to AURA? '),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => Navigator.of(context).pushReplacement(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                ),
                          child: const Text('Create an account'),
                        ),
                      ],
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

class _AuthBrand extends StatelessWidget {
  const _AuthBrand();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.auto_awesome, size: 19.sp, color: const Color(0xFF7B5D36)),
      SizedBox(width: 8.w),
      Text(
        'AURA',
        style: TextStyle(
          letterSpacing: 2,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

InputDecoration _inputDecoration(String label, IconData icon) =>
    InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
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
