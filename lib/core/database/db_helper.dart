import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/lesson.dart';
import '../models/reward.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  static const String _usersKey = 'edu_app_users';
  static const String _lessonsKey = 'edu_app_lessons';
  static const String _progressKey = 'edu_app_progress';
  static const String _rewardsKey = 'edu_app_rewards';

  // Helper methods to read/write JSON lists in SharedPreferences
  Future<List<Map<String, dynamic>>> _loadList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return [];
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('Error loading key $key: $e');
      return [];
    }
  }

  Future<void> _saveList(String key, List<Map<String, dynamic>> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(list);
      await prefs.setString(key, jsonStr);
    } catch (e) {
      debugPrint('Error saving key $key: $e');
    }
  }

  // --- Mock/Compatibility methods for remote API ---
  static Future<String> getBaseUrl() async => '';
  static Future<void> setCustomBaseUrl(String url) async {}
  static Future<bool> shouldUseMysql() async => false;

  // --- Users CRUD ---
  Future<UserProfile> createUser(UserProfile user) async {
    try {
      final users = await _loadList(_usersKey);
      
      // Check duplicate name
      if (users.any((u) => u['name'] == user.name)) {
        return user.copyWith(id: -1);
      }
      
      // Check duplicate phone
      if (users.any((u) => u['phone'] == user.phone)) {
        return user.copyWith(id: -2);
      }

      int newId = 1;
      if (users.isNotEmpty) {
        newId = users.map((u) => u['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
      }
      
      final created = user.copyWith(id: newId);
      users.add(created.toMap());
      await _saveList(_usersKey, users);
      
      // Initialize rewards automatically
      await checkAndUnlockRewards(newId);
      return created;
    } catch (e) {
      debugPrint('Error in createUser: $e');
      return user;
    }
  }

  Future<List<UserProfile>> readAllUsers() async {
    final users = await _loadList(_usersKey);
    return users.map((m) => UserProfile.fromMap(m)).toList();
  }

  Future<int> deleteUser(int id) async {
    try {
      final users = await _loadList(_usersKey);
      final initialLen = users.length;
      users.removeWhere((u) => u['id'] == id);
      await _saveList(_usersKey, users);

      // Cascade delete progress
      final progress = await _loadList(_progressKey);
      progress.removeWhere((p) => p['user_id'] == id);
      await _saveList(_progressKey, progress);

      // Cascade delete rewards
      final rewards = await _loadList(_rewardsKey);
      rewards.removeWhere((r) => r['user_id'] == id);
      await _saveList(_rewardsKey, rewards);

      return initialLen - users.length;
    } catch (e) {
      debugPrint('Error in deleteUser: $e');
      return 0;
    }
  }

  Future<int> updateUser(UserProfile user) async {
    try {
      final users = await _loadList(_usersKey);
      
      // Check duplicate name for another user
      if (users.any((u) => u['name'] == user.name && u['id'] != user.id)) {
        return -1;
      }
      
      // Check duplicate phone for another user
      if (users.any((u) => u['phone'] == user.phone && u['id'] != user.id)) {
        return -2;
      }

      final idx = users.indexWhere((u) => u['id'] == user.id);
      if (idx != -1) {
        users[idx] = user.toMap();
        await _saveList(_usersKey, users);
        return 1;
      }
      return 0;
    } catch (e) {
      debugPrint('Error in updateUser: $e');
      return 0;
    }
  }

  Future<UserProfile?> readUser(int id) async {
    final users = await _loadList(_usersKey);
    final idx = users.indexWhere((u) => u['id'] == id);
    if (idx != -1) {
      return UserProfile.fromMap(users[idx]);
    }
    return null;
  }

  Future<UserProfile> ensureDefaultUser() async {
    try {
      final user = await readUser(1);
      if (user != null) {
        return user;
      }
      
      final guest = UserProfile(
        id: 1,
        name: 'ນ້ອງນ້ອຍ',
        avatarId: 1,
        phone: 'guest',
        password: '',
        score: 0,
      );
      
      final users = await _loadList(_usersKey);
      users.add(guest.toMap());
      await _saveList(_usersKey, users);
      
      await checkAndUnlockRewards(1);
      return guest;
    } catch (e) {
      debugPrint('Error in ensureDefaultUser: $e');
      return UserProfile(id: 1, name: 'ນ້ອງນ້ອຍ', avatarId: 1, phone: 'guest', password: '');
    }
  }

  // --- Lessons CRUD ---
  Future<Lesson> createLesson(Lesson lesson) async {
    try {
      final lessons = await _loadList(_lessonsKey);
      int newId = 1;
      if (lessons.isNotEmpty) {
        newId = lessons.map((l) => l['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
      }
      final created = Lesson(
        id: newId,
        grade: lesson.grade,
        subject: lesson.subject,
        title: lesson.title,
        totalStars: lesson.totalStars,
      );
      lessons.add(created.toMap());
      await _saveList(_lessonsKey, lessons);
      return created;
    } catch (e) {
      debugPrint('Error in createLesson: $e');
      return lesson;
    }
  }

  Future<List<Lesson>> getAllLessons() async {
    try {
      final maps = await _loadList(_lessonsKey);
      final resultList = maps.map((m) => Lesson.fromMap(m)).toList();

      int extractLessonNumber(String title) {
        final match = RegExp(r'ບົດທີ\s*(\d+)').firstMatch(title);
        if (match != null) {
          return int.tryParse(match.group(1) ?? '') ?? 999;
        }
        return 999;
      }

      resultList.sort((a, b) {
        final gradeCompare = a.grade.compareTo(b.grade);
        if (gradeCompare != 0) return gradeCompare;

        final subjectCompare = a.subject.compareTo(b.subject);
        if (subjectCompare != 0) return subjectCompare;

        final numA = extractLessonNumber(a.title);
        final numB = extractLessonNumber(b.title);
        return numA.compareTo(numB);
      });

      return resultList;
    } catch (e) {
      debugPrint('Error in getAllLessons: $e');
      return [];
    }
  }

  Future<List<String>> getAllUniqueSubjects() async {
    final lessons = await getAllLessons();
    final subjects = lessons.map((l) => l.subject).toSet().toList();
    subjects.sort();
    return subjects;
  }

  Future<List<String>> getSubjectsForGrade(String grade) async {
    final lessons = await getAllLessons();
    final subjects = lessons
        .where((l) => l.grade == grade)
        .map((l) => l.subject)
        .toSet()
        .toList();
    subjects.sort();
    return subjects;
  }

  Future<int> deleteLesson(int id) async {
    try {
      final lessons = await _loadList(_lessonsKey);
      final initialLen = lessons.length;
      lessons.removeWhere((l) => l['id'] == id);
      await _saveList(_lessonsKey, lessons);
      return initialLen - lessons.length;
    } catch (e) {
      debugPrint('Error in deleteLesson: $e');
      return 0;
    }
  }

  // --- Seeding & Progress ---
  Future<void> seedInitialLessonsIfEmpty() async {
    try {
      final lessons = await getAllLessons();
      if (lessons.isEmpty || lessons.length != 90) {
        // Clear old ones first to prevent duplicates
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_lessonsKey);

        // ── P1 Lao: ພາສາລາວ (29 Lessons) ──────────────────────────────────────────────────────
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 1: ພະຍັນຊະນະ ປ & ສະຫຼະ xະ, xາ 🌸', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 2: ພະຍັນຊະນະ ມ & ວັນນະຍຸດ x່, x້ 💧', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 3: ພະຍັນຊະນະ ກ, ນ & ສະຫຼະ ໄx, ໃx 🌀', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 4: ພະຍັນຊະນະ ບ, ດ & ສະຫຼະ xິ, xີ 🦀', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 5: ບົດທວນຄືນ 📚', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 6: ພະຍັນຊະນະ ງ, ຈ & ສະຫຼະ xຸ, xູ 🕯️', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 7: ພະຍັນຊະນະ ຕ, ພ & ສະຫຼະ ເxະ, ເx 🐂', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 8: ພະຍັນຊະນະ ລ, ສ & ສະຫຼະ ແxະ, ແx 🍂', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 9: ພະຍັນຊະນະ ອ, ວ & ສະຫຼະ xຳ, ເxົາ 🍃', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 10: ບົດທວນຄືນ 📚', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 11: ພະຍັນຊະນະ ຂ, ຄ & ສະຫຼະ ເxາະ, xໍ 🎀', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 12: ພະຍັນຊະນະ ຊ, ຟ & ສະຫຼະ xຶ, xື 🔥', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 13: ພະຍັນຊະນະ ຍ, ຢ & ສະຫຼະ ໂxະ, ໂx 🐚', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 14: ພະຍັນຊະນະ ຮ, ຫ, ຣ & ສະຫຼະ ເxຶອ, ເxືອ 🐶', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 15: ພະຍັນຊະນະ ຜ, ຝ & ສະຫຼະ ເxິ, ເxີ 🌲', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 16: ບົດທວນຄືນ 📚', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 17: ພະຍັນຊະນະ ຖ, ທ & ສະຫຼະ ເxັຍ, ເxຍ 🍎', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 18: ອັກສອນປະສົມ ຫງ, ຫວ, ຫຍ & ສະຫຼະ xົວະ, xົວ 🌾', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 19: ອັກສອນປະສົມ ໜ, ໝ, ຫຼ & ຕົວສະກົດ ນ 🎀', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 20: ພະຍັນຊະນະຄວບ ກວ, ຂວ, ຄວ & ຕົວສະກົດ ນ 🐶', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 21: ບົດທວນຄືນ 📚', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 22: ຕົວສະກົດ ງ 🍉', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 23: ຕົວສະກົດ ມ, ວ, ຍ 🐚', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 24: ຕົວສະກົດ ກ, ດ, ບ 🌀', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 25: ບົດທວນຄືນ 📚', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 26: ການອ່ານປະໂຫຍກ ແລະ ຂໍ້ຄວາມ 📖', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 27: ການອ່ານປຶ້ມນິທານ 📚', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 28: ການຂຽນທວາຍ ແລະ ຝຶກແຕ່ງປະໂຫຍກ 📝', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 29: ທວນຄືນທ້າຍປີ 🏆', totalStars: 3));

        // ── P1 Math: ຄະນິດສາດ (17 Lessons) ──────────────────────────────────────────────────────
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 1: ການປຽບທຽບຈຳນວນ ⚖️', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 2: จຳນວນແຕ່ 1 ເຖິງ 10 ແລະ 0 🔢', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 3: ການແບ່ງຈຳນວນອອກເປັນສອງສ່ວນ 🧮', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 4: ການບວກ (ຜົນບວກບໍ່ເກີນ 9) ➕', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 5: ການລົບ (ຕົວຕັ້ງລົບບໍ່ເກີນ 9) ➖', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 6: ຈຳນວນທີ່ຫຼາຍກວ່າ 10 (11 ເຖິງ 20) 🔢', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 7: ການບວກ (ຕໍ່) (ຜົນບວກບໍ່ເກີນ 20) ➕', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 8: ການລົບ (ຕໍ່) (ຕົວຕັ້ງລົບບໍ່ເກີນ 20) ➖', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 9: ການຄິດໄລ່ຂອງ 3 ຈຳນວນ 🧮', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 10: ຮູບຮ່າງຂອງສິ່ງຕ່າງໆທີ່ຢູ່ອ້ອມຕົວເຮົາ 📦', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 11: จຳນວນທີ່ຫຼາຍກວ່າ 20 (21 ເຖິງ 100) 🔢', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 12: ໂມງ (ການອ່ານເວລາ) ⏰', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 13: ການບວກ ແລະ ການລົບ (ຕໍ່) 🧮', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 14: ການປຽບທຽບຄວາມຍາວ 📏', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 15: ການປຽບທຽບປະລິມານ (ຄວາມບັນຈຸ) 🍼', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 16: ຮູບຮ່າງ ແລະ ການຈັດລຽງ 🔴', totalStars: 3));
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 17: ເມດລາວ (໑ ເຖິງ ໑໐) 🇱🇦', totalStars: 3));

        // ── P2 ພາສາລາວ (30 Lessons) ────────────────────────────────────────────────────────────
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 1: ສະຫຼະ xະ, xາ ທີ່ມີຕົວສະກົດ 🌸', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 2: ສະຫຼະ xິ, xີ ທີ່ມີຕົວສະກົດ 💧', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 3: ສະຫຼະ xຶ, xື ທີ່ມີຕົວສະກົດ 🌀', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 4: ສະຫຼະ xຸ, xູ ທີ່ມີຕົວສະກົດ 🧸', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 5: ທວນຄືນສະຫຼະ xະ, xາ, xິ, xີ, xຶ, xື, xຸ, xູ 📚', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 6: ສະຫຼະ ເxະ, ເx ທີ່ມີຕົວສະກົດ 🕯️', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 7: ສະຫຼະ ແxະ, ແx ທີ່ມີຕົວສະກົດ 🍂', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 8: ສະຫຼະ ໂxະ, ໂx ທີ່ມີຕົວສະກົດ 🐂', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 9: ສະຫຼະ ເxາະ, xໍ ທີ່ມີຕົວສະກົດ 🌿', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 10: ທວນຄືນສະຫຼະ ເx, ແx, ໂx, xໍ 📚', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 11: ສະຫຼະ ເxິ, ເxີ ທີ່ມີຕົວສະກົດ 🍃', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 12: ສະຫຼະ ເxັຍ, ເxຍ ທີ່ມີຕົວສະກົດ 🐚', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 13: ສະຫຼະ ເxືອະ, ເxືອ ທີ່ມີຕົວສະກົດ 🌀', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 14: ສະຫຼະ xົວະ, xົວ ທີ່ມີຕົວສະກົດ 🍉', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 15: ທວນຄືນສະຫຼະ ເxີ, ເxຍ, ເxືອ, xົວ 📚', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 16: ພະຍັນຊະນະຄວບ ວ 🌸', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 17: ອັກສອນຄວບ ແລະ ວັນນະຍຸດ x໋, x໊ 🔔', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 18: ອັກສອນປະສົມ ຫງ, ຫຍ, ໜ, ໝ 🐶', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 19: ອັກສອນປະສົມ ຫຼ, ຫວ ແລະ ຄຳຄຸນນາມ 🗣️', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 20: ທວນຄືນອັກສອນປະສົມ ແລະ ອັກສອນຄວບ 📚', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 21: ຄຳນາມ ແລະ ຄຳກຳມະ 🏃', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 22: ຄຳແທນນາມ ແລະ ປະໂຫຍກ 🗣️', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 23: ຄຳເຊື່ອມ ແລະ ເຄື່ອງໝາຍຈຸດ (,) ✍️', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 24: ເຄື່ອງໝາຍອັດສະຈັນ (!) ແລະ ເຄື່ອງໝາຍຖາມ (?) ❓', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 25: ທວນຄືນປະເພດຄຳ ແລະ ເຄື່ອງໝາຍວັກຕອນ 📚', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 26: การຂຽນຈົດໝາຍ ແລະ ບົດເລົ່າຄືນ ✉️', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 27: ການຂຽນບົດອະທິບາຍ ແລະ ວິທີການ 📝', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 28: ການຂຽນບົດສະແດງຄວາມຄິດເຫັນ ✍️', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 29: ການອ່ານກາບກອນ ແລະ ນິທານ 📖', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 30: ທວນຄືນຄວາມຮູ້ພາສາລາວທ້າຍປີ 🏆', totalStars: 3));

        // ── P2 ຄະນິດສາດ (14 Lessons) ────────────────────────────────────────────────────────────
        await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 1: ການນຳສະເໜີຂໍ້ມູນ ແລະ ຕາຕະລາງ 📊', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 2: ຈຳນວນທີ່ມີສາມຕົວເລກ (ຫຼັກຮ້ອຍ, ສິບ, ໜ່ວຍ) 🔢', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 3: ການບວກເລກສອງຫຼັກ (ມີຕົວຈື່) ➕', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 4: ການລົບເລກສອງຫຼັກ (ມີຢືມ) ➖', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 5: ຄວາມຍາວ ແລະ ການວັດແທກ (ຊມ, ມມ, ມ) 📏', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 6: ໂຈດບັນຫາກ່ຽວກັບການບວກ ແລະ ການລົບ 🧮', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 7: ໂມງ ແລະ ເວລາ (ການອ່ານເວລາ ແລະ ໄລຍະເວລາ) ⏰', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 8: ຫົວໜ່ວຍ ແລະ ວິທີວັດແທກບໍລິມາດຂອງນໍ້າ 🍼', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 9: ຮູບເລຂາຄະນິດ (ເສັ້ນ, ມູມ, ຮູບສີ່ແຈ, ຮູບສາມແຈ) 📐', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 10: ການຄູນ (1) (ບັ້ງ 2, 5, 10) ✖️', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 11: ການຄູນ (2) (ບັ້ງ 3, 4, 6, 7, 8, 9) ✖️', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 12: ທະນະບັດ (ເງິນກີບ) 💵', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 13: ປະເພດຮູບສາມມິຕິ (ຮູບກ້ອນສາກ, ຮູບທໍ່ກົມ) 📦', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 14: ທວນຄືນຄະນິດສາດທ້າຍປີ 🏆', totalStars: 3));
      }
    } catch (e) {
      debugPrint('Error in seedInitialLessonsIfEmpty: $e');
    }
  }

  Future<void> saveProgress(int userId, int lessonId, int starsEarned) async {
    try {
      final progress = await _loadList(_progressKey);
      final idx = progress.indexWhere((p) => p['user_id'] == userId && p['lesson_id'] == lessonId);

      if (idx == -1) {
        int newId = 1;
        if (progress.isNotEmpty) {
          newId = progress.map((p) => p['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
        }
        progress.add({
          'id': newId,
          'user_id': userId,
          'lesson_id': lessonId,
          'stars_earned': starsEarned,
          'is_completed': starsEarned == 3 ? 1 : 0,
          'last_played': DateTime.now().toIso8601String(),
        });
      } else {
        final currentStars = progress[idx]['stars_earned'] as int;
        if (starsEarned > currentStars) {
          progress[idx]['stars_earned'] = starsEarned;
          progress[idx]['is_completed'] = starsEarned == 3 ? 1 : 0;
          progress[idx]['last_played'] = DateTime.now().toIso8601String();
        }
      }
      await _saveList(_progressKey, progress);

      // Recalculate user score
      final totalScore = progress
          .where((p) => p['user_id'] == userId)
          .fold<int>(0, (sum, p) => sum + (p['stars_earned'] as int? ?? 0));

      final users = await _loadList(_usersKey);
      final uIdx = users.indexWhere((u) => u['id'] == userId);
      if (uIdx != -1) {
        users[uIdx]['score'] = totalScore;
        await _saveList(_usersKey, users);
      }
    } catch (e) {
      debugPrint('Error in saveProgress: $e');
    }
  }

  Future<int> getLessonProgressStars(int userId, int lessonId) async {
    try {
      final progress = await _loadList(_progressKey);
      final match = progress.firstWhere(
        (p) => p['user_id'] == userId && p['lesson_id'] == lessonId,
        orElse: () => <String, dynamic>{},
      );
      return match['stars_earned'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error in getLessonProgressStars: $e');
      return 0;
    }
  }

  // --- Rewards CRUD & Dynamic Check ---
  Future<void> checkAndUnlockRewards(int userId) async {
    try {
      final rewards = await _loadList(_rewardsKey);
      final userRewards = rewards.where((r) => r['user_id'] == userId).toList();

      if (userRewards.isEmpty) {
        final defaultRewards = [
          {'reward_name': 'ຍອດນັກອ່ານ ປ.1', 'image_path': '📚'},
          {'reward_name': 'ຍອດນັກອ່ານ ປ.2', 'image_path': '📖'},
          {'reward_name': 'ນັກຄິດໄວ ປ.1', 'image_path': '🍎'},
          {'reward_name': 'ນັກຄິດໄວ ປ.2', 'image_path': '🧮'},
          {'reward_name': 'ດາວເດັ່ນຮຽນເກັ່ງ', 'image_path': '⭐'},
          {'reward_name': 'ແຊມປ້ຽນຫຼຽນທອງ', 'image_path': '🥉'},
          {'reward_name': 'ແຊມປ້ຽນຫຼຽນເງິນ', 'image_path': '🥈'},
          {'reward_name': 'ແຊມປ້ຽນຫຼຽນຄຳ', 'image_path': '🥇'},
          {'reward_name': 'ອັດສະລິຍະຕົວນ້ອຍ', 'image_path': '🏆'}
        ];
        
        int startId = 1;
        if (rewards.isNotEmpty) {
          startId = rewards.map((r) => r['id'] as int).reduce((a, b) => a > b ? a : b) + 1;
        }
        
        for (var r in defaultRewards) {
          rewards.add({
            'id': startId++,
            'user_id': userId,
            'reward_name': r['reward_name'],
            'image_path': r['image_path'],
            'is_unlocked': 0,
          });
        }
      }

      // Auto unlock logic based on stars/completed progress
      final progress = await _loadList(_progressKey);
      final userProgress = progress.where((p) => p['user_id'] == userId).toList();
      
      final totalStars = userProgress.fold<int>(0, (sum, p) => sum + (p['stars_earned'] as int? ?? 0));
      final completedCount = userProgress.where((p) => (p['stars_earned'] as int? ?? 0) > 0).length;

      final lessons = await getAllLessons();
      int laoG1Stars = 0;
      int laoG2Stars = 0;
      int mathG1Stars = 0;
      int mathG2Stars = 0;

      for (var p in userProgress) {
        final stars = p['stars_earned'] as int? ?? 0;
        final lessonId = p['lesson_id'] as int;
        final lesson = lessons.firstWhere((l) => l.id == lessonId, orElse: () => Lesson(id: -1, grade: '', subject: '', title: '', totalStars: 3));
        if (lesson.id == -1) continue;

        final grade = lesson.grade;
        final subject = lesson.subject;

        if (grade == 'P1' && (subject == 'ພາສາລາວ' || subject == 'ການອ່ານ')) {
          laoG1Stars += stars;
        } else if (grade == 'P1' && subject == 'ຄະນິດສາດ') {
          mathG1Stars += stars;
        } else if (grade == 'P2' && subject == 'ພາສາລາວ') {
          laoG2Stars += stars;
        } else if (grade == 'P2' && subject == 'ຄະນິດສາດ') {
          mathG2Stars += stars;
        }
      }

      final toUnlock = <String>[];
      if (laoG1Stars >= 3) toUnlock.add('ຍອດນັກອ່ານ ປ.1');
      if (laoG2Stars >= 3) toUnlock.add('ຍອດນັກອ່ານ ປ.2');
      if (mathG1Stars >= 3) toUnlock.add('ນັກຄິດໄວ ປ.1');
      if (mathG2Stars >= 3) toUnlock.add('ນັກຄິດໄວ ປ.2');
      if (totalStars >= 10) toUnlock.add('ດາວເດັ່ນຮຽນເກັ່ງ');
      if (totalStars >= 15) toUnlock.add('ແຊມປ້ຽນຫຼຽນທອງ');
      if (totalStars >= 25) toUnlock.add('ແຊມປ້ຽນຫຼຽນເງິນ');
      if (totalStars >= 35) toUnlock.add('ແຊມປ້ຽນຫຼຽນຄຳ');
      if (completedCount >= 25) toUnlock.add('ອັດສະລິຍະຕົວນ້ອຍ');

      if (toUnlock.isNotEmpty) {
        for (var i = 0; i < rewards.length; i++) {
          if (rewards[i]['user_id'] == userId && toUnlock.contains(rewards[i]['reward_name'])) {
            rewards[i]['is_unlocked'] = 1;
          }
        }
      }
      await _saveList(_rewardsKey, rewards);
    } catch (e) {
      debugPrint('Error in checkAndUnlockRewards: $e');
    }
  }

  Future<List<Reward>> getRewardsForUser(int userId) async {
    await checkAndUnlockRewards(userId);
    final rewards = await _loadList(_rewardsKey);
    final list = rewards.where((r) => r['user_id'] == userId).map((m) => Reward.fromMap(m)).toList();
    return list;
  }

  Future<void> updateRewardUnlockStatus(int userId, String rewardName, bool isUnlocked) async {
    try {
      final rewards = await _loadList(_rewardsKey);
      final idx = rewards.indexWhere((r) => r['user_id'] == userId && r['reward_name'] == rewardName);
      if (idx != -1) {
        rewards[idx]['is_unlocked'] = isUnlocked ? 1 : 0;
        await _saveList(_rewardsKey, rewards);
      }
    } catch (e) {
      debugPrint('Error in updateRewardUnlockStatus: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserProgressDetailed(int userId) async {
    try {
      final lessons = await getAllLessons();
      final progress = await _loadList(_progressKey);

      final list = <Map<String, dynamic>>[];
      for (var l in lessons) {
        final p = progress.firstWhere(
          (p) => p['lesson_id'] == l.id && p['user_id'] == userId,
          orElse: () => <String, dynamic>{},
        );
        list.add({
          'progress_id': p['id'],
          'stars_earned': p['stars_earned'],
          'is_completed': p['is_completed'],
          'last_played': p['last_played'],
          'lesson_id': l.id,
          'grade': l.grade,
          'subject': l.subject,
          'title': l.title,
          'max_stars': l.totalStars,
        });
      }

      int extractLessonNumber(String title) {
        final match = RegExp(r'ບົດທີ\s*(\d+)').firstMatch(title);
        if (match != null) {
          return int.tryParse(match.group(1) ?? '') ?? 999;
        }
        return 999;
      }

      list.sort((a, b) {
        final gradeCompare = (a['grade'] as String).compareTo(b['grade'] as String);
        if (gradeCompare != 0) return gradeCompare;

        final subjectCompare = (a['subject'] as String).compareTo(b['subject'] as String);
        if (subjectCompare != 0) return subjectCompare;

        final numA = extractLessonNumber(a['title'] as String);
        final numB = extractLessonNumber(b['title'] as String);
        return numA.compareTo(numB);
      });

      return list;
    } catch (e) {
      debugPrint('Error in getUserProgressDetailed: $e');
      return [];
    }
  }

  Future<void> resetUserProgress(int userId, int lessonId) async {
    try {
      final progress = await _loadList(_progressKey);
      progress.removeWhere((p) => p['user_id'] == userId && p['lesson_id'] == lessonId);
      await _saveList(_progressKey, progress);

      // Recalculate score
      final totalScore = progress
          .where((p) => p['user_id'] == userId)
          .fold<int>(0, (sum, p) => sum + (p['stars_earned'] as int? ?? 0));

      final users = await _loadList(_usersKey);
      final uIdx = users.indexWhere((u) => u['id'] == userId);
      if (uIdx != -1) {
        users[uIdx]['score'] = totalScore;
        await _saveList(_usersKey, users);
      }
    } catch (e) {
      debugPrint('Error in resetUserProgress: $e');
    }
  }
}
