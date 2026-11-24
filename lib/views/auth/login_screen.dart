import 'package:cropCompliance/views/shared/language_toggle.dart';
import 'package:cropCompliance/core/services/push_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:animate_do/animate_do.dart'; // Add this package to pubspec.yaml
import '../../providers/auth_provider.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  // Always start empty — never put real or test logins in code.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        // Admins → admin dashboard, auditors → Audit Index, everyone else → dashboard
        Navigator.of(context).pushReplacementNamed(authProvider.homeRoute);
        // Open any notification the user tapped to launch the app.
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => PushNotificationService.instance.markAppReady());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient and designs
          AnimatedPositioned(
            duration: const Duration(seconds: 1),
            curve: Curves.easeOut,
            top: -size.height * 0.1,
            left: -size.width * 0.1,
            child: Container(
              height: size.height * 0.5,
              width: size.width * 0.5,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1), // Primary green with opacity
                shape: BoxShape.circle,
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(seconds: 1),
            curve: Curves.easeOut,
            bottom: -size.height * 0.1,
            right: -size.width * 0.1,
            child: Container(
              height: size.height * 0.5,
              width: size.width * 0.5,
              decoration: BoxDecoration(
                color: const Color(0xFFFFA000).withOpacity(0.1), // Amber with opacity
                shape: BoxShape.circle,
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Card(
                      elevation: 10,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Row(
                            children: [
                              // Left side with branding and imagery (only on desktop)
                              if (isDesktop)
                                Expanded(
                                  flex: 6,
                                  child: Container(
                                    height: 600,
                                    color: const Color(0xFF2E7D32),
                                    child: Stack(
                                      children: [
                                        // Decorative pattern
                                        Positioned.fill(
                                          child: Opacity(
                                            opacity: 0.1,
                                            child: GridPattern(
                                              size: 20,
                                              lineWidth: 1,
                                              lineColor: Colors.white,
                                            ),
                                          ),
                                        ),

                                        Padding(
                                          padding: const EdgeInsets.all(40),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Logo and app name
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: SvgPicture.asset(
                                                      'assets/svg/logoIcon.svg',
                                                      width: 32,
                                                      height: 32,

                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  const Text(
                                                    'Crop Compliance', // l10n-ignore: product name
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 60),

                                              // Taglines
                                              FadeInLeft(
                                                delay: const Duration(milliseconds: 300),
                                                child: Text(
                                                  context.l10n.loginTagline1,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ),
                                              FadeInLeft(
                                                delay: const Duration(milliseconds: 600),
                                                child: Text(
                                                  context.l10n.loginTagline2,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 24),

                                              FadeInLeft(
                                                delay: const Duration(milliseconds: 900),
                                                child: Container(
                                                  width: 100,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFFA000),
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 32),

                                              // Bullet points
                                              FadeInLeft(
                                                delay: const Duration(milliseconds: 1200),
                                                child: _buildFeatureItem(
                                                  Icons.check_circle,
                                                  context.l10n.loginFeature1,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              FadeInLeft(
                                                delay: const Duration(milliseconds: 1400),
                                                child: _buildFeatureItem(
                                                  Icons.check_circle,
                                                  context.l10n.loginFeature2,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              FadeInLeft(
                                                delay: const Duration(milliseconds: 1600),
                                                child: _buildFeatureItem(
                                                  Icons.check_circle,
                                                  context.l10n.loginFeature3,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              FadeInLeft(
                                                delay: const Duration(milliseconds: 1800),
                                                child: _buildFeatureItem(
                                                  Icons.check_circle,
                                                  context.l10n.loginFeature4,
                                                ),
                                              ),

                                              const Spacer(),

                                              FadeInLeft(
                                                delay: const Duration(milliseconds: 2000),
                                                child: Text(
                                                  context.l10n.loginCopyright('${DateTime.now().year}'),
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Right side with login form
                              Expanded(
                                flex: isDesktop ? 4 : 10,
                                child: Container(
                                  padding: EdgeInsets.all(isDesktop ? 40 : 24),
                                  color: Colors.white,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (!isDesktop) ...[
                                        // Mobile logo and branding
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2E7D32).withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: SvgPicture.asset(
                                              'assets/svg/logoIcon.svg',
                                              width: 40,
                                              height: 40,

                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Center(
                                          child: Text(
                                            'Crop Compliance', // l10n-ignore: product name
                                            style: TextStyle(
                                              color: Color(0xFF2E7D32),
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                      ],

                                      // Welcome text
                                      FadeInUp(
                                        delay: const Duration(milliseconds: 300),
                                        child: Text(
                                          context.l10n.loginWelcomeBack,
                                          style: TextStyle(
                                            fontSize: isDesktop ? 32 : 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: isDesktop ? 16 : 8),

                                      FadeInUp(
                                        delay: const Duration(milliseconds: 400),
                                        child: Text(
                                          context.l10n.loginEnterCredentials,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: isDesktop ? 40 : 24),

                                      // Login form
                                      Form(
                                        key: _formKey,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Email field
                                            FadeInUp(
                                              delay: const Duration(milliseconds: 500),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    context.l10n.fieldEmail,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  TextFormField(
                                                    controller: _emailController,
                                                    decoration: InputDecoration(
                                                      hintText: context.l10n.fieldEmailHint,
                                                      prefixIcon: Icon(
                                                        Icons.email_outlined,
                                                        color: Colors.grey[400],
                                                      ),
                                                      filled: true,
                                                      fillColor: Colors.grey[100],
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                        borderSide: BorderSide.none,
                                                      ),
                                                      contentPadding: const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                        horizontal: 16,
                                                      ),
                                                    ),
                                                    keyboardType: TextInputType.emailAddress,
                                                    textInputAction: TextInputAction.next,
                                                    validator: (value) {
                                                      if (value == null || value.isEmpty) {
                                                        return context.l10n.validationEmailRequired;
                                                      }
                                                      if (!value.contains('@')) {
                                                        return context.l10n.validationEmailInvalid;
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),

                                            SizedBox(height: isDesktop ? 24 : 16),

                                            // Password field
                                            FadeInUp(
                                              delay: const Duration(milliseconds: 600),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    context.l10n.fieldPassword,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  TextFormField(
                                                    controller: _passwordController,
                                                    decoration: InputDecoration(
                                                      hintText: context.l10n.fieldPasswordHint,
                                                      prefixIcon: Icon(
                                                        Icons.lock_outline,
                                                        color: Colors.grey[400],
                                                      ),
                                                      suffixIcon: IconButton(
                                                        icon: Icon(
                                                          _obscurePassword
                                                              ? Icons.visibility_outlined
                                                              : Icons.visibility_off_outlined,
                                                          color: Colors.grey[400],
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _obscurePassword = !_obscurePassword;
                                                          });
                                                        },
                                                      ),
                                                      filled: true,
                                                      fillColor: Colors.grey[100],
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                        borderSide: BorderSide.none,
                                                      ),
                                                      contentPadding: const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                        horizontal: 16,
                                                      ),
                                                    ),
                                                    obscureText: _obscurePassword,
                                                    textInputAction: TextInputAction.done,
                                                    validator: (value) {
                                                      if (value == null || value.isEmpty) {
                                                        return context.l10n.validationPasswordRequired;
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),

                                            SizedBox(height: isDesktop ? 16 : 12),

                                            // Remember me and forgot password
                                            FadeInUp(
                                              delay: const Duration(milliseconds: 700),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                        height: 24,
                                                        width: 24,
                                                        child: Checkbox(
                                                          value: _rememberMe,
                                                          onChanged: (value) {
                                                            setState(() {
                                                              _rememberMe = value ?? false;
                                                            });
                                                          },
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          activeColor: const Color(0xFF2E7D32),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        context.l10n.loginRememberMe,
                                                        style: TextStyle(
                                                          color: Colors.grey[700],
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  TextButton(
                                                    onPressed: _showForgotPasswordDialog,
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: const Color(0xFF2E7D32),
                                                      padding: EdgeInsets.zero,
                                                      minimumSize: const Size(0, 0),
                                                    ),
                                                    child: Text(
                                                      context.l10n.loginForgotPassword,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            SizedBox(height: isDesktop ? 32 : 24),

                                            // Login button
                                            FadeInUp(
                                              delay: const Duration(milliseconds: 800),
                                              child: SizedBox(
                                                height: 56,
                                                child: ElevatedButton(
                                                  onPressed: authProvider.isLoading ? null : _login,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF2E7D32),
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    elevation: 2,
                                                  ),
                                                  child: authProvider.isLoading
                                                      ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child: CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 3,
                                                    ),
                                                  )
                                                      : Text(
                                                    context.l10n.signIn,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Error message
                                            if (authProvider.error != null) ...[
                                              const SizedBox(height: 16),
                                              FadeIn(
                                                child: Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade50,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: Colors.red.shade200,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.error_outline,
                                                        color: Colors.red.shade700,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          authProvider.error!,
                                                          style: TextStyle(
                                                            color: Colors.red.shade700,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],

                                            SizedBox(height: isDesktop ? 48 : 32),

                                            // Sign up option
                                            FadeInUp(
                                              delay: const Duration(milliseconds: 900),
                                              child: Center(
                                                child: RichText(
                                                  text: TextSpan(
                                                    text: context.l10n.loginNoAccount,
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 14,
                                                    ),
                                                    children: [
                                                      TextSpan(
                                                        text: context.l10n.loginContactSupport,
                                                        style: TextStyle(
                                                          color: const Color(0xFF2E7D32),
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
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
            ),
          ),
          // Language: choose English / Afrikaans before signing in.
          const Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: LanguageToggle(compact: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFFFFA000),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    bool sending = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              const Icon(Icons.lock_reset_outlined, color: Color(0xFF2E7D32)),
              const SizedBox(width: 10),
              Expanded(child: Text(context.l10n.resetPasswordTitle)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.resetPasswordBody,
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.l10n.fieldEmail,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Text(
                  context.l10n.resetPasswordSpamHint,
                  style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(ctx),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton.icon(
              onPressed: sending
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                              content: Text(context.l10n.validationEmailValidAddress)),
                        );
                        return;
                      }
                      setDialogState(() => sending = true);
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      final ok = await authProvider.resetPassword(email);
                      if (!ctx.mounted || !mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? context.l10n.resetPasswordSent(email)
                              : context.l10n.resetPasswordFailed),
                          backgroundColor:
                              ok ? const Color(0xFF2E7D32) : Colors.red,
                          duration: const Duration(seconds: 6),
                        ),
                      );
                    },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              icon: sending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_outlined, size: 16),
              label: Text(context.l10n.resetPasswordSend),
            ),
          ],
        ),
      ),
    );
  }
}

// Grid pattern for the decorative background
class GridPattern extends StatelessWidget {
  final double size;
  final double lineWidth;
  final Color lineColor;

  const GridPattern({
    Key? key,
    required this.size,
    required this.lineWidth,
    required this.lineColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(
        size: size,
        lineWidth: lineWidth,
        lineColor: lineColor,
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double size;
  final double lineWidth;
  final Color lineColor;

  GridPainter({
    required this.size,
    required this.lineWidth,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth;

    for (double i = 0; i < canvasSize.width; i += size) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, canvasSize.height),
        paint,
      );
    }

    for (double i = 0; i < canvasSize.height; i += size) {
      canvas.drawLine(
        Offset(0, i),
        Offset(canvasSize.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}