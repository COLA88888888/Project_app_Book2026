import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/user_profile.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddProfileScreen extends StatefulWidget {
  const AddProfileScreen({super.key});

  @override
  State<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ກະລຸນາປ້ອນຊື່ຫຼານນ້ອຍກ່ອນເດີ້!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ກະລຸນາປ້ອນເບີໂທຜູ້ປົກຄອງກ່ອນເດີ້!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Basic phone number length validation
    if (phone.replaceAll(' ', '').length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ເບີໂທລະສັບບໍ່ຖືກຕ້ອງ, ກະລຸນາປ້ອນໃຫ້ຄົບຖ້ວນ!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = UserProfile(
      name: name,
      phone: phone,
      avatarId: 1, // Default avatar 1
    );

    await DatabaseHelper.instance.createUser(user);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ລົງທະບຽນຫຼານ "$name" ສຳເລັດແລ້ວ! 🎉'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF38B264),
      ),
    );
    context.pop(); // Go back to login screen
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF3E8EF7)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'ລົງທະບຽນຜູ້ຫຼິ້ນ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppTheme.textColor,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              // Top illustration and texts
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPink.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.face_rounded,
                        size: 72,
                        color: AppTheme.primaryPink,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'ສ້າງໂປຣໄຟລ໌ໃໝ່',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ປ້ອນຊື່ ແລະ ເບີໂທລະສັບຜູ້ປົກຄອງ\nເພື່ອເກັບກຳຂໍ້ມູນການຮຽນຮູ້ຂອງຫຼານນ້ອຍ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: -0.1),
              const SizedBox(height: 32),

              // Block Form Fields Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100, width: 1.5),
                ),
                child: Column(
                  children: [
                    // Child's Name Input Block
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                      decoration: _buildInputDecoration(
                        labelText: 'ຊື່ຫຼານນ້ອຍ (ຊື່ຫຼິ້ນ)',
                        hintText: 'ພິມຊື່ຫຼານນ້ອຍຢູ່ນີ້',
                        prefixIcon: Icons.person_rounded,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Phone Number Input Block
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                      decoration: _buildInputDecoration(
                        labelText: 'ເບີໂທລະສັບຜູ້ປົກຄອງ',
                        hintText: 'ພິມເບີໂທ (ເຊັ່ນ: 020 99XXXXXX)',
                        prefixIcon: Icons.phone_iphone_rounded,
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: 150.ms),
              const SizedBox(height: 36),

              // Submit Registration Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38B264),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF38B264).withValues(alpha: 0.3),
                ),
                onPressed: _saveProfile,
                icon: const Icon(
                  Icons.app_registration_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                label: const Text(
                  'ລົງທະບຽນເລີຍ',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().scale(delay: 250.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
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
                      context.pop(); // Go back to login screen
                    },
                    child: const Text(
                      'ເຂົ້າສູ່ລະບົບ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3E8EF7),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ).animate().fade(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
