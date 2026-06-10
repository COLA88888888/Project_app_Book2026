import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as p;
import '../models/user_profile.dart';
import '../models/lesson.dart';
import '../models/reward.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  static String _activeBaseUrl = '';
  static sql.Database? _localDb;

  // --- SQLite Local Database (Mobile) ---
  static Future<sql.Database> getLocalDb() async {
    if (_localDb != null) return _localDb!;

    final dbPath = await sql.getDatabasesPath();
    final path = p.join(dbPath, 'edu_app.db');

    _localDb = await sql.openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            password TEXT DEFAULT '',
            avatarId INTEGER DEFAULT 1,
            score INTEGER DEFAULT 0,
            createdAt TEXT DEFAULT ''
          )
        ''');

        await db.execute('''
          CREATE TABLE lessons (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            grade TEXT DEFAULT '',
            subject TEXT DEFAULT '',
            title TEXT DEFAULT '',
            total_stars INTEGER DEFAULT 3,
            UNIQUE(grade, subject, title) ON CONFLICT REPLACE
          )
        ''');

        await db.execute('''
          CREATE TABLE progress (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            lesson_id INTEGER NOT NULL,
            stars_earned INTEGER DEFAULT 0,
            is_completed INTEGER DEFAULT 0,
            last_played TEXT DEFAULT '',
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE rewards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            reward_name TEXT NOT NULL,
            image_path TEXT DEFAULT '',
            is_unlocked INTEGER DEFAULT 0,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    // Run migration cleanup for any Thai or Cyrillic characters in titles
    await _migrateLaoTitles(_localDb!);
    // Ensure unique index is created for existing databases
    await _localDb!.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_lessons_unique ON lessons(grade, subject, title)');
    return _localDb!;
  }

  static Future<void> _migrateLaoTitles(sql.Database db) async {
    try {
      final Map<String, String> corrections = {
        'ບົດທີ 8: ทວນຄືນປະສົມພະຍັນຊະນະ ກ ຮອດ ຮ 📚': 'ບົດທີ 8: ທວນຄືນປະສົມພະຍັນຊະນະ ກ ຮອດ ຮ 📚',
        'ບົດທີ 12: ປະສົມພະຍັນຊະນະ ກັບ ສະຫຼະພіເສດ xຳ, ໄx, ໃx, ເxົາ 🔥': 'ບົດທີ 12: ປະສົມພະຍັນຊະນະ ກັບ ສະຫຼະພິເສດ xຳ, ໄx, ໃx, ເxົາ 🔥',
        'ບົດທີ 10: ทວນຄືນສະຫຼະ ເx, ແx, ໂx, xໍ 📚': 'ບົດທີ 10: ທວນຄືນສະຫຼະ ເx, ແx, ໂx, xໍ 📚',
        'ບົດທີ 15: ทວນຄືນສະຫຼະ ເxີ, ເxຍ, ເxືອ, xົວ 📚': 'ບົດທີ 15: ທວນຄືນສະຫຼະ ເxີ, ເxຍ, ເxືອ, xົວ 📚',
        'ບົດທີ 20: ทວນຄືນອັກສອນປະສົມ ແລະ ອັກສອນຄວບ 📚': 'ບົດທີ 20: ທວນຄືນອັກສອນປະສົມ ແລະ ອັກສອນຄວບ 📚',
        'ບົດທີ 25: ทວນຄືນປະເພດຄຳ ແລະ ເຄື່ອງໝາຍວັກຕອນ 📚': 'ບົດທີ 25: ທວນຄືນປະເພດຄຳ ແລະ ເຄື່ອງໝາຍວັກຕອນ 📚',
        'ບົດທີ 27: ການຂຽນບົດອະທິບາຍ ແລະ ວິທີການ 📝': 'ບົດທີ 27: ການຂຽນບົດອະທິບາຍ ແລະ ວິທີການ 📝',
        'ບົດທີ 27: ການຂຽນบົດອະທິບາຍ ແລະ ວິທີການ 📝': 'ບົດທີ 27: ການຂຽນບົດອະທິບາຍ ແລະ ວິທີການ 📝',
        'ບົດທີ 7: การຄູນ ແລະ ຕາຕະລາງບັ້ງສູດ (ບັ້ງ 2, 5, 10) ✖️': 'ບົດທີ 7: ການຄູນ ແລະ ຕາຕະລາງບັ້ງສູດ (ບັ້ງ 2, 5, 10) ✖️',
      };

      for (var entry in corrections.entries) {
        await db.update(
          'lessons',
          {'title': entry.value},
          where: 'title = ?',
          whereArgs: [entry.key],
        );
      }
    } catch (e) {
      debugPrint('Error in _migrateLaoTitles: $e');
    }
  }

  // --- Remote MySQL API URL Resolution (Desktop/Web) ---
  static Future<String> getBaseUrl() async {
    if (_activeBaseUrl.isNotEmpty) return _activeBaseUrl;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('custom_api_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _activeBaseUrl = savedUrl;
        return _activeBaseUrl;
      }
    } catch (_) {}

    // List of candidate URLs to test
    final candidates = <String>[];
    if (kIsWeb) {
      candidates.add('http://localhost/app_book/api.php');
    } else if (Platform.isAndroid) {
      candidates.add('http://localhost:8080/app_book/api.php'); // ADB reverse port forwarding
      candidates.add('http://127.0.0.1:8080/app_book/api.php'); // ADB reverse port forwarding
      candidates.add('http://10.0.2.2/app_book/api.php');       // Android Emulator port
      candidates.add('http://172.20.10.2/app_book/api.php');    // Computer hotspot/Wi-Fi IP
    } else {
      candidates.add('http://localhost/app_book/api.php');
      candidates.add('http://127.0.0.1/app_book/api.php');
      candidates.add('http://172.20.10.2/app_book/api.php');
    }

    // Ping them concurrently in parallel with a short timeout to see which one works first
    final pings = candidates.map((url) async {
      try {
        final uri = Uri.parse('$url?action=read_all_users');
        final response = await http.get(uri).timeout(const Duration(milliseconds: 1000));
        if (response.statusCode == 200) {
          return url;
        }
      } catch (_) {}
      return null;
    });

    final results = await Future.wait(pings);
    for (final res in results) {
      if (res != null) {
        _activeBaseUrl = res;
        debugPrint('Successfully connected to API at: $_activeBaseUrl');
        return _activeBaseUrl;
      }
    }

    // Default fallback if none succeed
    _activeBaseUrl = !kIsWeb && Platform.isAndroid
        ? 'http://10.0.2.2/app_book/api.php'
        : 'http://localhost/app_book/api.php';
    return _activeBaseUrl;
  }

  static Future<void> setCustomBaseUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (url.isEmpty) {
        await prefs.remove('custom_api_url');
        _activeBaseUrl = '';
      } else {
        await prefs.setString('custom_api_url', url);
        _activeBaseUrl = url;
      }
    } catch (_) {}
  }

  static Future<bool> shouldUseMysql() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        return true;
      }
      return prefs.getBool('use_mysql_database') ?? false;
    } catch (_) {
      return false;
    }
  }

  // Helper to handle and print errors, and reset active URL cache on network failure
  void _handleError(dynamic e, String methodName) {
    debugPrint('Error in $methodName: $e');
    _activeBaseUrl = ''; // Clear active URL cache so next query triggers a re-probe
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('custom_api_url');
    }).catchError((_) {});
  }

  // --- Users CRUD ---
  Future<UserProfile> createUser(UserProfile user) async {
    if (!await shouldUseMysql()) {
      try {
        final db = await getLocalDb();
        // Check duplicate name
        final List<Map<String, dynamic>> existing = await db.query(
          'users',
          where: 'name = ?',
          whereArgs: [user.name],
        );
        if (existing.isNotEmpty) {
          return user.copyWith(id: -1);
        }
        // Check duplicate phone
        final List<Map<String, dynamic>> existingPhone = await db.query(
          'users',
          where: 'phone = ?',
          whereArgs: [user.phone],
        );
        if (existingPhone.isNotEmpty) {
          return user.copyWith(id: -2);
        }
        final id = await db.insert('users', user.toMap()..remove('id'));
        final created = user.copyWith(id: id);
        // Initialize rewards automatically
        await checkAndUnlockRewards(id);
        return created;
      } catch (e) {
        debugPrint('SQLite Error in createUser: $e');
        return user;
      }
    }

    try {
      final url = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$url?action=create_user'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(user.toMap()..remove('id')),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null) {
          if (data['error'] == 'name_exists') {
            return user.copyWith(id: -1);
          }
          if (data['error'] == 'phone_exists') {
            return user.copyWith(id: -2);
          }
          if (data['id'] != null) {
            final int newId = data['id'];
            // Initialize rewards automatically for the new user in background
            http.get(Uri.parse('$url?action=check_and_unlock_rewards&userId=$newId'))
                .timeout(const Duration(seconds: 3))
                .catchError((_) => http.Response('', 500));
            return user.copyWith(id: newId);
          }
        }
      }
    } catch (e) {
      _handleError(e, 'createUser');
    }
    return user;
  }

  Future<List<UserProfile>> readAllUsers() async {
    if (!await shouldUseMysql()) {
      try {
        final db = await getLocalDb();
        final List<Map<String, dynamic>> maps = await db.query('users', orderBy: 'id ASC');
        return maps.map((m) => UserProfile.fromMap(m)).toList();
      } catch (e) {
        debugPrint('SQLite Error in readAllUsers: $e');
        return [];
      }
    }

    try {
      final url = await getBaseUrl();
      final response = await http.get(Uri.parse('$url?action=read_all_users')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => UserProfile.fromMap(json)).toList();
      }
    } catch (e) {
      _handleError(e, 'readAllUsers');
    }
    return [];
  }

  Future<int> deleteUser(int id) async {
    if (!await shouldUseMysql()) {
      try {
        final db = await getLocalDb();
        return await db.delete('users', where: 'id = ?', whereArgs: [id]);
      } catch (e) {
        debugPrint('SQLite Error in deleteUser: $e');
        return 0;
      }
    }

    try {
      final url = await getBaseUrl();
      final response = await http.get(Uri.parse('$url?action=delete_user&id=$id')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) == 1 ? 1 : 0;
      }
    } catch (e) {
      _handleError(e, 'deleteUser');
    }
    return 0;
  }

  Future<int> updateUser(UserProfile user) async {
    if (!await shouldUseMysql()) {
      try {
        final db = await getLocalDb();
        // Check duplicate name for another user
        final List<Map<String, dynamic>> existing = await db.query(
          'users',
          where: 'name = ? AND id != ?',
          whereArgs: [user.name, user.id],
        );
        if (existing.isNotEmpty) {
          return -1;
        }
        // Check duplicate phone for another user
        final List<Map<String, dynamic>> existingPhone = await db.query(
          'users',
          where: 'phone = ? AND id != ?',
          whereArgs: [user.phone, user.id],
        );
        if (existingPhone.isNotEmpty) {
          return -2;
        }
        return await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
      } catch (e) {
        debugPrint('SQLite Error in updateUser: $e');
        return 0;
      }
    }

    try {
      final url = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$url?action=update_user'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(user.toMap()),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['error'] == 'name_exists') {
            return -1;
          }
          if (decoded is Map && decoded['error'] == 'phone_exists') {
            return -2;
          }
          return decoded == 1 ? 1 : 0;
        } catch (_) {
          return jsonDecode(response.body) == 1 ? 1 : 0;
        }
      }
    } catch (e) {
      _handleError(e, 'updateUser');
    }
    return 0;
  }

  Future<UserProfile?> readUser(int id) async {
    if (!await shouldUseMysql()) {
      try {
        final db = await getLocalDb();
        final List<Map<String, dynamic>> maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
        if (maps.isNotEmpty) {
          return UserProfile.fromMap(maps.first);
        }
      } catch (e) {
        debugPrint('SQLite Error in readUser: $e');
      }
      return null;
    }

    try {
      final url = await getBaseUrl();
      final response = await http.get(Uri.parse('$url?action=read_user&id=$id')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null) {
          return UserProfile.fromMap(data);
        }
      }
    } catch (e) {
      _handleError(e, 'readUser');
    }
    return null;
  }

  Future<UserProfile> ensureDefaultUser() async {
    if (!await shouldUseMysql()) {
      try {
        final db = await getLocalDb();
        final List<Map<String, dynamic>> maps = await db.query('users', where: 'id = ?', whereArgs: [1]);
        if (maps.isNotEmpty) {
          return UserProfile.fromMap(maps.first);
        }
        final guest = UserProfile(
          id: 1,
          name: 'ນ້ອງນ້ອຍ',
          avatarId: 1,
          phone: 'guest',
          password: '',
          score: 0,
        );
        await db.insert('users', guest.toMap());
        await checkAndUnlockRewards(1);
        return guest;
      } catch (e) {
        debugPrint('SQLite Error in ensureDefaultUser: $e');
      }
    } else {
      try {
        final url = await getBaseUrl();
        final response = await http.get(Uri.parse('$url?action=read_user&id=1')).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data != null) {
            return UserProfile.fromMap(data);
          }
        }
        
        final guest = UserProfile(
          id: 1,
          name: 'ນ້ອງນ້ອຍ',
          avatarId: 1,
          phone: 'guest',
          password: '',
          score: 0,
        );
        
        final createResponse = await http.post(
          Uri.parse('$url?action=create_user'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(guest.toMap()),
        ).timeout(const Duration(seconds: 5));
        if (createResponse.statusCode == 200) {
          final data = jsonDecode(createResponse.body);
          if (data != null && data['id'] != null) {
            return guest.copyWith(id: data['id']);
          }
        }
        return guest;
      } catch (e) {
        _handleError(e, 'ensureDefaultUser');
      }
    }
    return UserProfile(id: 1, name: 'ນ້ອງນ້ອຍ', avatarId: 1, phone: 'guest', password: '');
  }

  // --- Lessons CRUD ---
  Future<Lesson> createLesson(Lesson lesson) async {
    if (!await shouldUseMysql()) {
      try {
        final db = await getLocalDb();
        final id = await db.insert('lessons', lesson.toMap()..remove('id'));
        return Lesson(
          id: id,
          grade: lesson.grade,
          subject: lesson.subject,
          title: lesson.title,
          totalStars: lesson.totalStars,
        );
      } catch (e) {
        debugPrint('SQLite Error in createLesson: $e');
        return lesson;
      }
    }

    try {
      final url = await getBaseUrl();
      final response = await http.post(
        Uri.parse('$url?action=create_lesson'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(lesson.toMap()),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['id'] != null) {
          return Lesson(
            id: data['id'],
            grade: lesson.grade,
            subject: lesson.subject,
            title: lesson.title,
            totalStars: lesson.totalStars,
          );
        }
      }
    } catch (e) {
      _handleError(e, 'createLesson');
    }
    return lesson;
  }

  Future<List<Lesson>> getAllLessons() async {
    if (!await shouldUseMysql()) {
      try {
        final db = await getLocalDb();
        final List<Map<String, dynamic>> maps = await db.query('lessons', orderBy: 'id ASC');
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
        debugPrint('SQLite Error in getAllLessons: $e');
        return [];
      }
    }

    try {
      final url = await getBaseUrl();
      final response = await http.get(Uri.parse('$url?action=get_all_lessons')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final resultList = list.map((json) => Lesson.fromMap(json)).toList();

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
      }
    } catch (e) {
      _handleError(e, 'getAllLessons');
    }
    return [];
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
    if (!await shouldUseMysql()) {
      try {
        final db = await getLocalDb();
        return await db.delete('lessons', where: 'id = ?', whereArgs: [id]);
      } catch (e) {
        debugPrint('SQLite Error in deleteLesson: $e');
        return 0;
      }
    }

    try {
      final url = await getBaseUrl();
      final response = await http.get(Uri.parse('$url?action=delete_lesson&id=$id')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) == 1 ? 1 : 0;
      }
    } catch (e) {
      _handleError(e, 'deleteLesson');
    }
    return 0;
  }

  // --- Seeding & Progress CRUD ---
  Future<void> seedInitialLessonsIfEmpty() async {
    try {
      final lessons = await getAllLessons();
      if (lessons.isEmpty || lessons.length != 90) {
        // Clear old ones first to prevent duplicates
        for (var l in lessons) {
          await deleteLesson(l.id!);
        }

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
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 2: ຈຳນວນແຕ່ 1 ເຖິງ 10 ແລະ 0 🔢', totalStars: 3));
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
        await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 17: ເລກລາວ (໑ ເຖິງ ໑໐) 🇱🇦', totalStars: 3));

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
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 26: ການຂຽນຈົດໝາຍ ແລະ ບົດເລົ່າຄືນ ✉️', totalStars: 3));
        await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 27: ການຂຽນบົດອະທິບາຍ ແລະ ວິທີການ 📝', totalStars: 3));
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
    if (!await shouldUseMysql()) {
      try {
        final db = await getLocalDb();
        final List<Map<String, dynamic>> existing = await db.query(
          'progress',
          where: 'user_id = ? AND lesson_id = ?',
          whereArgs: [userId, lessonId],
        );

        if (existing.isEmpty) {
          await db.insert('progress', {
            'user_id': userId,
            'lesson_id': lessonId,
            'stars_earned': starsEarned,
            'is_completed': starsEarned == 3 ? 1 : 0,
            'last_played': DateTime.now().toIso8601String(),
          });
        } else {
          final currentStars = existing.first['stars_earned'] as int;
          if (starsEarned > currentStars) {
            await db.update(
              'progress',
              {
                'stars_earned': starsEarned,
                'is_completed': starsEarned == 3 ? 1 : 0,
                'last_played': DateTime.now().toIso8601String(),
              },
              where: 'user_id = ? AND lesson_id = ?',
              whereArgs: [userId, lessonId],
            );
          }
        }

        // Recalculate user score
        final List<Map<String, dynamic>> scoreResult = await db.rawQuery(
          'SELECT SUM(stars_earned) as total FROM progress WHERE user_id = ?',
          [userId],
        );
        final totalScore = scoreResult.first['total'] as int? ?? 0;

        await db.update(
          'users',
          {'score': totalScore},
          where: 'id = ?',
          whereArgs: [userId],
        );
      } catch (e) {
        debugPrint('SQLite Error in saveProgress: $e');
      }
      return;
    }

    try {
      final url = await getBaseUrl();
      await http.post(
        Uri.parse('$url?action=save_progress'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'userId': userId,
          'lessonId': lessonId,
          'starsEarned': starsEarned,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      _handleError(e, 'saveProgress');
    }
  }

  Future<int> getLessonProgressStars(int userId, int lessonId) async {
    if (!await shouldUseMysql()) {
      try {
        final db = await getLocalDb();
        final List<Map<String, dynamic>> maps = await db.query(
          'progress',
          columns: ['stars_earned'],
          where: 'user_id = ? AND lesson_id = ?',
          whereArgs: [userId, lessonId],
        );
        if (maps.isNotEmpty) {
          return maps.first['stars_earned'] as int? ?? 0;
        }
      } catch (e) {
        debugPrint('SQLite Error in getLessonProgressStars: $e');
      }
      return 0;
    }

    try {
      final url = await getBaseUrl();
      final response = await http.get(Uri.parse('$url?action=get_lesson_progress_stars&userId=$userId&lessonId=$lessonId')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      _handleError(e, 'getLessonProgressStars');
    }
    return 0;
  }

  // --- Rewards CRUD & Dynamic Check ---
  Future<void> checkAndUnlockRewards(int userId) async {
    if (!await shouldUseMysql()) {
      try {
        final db = await getLocalDb();
        final List<Map<String, dynamic>> countResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM rewards WHERE user_id = ?',
          [userId],
        );
        final count = countResult.first['count'] as int? ?? 0;

        if (count == 0) {
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
          for (var r in defaultRewards) {
            await db.insert('rewards', {
              'user_id': userId,
              'reward_name': r['reward_name'],
              'image_path': r['image_path'],
              'is_unlocked': 0,
            });
          }
        }

        // Auto unlock logic based on stars/completed progress
        final List<Map<String, dynamic>> summaryResult = await db.rawQuery(
          'SELECT SUM(stars_earned) as totalStars, COUNT(CASE WHEN stars_earned > 0 THEN 1 END) as completedCount FROM progress WHERE user_id = ?',
          [userId],
        );
        final summary = summaryResult.first;
        final totalStars = summary['totalStars'] as int? ?? 0;
        final completedCount = summary['completedCount'] as int? ?? 0;

        final List<Map<String, dynamic>> details = await db.rawQuery(
          'SELECT p.stars_earned, l.grade, l.subject FROM progress p JOIN lessons l ON p.lesson_id = l.id WHERE p.user_id = ?',
          [userId],
        );

        int laoG1Stars = 0; int laoG2Stars = 0; int mathG1Stars = 0; int mathG2Stars = 0;
        for (var row in details) {
          final stars = row['stars_earned'] as int? ?? 0;
          final grade = row['grade'] as String? ?? '';
          final subject = row['subject'] as String? ?? '';

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
          for (var rewardName in toUnlock) {
            await db.update(
              'rewards',
              {'is_unlocked': 1},
              where: 'user_id = ? AND reward_name = ?',
              whereArgs: [userId, rewardName],
            );
          }
        }
      } catch (e) {
        debugPrint('SQLite Error in checkAndUnlockRewards: $e');
      }
      return;
    }

    try {
      final url = await getBaseUrl();
      await http.get(Uri.parse('$url?action=check_and_unlock_rewards&userId=$userId')).timeout(const Duration(seconds: 5));
    } catch (e) {
      _handleError(e, 'checkAndUnlockRewards');
    }
  }

  Future<List<Reward>> getRewardsForUser(int userId) async {
    if (!await shouldUseMysql()) {
      try {
        final db = await getLocalDb();
        await checkAndUnlockRewards(userId);
        final List<Map<String, dynamic>> maps = await db.query('rewards', where: 'user_id = ?', whereArgs: [userId]);
        return maps.map((m) => Reward.fromMap(m)).toList();
      } catch (e) {
        debugPrint('SQLite Error in getRewardsForUser: $e');
      }
      return [];
    }

    try {
      final url = await getBaseUrl();
      // First ensure the user rewards are checked/seeded in MySQL
      await checkAndUnlockRewards(userId);

      final response = await http.get(Uri.parse('$url?action=get_rewards_for_user&userId=$userId')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => Reward.fromMap(json)).toList();
      }
    } catch (e) {
      _handleError(e, 'getRewardsForUser');
    }
    return [];
  }

  Future<void> updateRewardUnlockStatus(int userId, String rewardName, bool isUnlocked) async {
    if (!await shouldUseMysql()) {
      try {
        final db = await getLocalDb();
        await db.update(
          'rewards',
          {'is_unlocked': isUnlocked ? 1 : 0},
          where: 'user_id = ? AND reward_name = ?',
          whereArgs: [userId, rewardName],
        );
      } catch (e) {
        debugPrint('SQLite Error in updateRewardUnlockStatus: $e');
      }
      return;
    }

    try {
      final url = await getBaseUrl();
      await http.post(
        Uri.parse('$url?action=update_reward_unlock_status'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'userId': userId,
          'rewardName': rewardName,
          'isUnlocked': isUnlocked ? 1 : 0,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      _handleError(e, 'updateRewardUnlockStatus');
    }
  }

  Future<List<Map<String, dynamic>>> getUserProgressDetailed(int userId) async {
    if (!await shouldUseMysql()) {
      try {
        final db = await getLocalDb();
        final List<Map<String, dynamic>> list = await db.rawQuery('''
          SELECT p.id as progress_id, p.stars_earned, p.is_completed, p.last_played,
                 l.id as lesson_id, l.grade, l.subject, l.title, l.total_stars as max_stars
          FROM lessons l
          LEFT JOIN progress p ON l.id = p.lesson_id AND p.user_id = ?
        ''', [userId]);

        final progressList = List<Map<String, dynamic>>.from(list);

        int extractLessonNumber(String title) {
          final match = RegExp(r'ບົດທີ\s*(\d+)').firstMatch(title);
          if (match != null) {
            return int.tryParse(match.group(1) ?? '') ?? 999;
          }
          return 999;
        }

        progressList.sort((a, b) {
          final gradeCompare = (a['grade'] as String).compareTo(b['grade'] as String);
          if (gradeCompare != 0) return gradeCompare;

          final subjectCompare = (a['subject'] as String).compareTo(b['subject'] as String);
          if (subjectCompare != 0) return subjectCompare;

          final numA = extractLessonNumber(a['title'] as String);
          final numB = extractLessonNumber(b['title'] as String);
          return numA.compareTo(numB);
        });

        return progressList;
      } catch (e) {
        debugPrint('SQLite Error in getUserProgressDetailed: $e');
      }
      return [];
    }

    try {
      final url = await getBaseUrl();
      final response = await http.get(Uri.parse('$url?action=get_user_progress_detailed&userId=$userId')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final progressList = List<Map<String, dynamic>>.from(list);

        int extractLessonNumber(String title) {
          final match = RegExp(r'ບົດທີ\s*(\d+)').firstMatch(title);
          if (match != null) {
            return int.tryParse(match.group(1) ?? '') ?? 999;
          }
          return 999;
        }

        progressList.sort((a, b) {
          final gradeCompare = (a['grade'] as String).compareTo(b['grade'] as String);
          if (gradeCompare != 0) return gradeCompare;

          final subjectCompare = (a['subject'] as String).compareTo(b['subject'] as String);
          if (subjectCompare != 0) return subjectCompare;

          final numA = extractLessonNumber(a['title'] as String);
          final numB = extractLessonNumber(b['title'] as String);
          return numA.compareTo(numB);
        });

        return progressList;
      }
    } catch (e) {
      _handleError(e, 'getUserProgressDetailed');
    }
    return [];
  }

  Future<void> resetUserProgress(int userId, int lessonId) async {
    if (!await shouldUseMysql()) {
      try {
        final db = await getLocalDb();
        await db.delete('progress', where: 'user_id = ? AND lesson_id = ?', whereArgs: [userId, lessonId]);

        // Recalculate score
        final List<Map<String, dynamic>> scoreResult = await db.rawQuery(
          'SELECT SUM(stars_earned) as total FROM progress WHERE user_id = ?',
          [userId],
        );
        final totalScore = scoreResult.first['total'] as int? ?? 0;

        await db.update(
          'users',
          {'score': totalScore},
          where: 'id = ?',
          whereArgs: [userId],
        );
      } catch (e) {
        debugPrint('SQLite Error in resetUserProgress: $e');
      }
      return;
    }

    try {
      final url = await getBaseUrl();
      await http.get(Uri.parse('$url?action=reset_user_progress&userId=$userId&lessonId=$lessonId')).timeout(const Duration(seconds: 5));
    } catch (e) {
      _handleError(e, 'resetUserProgress');
    }
  }
}
