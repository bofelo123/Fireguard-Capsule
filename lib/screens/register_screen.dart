import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ===============================================================
// CONFIG - CHANGE THIS ONE PLACE FOR PROD
// ===============================================================
class FireGuardConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'FIREGUARD_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static const String registerEndpoint = '/auth/register';
  static const Duration timeout = Duration(seconds: 20);
}

// ===============================================================
// COLORS - FIREGUARD / LIVESTI GUARD THEME
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
// API SERVICE - NO UI LOGIC HERE
// ===============================================================
class AuthApiResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? errors;
  AuthApiResult({required this.success, required this.message, this.errors});
}

class AuthApiService {
  final String baseUrl;
  final http.Client client;
  AuthApiService({required this.baseUrl, http.Client? client})
      : client = client?? http.Client();

  Future<AuthApiResult> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final url = Uri.parse('$baseUrl${FireGuardConfig.registerEndpoint}');
    final body = {
      "full_name": fullName.trim(),
      "email": email.trim().toLowerCase(),
      "password": password,
      if (phone!= null && phone.isNotEmpty) "phone": phone.trim(),
      "terms_accepted": true,
    };

    try {
      final res = await client
         .post(url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(body))
         .timeout(FireGuardConfig.timeout);

      final data = res.body.isNotEmpty? jsonDecode(res.body) : {};

      if (res.statusCode == 201 || res.statusCode == 200) {
        return AuthApiResult(
            success: true,
            message: data['message']?.toString()??
                'Account created successfully! Please login.');
      }
      if (res.statusCode == 409) {
        return AuthApiResult(
            success: false,
            message: data['message']?.toString()?? 'Email already exists',
            errors: {"email": "Email already exists"});
      }
      if (res.statusCode == 400 || res.statusCode == 422) {
        return AuthApiResult(
            success: false,
            message: data['message']?.toString()?? 'Validation failed',
            errors: data['errors'] as Map<String, dynamic>?);
      }
      return AuthApiResult(
          success: false,
          message: data['message']?.toString()?? 'Registration failed. Try again');
    } on http.ClientException {
      return AuthApiResult(
          success: false, message: 'Network unavailable - try again');
    } on TimeoutException {
      return AuthApiResult(
          success: false, message: 'Request timeout - try again');
    } catch (e) {
      return AuthApiResult(
          success: false, message: 'Registration failed. Try again');
    }
  }
}

