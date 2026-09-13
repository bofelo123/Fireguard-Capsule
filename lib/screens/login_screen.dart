import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../fireguard_dashboard_complete.dart';
import 'register_screen.dart';

// ===============================================================
// CONFIG
// ===============================================================
class FireGuardConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'FIREGUARD_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static const String loginEndpoint = '/auth/login';
  static const Duration timeout = Duration(seconds: 20);
}

// ===============================================================
// COLORS
// ===============================================================
class AppColors {
  static const bg = Color(0xFF07111F);
  static const cardBg = Color(0xFF0D1B2A);
  static const border = Color(0xFF1B3045);
  static const primaryText = Color(0xFFF5F7FA);
  static const secondaryText = Color(0xFF8FA3B8);
  static const primary = Color(0xFF4DA3FF);
  static const primary2 = Color(0xFF25C281);
  static const error = Color(0xFFFF4D3D);
  static const success = Color(0xFF25C281);
}

// ===============================================================
// API SERVICE - REAL BACKEND CONNECTION
// ===============================================================
class LoginResult {
  final bool success;
  final String message;
  final String? token;
  final Map<String, dynamic>? user;
  LoginResult(
      {required this.success, required this.message, this.token, this.user});
}

class AuthApiService {
  final String baseUrl;
  final http.Client client;
  AuthApiService({required this.baseUrl, http.Client? client})
      : client = client ?? http.Client();

  // =============================================================
  // CORRECTED LOGIN FUNCTION - REPLACE ONLY THIS FUNCTION
  // =============================================================
  Future<LoginResult> login(
      {required String email, required String password}) async {
    final url = Uri.parse('$baseUrl${FireGuardConfig.loginEndpoint}');

    debugPrint('EMAIL SENT: ${email.trim().toLowerCase()}');
    debugPrint('PASSWORD LENGTH: ${password.length}');
    debugPrint('URL SENT: $url');

    try {
      final res = await client
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email.trim().toLowerCase(),
              "password": password,
            }),
          )
          .timeout(FireGuardConfig.timeout);

      final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

      debugPrint('========================================');
      debugPrint('LOGIN REQUEST');
      debugPrint('URL: $url');
      debugPrint('EMAIL: ${email.trim().toLowerCase()}');
      debugPrint('STATUS CODE: ${res.statusCode}');
      debugPrint('RESPONSE BODY: ${res.body}');
      debugPrint('========================================');

      if (res.statusCode == 200) {
        return LoginResult(
          success: true,
          message: data['message']?.toString() ?? 'Login successful',
          token: data['token']?.toString() ??
              data['access_token']?.toString(),
          user: {
            'user_id': data['user_id'],
            'full_name': data['full_name'],
            'email': data['email'] ?? email.trim().toLowerCase(),
          },
        );
      }

      if (res.statusCode == 401) {
        debugPrint('LOGIN FAILED: 401');
        return LoginResult(
          success: false,
          message: data['detail']?.toString() ?? 'Invalid email or password',
        );
      }

      if (res.statusCode == 403) {
        debugPrint('LOGIN FAILED: 403');
        return LoginResult(
          success: false,
          message: data['detail']?.toString() ??
              data['message']?.toString() ??
              'Account not verified. Please verify email.',
        );
      }

      debugPrint('LOGIN FAILED: ${res.statusCode}');
      return LoginResult(
        success: false,
        message: data['detail']?.toString() ??
            data['message']?.toString() ??
            'Login failed. Please try again.',
      );
    } on http.ClientException catch (e) {
      debugPrint('========================================');
      debugPrint('HTTP CLIENT ERROR');
      debugPrint('$e');
      debugPrint('========================================');
      return LoginResult(
        success: false,
        message: 'Network unavailable - $e',
      );
    } on TimeoutException catch (e) {
      debugPrint('========================================');
      debugPrint('LOGIN TIMEOUT');
      debugPrint('$e');
      debugPrint('========================================');
      return LoginResult(
        success: false,
        message: 'Request timeout - backend did not respond.',
      );
    } catch (e) {
      debugPrint('========================================');
      debugPrint('LOGIN ERROR');
      debugPrint('$e');
      debugPrint('========================================');
      return LoginResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }
}

