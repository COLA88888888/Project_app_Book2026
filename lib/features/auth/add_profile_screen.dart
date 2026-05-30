import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/user_profile.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/avatar_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';

// 18 ແຂວງ + ນະຄອນຫຼວງ
const List<String> kLaoProvinces = [
  'ນະຄອນຫຼວງວຽງຈັນ',
  'ວຽງຈັນ',
  'ໄຊສົມບູນ',
  'ຜົ້ງສາລີ',
  'ຫຼວງນໍ້າທາ',
  'ອຸດົມໄຊ',
  'ບໍ່ແກ້ວ',
  'ຫຼວງພະບາງ',
  'ຫົວພັນ',
  'ໄຊຍະບູລີ',
  'ຊຽງຂວາງ',
  'ບໍລິຄຳໄຊ',
  'ຄຳມ່ວນ',
  'ສະຫວັນນະເຂດ',
  'ສາລະວັນ',
  'ເຊກອງ',
  'ຈຳປາສັກ',
  'ອັດຕະປື',
];

class AddProfileScreen extends StatefulWidget {
  const AddProfileScreen({super.key});

  @override
  State<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen>
    with SingleTickerProviderStateMixin {
  // Page controller for multi-step form
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ── ຂໍ້ມູນຫຼານ ──────────────────────────────────────
  final TextEditingController _nameController = TextEditingController();
  String _gender = '';
  DateTime? _birthDate;
  String _grade = '';
  final TextEditingController _schoolController = TextEditingController();
  String _province = '';
  int _selectedAvatarId = 1;

  // ── ຂໍ້ມູນຜູ້ປົກຄອງ ──────────────────────────────────
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _schoolController.dispose();
    _parentNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Validators ───────────────────────────────────────
  bool _validateChildPage() {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('ກະລຸນາປ້ອນຊື່ຫຼານນ້ອຍ!', isError: true);
      return false;
    }
    if (_gender.isEmpty) {
      _showSnackBar('ກະລຸນາເລືອກເພດ!', isError: true);
      return false;
    }
    if (_grade.isEmpty) {
      _showSnackBar('ກະລຸນາເລືອກຊັ້ນຮຽນ!', isError: true);
      return false;
    }
    return true;
  }

