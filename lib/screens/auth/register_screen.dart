import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/jihc_logo.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.member;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = ref.read(authServiceProvider);
      final firestore = ref.read(firestoreServiceProvider);
      final credential = await auth.registerWithEmail(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (credential.user != null) {
        await firestore.syncUser(
          credential.user!,
          fullName: _nameController.text.trim(),
          studentId: _studentIdController.text.trim(),
          role: _role,
        );
      }
      if (mounted) context.go('/home');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = MediaQuery.sizeOf(context).shortestSide.clamp(72.0, 104.0);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: JihcLogo(size: logoSize)),
                    const SizedBox(height: 20),
                    Text(
                      'Create your account',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Register with your name, email, and password.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Enter your name.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          (value == null || !value.contains('@'))
                          ? 'Enter a valid email.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _studentIdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Student ID',
                      ),
                      validator: (value) =>
                          (value == null || value.trim().length < 6)
                          ? 'Enter a valid student ID.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (value) => (value == null || value.length < 6)
                          ? 'Use at least 6 characters.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<UserRole>(
                      segments: const [
                        ButtonSegment<UserRole>(
                          value: UserRole.member,
                          label: Text('Member'),
                        ),
                        ButtonSegment<UserRole>(
                          value: UserRole.head,
                          label: Text('Head'),
                        ),
                      ],
                      selected: {_role},
                      onSelectionChanged: (selection) =>
                          setState(() => _role = selection.first),
                    ),
                    const SizedBox(height: 20),
                    GoldButton(
                      label: 'Register',
                      onPressed: _submit,
                      isLoading: _loading,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/auth/login'),
                      child: const Text('Already have an account? Login'),
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