// ===============================================================
// LOGIN SCREEN UI
// ===============================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final _api = AuthApiService(baseUrl: FireGuardConfig.apiBaseUrl);
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _api.login(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    debugPrint('========================================');
    debugPrint('LOGIN RESULT RECEIVED');
    debugPrint('SUCCESS: ${result.success}');
    debugPrint('MESSAGE: ${result.message}');
    debugPrint('========================================');

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      debugPrint('LOGIN SUCCESS - SAVING TOKEN');

      if (result.token == null || result.token!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login succeeded, but no access token was received.'),
          ),
        );
        return;
      }

      await _storage.write(
        key: 'access_token',
        value: result.token,
      );

      await _storage.write(
        key: 'user_id',
        value: result.user?['user_id']?.toString(),
      );

      await _storage.write(
        key: 'full_name',
        value: result.user?['full_name']?.toString(),
      );

      await _storage.write(
        key: 'email',
        value: result.user?['email']?.toString(),
      );

      debugPrint('JWT TOKEN SAVED');
      debugPrint('OPENING DASHBOARD');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const FireGuardDashboard(),
        ),
      );
    } else {
      debugPrint('LOGIN FAILED - STAYING ON LOGIN SCREEN');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  InputDecoration _decoration(
      {required String label,
      required IconData icon,
      Widget? suffix,
      String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppColors.secondaryText),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      labelStyle:
          const TextStyle(color: AppColors.secondaryText, fontSize: 14),
      hintStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // LOGO
                Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primary2]),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8))
                        ]),
                    child: const Icon(Icons.local_fire_department,
                        color: Colors.white, size: 36)),
                const SizedBox(height: 20),
                const Text("Welcome Back",
                    style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text("Login to FireGuard Monitoring System",
                    style: TextStyle(
                        color: AppColors.secondaryText, fontSize: 14)),
                const SizedBox(height: 36),

                // FORM CARD
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8))
                      ]),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // EMAIL
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.primaryText),
                          decoration: _decoration(
                              label: "Email",
                              icon: Icons.mail_outline,
                              hint: "Enter your email"),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return "Please enter your email";
                            }
                            final emailRegex =
                                RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(v.trim())) {
                              return "Enter a valid email";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // PASSWORD
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(color: AppColors.primaryText),
                          decoration: _decoration(
                              label: "Password",
                              icon: Icons.lock_outline,
                              hint: "Enter your password",
                              suffix: IconButton(
                                  icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: AppColors.secondaryText),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure))),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return "Please enter password";
                            }
                            if (v.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // REMEMBER + FORGOT
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: AppColors.primary,
                                    side: const BorderSide(
                                        color: AppColors.border),
                                    onChanged: (v) => setState(
                                        () => _rememberMe = v ?? false)),
                              ),
                              const SizedBox(width: 8),
                              const Text("Remember me",
                                  style: TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 13)),
                            ]),
                            TextButton(
                              onPressed: () {
                                // TODO: Add ForgotPasswordScreen navigation
                              },
                              child: const Text("Forgot Password?",
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: AppColors.border
                                    .withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0),
                            onPressed: _isLoading ? null : _onLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text("Login",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // DIVIDER
                        Row(children: [
                          const Expanded(
                              child: Divider(color: AppColors.border)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text("OR",
                                style: TextStyle(
                                    color: AppColors.secondaryText
                                        .withValues(alpha: 0.7),
                                    fontSize: 12)),
                          ),
                          const Expanded(
                              child: Divider(color: AppColors.border)),
                        ]),
                        const SizedBox(height: 20),
                        // REGISTER LINK
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? ",
                                style: TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 14)),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: const Text("Register",
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text("Secure • Encrypted • FireGuard v1.0",
                    style: TextStyle(
                        color:
                            AppColors.secondaryText.withValues(alpha: 0.6),
                        fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}