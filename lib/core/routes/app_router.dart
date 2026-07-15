import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/subject_selection_screen.dart';
import '../../features/rewards/reward_room_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/home/student_lessons_screen.dart';
import '../../features/home/lesson_play_screen.dart';

// ── ຕາຕະລາງໜ້າຈໍທັງໝົດ (Navigation Routes) ──────────────
// ── ສ້າງໂຕແປ appRouter ເພື່ອຄຸ້ມຄອງການປ່ຽນໜ້າຈໍພາຍໃນແອັບ ─────────────────────────────
final appRouter = GoRouter(
  // ກຳນົດໜ້າຈໍທຳອິດເມື່ອເປີດແອັບ (ເລີ່ມທີ່ '/' ເຊິ່ງກໍຄື SplashScreen)
  initialLocation: '/',
  routes: [
    // 1. ໜ້າ Splash Screen: ໜ້າສະແດງໂລໂກ້ ແລະ ໂຫຼດຂໍ້ມູນເລີ່ມຕົ້ນ
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    
    // 2. ໜ້າ Home Screen: ໜ້າຈໍຫຼັກຂອງແອັບ
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    
    // 3. ໜ້າ Subject Selection: ໜ້າເລືອກວິຊາຮຽນ (ເຊັ່ນ: ປ.1 ຫຼື ປ.2)
    GoRoute(
      path: '/subject/:grade',
      builder: (context, state) =>
          SubjectSelectionScreen(grade: state.pathParameters['grade'] ?? 'ປ.1'),
    ),
    
    // 4. ໜ້າ Student Lessons List: ໜ້າສະແດງລາຍການບົດຮຽນຕາມວິຊາ ແລະ ຊັ້ນຮຽນ
    GoRoute(
      path: '/lessons/:grade/:subject',
      builder: (context, state) => StudentLessonsScreen(
        grade: state.pathParameters['grade'] ?? 'P1',
        subject: state.pathParameters['subject'] ?? 'Lao',
      ),
    ),
    
    // 5. ໜ້າ Lesson Play Screen: ໜ້າຫຼິ້ນບົດຮຽນ, ອ່ານປຶ້ມ ຫຼື ຕອບຄຳຖາມ
    GoRoute(
      path: '/play-lesson/:lessonId',
      builder: (context, state) =>
          LessonPlayScreen(lessonId: state.pathParameters['lessonId'] ?? '1'),
    ),
    
    // 6. ໜ້າ Reward Room: ໜ້າຫ້ອງສະສົມລາງວັນຂອງຫຼານນ້ອຍ
    GoRoute(
      path: '/rewards',
      builder: (context, state) => const RewardRoomScreen(),
    ),
  ],
);
