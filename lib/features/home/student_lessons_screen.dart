import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/lesson.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StudentLessonsScreen extends StatefulWidget {
  final String grade; // 'P1' or 'P2'
  final String subject; // 'Lao' or 'Math'

  const StudentLessonsScreen({
    super.key,
    required this.grade,
    required this.subject,
  });

  @override
  State<StudentLessonsScreen> createState() => _StudentLessonsScreenState();
}

class _StudentLessonsScreenState extends State<StudentLessonsScreen> {
  List<Lesson> lessons = []; // ຕົວແປເກັບລາຍຊື່ບົດຮຽນທັງໝົດທີ່ດຶງມາຈາກຖານຂໍ້ມູນ
  Map<int, int> progressStars = {}; // ຕົວແປເກັບດາວທີ່ຫຼິ້ນໄດ້ຂອງແຕ່ລະບົດຮຽນ (lessonId -> starsEarned)
  bool isLoading = true; // ສະຖານະການໂຫຼດຂໍ້ມູນ (true = ກຳລັງໂຫຼດ, false = ໂຫຼດແລ້ວ)
  int currentUserId = 0; // ID ຂອງຜູ້ໃຊ້ປັດຈຸບັນ

  @override
  void initState() {
    super.initState();
    _initData(); // ເອີ້ນໃຊ້ຟັງຊັນໂຫຼດຂໍ້ມູນເລີ່ມຕົ້ນ
  }