  bool _validateParentPage() {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (_parentNameController.text.trim().isEmpty) {
      _showSnackBar('ກະລຸນາປ້ອນຊື່ຜູ້ປົກຄອງ!', isError: true);
      return false;
    }
    if (phone.isEmpty || phone.replaceAll(' ', '').length < 8) {
      _showSnackBar('ກະລຸນາປ້ອນເບີໂທທີ່ຖືກຕ້ອງ!', isError: true);
      return false;
    }
    if (password.isEmpty || password.length < 6) {
      _showSnackBar('ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 6 ຕົວ!', isError: true);
      return false;
    }
    if (password != confirm) {
      _showSnackBar('ລະຫັດຜ່ານ ແລະ ຢືນຢັນລະຫັດຜ່ານບໍ່ກົງກັນ! 🔑', isError: true);
      return false;
    }
    return true;
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF38B264),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage == 0 && !_validateChildPage()) return;
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 6),
      firstDate: DateTime(now.year - 15),
      lastDate: DateTime(now.year - 3),
      helpText: 'ເລືອກວັນເດືອນປີເກີດ',
      cancelText: 'ຍົກເລີກ',
      confirmText: 'ຕົກລົງ',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF3E8EF7),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _saveProfile() async {
    if (!_validateParentPage()) return;

    final user = UserProfile(
      name: _nameController.text.trim(),
      gender: _gender,
      birthDate: _birthDate?.toIso8601String() ?? '',
      grade: _grade,
      school: _schoolController.text.trim(),
      province: _province,
      avatarId: _selectedAvatarId,
      parentName: _parentNameController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    await DatabaseHelper.instance.createUser(user);

    if (!mounted) return;
    _showSnackBar('ລົງທະບຽນ "${user.name}" ສຳເລັດແລ້ວ! 🎉');
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) context.pop();
  }

  // ── UI Helpers ────────────────────────────────────────
  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF3E8EF7), size: 22),
      suffixIcon: suffix,
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

  // ── Step indicator ────────────────────────────────────
  Widget _buildStepIndicator() {
    final steps = ['ຂໍ້ມູນຫຼານ', 'ໂປຣໄຟລ໌', 'ຜູ້ປົກຄອງ'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _currentPage;
          final isDone = i < _currentPage;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isDone
                              ? const Color(0xFF38B264)
                              : Colors.grey.shade200,
                        ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isActive ? 32 : 26,
                      height: isActive ? 32 : 26,
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0xFF38B264)
                            : isActive
                                ? const Color(0xFF3E8EF7)
                                : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF3E8EF7).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.grey.shade500,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isActive ? 14 : 12,
                                ),
                              ),
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i < _currentPage
                              ? const Color(0xFF38B264)
                              : Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? const Color(0xFF3E8EF7)
                        : isDone
                            ? const Color(0xFF38B264)
                            : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Page 0: ຂໍ້ມູນຫຼານ ──────────────────────────────────
  Widget _buildChildPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('👦 ຂໍ້ມູນຫຼານນ້ອຍ'),
          const SizedBox(height: 16),

          // ຊື່ຫຼານ
          TextField(
            controller: _nameController,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
            decoration: _fieldDecoration(
              label: 'ຊື່ຫຼານນ້ອຍ (ຊື່ຫຼິ້ນ) *',
              hint: 'ພິມຊື່ຫຼານ',
              icon: Icons.person_rounded,
            ),
          ),
          const SizedBox(height: 16),

          // ເພດ
          _sectionLabel('ເພດ *'),
          const SizedBox(height: 8),
          Row(
            children: [
              _genderButton('ຊາຍ', '👦', _gender == 'ຊາຍ'),
              const SizedBox(width: 12),
              _genderButton('ຍິງ', '👧', _gender == 'ຍິງ'),
            ],
          ),
          const SizedBox(height: 16),

          // ວັນເດືອນປີເກີດ
          GestureDetector(
            onTap: _pickBirthDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake_rounded, color: Color(0xFF3E8EF7), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ວັນເດືອນປີເກີດ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _birthDate == null
                              ? 'ແຕະເພື່ອເລືອກວັນ'
                              : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _birthDate == null ? Colors.grey.shade400 : AppTheme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.calendar_month_rounded, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ຊັ້ນຮຽນ
          _sectionLabel('ຊັ້ນຮຽນ *'),
          const SizedBox(height: 8),
          Row(
            children: [
              _gradeButton('P1', 'ປ.1'),
              const SizedBox(width: 12),
              _gradeButton('P2', 'ປ.2'),
            ],
          ),
          const SizedBox(height: 16),

          // ໂຮງຮຽນ
          TextField(
            controller: _schoolController,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
            decoration: _fieldDecoration(
              label: 'ຊື່ໂຮງຮຽນ',
              hint: 'ໂຮງຮຽນຂອງຫຼານ (ບໍ່ບັງຄັບ)',
              icon: Icons.school_rounded,
            ),
          ),
          const SizedBox(height: 16),

          // ແຂວງ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _province.isEmpty ? null : _province,
                hint: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Color(0xFF3E8EF7), size: 22),
                    const SizedBox(width: 12),
                    Text('ເລືອກແຂວງ (ບໍ່ບັງຄັບ)', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                  ],
                ),
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500),
                items: kLaoProvinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _province = v ?? ''),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Next button ──
          _nextButton('ຕໍ່ໄປ: ໂປຣໄຟລ໌ ➡️', _nextPage),
        ],
      ),
    );
  }

  // ── Page 1: Avatar Selector ───────────────────────────
  Widget _buildAvatarPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('🐻 ເລືອກຮູບໂປຣໄຟລ໌ຂອງຫຼານ'),
          const SizedBox(height: 8),
          Text(
            'ເລືອກ avatar ທີ່ຫຼານຊອບ',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Selected avatar preview
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AvatarHelper.getColor(_selectedAvatarId).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AvatarHelper.getColor(_selectedAvatarId),
                  width: 3.5,
                ),
              ),
              child: Center(
                child: Text(
                  AvatarHelper.getEmoji(_selectedAvatarId),
                  style: const TextStyle(fontSize: 56),
                ),
              ),
            ).animate(key: ValueKey(_selectedAvatarId)).scale(duration: 300.ms, curve: Curves.easeOutBack),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              AvatarHelper.getName(_selectedAvatarId),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor),
            ),
          ),
          const SizedBox(height: 28),

          // Avatar Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: List.generate(AvatarHelper.avatars.length, (i) {
              final id = i + 1;
              final emoji = AvatarHelper.getEmoji(id);
              final name = AvatarHelper.getName(id);
              final color = AvatarHelper.getColor(id);
              final isSelected = _selectedAvatarId == id;
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatarId = id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.18) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade200,
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 4))]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),

          // Nav buttons
          Row(
            children: [
              Expanded(child: _backButton()),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _nextButton('ຕໍ່ໄປ: ຜູ້ປົກຄອງ ➡️', _nextPage)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Page 2: ຂໍ້ມູນຜູ້ປົກຄອງ ──────────────────────────────
  Widget _buildParentPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('👨‍👩‍👧 ຂໍ້ມູນຜູ້ປົກຄອງ'),
          const SizedBox(height: 16),

          // ຊື່ຜູ້ປົກຄອງ
          TextField(
            controller: _parentNameController,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
            decoration: _fieldDecoration(
              label: 'ຊື່ຜູ້ປົກຄອງ *',
              hint: 'ຊື່ຜູ້ໃຊ້ app ນີ້',
              icon: Icons.supervisor_account_rounded,
            ),
          ),
          const SizedBox(height: 16),

          // ເບີໂທ
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
            decoration: _fieldDecoration(
              label: 'ເບີໂທລະສັບ *',
              hint: '020 99XXXXXX',
              icon: Icons.phone_iphone_rounded,
            ),
          ),
          const SizedBox(height: 16),

          // ລະຫັດຜ່ານ
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
            decoration: _fieldDecoration(
              label: 'ລະຫັດຜ່ານ * (ຢ່າງໜ້ອຍ 6 ຕົວ)',
              hint: 'ຕັ້ງລະຫັດຜ່ານ',
              icon: Icons.lock_rounded,
              suffix: _eyeButton(
                _obscurePassword,
                () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ຢືນຢັນລະຫັດຜ່ານ
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
            decoration: _fieldDecoration(
              label: 'ຢືນຢັນລະຫັດຜ່ານ *',
              hint: 'ໃສ່ລະຫັດຜ່ານອີກຄັ້ງ',
              icon: Icons.lock_outline_rounded,
              suffix: _eyeButton(
                _obscureConfirmPassword,
                () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Summary card
          _buildSummaryCard(),
          const SizedBox(height: 24),

          // Nav + Submit
          Row(
            children: [
              Expanded(child: _backButton()),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38B264),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: const Color(0xFF38B264).withValues(alpha: 0.35),
                  ),
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: const Text(
                    'ລົງທະບຽນ 🎉',
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────
  Widget _buildSummaryCard() {
    String birthStr = _birthDate == null
        ? '-'
        : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}';
    String gradeStr = _grade == 'P1' ? 'ປ.1' : _grade == 'P2' ? 'ປ.2' : '-';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3E8EF7).withValues(alpha: 0.08),
            const Color(0xFF38B264).withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3E8EF7).withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(AvatarHelper.getEmoji(_selectedAvatarId), style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameController.text.trim().isEmpty ? '-' : _nameController.text.trim(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                  ),
                  Text(
                    '$_gender  •  $gradeStr  •  $birthStr',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          if (_schoolController.text.trim().isNotEmpty || _province.isNotEmpty) ...[
            const Divider(height: 18),
            if (_schoolController.text.trim().isNotEmpty)
              _summaryRow(Icons.school_rounded, _schoolController.text.trim()),
            if (_province.isNotEmpty)
              _summaryRow(Icons.location_on_rounded, _province),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF3E8EF7)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
      ],
    ),
  );

  // ── Shared Widgets ────────────────────────────────────
  Widget _sectionHeader(String title) => Text(
    title,
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textColor),
  );

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textColor),
  );

  Widget _genderButton(String gender, String emoji, bool isSelected) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _gender = gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3E8EF7).withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF3E8EF7) : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              gender,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF3E8EF7) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _gradeButton(String value, String label) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _grade = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _grade == value ? AppTheme.primaryPink.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _grade == value ? AppTheme.primaryPink : Colors.grey.shade300,
            width: _grade == value ? 2.5 : 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _grade == value ? AppTheme.primaryPink : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _eyeButton(bool obscure, VoidCallback onTap) => IconButton(
    icon: Icon(
      obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
      color: Colors.grey.shade500,
    ),
    onPressed: onTap,
  );

  Widget _nextButton(String label, VoidCallback onTap) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF3E8EF7),
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: const Color(0xFF3E8EF7).withValues(alpha: 0.35),
    ),
    onPressed: onTap,
    child: Text(
      label,
      style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );

  Widget _backButton() => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 15),
      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    onPressed: _prevPage,
    icon: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: AppTheme.textColor),
    label: const Text('ກັບຄືນ', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
  );

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'ລົງທະບຽນຜູ້ໃໝ່',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.textColor),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildChildPage(),
                  _buildAvatarPage(),
                  _buildParentPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
