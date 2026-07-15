import 'package:flutter/material.dart';

// ── ຊ່ວຍຈັດການ Avatar ຂອງຜູ້ໃຊ້ ───────────────────────────
class AvatarHelper {
  // ຕາຕະລາງ avatar: ID → emoji, ຊື່, ສີ
  static const Map<int, Map<String, String>> avatars = {
    1: {'emoji': '🐻', 'name': 'ໝີນ້ອຍ', 'color': '0xFF8D6E63'},
    2: {'emoji': '🐯', 'name': 'ເສືອນ້ອຍ', 'color': '0xFFFFB74D'},
    3: {'emoji': '🐰', 'name': 'ກະຕ່າຍນ້ອຍ', 'color': '0xFFF48FB1'},
    4: {'emoji': '🐼', 'name': 'ແພນດ້າ', 'color': '0xFF90A4AE'},
    5: {'emoji': '🦊', 'name': 'ໝີຈິ້ງຈອກ', 'color': '0xFFFF7043'},
    6: {'emoji': '🦁', 'name': 'ສິງໂຕນ້ອຍ', 'color': '0xFFFFD54F'},
  };

  // ດຶງ emoji ຈາກ avatarId
  static String getEmoji(int avatarId) {
    return avatars[avatarId]?['emoji'] ?? '👶';
  }

  // ດຶງຊື່ avatar ຈາກ avatarId
  static String getName(int avatarId) {
    return avatars[avatarId]?['name'] ?? 'ນ້ອງນ້ອຍ';
  }

  // ດຶງ Color object ຈາກ avatarId
  static Color getColor(int avatarId) {
    final hexString = avatars[avatarId]?['color'] ?? '0xFF3E8EF7';
    return Color(int.parse(hexString));
  }
}
