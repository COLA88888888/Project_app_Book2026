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

  @override
  void initState() {
    super.initState();
    _loadProfiles();
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
    if (phoneInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ກະລຸນາປ້ອນເບີໂທລະສັບເພື່ອເຂົ້າສູ່ລະບົບເດີ້!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

    if (matchedUser != null) {
      await _loginAs(matchedUser);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ບໍ່ພົບເບີໂທລະສັບນີ້ໃນລະບົບ! ກະລຸນາກວດສອບ ຫຼື ລົງທະບຽນໃໝ່',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loginAs(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_user_id', user.id!);
    await prefs.setString('current_user_name', user.name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ຍິນດີຕ້ອນຮັບ, ຫຼານ "${user.name}"! 👋'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF3E8EF7),
      ),
    );
    context.go('/home');
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
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E8EF7).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 60,
                        color: Color(0xFF3E8EF7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ເຂົ້າສູ່ລະບົບ',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ປ້ອນເບີໂທລະສັບຜູ້ປົກຄອງເພື່ອເລີ່ມຮຽນຮູ້',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: -0.1),
              const SizedBox(height: 32),

              // Login Input Block Card
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
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                      decoration: InputDecoration(
                        labelText: 'ເບີໂທລະສັບຜູ້ປົກຄອງ',
                        hintText: 'ປ້ອນເບີໂທ (ເຊັ່ນ: 020 99XXXXXX)',
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        prefixIcon: const Icon(
                          Icons.phone_iphone_rounded,
                          color: Color(0xFF3E8EF7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF3E8EF7),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Login Button inside form card
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3E8EF7),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          shadowColor: const Color(
                            0xFF3E8EF7,
                          ).withValues(alpha: 0.3),
                        ),
                        onPressed: _loginWithPhone,
                        icon: const Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                        ),
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
              ).animate().fade(delay: 100.ms),
              const SizedBox(height: 32),

              // Quick Selection Section
              if (profiles.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'ຫຼື ເລືອກຜູ້ຫຼິ້ນທີ່ມີຢູ່ແລ້ວ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ).animate().fade(delay: 150.ms),
                const SizedBox(height: 20),

                // Horizontal list of quick profiles
                SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      final user = profiles[index];
                      return Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 14, bottom: 6),
                        child: GestureDetector(
                          onTap: () => _loginAs(user),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: AppTheme.primaryBlue.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.primaryPink,
                                  child: Icon(
                                    Icons.face,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.phone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ).animate().fade(delay: 200.ms),
              ],

              const SizedBox(height: 24),
              // Bottom Register Navigation Row
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
                      _loadProfiles(); // Reload profiles after coming back
                    },
                    child: const Text(
                      'ລົງທະບຽນເລີຍ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF38B264),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
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
