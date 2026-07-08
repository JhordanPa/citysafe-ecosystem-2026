import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../common/custom_text_field.dart';
import '../common/glass_container.dart';

class LoginFormWidget extends StatelessWidget {
  final ThemeData theme;
  final String selectedRole;
  final VoidCallback onBack;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final bool isLoading;
  final VoidCallback onLogin;

  const LoginFormWidget({
    super.key,
    required this.theme,
    required this.selectedRole,
    required this.onBack,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.isLoading,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onBack,
                tooltip: 'Volver',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ingreso de ${selectedRole == "ciudadano" ? "Ciudadano" : "Gestor"}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CustomTextField(
            hintText: 'Nombre de usuario',
            prefixIcon: Icons.person_outline_rounded,
            controller: usernameController,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            hintText: 'Contraseña',
            prefixIcon: Icons.lock_rounded,
            obscureText: obscurePassword,
            controller: passwordController,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
              ),
              onPressed: onTogglePassword,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: isLoading ? null : onLogin,
              style: FilledButton.styleFrom(
                backgroundColor: selectedRole == 'ciudadano'
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 400.ms)
    .slideY(begin: 0.1, curve: Curves.easeOutCubic);
  }
}
