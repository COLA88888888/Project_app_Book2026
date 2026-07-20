import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/db_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../rewards/reward_room_screen.dart';
import 'developer_info_body.dart';
import 'dart:ui';

/// ============================================================================
/// 📱 [HomeScreen] - ໜ້າຈໍຫຼັກ (Main Screen) ຂອງແອັບພລິເຄຊັນ
/// ============================================================================
/// ໄຟລ໌ນີ້ເຮັດໜ້າທີ່ເປັນສູນກາງຂອງແອັບ ປະກອບມີ 3 ແຖບເມນູຫຼັກ (Bottom Navigation Tabs):
/// 1. ຫ້ອງຮຽນ (Classrooms Tab): ເລືອກຂັ້ນຮຽນ ປ.1 ຫຼື ປ.2 ເພື່ອເຂົ້າຮຽນ.
/// 2. ລາງວັນ (Reward Room Tab): ເບິ່ງຫ້ອງສະສົມດາວ ແລະ ຫຼຽນລາງວັນ.
/// 3. ຜູ້ພັດທະນາ (Developer Info Tab): ສະແດງຂໍ້ມູນຜູ້ພັດທະນາແອັບ.
/// ============================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// --------------------------------------------------------------------------
  /// ⚙️ ຕົວແປຈັດການສະຖານະ (State Variables)
  /// --------------------------------------------------------------------------
  String userName = ''; // ຕົວແປເກັບຊື່ຂອງຜູ້ໃຊ້ (ນັກຮຽນ) ເພື່ອນຳມາສະແດງໃນໜ້າຕ້ອນຮັບ
  int _currentIndex = 0; // ຕົວແປເກັບດັດສະນີແຖບເມນູປັດຈຸບັນ (0 = ຫ້ອງຮຽນ, 1 = ລາງວັນ, 2 = ຜູ້ພັດທະນາ)

  @override
  void initState() {
    super.initState();
    _loadUser(); // ເອີ້ນໂຫຼດຂໍ້ມູນຜູ້ໃຊ້ທັນທີເມື່ອ Widget ຖືກສ້າງຂຶ້ນ
  }

  /// --------------------------------------------------------------------------
  /// 🔍 ຟັງຊັນໂຫຼດຂໍ້ມູນຜູ້ໃຊ້ (Load User Profile)
  /// --------------------------------------------------------------------------
  /// ດຶງ ID ຜູ້ໃຊ້ປັດຈຸບັນຈາກ [SharedPreferences] ແລ້ວນຳໄປຄົ້ນຫາຂໍ້ມູນໃນຖານຂໍ້ມູນ SQLite [DatabaseHelper]
  /// ຖ້າບໍ່ພົບຂໍ້ມູນ ເພິ່ນຈະໃຊ້ຊື່ຄ່າເລີ່ມຕົ້ນເປັນ 'ນ້ອງນ້ອຍ'.
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('current_user_id') ?? 1; // ດຶງ ID ຜູ້ໃຊ້ (ຄ່າເລີ່ມຕົ້ນ 1)
    final fetchedUser = await DatabaseHelper.instance.readUser(userId); // ດຶງຂໍ້ມູນຈາກ SQLite
    setState(() {
      userName = fetchedUser?.name ?? prefs.getString('current_user_name') ?? 'ນ້ອງນ້ອຍ'; // ອັບເດດ State ຊື່ຜູ້ໃຊ້
    });
  }

  /// --------------------------------------------------------------------------
  /// 🏫 ວິຈິດສ້າງແຖບ "ຫ້ອງຮຽນ" (Classrooms Tab UI)
  /// --------------------------------------------------------------------------
  /// ປະກອບດ້ວຍ:
  /// - Header Banner: ກ່ອງຕ້ອນຮັບ "ແອັບຮຽນຮູ້ແສນສະໜຸກ 🌟" ພ້ອມ Icon ໂຮງຮຽນ
  /// - Title: ຂໍ້ຄວາມສອບຖາມ "ມື້ນີ້ຫຼານຢາກຮຽນຫຍັງດີນໍ້? 🌟"
  /// - List of Class Cards: Card ຫ້ອງຮຽນ ປ.1 ແລະ ປ.2
  Widget _buildClassroomsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------------------------------------------------------------------
        // 📌 ກ່ອງ Header Banner ສະແດງຂໍ້ມູນຕ້ອນຮັບ ແລະ ຫົວຂໍ້ແອັບ
        // ---------------------------------------------------------------------
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
              // ໄອຄອນໂຮງຮຽນ ພື້ນຫຼັງສີຂຽວອ່ອນ
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
              // ຂໍ້ຄວາມຕ້ອນຮັບ ແລະ ລາຍລະອຽດ
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
        ).animate().fade(duration: 500.ms).slideY(begin: -0.1), // Animation ເລື່ອນລົງ ແລະ ຄ່ອຍໆປາກົດ

        const SizedBox(height: 24),

        // ---------------------------------------------------------------------
        // 💬 ຂໍ້ຄວາມທັກທາຍກະຕຸ້ນຄວາມສົນໃຈຂອງນັກຮຽນ
        // ---------------------------------------------------------------------
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

        // ---------------------------------------------------------------------
        // 📚 ລາຍການ Card ຫ້ອງຮຽນ (ປ.1 ແລະ ປ.2) ທີ່ສາມາດກົດເຂົ້າໄປຮຽນໄດ້
        // ---------------------------------------------------------------------
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            physics: const BouncingScrollPhysics(), // ຜົນກະທົບການ Scroll ແບບເດ້ງຢືດຢຸ່ນ
            children: [
              // 🏫 Card ຫ້ອງຮຽນ ປ.1 (ໂທນສີຂຽວ)
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
                  // ນຳທາງໄປຫາໜ້າເລືອກວິຊາ ປ.1 ໂດຍໃຊ້ GoRouter
                  context.push('/subject/ປ.1');
                },
              ),

              const SizedBox(height: 20),

              // 📖 Card ຫ້ອງຮຽນ ປ.2 (ໂທນສີຟ້າ)
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
                  // ນຳທາງໄປຫາໜ້າເລືອກວິຊາ ປ.2 ໂດຍໃຊ້ GoRouter
                  context.push('/subject/ປ.2');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// --------------------------------------------------------------------------
  /// 🎨 ວິຈິດສ້າງ Bottom Navigation Bar ແບບ Glassmorphism (Bubbly Style)
  /// --------------------------------------------------------------------------
  /// ແຖບເມນູລຸ່ມທີ່ສະແດງຄວາມສວຍງາມດ້ວຍ Glassmorphic Blur, ຄວາມໂຄ້ງມົນ,
  /// ພ້ອມກັບແສງ Glow Shadow ທີ່ປ່ຽນສີຕາມ Tab ທີ່ກຳລັງເລືອກ (Dynamic Active Color).
  Widget _buildBubblyBottomNavBar() {
    // ກຳນົດສີ Glow ຂອງແຖບເມນູຕາມ Tab ທີ່ເລືອກປັດຈຸບັນ
    Color activeColor = const Color(0xFF38B264); // ສີຂຽວ ສຳລັບ ຫ້ອງຮຽນ (Index 0)
    if (_currentIndex == 1) activeColor = const Color(0xFFEAB308); // ສີເຫຼືອງ/ທອງ ສຳລັບ ລາງວັນ (Index 1)
    if (_currentIndex == 2) activeColor = const Color(0xFF3E8EF7); // ສີຟ້າ ສຳລັບ ຜູ້ພັດທະນາ (Index 2)

    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          // ຜົນກະທົບເງົາມົນສະຫວ່າງ (Ambient Glow Shadow)
          BoxShadow(
            color: activeColor.withValues(alpha: 0.15),
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
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), // ຜົນກະທົບເບຼີ Glassmorphism
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9), // ພື້ນຫຼັງສີຂາວໂປ່ງແສງ
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // ປຸ່ມແຖບ 0: ຫ້ອງຮຽນ
                _buildNavItem(0, Icons.school_rounded, 'ຫ້ອງຮຽນ', const Color(0xFF38B264)),
                // ປຸ່ມແຖບ 1: ລາງວັນ
                _buildNavItem(1, Icons.stars_rounded, 'ລາງວັນ', const Color(0xFFEAB308)),
                // ປຸ່ມແຖບ 2: ຜູ້ພັດທະນາ
                _buildNavItem(2, Icons.info_rounded, 'ຜູ້ພັດທະນາ', const Color(0xFF3E8EF7)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// 🔘 ວິຈິດສ້າງແຕ່ລະປຸ່ມເມນູໃນ Bottom Navigation Bar
  /// --------------------------------------------------------------------------
  /// - [index]: ໝາຍເລກ Index ຂອງ Tab (0, 1, 2)
  /// - [icon]: ໄອຄອນສະແດງຜົນ
  /// - [label]: ຊື່ແຖບເມນູ
  /// - [activeColor]: ສີປະຈຳ Tab ເມື່ອຖືກເລືອກ
  Widget _buildNavItem(int index, IconData icon, String label, Color activeColor) {
    final isSelected = _currentIndex == index; // ກວດສອບວ່າມັນແມ່ນ Tab ທີ່ກຳລັງເລືອກຢູ່ບໍ

    return GestureDetector(
      onTap: () {
        // ເມື່ອກົດປຸ່ມ ອັບເດດ _currentIndex ເພື່ອປ່ຽນ Tab
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isSelected ? 1.08 : 1.0, // ຜົນກະທົບຂະຫຍາຍ 1.08x ເມື່ອ Tab ຖືກເລືອກ
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: 76,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ໄອຄອນ ພ້ອມພື້ນຫຼັງສີອ່ອນ circular glow ເມື່ອຖືກເລືອກ
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

              // ຊື່ຂອງ Tab
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

              // ເສັ້ນຂີດນ້ອຍໆ ດ້ານລຸ່ມສະແດງວ່າ Tab ນີ້ active ຢູ່
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

  /// --------------------------------------------------------------------------
  /// 🏗️ ຟັງຊັນ build() ຫຼັກຂອງ HomeScreen
  /// --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), // ພື້ນຫຼັງສີເທົາ/ຂາວ pastel ສະບາຍຕາ
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 20.0, right: 20.0),
          // ໃຊ້ IndexedStack ເພື່ອສະຫຼັບໜ້າແຖບເມນູລຸ່ມໂດຍບໍ່ຕ້ອງເປີດໜ້າຈໍໃໝ່ (ຮັກສາສະຖານະໜ້າເກົ່າໄວ້)
          child: IndexedStack(
            index: _currentIndex, // ສະແດງໜ້າຕາມ index ປັດຈຸບັນ
            children: [
              _buildClassroomsTab(), // ໜ້າເລືອກຫ້ອງຮຽນ (Index 0)
              const RewardRoomBody(showBackButton: false), // ໜ້າຫ້ອງລາງວັນ (Index 1)
              const DeveloperInfoBody(), // ໜ້າສະແດງຂໍ້ມູນຜູ້ພັດທະນາ (Index 2)
            ],
          ),
        ),
      ),
      // ແຖບເມນູນຳທາງລຸ່ມສຸດ (Bubbly Bottom Navigation Bar)
      bottomNavigationBar: _buildBubblyBottomNavBar(),
    );
  }
}

