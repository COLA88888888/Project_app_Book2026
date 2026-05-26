import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_profile.dart';
import '../models/lesson.dart';
import '../models/reward.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('edu_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Drop all tables and recreate them if schema changes during development
    await db.execute('DROP TABLE IF EXISTS users');
    await db.execute('DROP TABLE IF EXISTS lessons');
    await db.execute('DROP TABLE IF EXISTS progress');
    await db.execute('DROP TABLE IF EXISTS rewards');
    await _createDB(db, newVersion);
  }

  Future _createDB(Database db, int version) async {
    // 1. Users Table
    await db.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  avatarId INTEGER NOT NULL,
  score INTEGER NOT NULL
)
''');

    // 2. Lessons Table
    await db.execute('''
CREATE TABLE lessons (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    grade TEXT,
    subject TEXT,
    title TEXT,
    total_stars INTEGER
)
''');

    // 3. Progress Table (Added user_id to track which child played)
    await db.execute('''
CREATE TABLE progress (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    lesson_id INTEGER,
    stars_earned INTEGER,
    is_completed INTEGER,
    last_played TEXT,
    FOREIGN KEY (user_id) REFERENCES users (id),
    FOREIGN KEY (lesson_id) REFERENCES lessons (id)
)
''');

    // 4. Rewards Table (Added user_id to track which child unlocked it)
    await db.execute('''
