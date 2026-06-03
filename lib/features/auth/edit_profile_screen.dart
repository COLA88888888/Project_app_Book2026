import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/user_profile.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EditProfileScreen extends StatefulWidget {
  final String? userId;
  const EditProfileScreen({super.key, this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  UserProfile? _user;
  bool _isLoading = true;
  bool _isCurrentUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final currentActiveId = prefs.getInt('current_user_id') ?? 1;

    int editId = currentActiveId;
    if (widget.userId != null) {
      final parsed = int.tryParse(widget.userId!);
      if (parsed != null) {
        editId = parsed;
        _isCurrentUser = (parsed == currentActiveId);
      }
    }

    final fetched = await DatabaseHelper.instance.readUser(editId);
    if (fetched != null) {
      setState(() {
        _user = fetched;
        _nameController.text = fetched.name;
        _phoneController.text = fetched.phone;
        _passwordController.text = fetched.password;
        _confirmPasswordController.text = fetched.password;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_user == null) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty) {
      _showSnackBar('ກະລຸນາປ້ອນຊື່ຫຼານນ້ອຍ!', isError: true);
      return;
    }
    if (phone.isEmpty || phone.replaceAll(' ', '').length < 8) {
      _showSnackBar('ກະລຸນາປ້ອນເບີໂທທີ່ຖືກຕ້ອງ!', isError: true);
      return;
    }
    if (password.isEmpty || password.length < 6) {
      _showSnackBar('ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 6 ຕົວ!', isError: true);
      return;
    }
    if (password != confirm) {
      _showSnackBar('ລະຫັດຜ່ານ ແລະ ຢືນຢັນລະຫັດຜ່ານບໍ່ກົງກັນ! 🔑', isError: true);
      return;
    }

    final updated = _user!.copyWith(
      name: name,
      phone: phone,
      password: password,
    );

    final res = await DatabaseHelper.instance.updateUser(updated);

    if (res == -1) {
      _showSnackBar('ຊື່ນີ້ມີໃນລະບົບແລ້ວ! ກະລຸນາໃຊ້ຊື່ວື່ນເດີ້', isError: true);
      return;
    }
    if (res == -2) {
      _showSnackBar('ເບີໂທນີ້ມີໃນລະບົບແລ້ວ! ກະລຸນາໃຊ້ເບີໂທອື່ນເດີ້', isError: true);
      return;
    }

    if (_isCurrentUser) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_name', name);
    }

    if (!mounted) return;
    _showSnackBar('ອັບເດດໂປຣໄຟລ໌ "$name" ສຳເລັດ! 🎉');
    context.pop(true);
  }

  Future<void> _deleteProfile() async {
    if (_user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('ຢືນຢັນການລຶບ ⚠️', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'ຫຼານແນ່ໃຈແລ້ວບໍ ວ່າຕ້ອງການລຶບໂປຣໄຟລ໌ "${_user!.name}"?\nຂໍ້ມູນທັງໝົດຈະຖືກລຶບຖາວອນ!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ຢືນຢັນລຶບ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteUser(_user!.id!);
      if (_isCurrentUser) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('current_user_id');
        await prefs.remove('current_user_name');
        if (!mounted) return;
        context.go('/login');
      } else {
        if (!mounted) return;
        _showSnackBar('ລຶບໂປຣໄຟລ໌ສຳເລັດ!');
        context.pop(true);
      }
    }
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

  InputDecoration _dec({
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3E8EF7), width: 2)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _eyeButton(bool obscure, VoidCallback onTap) => IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: Colors.grey.shade500,
          size: 22,
        ),
        onPressed: onTap,
      );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_user == null) {
      return Scaffold(appBar: AppBar(title: const Text('ບໍ່ພົບຜູ້ໃຊ້')),
          body: const Center(child: Text('ບໍ່ພົບຂໍ້ມູນ')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('ແກ້ໄຂຂໍ້ມູນ ✏️',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.textColor)),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── User ID and Avatar Header ────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E8EF7).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF3E8EF7), width: 3),
                    ),
                    child: const Center(
                      child: Icon(Icons.account_circle_rounded, size: 70, color: Color(0xFF3E8EF7)),
                    ),
                  ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E8EF7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF3E8EF7).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'ລະຫັດຜູ້ໃຊ້: ${_user!.id}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E8EF7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 4),
                      Text('${_user!.score} ດາວ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── ຂໍ້ມູນຫຼານ ─────────────────────────────────
            _sectionCard(
              title: '👦 ຂໍ້ມູນບັນຊີຜູ້ໃຊ້',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name field
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                    decoration: _dec(label: 'ຊື່ຫຼານນ້ອຍ / ຜູ້ປົກຄອງ *', hint: 'ພິມຊື່ຫຼານ...', icon: Icons.person_rounded),
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone field
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                    decoration: _dec(label: 'ເບີໂທຜູ້ປົກຄອງ *', hint: '020...', icon: Icons.phone_iphone_rounded),
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                    decoration: _dec(
                      label: 'ລະຫັດຜ່ານ...',
                      hint: 'ປ່ຽນລະຫັດຜ່ານ',
                      icon: Icons.lock_rounded,
                      suffix: _eyeButton(
                        _obscurePassword,
                        () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password field
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                    decoration: _dec(
                      label: 'ຢືນຢັນລະຫັດຜ່ານ *',
                      hint: 'ຢືນຢັນລະຫັດຜ່ານອີກຄັ້ງ',
                      icon: Icons.lock_outline_rounded,
                      suffix: _eyeButton(
                        _obscureConfirmPassword,
                        () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Save Button ──────────────────────────────────
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38B264),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: const Color(0xFF38B264).withValues(alpha: 0.3),
              ),
              onPressed: _updateProfile,
              icon: const Icon(Icons.save_rounded, color: Colors.white, size: 22),
              label: const Text('ບັນທຶກການປ່ຽນແປງ', style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
            ).animate().scale(delay: 200.ms),
            const SizedBox(height: 12),

            // ── Delete Button ────────────────────────────────
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 50),
                side: BorderSide(color: Colors.red.shade400, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _deleteProfile,
              icon: Icon(Icons.delete_forever_rounded, color: Colors.red.shade400),
              label: Text('ລຶບໂປຣໄຟລ໌', style: TextStyle(fontSize: 15, color: Colors.red.shade500, fontWeight: FontWeight.bold)),
            ).animate().fade(delay: 300.ms),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}


