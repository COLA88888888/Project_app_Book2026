import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('current_user_name') ?? 'ນ້ອງນ້ອຍ';
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    await prefs.remove('current_user_name');
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Beautiful Header Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryPink.withValues(alpha: 0.5),
                          width: 3,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 26,
                        backgroundColor: AppTheme.primaryPink,
                        child: Icon(Icons.face, size: 36, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ສະບາຍດີ, ຫຼານນ້ອຍ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.logout,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                      ),
                      onPressed: _logout,
                      tooltip: 'ປ່ຽນຜູ້ຫຼິ້ນ',
                    ),
                  ],
                ),
              ).animate().fade(duration: 500.ms).slideY(begin: -0.1),
              const SizedBox(height: 24),
              // Action Subtitle
              const Text(
                'ມື້ນີ້ຫຼານຢາກຮຽນຫຍັງດີນໍ້? 🌟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ).animate().fade(duration: 500.ms, delay: 100.ms),
              const SizedBox(height: 20),
              // 2x2 Grid of Beautiful Rectangular Blocks
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: [
                    HomeBlockCard(
                      title: 'ຫ້ອງຮຽນ ປ.1',
                      subtitle: 'ອ່ານ & ພາສາລາວ & ເລກ ປ.1 📚',
                      gradientColors: const [
                        Color(0xFF5CDA89),
                        Color(0xFF38B264),
                      ],
                      icon: Icons.school_rounded,
                      index: 0,
                      onTap: () {
                        context.push('/subject/ປ.1');
                      },
                    ),
                    HomeBlockCard(
                      title: 'ຫ້ອງຮຽນ ປ.2',
                      subtitle: 'ພາສາລາວ & ເລກ ປ.2',
                      gradientColors: const [
                        Color(0xFF6EBEFB),
                        Color(0xFF3E8EF7),
                      ],
                      icon: Icons.auto_stories_rounded,
                      index: 1,
                      onTap: () {
                        context.push('/subject/ປ.2');
                      },
                    ),
                    HomeBlockCard(
                      title: 'ຫ້ອງລາງວັນ',
                      subtitle: 'ສະສົມສະຕິກເກີ 🏅',
                      gradientColors: const [
                        Color(0xFFFCD34D),
                        Color(0xFFF59E0B),
                      ],
                      icon: Icons.stars_rounded,
                      index: 2,
                      onTap: () {
                        context.push('/rewards');
                      },
                    ),
                    HomeBlockCard(
                      title: 'ຜູ້ປົກຄອງ',
                      subtitle: 'ການຕັ້ງຄ່າ & ຫຼັງບ້ານ',
                      gradientColors: const [
                        Color(0xFFFFA4A4),
                        Color(0xFFFF6B6B),
                      ],
                      icon: Icons.family_restroom_rounded,
                      index: 3,
                      onTap: () {
                        context.push('/parent-gateway');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeBlockCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final IconData icon;
  final VoidCallback onTap;
  final int index;

  const HomeBlockCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.icon,
    required this.onTap,
    required this.index,
  });

  @override
  State<HomeBlockCard> createState() => _HomeBlockCardState();
}

class _HomeBlockCardState extends State<HomeBlockCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTapDown: (_) => setState(() => _scale = 0.95),
          onTapUp: (_) => setState(() => _scale = 1.0),
          onTapCancel: () => setState(() => _scale = 1.0),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.gradientColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradientColors.first.withValues(alpha: 0.3),
                    offset: const Offset(0, 6),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, size: 32, color: Colors.white),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Color(0x40000000),
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fade(duration: 400.ms, delay: (100 * widget.index).ms)
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }
}
