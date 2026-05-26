class UserProfile {
  final int? id;
  final String name;
  final String phone;
  final int avatarId; // ID or index for Avatar image
  final int score;

  UserProfile({
    this.id,
    required this.name,
    required this.phone,
    required this.avatarId,
    this.score = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'avatarId': avatarId,
      'score': score,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      name: map['name'],
      phone: map['phone'] ?? '',
      avatarId: map['avatarId'],
      score: map['score'],
    );
  }
}
