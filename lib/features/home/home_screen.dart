import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/db_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../rewards/reward_room_screen.dart';
import 'developer_info_body.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  int _currentIndex = 0;
  int userAvatarId = 1;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('current_user_id') ?? 1;
    final fetchedUser = await DatabaseHelper.instance.readUser(userId);
    setState(() {
      userName = fetchedUser?.name ?? prefs.getString('current_user_name') ?? 'ນ້ອງນ້ອຍ';
      userAvatarId = fetchedUser?.avatarId ?? 1;
    });
  }

  Widget _buildClassroomsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 32,
                  color: Color(0xFF38B264),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ແອັບຮຽນຮູ້ແສນສະໜຸກ 🌟',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ຮຽນຮູ້, ຫຼິ້ນເກມ & ສະສົມລາງວັນ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
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
        // Large prominent classrooms blocks
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            physics: const BouncingScrollPhysics(),
            children: [
              HomeWideCard(
                title: 'ຫ້ອງຮຽນ ປ.1 🏫',
                subtitle: 'ຮຽນອ່ານ, ພາສາລາວ ແລະ ຄະນິດສາດ ປ.1 ແສນສະໜຸກ 📚',
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
              const SizedBox(height: 20),
              HomeWideCard(
                title: 'ຫ້ອງຮຽນ ປ.2 📖',
                subtitle: 'ຮຽນຮູ້ສະຫຼະມີຕົວສະກົດ, ບັ້ງສູດ ແລະ ການຫານ ປ.2 🧮',
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBubblyBottomNavBar() {
    // Dynamic glow color based on the selected index
    Color activeColor = const Color(0xFF38B264);
    if (_currentIndex == 1) activeColor = const Color(0xFFEAB308);
    if (_currentIndex == 2) activeColor = const Color(0xFF3E8EF7);

    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.15), // Dynamic ambient glow shadow!
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.school_rounded, 'ຫ້ອງຮຽນ', const Color(0xFF38B264)),
                _buildNavItem(1, Icons.stars_rounded, 'ລາງວັນ', const Color(0xFFEAB308)),
                _buildNavItem(2, Icons.info_rounded, 'ຜູ້ພັດທະນາ', const Color(0xFF3E8EF7)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color activeColor) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isSelected ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container with soft background glow when selected
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? activeColor : Colors.grey.shade400,
                  size: 28,
                ),
              ),
              const SizedBox(height: 4),
              // Label
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? activeColor : Colors.grey.shade500,
                  fontWeight: isSelected ? FontWeight.bold : const Color(0xFFEAB308) == activeColor ? FontWeight.w500 : FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              // Active indicator line
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 14 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 20.0, right: 20.0),
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildClassroomsTab(),
              const RewardRoomBody(showBackButton: false),
              const DeveloperInfoBody(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBubblyBottomNavBar(),
    );
  }
}

class HomeWideCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final IconData icon;
  final VoidCallback onTap;
  final int index;

  const HomeWideCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.icon,
    required this.onTap,
    required this.index,
  });

  @override
  State<HomeWideCard> createState() => _HomeWideCardState();
}

class _HomeWideCardState extends State<HomeWideCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors.first.withValues(alpha: 0.35),
                offset: const Offset(0, 8),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(widget.icon, size: 48, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Color(0x33000000),
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 400.ms, delay: (100 * widget.index).ms).slideY(
          begin: 0.15,
          end: 0,
          curve: Curves.easeOutBack,
        );
  }
}
