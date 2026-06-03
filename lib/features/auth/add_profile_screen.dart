import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/user_profile.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

// 18 ແຂວງ + ນະຄອນຫຼວງ (Keep for edit_profile_screen.dart import)
// const List<String> kLaoProvinces = [
//   'ນະຄອນຫຼວງວຽງຈັນ',
//   'ວຽງຈັນ',
//   'ໄຊສົມບູນ',
//   'ຜົ້ງສາລີ',
//   'ຫຼວງນໍ້າທາ',
//   'ອຸດົມໄຊ',
//   'ບໍ່ແກ້ວ',
//   'ຫຼວງພະບາງ',
//   'ຫົວພັນ',
//   'ໄຊຍະບູລີ',
//   'ຊຽງຂວາງ',
//   'ບໍລິຄຳໄຊ',
//   'ຄຳມ່ວນ',
//   'ສະຫວັນນະເຂດ',
//   'ສາລະວັນ',
//   'ເຊກອງ',
//   'ຈຳປາສັກ',
//   'ອັດຕະປື',
// ];

class AddProfileScreen extends StatefulWidget {
  const AddProfileScreen({super.key});

  @override
  State<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Validators ───────────────────────────────────────
  bool _validateForm() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty) {
      _showSnackBar('ກະລຸນາປ້ອນຊື່ຜູ້ໃຊ້!', isError: true);
      return false;
    }
    if (phone.isEmpty || phone.replaceAll(' ', '').length < 8) {
      _showSnackBar('ກະລຸນາປ້ອນເບີໂທທີ່ຖືກຕ້ອງ!', isError: true);
      return false;
    }
    if (password.isEmpty || password.length < 6) {
      _showSnackBar('ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 6 ຕົວ!', isError: true);
      return false;
    }
    if (password != confirm) {
      _showSnackBar('ລະຫັດຜ່ານ ແລະ ຢືນຢັນລະຫັດຜ່ານບໍ່ກົງກັນ! 🔑', isError: true);
      return false;
    }
    return true;
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF38B264),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_validateForm()) return;

    final user = UserProfile(
      name: _nameController.text.trim(),
      avatarId: 1, // Default avatar
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    // Create user profile directly without showing the temporary loading message
    final createdUser = await DatabaseHelper.instance.createUser(user);

    if (!mounted) return;

    if (createdUser.id == -1) {
      _showSnackBar('ຊື່ນີ້ມີໃນລະບົບແລ້ວ! ກະລຸນາໃຊ້ຊື່ວື່ນເດີ້', isError: true);
    } else if (createdUser.id != null) {
      _showSnackBar('ລົງທະບຽນ "${user.name}" ສຳເລັດແລ້ວ! 🎉');
      if (mounted) context.pop();
    } else {
      _showSnackBar(
        'ບໍ່ສາມາດລົງທະບຽນໄດ້! ກະລຸນາກວດສອບການເຊື່ອມຕໍ່ ຫຼື IP ຂອງເຊີເວີ 🔌',
        isError: true,
      );
    }
  }

  // ── UI Helpers ────────────────────────────────────────
  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF3E8EF7), size: 22),
      suffixIcon: suffix,
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

  Widget _eyeButton(bool obscure, VoidCallback onTap) => IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: Colors.grey.shade500,
        ),
        onPressed: onTap,
      );

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'ລົງທະບຽນຜູ້ໃຊ້ໃໝ່',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.textColor),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38B264).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 64,
                        color: Color(0xFF38B264),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'ສ້າງບັນຊີໃໝ່',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ປ້ອນຂໍ້ມູນລຸ່ມນີ້ເພື່ອເລີ່ມຕົ້ນຮຽນຮູ້',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: -0.1),
              const SizedBox(height: 32),

              // Form card
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Name field ──────────────────────────────
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                      decoration: _fieldDecoration(
                        label: 'ຊື່ຫຼານນ້ອຍ / ຜູ້ປົກຄອງ...',
                        hint: 'ປ້ອນຊື່ຂອງທ່ານ...',
                        icon: Icons.person_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Phone field ──────────────────────────────
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                      decoration: _fieldDecoration(
                        label: 'ເບີໂທລະສັບ...',
                        hint: 'ປ້ອນເບີໂທ (ເຊັ່ນ: 020...)',
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
                      decoration: _fieldDecoration(
                        label: 'ລະຫັດຜ່ານ...',
                        hint: 'ຕັ້ງລະຫັດຜ່ານຂອງທ່ານ...',
                        icon: Icons.lock_rounded,
                        suffix: _eyeButton(
                          _obscurePassword,
                          () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Confirm password field ───────────────────
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                      decoration: _fieldDecoration(
                        label: 'ຢືນຢັນລະຫັດຜ່ານ...',
                        hint: 'ໃສ່ລະຫັດຜ່ານອີກຄັ້ງ',
                        icon: Icons.lock_outline_rounded,
                        suffix: _eyeButton(
                          _obscureConfirmPassword,
                          () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Register Button ──────────────────────────
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38B264),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF38B264).withValues(alpha: 0.35),
                      ),
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                      label: const Text(
                        'ລົງທະບຽນ',
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: 100.ms).slideY(begin: 0.05),
              const SizedBox(height: 28),

              // ── Login link ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ທ່ານມີບັນຊີແລ້ວບໍ? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/login');
                      }
                    },
                    child: const Text(
                      'ເຂົ້າສູ່ລະບົບ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3E8EF7),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF3E8EF7),
                      ),
                    ),
                  ),
                ],
              ).animate().fade(delay: 250.ms),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
