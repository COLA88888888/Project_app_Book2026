import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'ລະບົບຫຼັງບ້ານ (Admin)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF3E8EF7),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'ເມນູການຈັດການລະບົບ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
          ).animate().fade().slideX(begin: -0.1),

          AdminMenuCard(
            title: 'ຈັດການບົດຮຽນ (Lessons)',
            subtitle: 'ເພີ່ມ, ລຶບ ແລະ ແກ້ໄຂບົດຮຽນທັງໝົດໃນລະບົບ',
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFF38B264),
            bgColor: const Color(0xFFE8F5E9),
            index: 0,
            onTap: () {
              context.push('/admin/lessons');
            },
          ),
          const SizedBox(height: 16),

          AdminMenuCard(
            title: 'ຈັດການລາງວັນ (Rewards)',
            subtitle: 'ຈັດການສະຕິກເກີ ແລະ ລາງວັນຂອງເດັກນ້ອຍ',
            icon: Icons.stars_rounded,
            iconColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
            index: 1,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ລະບົບຈັດການລາງວັນ ກຳລັງພັດທະນາ...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          AdminMenuCard(
            title: 'ຕິດຕາມຜົນການຮຽນ',
            subtitle: 'ເບິ່ງລາຍງານ ແລະ ຄວາມຄືບໜ້າການຮຽນຂອງເດັກນ້ອຍ',
            icon: Icons.analytics_rounded,
            iconColor: const Color(0xFFFF6B6B),
            bgColor: const Color(0xFFFFEBEE),
            index: 2,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ລະບົບຕິດຕາມຜົນການຮຽນ ກຳລັງພັດທະນາ...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AdminMenuCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;
  final int index;

  const AdminMenuCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
    required this.index,
  });

  @override
  State<AdminMenuCard> createState() => _AdminMenuCardState();
}

class _AdminMenuCardState extends State<AdminMenuCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTapDown: (_) => setState(() => _scale = 0.98),
          onTapUp: (_) => setState(() => _scale = 1.0),
          onTapCancel: () => setState(() => _scale = 1.0),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.bgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(widget.icon, size: 32, color: widget.iconColor),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fade(duration: 400.ms, delay: (80 * widget.index).ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}
