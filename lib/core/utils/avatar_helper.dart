import 'package:flutter/material.dart';

class AvatarHelper {
  static const Map<int, Map<String, String>> avatars = {
    1: {'emoji': '🐻', 'name': 'ໝີນ້ອຍ', 'color': '0xFF8D6E63'},
    2: {'emoji': '🐯', 'name': 'ເສືອນ້ອຍ', 'color': '0xFFFFB74D'},
    3: {'emoji': '🐰', 'name': 'ກະຕ່າຍນ້ອຍ', 'color': '0xFFF48FB1'},
    4: {'emoji': '🐼', 'name': 'ແພນດ້າ', 'color': '0xFF90A4AE'},
    5: {'emoji': '🦊', 'name': 'ໝີຈິ້ງຈອກ', 'color': '0xFFFF7043'},
    6: {'emoji': '🦁', 'name': 'ສິງໂຕນ້ອຍ', 'color': '0xFFFFD54F'},
  };

  static String getEmoji(int avatarId) {
    return avatars[avatarId]?['emoji'] ?? '👶';
  }

  static String getName(int avatarId) {
    return avatars[avatarId]?['name'] ?? 'ນ້ອງນ້ອຍ';
  }

  static Color getColor(int avatarId) {
    final hexString = avatars[avatarId]?['color'] ?? '0xFF3E8EF7';
    return Color(int.parse(hexString));
  }
}
