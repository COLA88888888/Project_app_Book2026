class UserProfile {
  final int? id;

  // ── ຂໍ້ມູນຫຼານນ້ອຍ (ຜູ້ຮຽນ) ──────────────────────────
  final String name;       // ຊື່ຫຼານ
  final String gender;     // ເພດ: 'ຊາຍ' | 'ຍິງ'
  final String birthDate;  // ວັນເດືອນປີເກີດ ISO8601
  final String grade;      // ຊັ້ນຮຽນ: 'P1' | 'P2'
  final String school;     // ຊື່ໂຮງຮຽນ
  final String province;   // ແຂວງ
  final int avatarId;      // ID ຮູບໂປຣໄຟລ໌

  // ── ຂໍ້ມູນຜູ້ປົກຄອງ ────────────────────────────────────
  final String parentName; // ຊື່ຜູ້ປົກຄອງ
  final String phone;      // ເບີໂທຜູ້ປົກຄອງ
  final String password;   // ລະຫັດຜ່ານ

  // ── ຂໍ້ມູນລະບົບ ─────────────────────────────────────────
  final int score;
  final String createdAt;  // ວັນທີລົງທະບຽນ

  UserProfile({
    this.id,
    required this.name,
    this.gender = '',
    this.birthDate = '',
    this.grade = '',
    this.school = '',
    this.province = '',
    required this.avatarId,
    this.parentName = '',
    required this.phone,
    required this.password,
    this.score = 0,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'birthDate': birthDate,
      'grade': grade,
      'school': school,
      'province': province,
      'avatarId': avatarId,
      'parentName': parentName,
      'phone': phone,
      'password': password,
      'score': score,
      'createdAt': createdAt,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      name: map['name'] ?? '',
      gender: map['gender'] ?? '',
      birthDate: map['birthDate'] ?? '',
      grade: map['grade'] ?? '',
      school: map['school'] ?? '',
      province: map['province'] ?? '',
      avatarId: map['avatarId'] ?? 1,
      parentName: map['parentName'] ?? '',
      phone: map['phone'] ?? '',
      password: map['password'] ?? '',
      score: map['score'] ?? 0,
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  /// ສ້າງ copy ໃໝ່ດ້ວຍ fields ທີ່ປ່ຽນ
  UserProfile copyWith({
    int? id,
    String? name,
    String? gender,
    String? birthDate,
    String? grade,
    String? school,
    String? province,
    int? avatarId,
    String? parentName,
    String? phone,
    String? password,
    int? score,
    String? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      grade: grade ?? this.grade,
      school: school ?? this.school,
      province: province ?? this.province,
      avatarId: avatarId ?? this.avatarId,
      parentName: parentName ?? this.parentName,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// ອາຍຸ (ຄຳນວນຈາກ birthDate)
  int get age {
    if (birthDate.isEmpty) return 0;
    try {
      final birth = DateTime.parse(birthDate);
      final now = DateTime.now();
      int years = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        years--;
      }
      return years;
    } catch (_) {
      return 0;
    }
  }

  /// ຊື່ຊັ້ນຮຽນ Lao display
  String get gradeLabel {
    switch (grade) {
      case 'P1': return 'ປ.1';
      case 'P2': return 'ປ.2';
      default: return grade;
    }
  }
}
