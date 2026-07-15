// ── Model ຂໍ້ມູນລາງວັນ ──────────────────────────────────────
class Reward {
  final int? id;
  final int userId;
  final String rewardName;
  final String imagePath;
  final bool isUnlocked;

  Reward({
    this.id,
    required this.userId,
    required this.rewardName,
    required this.imagePath,
    this.isUnlocked = false,
  });

  // isUnlocked ເກັບໃນ DB ເປັນ int (1=ປົດລັອກ, 0=ຍັງລັອກ)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'reward_name': rewardName,
      'image_path': imagePath,
      'is_unlocked': isUnlocked ? 1 : 0,
    };
  }

  factory Reward.fromMap(Map<String, dynamic> map) {
    return Reward(
      id: map['id'],
      userId: map['user_id'],
      rewardName: map['reward_name'],
      imagePath: map['image_path'],
      isUnlocked: map['is_unlocked'] == 1,
    );
  }
}
