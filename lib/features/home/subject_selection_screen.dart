import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/db_helper.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SubjectSelectionScreen extends StatefulWidget {
  final String grade; // ຂັ້ນຮຽນທີ່ສົ່ງເຂົ້າມາ ເຊັ່ນ: 'ປ.1' ຫຼື 'ປ.2'

  const SubjectSelectionScreen({super.key, required this.grade});

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  List<String> subjects = []; // ຕົວແປເກັບລາຍຊື່ວິຊາຮຽນ
  bool isLoading = true; // ສະຖານະກຳລັງໂຫຼດຂໍ້ມູນ

  @override
  void initState() {
    super.initState();
    _loadSubjects(); // ເອີ້ນໃຊ້ຟັງຊັນໂຫຼດຂໍ້ມູນເມື່ອເລີ່ມຕົ້ນໜ້າຈໍ
  }

  // ຟັງຊັນໂຫຼດຂໍ້ມູນວິຊາຈາກຖານຂໍ້ມູນ SQLite
  Future<void> _loadSubjects() async {
    // 1. ກວດສອບ ແລະ ໃສ່ຂໍ້ມູນເລີ່ມຕົ້ນ ຫາກຖານຂໍ້ມູນຫວ່າງເປົ່າ
    await DatabaseHelper.instance.seedInitialLessonsIfEmpty();

    // 2. ດຶງຂໍ້ມູນວິຊາຮຽນຂອງຂັ້ນຮຽນປັດຈຸບັນ (ປ່ຽນ ປ.1 ເປັນ P1, ປ.2 ເປັນ P2 ເພື່ອຄົ້ນຫາໃນ DB)
    final dbGrade = widget.grade == 'ປ.1' ? 'P1' : 'P2';
    final data = await DatabaseHelper.instance.getSubjectsForGrade(dbGrade);

    setState(() {
      subjects = data; // ເກັບຂໍ້ມູນວິຊາທີ່ດຶງມາໄດ້
      isLoading = false; // ປ່ຽນສະຖານະການໂຫຼດຂໍ້ມູນເປັນສຳເລັດ
    });
  }

  // ຟັງຊັນກຳນົດຄ່າສະແດງຜົນຂອງແຕ່ລະວິຊາ (ສີ Gradient, ໄອຄອນ, ຄຳອະທິບາຍ)
  _SubjectCardConfig _getSubjectConfig(String subject) {
    if (subject == 'Lao' || subject == 'ພາສາລາວ') {
      return _SubjectCardConfig(
        title: 'ພາສາລາວ',
        subtitle: 'ຮຽນອ່ານ, ພະຍັນຊະນະ, ສະຫຼະ ແລະ ແຕ່ງປະໂຫຍກ 📖',
        gradientColors: const [
          Color(0xFFFF8A80),
          Color(0xFFFF5252),
        ],
        icon: Icons.menu_book_rounded,
      );
    } else if (subject == 'Math' || subject == 'ຄະນິດສາດ') {
      return _SubjectCardConfig(
        title: 'ຄະນິດສາດ',
        subtitle: 'ຮຽນນັບເລກ, ການບວກ, ການລົບ ແລະ ສູດຄູນ 🧮',
        gradientColors: const [
          Color(0xFF6EBEFB),
          Color(0xFF3E8EF7),
        ],
        icon: Icons.calculate_rounded,
      );
    } else {
      // ກໍລະນີມີວິຊາອື່ນໆ ທີ່ເພີ່ມເຂົ້າມາໃໝ່ (ໃຊ້ໂທນສີມ່ວງ Premium)
      return _SubjectCardConfig(
        title: subject,
        subtitle: 'ບົດຮຽນແສນສະໜຸກໃນວິຊາ $subject 🌟',
        gradientColors: const [
          Color(0xFFB19FFB),
          Color(0xFF7C4DFF),
        ],
        icon: Icons.auto_stories_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbGrade = widget.grade == 'ປ.1' ? 'P1' : 'P2';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          'ເລືອກວິຊາ (${widget.grade})',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppTheme.textColor,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        // ====================================================
        // [ສ່ວນປິດ / ກັບຄືນ]: ປຸ່ມກົດກັບຄືນໄປໜ້າກ່ອນໜ້າ (ໜ້າເລືອກຫ້ອງຮຽນ)
        // ====================================================
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppTheme.textColor,
          ),
          onPressed: () => context.pop(), // ປິດໜ້ານີ້ ແລະ ກັບຄືນໄປໜ້າກ່ອນໜ້າ
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator()) // ສະແດງຕົວໂຫຼດຂໍ້ມູນ
            : subjects.isEmpty
                ? _buildEmptyState() // ສະແດງໜ້າຫວ່າງເປົ່າ ຫາກບໍ່ມີຂໍ້ມູນວິຊາ
                : Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'ມື້ນີ້ຫຼານຢາກຮຽນວິຊາຫຍັງ? 📚',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ).animate().fade(duration: 400.ms).slideY(begin: -0.1),
                        const SizedBox(height: 36),

                        // ====================================================
                        // [ສ່ວນສະແດງລາຍການວິຊາ]: ດຶງຂໍ້ມູນມາສະແດງເປັນບັດແຕ່ລະວິຊາ
                        // ====================================================
                        Expanded(
                          child: ListView.builder(
                            itemCount: subjects.length,
                            itemBuilder: (context, index) {
                              final sub = subjects[index];
                              final config = _getSubjectConfig(sub);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _buildSubjectCard(
                                  context: context,
                                  title: config.title,
                                  subtitle: config.subtitle,
                                  gradientColors: config.gradientColors,
                                  icon: config.icon,
                                  index: index,
                                  onTap: () {
                                    // ເມື່ອກົດເລືອກວິຊາ: ຈະເປີດໜ້າບົດຮຽນ (LessonsScreen) ໂດຍສົ່ງ dbGrade ແລະ ວິຊາໄປ
                                    context.push('/lessons/$dbGrade/$sub');
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  // ສ້າງບັດສະແດງຜົນຂອງແຕ່ລະວິຊາ
  Widget _buildSubjectCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required IconData icon,
    required int index,
    required VoidCallback onTap,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        double scale = 1.0;
        return GestureDetector(
          onTapDown: (_) => setState(() => scale = 0.96), // ຫຍໍ້ຂະໜາດລົງເລັກນ້ອຍຕອນແຕະ
          onTapUp: (_) => setState(() => scale = 1.0),
          onTapCancel: () => setState(() => scale = 1.0),
          onTap: onTap,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withValues(alpha: 0.35),
                    offset: const Offset(0, 8),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ໄອຄອນປະຈຳວິຊາ
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, size: 48, color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  // ລາຍລະອຽດຂໍ້ຄວາມ (ຊື່ວິຊາ ແລະ ຄຳອະທິບາຍ)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Color(0x40000000),
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                            height: 1.2,
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
        );
      },
    ).animate().fade(duration: 450.ms, delay: (120 * index).ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutBack);
  }

  // ສ້າງ Widget ສະແດງຜົນເມື່ອບໍ່ມີຂໍ້ມູນວິຊາຮຽນ
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_rounded, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'ບໍ່ມີວິຊາຮຽນເທື່ອ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ກະລຸນາຕິດຕໍ່ຜູ້ປົກຄອງເພື່ອເພີ່ມວິຊາ ແລະ ບົດຮຽນໃນລະບົບຫຼັງບ້ານ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCardConfig {
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final IconData icon;

  _SubjectCardConfig({
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.icon,
  });
}