// ===============================================================
// REGISTER SCREEN UI - 100% REAL FRONTEND
// ===============================================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _termsAccepted = false;
  bool _isLoading = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final _api = AuthApiService(baseUrl: FireGuardConfig.apiBaseUrl);

  // Password strength
  int _strength = 0; // 0-4
  String _strengthText = '';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _passwordCtrl.addListener(_calcStrength);
  }

  void _calcStrength() {
    final p = _passwordCtrl.text;
    int score = 0;
    if (p.length >= 8) score++;
    if (p.contains(RegExp(r'[A-Z]'))) score++;
    if (p.contains(RegExp(r'[a-z]'))) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    setState(() {
      _strength = score.clamp(0, 4);
      if (p.isEmpty) {
        _strengthText = '';
      } else if (score <= 2) {
        _strengthText = 'Weak';
      } else if (score == 3) {
        _strengthText = 'Medium';
      } else {
        _strengthText = 'Strong';
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _formKey.currentState?.validate()?? false && _termsAccepted;
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please accept Terms & Conditions'),
          backgroundColor: AppColors.error));
      return;
    }

    setState(() => _isLoading = true);

    final result = await _api.register(
      fullName: _fullNameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      phone: _phoneCtrl.text.isNotEmpty? _phoneCtrl.text : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating));
      // Navigate to Login - replace with your route
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    }
  }

  InputDecoration _inputDecoration(
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
                const SizedBox(height: 24),
                // LOGO + TITLE
                Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primary2]),
                        borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.local_fire_department,
                        color: Colors.white, size: 32)),
                const SizedBox(height: 16),
                const Text("Create Your Account",
                    style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 24,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text("Secure Access to Livestock Monitoring System",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.secondaryText, fontSize: 14)),
                const SizedBox(height: 32),

                // FORM CARD
                Container(
                  padding: const EdgeInsets.all(20),
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
                      children: [
                        // FULL NAME
                        TextFormField(
                          controller: _fullNameCtrl,
                          style: const TextStyle(color: AppColors.primaryText),
                          decoration: _inputDecoration(
                              label: "Full Name",
                              icon: Icons.person_outline,
                              hint: "Full Name"),
                          validator: (v) {
                            if (v== null || v.trim().isEmpty) {
                              return "Please enter your full name";
                            }
                            if (v.trim().length < 2) {
                              return "Name too short";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // EMAIL
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.primaryText),
                          decoration: _inputDecoration(
                              label: "Email",
                              icon: Icons.mail_outline,
                              hint: "Email"),
                          validator: (v) {
                            if (v== null || v.trim().isEmpty) {
                              return "Please enter your email";
                            }
                            final emailRegex = RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
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
                          obscureText: _obscurePass,
                          style: const TextStyle(color: AppColors.primaryText),
                          decoration: _inputDecoration(
                              label: "Password",
                              icon: Icons.lock_outline,
                              hint: "Password",
                              suffix: IconButton(
                                  icon: Icon(
                                      _obscurePass
                                         ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: AppColors.secondaryText),
                                  onPressed: () => setState(
                                      () => _obscurePass =!_obscurePass))),
                          validator: (v) {
                            if (v== null || v.isEmpty) {
                              return "Please enter password";
                            }
                            if (v.length < 8) {
                              return "Password must be at least 8 characters";
                            }
                            if (!RegExp(r'[A-Z]').hasMatch(v)) {
                              return "Must include uppercase";
                            }
                            if (!RegExp(r'[a-z]').hasMatch(v)) {
                              return "Must include lowercase";
                            }
                            if (!RegExp(r'[0-9]').hasMatch(v)) {
                              return "Must include number";
                            }
                            if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                               .hasMatch(v)) {
                              return "Must include symbol";
                            }
                            return null;
                          },
                        ),
                        if (_passwordCtrl.text.isNotEmpty)...[
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                                child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (_strength + 1) / 5,
                                minHeight: 4,
                                backgroundColor: AppColors.border,
                                valueColor: AlwaysStoppedAnimation(
                                    _strength <= 1
                                       ? AppColors.error
                                        : _strength == 2
                                           ? Colors.orange
                                            : _strength == 3
                                               ? Colors.amber
                                                : AppColors.success),
                              ),
                            )),
                            const SizedBox(width: 8),
                            Text(_strengthText,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _strength <= 1
                                       ? AppColors.error
                                        : _strength == 2
                                           ? Colors.orange
                                            : AppColors.success)),
                          ]),
                        ],
                        const SizedBox(height: 16),
                        // CONFIRM PASSWORD
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscureConfirm,
                          style: const TextStyle(color: AppColors.primaryText),
                          decoration: _inputDecoration(
                              label: "Confirm Password",
                              icon: Icons.lock_outline,
                              hint: "Confirm Password",
                              suffix: IconButton(
                                  icon: Icon(
                                      _obscureConfirm
                                         ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: AppColors.secondaryText),
                                  onPressed: () => setState(() =>
                                      _obscureConfirm =!_obscureConfirm))),
                          validator: (v) {
                            if (v== null || v.isEmpty) {
                              return "Please confirm password";
                            }
                            if (v!= _passwordCtrl.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // PHONE OPTIONAL
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: AppColors.primaryText),
                          decoration: _inputDecoration(
                              label: "Phone Number (Optional)",
                              icon: Icons.phone_outlined,
                              hint: "Phone Number (Optional)"),
                          validator: (v) {
                            if (v== null || v.trim().isEmpty) return null;
                            final phoneRegex = RegExp(r'^[+]*[0-9]{7,15}$');
                            if (!phoneRegex
                               .hasMatch(v.replaceAll(' ', ''))) {
                              return "Enter a valid phone number";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // TERMS
                        Row(children: [
                          Checkbox(
                              value: _termsAccepted,
                              activeColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.border),
                              onChanged: (v) => setState(
                                  () => _termsAccepted = v?? false)),
                          Expanded(
                              child: RichText(
                                  text: const TextSpan(
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.secondaryText),
                                      children: [
                                TextSpan(text: "I agree to "),
                                TextSpan(
                                    text: "Terms & Conditions",
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600)),
                              ]))),
                        ]),
                        const SizedBox(height: 8),
                        // REGISTER BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor:
                                    AppColors.border.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0),
                            onPressed: (_isLoading ||!_termsAccepted)
                               ? null
                                : _onRegister,
                            child: _isLoading
                               ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text("Create Account",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // LOGIN LINK
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account? ",
                                style: TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 14)),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text("Login",
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