  // ຟັງຊັນດຶງຂໍ້ມູນບົດຮຽນ ແລະ ຄະແນນດາວທັງໝົດມາສະແດງ
  Future<void> _initData() async {
    // 1. ກວດສອບ ແລະ ສ້າງບົດຮຽນເລີ່ມຕົ້ນຫາກຍັງບໍ່ທັນມີຂໍ້ມູນໃນ DB
    await DatabaseHelper.instance.seedInitialLessonsIfEmpty();

    // 2. ດຶງຂໍ້ມູນ ID ຜູ້ໃຊ້ປັດຈຸບັນຈາກ SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('current_user_id') ?? 1;

    // 3. ດຶງຂໍ້ມູນບົດຮຽນທັງໝົດຈາກຖານຂໍ້ມູນ
    final allLessons = await DatabaseHelper.instance.getAllLessons();
    
    // ກັ່ນຕອງ (Filter) ເອົາສະເພາະບົດຮຽນທີ່ກົງກັບຊັ້ນຮຽນ ແລະ ວິຊາທີ່ເລືອກ
    final filtered = allLessons.where((lesson) {
      return lesson.grade == widget.grade && lesson.subject == widget.subject;
    }).toList();

    // 4. ດຶງຈຳນວນດາວທີ່ຫຼານນ້ອຍເຄີຍຫຼິ້ນໄດ້ໃນແຕ່ລະບົດຮຽນ
    final Map<int, int> starsMap = {};
    for (var lesson in filtered) {
      final stars = await DatabaseHelper.instance.getLessonProgressStars(
        currentUserId,
        lesson.id!,
      );
      starsMap[lesson.id!] = stars; // ບັນທຶກຄ່າດາວໃສ່ Map
    }

    // ອັບເດດໜ້າຈໍດ້ວຍຂໍ້ມູນໃໝ່
    setState(() {
      lessons = filtered;
      progressStars = starsMap;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjectTitle = widget.subject == 'Lao'
        ? 'ພາສາລາວ'
        : widget.subject == 'Math'
            ? 'ຄະນິດສາດ'
            : widget.subject;
    final gradeTitle = widget.grade == 'P1' ? 'ປ.1' : 'ປ.2';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          '$subjectTitle ($gradeTitle)',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppTheme.textColor,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppTheme.textColor,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : lessons.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                itemCount: lessons.length,
                itemBuilder: (context, index) {
                  final lesson = lessons[index]; // ດຶງຂໍ້ມູນບົດຮຽນແຕ່ລະຂໍ້ຕາມ index
                  final earnedStars = progressStars[lesson.id!] ?? 0; // ດຶງດາວທີ່ໄດ້ຮັບ (ຖ້າບໍ່ມີໃຫ້ເປັນ 0)

                  // ─── ຕັ້ງຄ່າຮູບແບບສີສັນ ແລະ ສະຖານະ (Soft Pastel 3-State Styling) ───
                  final Color borderColor;
                  final Color iconBgColor;
                  final IconData iconData;
                  final Color iconColor;
                  final Color badgeBgColor;
                  final String badgeText;
                  final Color badgeTextColor;

                  if (earnedStars == 3) {
                    // ສະຖານະທີ 1: ຮຽນຜ່ານແລ້ວ (ໄດ້ 3 ດາວເຕັມ) -> ໃຊ້ໂທນສີຂຽວ Pastel
                    borderColor = const Color(0xFFC3E6CB); // ຂອບສີຂຽວອ່ອນ
                    iconBgColor = const Color(0xFFE8F5E9); // ພື້ນຫຼັງໄອຄອນສີຂຽວຈາງ
                    iconData = Icons.check_circle_rounded; // ໄອຄອນຕິກຖືກ
                    iconColor = const Color(0xFF2E7D32); // ໄອຄອນສີຂຽວເຂັ້ມ
                    badgeBgColor = const Color(0xFFE8F5E9);
                    badgeText = 'ຜ່ານແລ້ວ 🎉';
                    badgeTextColor = const Color(0xFF2E7D32);
                  } else if (earnedStars > 0) {
                    // ສະຖານະທີ 2: ຍັງຮຽນບໍ່ທັນຜ່ານ (ໄດ້ 1 ຫຼື 2 ດາວ) -> ໃຊ້ໂທນສີເຫຼືອງ/ສົ້ມ Pastel
                    borderColor = const Color(0xFFFFD54F); // ຂອບສີເຫຼືອງ
                    iconBgColor = const Color(0xFFFFF8E1); // ພື້ນຫຼັງໄອຄອນສີເຫຼືອງຈາງ
                    iconData = Icons.star_half_rounded; // ໄອຄອນເຄິ່ງດາວ
                    iconColor = const Color(0xFFD97706); // ໄອຄອນສີສົ້ມເຂັ້ມ
                    badgeBgColor = const Color(0xFFFFF8E1);
                    badgeText = 'ຍັງບໍ່ຜ່ານ ⚠️';
                    badgeTextColor = const Color(0xFFD97706);
                  } else {
                    // ສະຖານະທີ 3: ຍັງບໍ່ໄດ້ຮຽນ (ໄດ້ 0 ດາວ) -> ໃຊ້ໂທນສີເທົາ Pastel
                    borderColor = Colors.grey.shade200; // ຂອບສີເທົາອ່ອນ
                    iconBgColor = const Color(0xFFF1F3F9);
                    iconData = Icons.play_arrow_rounded; // ໄອຄອນປຸ່ມ Play
                    iconColor = Colors.grey.shade500;
                    badgeBgColor = Colors.grey.shade100;
                    badgeText = 'ຍັງບໍ່ໄດ້ຮຽນ 📚';
                    badgeTextColor = Colors.grey.shade600;
                  }

                  return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: borderColor, // ນຳໃຊ້ສີຂອບຕາມສະຖານະ
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                // ເມື່ອກົດເລືອກບົດຮຽນ ໃຫ້ລິ້ງໄປຫາໜ້າຈໍຫຼິ້ນເກມບົດຮຽນ (/play-lesson/id)
                                await context.push('/play-lesson/${lesson.id}');
                                _initData(); // ເມື່ອກັບຄືນມາ ໃຫ້ໂຫຼດຂໍ້ມູນຄະແນນດາວໃໝ່ ເພື່ອອັບເດດສະຖານະການຫຼິ້ນ
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  children: [
                                    // Play icon circular container
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: iconBgColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        iconData,
                                        size: 32,
                                        color: iconColor,
                                      ),
                                    ),
                                    const SizedBox(width: 18),
                                    // Details column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Status badge text
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badgeBgColor,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              badgeText,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: badgeTextColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Title
                                          Text(
                                            lesson.title,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textColor,
                                              height: 1.25,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Stars Progress row
                                          Row(
                                            children: [
                                              Text(
                                                'ດາວຂອງຫຼານ: ',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Row(
                                                children: List.generate(
                                                  lesson.totalStars,
                                                  (i) => Icon(
                                                    Icons.star_rounded,
                                                    color: i < earnedStars
                                                        ? const Color(
                                                            0xFFF59E0B,
                                                          )
                                                        : Colors.grey.shade300,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fade(duration: 400.ms, delay: (80 * index).ms)
                      .slideY(begin: 0.1, end: 0);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_rounded, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'ຍັງບໍ່ມີບົດຮຽນ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ກະລຸນາຕິດຕໍ່ຜູ້ປົກຄອງເພື່ອເພີ່ມບົດຮຽນໃນລະບົບຫຼັງບ້ານ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
