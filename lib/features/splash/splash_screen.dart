import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEBF3FE), // Soft blue sky
              Color(0xFFFFF2F5), // Soft pastel blush pink
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Animated Logo Container
              Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF3E8EF7,
                          ).withValues(alpha: 0.12),
                          blurRadius: 30,
                          spreadRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 80,
                      color: Color(0xFF3E8EF7),
                    ),
                  )
                  .animate()
                  .scale(duration: 900.ms, curve: Curves.elasticOut)
                  .then()
                  .shake(duration: 400.ms),
              const SizedBox(height: 28),

              // App Title Lao
              const Text(
                    'ແອັບຮຽນຮູ້ແສນສະໜຸກ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  )
                  .animate()
                  .fade(duration: 600.ms, delay: 300.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'ຮຽນຮູ້, ຫຼິ້ນເກມ & ສະສົມລາງວັນ 🌟',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ).animate().fade(duration: 600.ms, delay: 500.ms),
              const SizedBox(height: 48),

              // Custom Progress Indicator
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF3E8EF7),
                  ),
                  backgroundColor: const Color(
                    0xFF3E8EF7,
                  ).withValues(alpha: 0.1),
                ),
              ).animate().fade(duration: 400.ms, delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}
