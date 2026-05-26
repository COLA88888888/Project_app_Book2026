class Progress {
  final int? id;
  final int userId;
  final int lessonId;
  final int starsEarned;
  final bool isCompleted;
  final String lastPlayed;

  Progress({
    this.id,
    required this.userId,
    required this.lessonId,
    required this.starsEarned,
    required this.isCompleted,
    required this.lastPlayed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'lesson_id': lessonId,
      'stars_earned': starsEarned,
      'is_completed': isCompleted ? 1 : 0,
      'last_played': lastPlayed,
    };
  }

  factory Progress.fromMap(Map<String, dynamic> map) {
    return Progress(
      id: map['id'],
      userId: map['user_id'],
      lessonId: map['lesson_id'],
      starsEarned: map['stars_earned'],
      isCompleted: map['is_completed'] == 1,
      lastPlayed: map['last_played'],
    );
  }
}
