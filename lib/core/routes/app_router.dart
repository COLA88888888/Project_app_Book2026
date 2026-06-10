import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/subject_selection_screen.dart';
import '../../features/rewards/reward_room_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/add_profile_screen.dart';
import '../../features/auth/edit_profile_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/home/student_lessons_screen.dart';
import '../../features/home/lesson_play_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/add-profile',
      builder: (context, state) => const AddProfileScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => EditProfileScreen(
        userId: state.uri.queryParameters['userId'],
      ),
    ),
    GoRoute(
      path: '/subject/:grade',
      builder: (context, state) =>
          SubjectSelectionScreen(grade: state.pathParameters['grade'] ?? 'ປ.1'),
    ),
    GoRoute(
      path: '/lessons/:grade/:subject',
      builder: (context, state) => StudentLessonsScreen(
        grade: state.pathParameters['grade'] ?? 'P1',
        subject: state.pathParameters['subject'] ?? 'Lao',
      ),
    ),
    GoRoute(
      path: '/play-lesson/:lessonId',
      builder: (context, state) =>
          LessonPlayScreen(lessonId: state.pathParameters['lessonId'] ?? '1'),
    ),
    GoRoute(
      path: '/rewards',
      builder: (context, state) => const RewardRoomScreen(),
    ),
  ],
);
