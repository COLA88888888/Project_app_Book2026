import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/user_profile.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  List<UserProfile> profiles = [];
  bool isLoading = true;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    final users = await DatabaseHelper.instance.readAllUsers();
    setState(() {
      profiles = users;
      isLoading = false;
    });
  }

  Future<void> _loginWithPhone() async {
    final phoneInput = _phoneController.text.trim();
    final passwordInput = _passwordController.text;

    if (phoneInput.isEmpty) {
      _showSnackBar('ກະລຸນາປ້ອນເບີໂທລະສັບຜູ້ປົກຄອງເພື່ອເຂົ້າສູ່ລະບົບເດີ້!', isError: true);
      return;
    }

    if (passwordInput.isEmpty) {
      _showSnackBar('ກະລຸນາປ້ອນລະຫັດຜ່ານເດີ້!', isError: true);
      return;
    }

    // Search database for matching phone number
    UserProfile? matchedUser;
    for (var u in profiles) {
      if (u.phone.replaceAll(' ', '') == phoneInput.replaceAll(' ', '')) {
        matchedUser = u;
        break;
      }
    }

    if (matchedUser == null) {
      _showSnackBar('ບໍ່ພົບເບີໂທລະສັບນີ້ໃນລະບົບ! ກະລຸນາກວດສອບ ຫຼື ລົງທະບຽນໃໝ່', isError: true);
      return;
    }

    // Verify password
    if (matchedUser.password != passwordInput) {
      _showSnackBar('ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ! ກະລຸນາກວດສອບອີກເທື່ອ 🔑', isError: true);
      return;
    }

    await _loginAs(matchedUser);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF3E8EF7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _loginAs(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_user_id', user.id!);
    await prefs.setString('current_user_name', user.name);
    if (!mounted) return;
    _showSnackBar('ຍິນດີຕ້ອນຮັບ, ຫຼານ "${user.name}"! 👋');
    context.go('/home');
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF3E8EF7)),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3E8EF7), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Logo and welcome
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E8EF7).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 64,
                        color: Color(0xFF3E8EF7),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'ເຂົ້າສູ່ລະບົບ',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ປ້ອນຂໍ້ມູນຜູ້ປົກຄອງເພື່ອເລີ່ມຮຽນຮູ້',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: -0.1),
              const SizedBox(height: 36),

              // Login Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Phone field ──────────────────────────────
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                      decoration: _inputDecoration(
                        label: 'ເບີໂທລະສັບຜູ້ປົກຄອງ',
                        hint: 'ປ້ອນເບີໂທ (ເຊັ່ນ: 020 99XXXXXX)',
                        icon: Icons.phone_iphone_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Password field ───────────────────────────
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                      decoration: _inputDecoration(
                        label: 'ລະຫັດຜ່ານ',
                        hint: 'ປ້ອນລະຫັດຜ່ານຂອງທ່ານ',
                        icon: Icons.lock_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.grey.shade500,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Login Button ─────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3E8EF7),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          shadowColor: const Color(0xFF3E8EF7).withValues(alpha: 0.35),
                        ),
                        onPressed: _loginWithPhone,
                        icon: const Icon(Icons.login_rounded, color: Colors.white),
                        label: const Text(
                          'ເຂົ້າສູ່ລະບົບ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: 100.ms).slideY(begin: 0.05),
              const SizedBox(height: 28),

              // ── Register link ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ທ່ານຍັງບໍ່ມີບັນຊີເທື່ອບໍ? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await context.push('/add-profile');
                      _loadProfiles();
                    },
                    child: const Text(
                      'ລົງທະບຽນເລີຍ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF38B264),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF38B264),
                      ),
                    ),
                  ),
                ],
              ).animate().fade(delay: 250.ms),
            ],
          ),
        ),
      ),
    );
  }
}
