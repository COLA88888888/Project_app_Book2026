// ── Model ຂໍ້ມູນບົດຮຽນ ─────────────────────────────────────
class Lesson {
  final int? id;
  final String grade; // 'P1' or 'P2'
  final String subject; // 'Lao' or 'Math'
  final String title;
  final int totalStars;

  Lesson({
    this.id,
    required this.grade,
    required this.subject,
    required this.title,
    required this.totalStars,
  });

  // ── ແປງ object → Map ────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grade': grade,
      'subject': subject,
      'title': title,
      'total_stars': totalStars,
    };
  }

  // ── ສ້າງ Lesson ຈາກ Map (ດຶງຈາກ DB) ─────────────────────
  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'],
      grade: map['grade'],
      subject: map['subject'],
      title: map['title'],
      totalStars: map['total_stars'],
    );
  }
}
