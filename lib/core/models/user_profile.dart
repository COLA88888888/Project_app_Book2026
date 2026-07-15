// ── Model ຂໍ້ມູນຜູ້ໃຊ້ (User Profile) ────────────────────
class UserProfile {
  final int? id;

  // ── ຂໍ້ມູນຫຼານນ້ອຍ (ຜູ້ຮຽນ) ──────────────────────────
  final String name;       // ຊື່ຫຼານ
  final int avatarId;      // ID ຮູບໂປຣໄຟລ໌

  // ── ຂໍ້ມູນຜູ້ປົກຄອງ/ລະບົບ ────────────────────────────────────
  final String phone;      // ເບີໂທຜູ້ປົກຄອງ
  final String password;   // ລະຫັດຜ່ານ
  final int score;         // ຄະແນນ
  final String createdAt;  // ວັນທີລົງທະບຽນ

  UserProfile({
    this.id,
    required this.name,
    required this.avatarId,
    required this.phone,
    required this.password,
    this.score = 0,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  // ── ແປງ object → Map (ສຳລັບບັນທຶກ DB) ──────────────────
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarId': avatarId,
      'phone': phone,
      'password': password,
      'score': score,
      'createdAt': createdAt,
    };
  }

  // ── ສ້າງ UserProfile ຈາກ Map (ດຶງຈາກ DB) ────────────────
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    int? parseId(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.tryParse(val.toString());
    }

    int parseIdNonNull(dynamic val, int defaultValue) {
      if (val == null) return defaultValue;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? defaultValue;
    }

    return UserProfile(
      id: parseId(map['id']),
      name: map['name'] ?? '',
      avatarId: parseIdNonNull(map['avatarId'], 1),
      phone: map['phone'] ?? '',
      password: map['password'] ?? '',
      score: parseIdNonNull(map['score'], 0),
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  // ── ສ້າງ copy ໃໝ່ທີ່ປ່ຽນສະເພາະບາງ field ──────────────
  UserProfile copyWith({
    int? id,
    String? name,
    int? avatarId,
    String? phone,
    String? password,
    int? score,
    String? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarId: avatarId ?? this.avatarId,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

