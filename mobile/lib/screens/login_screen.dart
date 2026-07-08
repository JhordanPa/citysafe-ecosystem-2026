import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/api_service.dart';
import '../widgets/auth/auth_animated_background.dart';
import '../widgets/auth/auth_logo.dart';
import '../widgets/auth/login_form_widget.dart';
import '../widgets/auth/role_selection.dart';
import '../widgets/common/custom_popups.dart';
import 'gestor_home_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _selectedRole;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      CustomPopups.showError(
        context: context,
        title: 'Campos vacíos',
        message: 'Por favor, ingresa tus credenciales.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ApiService().login(username, password);
      if (success) {
        if (!mounted) return;

        final userRole = ApiService().role;

        if (_selectedRole != null && userRole != _selectedRole) {
          CustomPopups.showError(
            context: context,
            title: 'Acceso denegado',
            message: 'No tienes permisos de $_selectedRole.',
          );
          await ApiService().logout();
          return;
        }

        CustomPopups.showWelcome(
          context: context,
          title: '¡Bienvenido!',
          message: 'Has iniciado sesión correctamente.',
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;

        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (userRole == 'gestor') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const GestorHomeScreen()),
            (Route<dynamic> route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        if (!mounted) return;
        CustomPopups.showError(
          context: context,
          title: 'Error de autenticación',
          message: 'Credenciales incorrectas.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      CustomPopups.showError(
        context: context,
        title: 'Error',
        message: e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          const AuthAnimatedBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AuthLogo(),
                    const SizedBox(height: 48),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      child: _selectedRole == null
                          ? RoleSelection(
                              theme: theme,
                              onRoleSelected: (role) => setState(() => _selectedRole = role),
                            )
                          : LoginFormWidget(
                              theme: theme,
                              selectedRole: _selectedRole!,
                              onBack: () => setState(() => _selectedRole = null),
                              usernameController: _usernameController,
                              passwordController: _passwordController,
                              obscurePassword: _obscurePassword,
                              onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                              isLoading: _isLoading,
                              onLogin: _login,
                            ),
                    ),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: '¿No tienes cuenta? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          children: [
                            TextSpan(
                              text: 'Regístrate aquí',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 1000.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