/// ============================================================================
/// 🎴 [HomeWideCard] - Widget Card ຂະໜາດໃຫຍ່ສຳລັບເລືອກຫ້ອງຮຽນ (ປ.1, ປ.2)
/// ============================================================================
/// Widget ນີ້ມີຜົນກະທົບ Touch Animation ງາມໆ ເມື່ອກົດ (Scale Down 0.96)
/// ພ້ອມ Gradient color, Shadow, Icon, Title, Subtitle ແລະ Staggered Animation.
/// ============================================================================
class HomeWideCard extends StatefulWidget {
  final String title; // ຫົວຂໍ້ Card (ເຊັ່ນ: 'ຫ້ອງຮຽນ ປ.1 🏫')
  final String subtitle; // ຄຳອະທິບາຍ (ເຊັ່ນ: 'ຮຽນອ່ານ, ພາສາລາວ...')
  final List<Color> gradientColors; // ບັນຊີລາຍຊື່ສີ Gradient ພື້ນຫຼັງ
  final IconData icon; // ໄອຄອນປະຈຳ Card
  final VoidCallback onTap; // ຟັງຊັນ CallBack ເມື່ອກົດ Card
  final int index; // ດັດສະນີສຳລັບຄິດໄລ່ Animation Delay

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
  double _scale = 1.0; // ຕົວແປຂະໜາດ Scale ຂອງ Card (1.0 = ຂະໜາດປົກຕິ, 0.96 = ຕອນກົດ)

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ເມື່ອກົດລົງ ເຮັດໃຫ້ Card ຫຍໍ້ຕົວລົງ (0.96)
      onTapDown: (_) => setState(() => _scale = 0.96),
      // ເມື່ອປ່ອຍ ຫຼື ຍົກເລີກ ໃຫ້ Card ກັບມາຂະໜາດປົກຕິ (1.0)
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap, // ເອີ້ນຟັງຊັນນຳທາງ ເມື່ອກົດ
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            // ສີ Gradient ແບບອຽງຈາກ Top-Left ໄປ Bottom-Right
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradientColors,
            ),
            boxShadow: [
              // ເງົາມົນສີດຽວກັບ Gradient ເພື່ອຄວາມສວຍງາມ
              BoxShadow(
                color: widget.gradientColors.first.withValues(alpha: 0.35),
                offset: const Offset(0, 8),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            children: [
              // ກ່ອງໄອຄອນພື້ນຫຼັງຂາວ ໂປ່ງແສງ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(widget.icon, size: 48, color: Colors.white),
              ),
              const SizedBox(width: 20),

              // ສ່ວນສະແດງ ຫົວຂໍ້ (Title) ແລະ ຄຳອະທິບາຍ (Subtitle)
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

              // ໄອຄອນ ລູກສອນໄປທາງໜ້າ
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
        ); // Animation ຄ່ອຍໆເລື່ອນຂຶ້ນ ແລະ ແຍກເວລາຕາມ Index
  }
}

