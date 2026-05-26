import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/lesson.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddEditLessonScreen extends StatefulWidget {
  const AddEditLessonScreen({super.key});

  @override
  State<AddEditLessonScreen> createState() => _AddEditLessonScreenState();
}

class _AddEditLessonScreenState extends State<AddEditLessonScreen> {
  String _grade = 'P1';
  final _subjectController = TextEditingController(text: 'Lao');
  final _titleController = TextEditingController();
  final _starsController = TextEditingController(text: '3');

  @override
  void dispose() {
    _subjectController.dispose();
    _titleController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  Future<void> _saveLesson() async {
    final title = _titleController.text.trim();
    final subject = _subjectController.text.trim();
    final stars = int.tryParse(_starsController.text) ?? 3;

    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ກະລຸນາພິມຊື່ວິຊາກ່ອນເດີ້!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ກະລຸນາພິມຊື່ບົດຮຽນກ່ອນເດີ້!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final lesson = Lesson(
      grade: _grade,
      subject: subject,
      title: title,
      totalStars: stars,
    );

    await DatabaseHelper.instance.createLesson(lesson);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ເພີ່ມບົດຮຽນໃໝ່ສຳເລັດແລ້ວ! 🎉'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop();
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF3E8EF7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3E8EF7), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'ເພີ່ມບົດຮຽນໃໝ່',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_rounded,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'ກະລຸນາປ້ອນຂໍ້ມູນດ້ານລຸ່ມໃຫ້ຄົບຖ້ວນ ເພື່ອເພີ່ມບົດຮຽນໃໝ່ເຂົ້າໃນລະບົບ.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fade().slideY(begin: -0.1),
            const SizedBox(height: 24),

            // Form container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Grade Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _grade,
                    decoration: _buildInputDecoration(
                      labelText: 'ຊັ້ນຮຽນ',
                      prefixIcon: Icons.school_rounded,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'P1', child: Text('ປ.1')),
                      DropdownMenuItem(value: 'P2', child: Text('ປ.2')),
                    ],
                    onChanged: (value) => setState(() => _grade = value!),
                  ),
                  const SizedBox(height: 18),

                  // Subject Textfield
                  TextField(
                    controller: _subjectController,
                    decoration: _buildInputDecoration(
                      labelText: 'ວິຊາ',
                      prefixIcon: Icons.auto_stories_rounded,
                    ).copyWith(hintText: 'ເຊັ່ນ: ພາສາລາວ, ຄະນິດສາດ, ພາສາອັງກິດ'),
                  ),
                  const SizedBox(height: 18),

                  // Title Textfield
                  TextField(
                    controller: _titleController,
                    decoration: _buildInputDecoration(
                      labelText: 'ຊື່ບົດຮຽນ',
                      prefixIcon: Icons.edit_note_rounded,
                    ).copyWith(hintText: 'ເຊັ່ນ: ພະຍັນຊະນະ ກ-ງ'),
                  ),
                  const SizedBox(height: 18),

                  // Stars Textfield
                  TextField(
                    controller: _starsController,
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDecoration(
                      labelText: 'ຈຳນວນດາວເຕັມ',
                      prefixIcon: Icons.star_rounded,
                    ),
                  ),
                ],
              ),
            ).animate().fade(delay: 100.ms),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38B264),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                shadowColor: const Color(0xFF38B264).withValues(alpha: 0.3),
              ),
              onPressed: _saveLesson,
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: const Text(
                'ບັນທຶກບົດຮຽນ',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
          ],
        ),
      ),
    );
  }
}
