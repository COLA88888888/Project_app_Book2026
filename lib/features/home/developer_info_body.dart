import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class DeveloperInfoBody extends StatelessWidget {
  const DeveloperInfoBody({super.key});

  @override
  Widget build(BuildContext context) {
    // List of developers - edit this list to add/change developer info!
    final developers = [
      _DeveloperInfo(
        name: 'ທ້າວ ແກ້ວອຸນເຮືອນ ວົງພະນາມ',
        role: 'ຜູ້ພັດທະນາລະບົບ (Developer)',
        phone: '020 95 321 848',
        facebook: 'Keounheuan Vongphanam',
        emoji: '💻',
        gradientColors: [const Color(0xFF3E8EF7), const Color(0xFF6EBEFB)],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_rounded,
                  size: 32,
                  color: Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ຜູ້ພັດທະນາ 🌟',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ຂໍ້ມູນຕິດຕໍ່ ແລະ ຜູ້ສ້າງແອັບພລິເຄຊັນ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fade(duration: 500.ms).slideY(begin: -0.1),
        const SizedBox(height: 20),

        // Scrollable list of developers
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: developers.length,
            itemBuilder: (context, index) {
              final dev = developers[index];
              return _buildDeveloperCard(context, dev, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDeveloperCard(BuildContext context, _DeveloperInfo dev, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // Card header with profile background
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: dev.gradientColors,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dev.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dev.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dev.role,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Contact Details Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildContactRow(
                    context,
                    icon: Icons.phone_rounded,
                    iconColor: const Color(0xFF38B264),
                    title: 'ເບີໂທລະສັບ / WhatsApp',
                    value: dev.phone,
                  ),
                  const Divider(height: 24, thickness: 0.8),
                  _buildContactRow(
                    context,
                    icon: Icons.facebook_rounded,
                    iconColor: const Color(0xFF1877F2),
                    title: 'ເຟສບຸກ (Facebook)',
                    value: dev.facebook,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms, delay: (150 * index).ms).slideY(
          begin: 0.15,
          end: 0,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildContactRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
        ),
        // Copy Button for easy contact copy
        IconButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'ຄັດລອກ "$value" ແລ້ວ! 📋',
                  style: const TextStyle(fontFamily: 'NotoSansLao'),
                ),
                backgroundColor: iconColor,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          icon: const Icon(
            Icons.copy_rounded,
            color: Colors.grey,
            size: 20,
          ),
          tooltip: 'ຄັດລອກ',
        ),
      ],
    );
  }
}

class _DeveloperInfo {
  final String name;
  final String role;
  final String phone;
  final String facebook;
  final String emoji;
  final List<Color> gradientColors;

  _DeveloperInfo({
    required this.name,
    required this.role,
    required this.phone,
    required this.facebook,
    required this.emoji,
    required this.gradientColors,
  });
}