CREATE TABLE rewards (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    reward_name TEXT,
    image_path TEXT,
    is_unlocked INTEGER,
    FOREIGN KEY (user_id) REFERENCES users (id)
)
''');
  }

  Future<UserProfile> createUser(UserProfile user) async {
    final db = await instance.database;
    final id = await db.insert('users', user.toMap());
    return UserProfile(
      id: id,
      name: user.name,
      phone: user.phone,
      avatarId: user.avatarId,
      score: user.score,
    );
  }

  Future<List<UserProfile>> readAllUsers() async {
    final db = await instance.database;
    const orderBy = 'id ASC';
    final result = await db.query('users', orderBy: orderBy);

    return result.map((json) => UserProfile.fromMap(json)).toList();
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // --- Lessons CRUD ---
  Future<Lesson> createLesson(Lesson lesson) async {
    final db = await instance.database;
    final id = await db.insert('lessons', lesson.toMap());
    return Lesson(
      id: id,
      grade: lesson.grade,
      subject: lesson.subject,
      title: lesson.title,
      totalStars: lesson.totalStars,
    );
  }

  Future<List<Lesson>> getAllLessons() async {
    final db = await instance.database;
    final result = await db.query('lessons', orderBy: 'grade ASC, subject ASC');
    return result.map((json) => Lesson.fromMap(json)).toList();
  }

  Future<List<String>> getAllUniqueSubjects() async {
    final db = await instance.database;
    final result = await db.query(
      'lessons',
      columns: ['subject'],
      groupBy: 'subject',
      orderBy: 'subject ASC',
    );
    return result.map((row) => row['subject'] as String).toList();
  }

  Future<List<String>> getSubjectsForGrade(String grade) async {
    final db = await instance.database;
    final result = await db.query(
      'lessons',
      columns: ['subject'],
      where: 'grade = ?',
      whereArgs: [grade],
      groupBy: 'subject',
      orderBy: 'subject ASC',
    );
    return result.map((row) => row['subject'] as String).toList();
  }

  Future<int> deleteLesson(int id) async {
    final db = await instance.database;
    return await db.delete('lessons', where: 'id = ?', whereArgs: [id]);
  }

  // --- Seeding & Progress CRUD ---
  Future<void> seedInitialLessonsIfEmpty() async {
    final db = await instance.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM lessons'),
    );
    if (count == 0) {
      // ── P1 Lao: ພາສາລາວ ──────────────────────────────────────────────────────
      // ຊຸດ 1: ພະຍັນຊະນະ + ສະຫຼະ (14 ບົດ)
      await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 1: ພະຍັນຊະນະ ກ, ຂ & ສະຫຼະ xະ, xາ', totalStars: 3));
      await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 2: ພະຍັນຊະນະ ຄ, ງ & ສະຫຼະ xິ, xີ', totalStars: 3));
      await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 3: ພະຍັນຊະນະ ຈ, ສ & ສະຫຼະ xຶ, xື', totalStars: 3));
      await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 4: ພະຍັນຊະນະ ຊ, ຍ & ສະຫຼະ xຸ, xູ', totalStars: 3));
      await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 5: ພະຍັນຊະນະ ດ, ຕ & ສະຫຼະ ເxະ, ເx', totalStars: 3));
      await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 6: ພະຍັນຊະນະ ຖ, ທ & ສະຫຼະ ແxະ, ແx', totalStars: 3));
      await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 7: ພະຍັນຊະນະ ນ, ບ & ສະຫຼະ ໂxະ, ໂx', totalStars: 3));
      await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 8: ພະຍັນຊະນະ ປ, ຜ & ສະຫຼະ ເxາະ, xໍ', totalStars: 3));
      await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 9: ພະຍັນຊະນະ ຝ, ພ & ສະຫຼະ ເxີ, ເxີຍ', totalStars: 3));
      await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 10: ພະຍັນຊະນະ ຟ, ມ & ສະຫຼະ xົ, xົວ', totalStars: 3));
      await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 11: ພະຍັນຊະນະ ຢ, ຣ & ສະຫຼະ ເxຍ, ເxືອ', totalStars: 3));
      await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 12: ພະຍັນຊະນະ ລ, ວ & ສະຫຼະ xຳ, ໄx, ໃx, xົາ', totalStars: 3));
      await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 13: ພະຍັນຊະນະ ຫ, ອ, ຮ & ທວນຄືນສະຫຼະທັງໝົດ', totalStars: 3));
      await createLesson(Lesson(grade: 'P1', subject: 'ພາສາລາວ', title: 'ບົດທີ 14: ວັນນະຍຸດ ໄມ້ເອກ (x่) ແລະ ໄມ້ໂທ (x้)', totalStars: 3));

      // ຊຸດ 2: ໝວດອັກສອນ + ສະຫຼະຄົບຊຸດ (9 ບົດ)
      await createLesson(Lesson(grade: 'P1', subject: 'ການອ່ານ', title: 'ໂຈດອ່ານ 1: ອັກສອນກາງ ກ ຈ ດ ຕ ບ ປ ອ', totalStars: 5));
      await createLesson(Lesson(grade: 'P1', subject: 'ການອ່ານ', title: 'ໂຈດອ່ານ 2: ອັກສອນສູງ ຂ ສ ຖ ຝ ຫ', totalStars: 5));
      await createLesson(Lesson(grade: 'P1', subject: 'ການອ່ານ', title: 'ໂຈດອ່ານ 3: ອັກສອນຕໍ່າ ຄ ງ ຊ ຍ ທ ນ', totalStars: 5));
      await createLesson(Lesson(grade: 'P1', subject: 'ການອ່ານ', title: 'ໂຈດອ່ານ 4: ອັກສອນຕໍ່າ ຜ ພ ຟ ມ ຢ ລ ວ ຮ', totalStars: 5));
      await createLesson(Lesson(grade: 'P1', subject: 'ການອ່ານ', title: 'ໂຈດອ່ານ 5: ອັກສອນປະສົມ ຫງ ຫຍ ໜ ໝ ຫຼ ຫວ', totalStars: 5));
      await createLesson(Lesson(grade: 'P1', subject: 'ການອ່ານ', title: 'ໂຈດອ່ານ 6: ສະຫຼະສຽງສັ້ນ xະ xິ xຶ xຸ', totalStars: 5));
      await createLesson(Lesson(grade: 'P1', subject: 'ການອ່ານ', title: 'ໂຈດອ່ານ 7: ສະຫຼະສຽງຍາວ xາ xີ xື xູ', totalStars: 5));
      await createLesson(Lesson(grade: 'P1', subject: 'ການອ່ານ', title: 'ໂຈດອ່ານ 8: ສະຫຼະ ເx ແx ໂx xໍ', totalStars: 5));
      await createLesson(Lesson(grade: 'P1', subject: 'ການອ່ານ', title: 'ໂຈດອ່ານ 9: ສະຫຼະພິເສດ xຳ ໄx ໃx ເxົາ xົວ ເxຍ ເxືອ', totalStars: 5));

      // ── P1 ຄະນິດສາດ ────────────────────────────────────────────────────────────
      await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 1: ການນັບຈຳນວນ 1 ຮອດ 10', totalStars: 3));
      await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 2: ການປຽບທຽບຈຳນວນ (ຫຼາຍ/ໜ້ອຍ)', totalStars: 3));
      await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 3: ການບວກຈຳນວນ (ບໍ່ເກີນ 10)', totalStars: 3));
      await createLesson(Lesson(grade: 'P1', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 4: ການລົບຈຳນວນ (ບໍ່ເກີນ 10)', totalStars: 3));

      // ── P2 ພາສາລາວ ────────────────────────────────────────────────────────────
      await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 1: ພະຍັນຊະນະຄວບ ກວ, ຄວ, ຂວ', totalStars: 3));
      await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 2: ພະຍັນຊະນະປະສົມ ໝ, ຫຼ', totalStars: 3));
      await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 3: ຕົວສະກົດທັງ 8 (ກ, ດ, ບ, ງ, ນ, ມ, ຍ, ວ)', totalStars: 3));
      await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 4: ຄຳນາມ, ຄຳແທນນາມ ແລະ ຄຳກຳມະ', totalStars: 3));
      await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 5: ຄຳຄຸນນາມ ແລະ ການແຕ່ງປະໂຫຍກ', totalStars: 3));
      await createLesson(Lesson(grade: 'P2', subject: 'ພາສາລາວ', title: 'ບົດທີ 6: ການອ່ານບົດເລື່ອງສັ້ນ ແລະ ຕອບຄຳຖາມ', totalStars: 3));

      // ── P2 ຄະນິດສາດ ────────────────────────────────────────────────────────────
      await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 1: ການບວກເລກສອງຫຼັກ (ມີຕົວຈື່)', totalStars: 3));
      await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 2: ການລົບເລກສອງຫຼັກ (ມີຢືມ)', totalStars: 3));
      await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 3: ສູດຄູນ ບົດແນະນຳການຄູນ', totalStars: 3));
      await createLesson(Lesson(grade: 'P2', subject: 'ຄະນິດສາດ', title: 'ບົດທີ 4: ຮູບເລຂາຄະນິດສາມມິຕິ', totalStars: 3));
    }
  }

  Future<void> saveProgress(int userId, int lessonId, int starsEarned) async {
    final db = await instance.database;

    // Check if progress already exists
    final result = await db.query(
      'progress',
      where: 'user_id = ? AND lesson_id = ?',
      whereArgs: [userId, lessonId],
    );

    if (result.isEmpty) {
      await db.insert('progress', {
        'user_id': userId,
        'lesson_id': lessonId,
        'stars_earned': starsEarned,
        'is_completed': 1,
        'last_played': DateTime.now().toIso8601String(),
      });
    } else {
      final currentStars = result.first['stars_earned'] as int;
      if (starsEarned > currentStars) {
        await db.update(
          'progress',
          {
            'stars_earned': starsEarned,
            'last_played': DateTime.now().toIso8601String(),
          },
          where: 'user_id = ? AND lesson_id = ?',
          whereArgs: [userId, lessonId],
        );
      }
    }

    // Update user score (sum of all stars earned)
    final progressResult = await db.query(
      'progress',
      columns: ['stars_earned'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    int totalScore = 0;
    for (var row in progressResult) {
      totalScore += row['stars_earned'] as int;
    }

    await db.update(
      'users',
      {'score': totalScore},
      where: 'id = ?',
      whereArgs: [userId],
    );

    // Dynamic reward unlocking check
    await checkAndUnlockRewards(userId);
  }

  Future<int> getLessonProgressStars(int userId, int lessonId) async {
    final db = await instance.database;
    final result = await db.query(
      'progress',
      columns: ['stars_earned'],
      where: 'user_id = ? AND lesson_id = ?',
      whereArgs: [userId, lessonId],
    );
    if (result.isEmpty) return 0;
    return result.first['stars_earned'] as int;
  }

  // --- Rewards CRUD & Dynamic Check ---
  Future<void> checkAndUnlockRewards(int userId) async {
    final db = await instance.database;

    // 1. Ensure the user has the 9 rewards seeded in the table.
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) FROM rewards WHERE user_id = ?',
      [userId],
    );
    final count = Sqflite.firstIntValue(countResult) ?? 0;
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
        {'reward_name': 'ອັດສະລິຍະຕົວນ້ອຍ', 'image_path': '🏆'},
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

    // 2. Fetch current achievements
    final progressResult = await db.query(
      'progress',
      columns: ['stars_earned', 'lesson_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    int totalStars = 0;
    int completedCount = 0;
    int laoG1Stars = 0;
    int laoG2Stars = 0;
    int mathG1Stars = 0;
    int mathG2Stars = 0;

    final lessons = await getAllLessons();
    final lessonMap = {for (var l in lessons) l.id: l};

    for (var row in progressResult) {
      final stars = row['stars_earned'] as int;
      final lessonId = row['lesson_id'] as int;
      totalStars += stars;
      if (stars > 0) completedCount++;

      final lesson = lessonMap[lessonId];
      if (lesson != null) {
        if (lesson.grade == 'P1' &&
            (lesson.subject == 'ພາສາລາວ' || lesson.subject == 'ການອ່ານ')) {
          laoG1Stars += stars;
        } else if (lesson.grade == 'P2' && lesson.subject == 'ພາສາລາວ') {
          laoG2Stars += stars;
        } else if (lesson.grade == 'P1' && lesson.subject == 'ຄະນິດສາດ') {
          mathG1Stars += stars;
        } else if (lesson.grade == 'P2' && lesson.subject == 'ຄະນິດສາດ') {
          mathG2Stars += stars;
        }
      }
    }

    // Determine which rewards to unlock
    final List<String> toUnlock = [];

    if (laoG1Stars >= 3) toUnlock.add('ຍອດນັກອ່ານ ປ.1');
    if (laoG2Stars >= 3) toUnlock.add('ຍອດນັກອ່ານ ປ.2');
    if (mathG1Stars >= 3) toUnlock.add('ນັກຄິດໄວ ປ.1');
    if (mathG2Stars >= 3) toUnlock.add('ນັກຄິດໄວ ປ.2');
    if (totalStars >= 10) toUnlock.add('ດາວເດັ່ນຮຽນເກັ່ງ');
    if (totalStars >= 15) toUnlock.add('ແຊມປ້ຽນຫຼຽນທອງ');
    if (totalStars >= 25) toUnlock.add('ແຊມປ້ຽນຫຼຽນເງິນ');
    if (totalStars >= 35) toUnlock.add('ແຊມປ້ຽນຫຼຽນຄຳ');
    if (completedCount >= 25) toUnlock.add('ອັດສະລິຍະຕົວນ້ອຍ');

    // Update the database to unlock these rewards
    if (toUnlock.isNotEmpty) {
      final placeholders = List.filled(toUnlock.length, '?').join(',');
      await db.update(
        'rewards',
        {'is_unlocked': 1},
        where: 'user_id = ? AND reward_name IN ($placeholders)',
        whereArgs: [userId, ...toUnlock],
      );
    }
  }

  Future<List<Reward>> getRewardsForUser(int userId) async {
    final db = await instance.database;
    // First, ensure rewards are seeded and checked
    await checkAndUnlockRewards(userId);

    final result = await db.query(
      'rewards',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return result.map((json) => Reward.fromMap(json)).toList();
  }
}
