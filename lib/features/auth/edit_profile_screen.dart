import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/user_profile.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/avatar_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'add_profile_screen.dart' show kLaoProvinces;

class EditProfileScreen extends StatefulWidget {
  final String? userId;
  const EditProfileScreen({super.key, this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
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

  UserProfile? _user;
  bool _isLoading = true;
  bool _isCurrentUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _parentNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final currentActiveId = prefs.getInt('current_user_id') ?? 1;

    int editId = currentActiveId;
    if (widget.userId != null) {
      final parsed = int.tryParse(widget.userId!);
      if (parsed != null) {
        editId = parsed;
        _isCurrentUser = (parsed == currentActiveId);
      }
    }

    final fetched = await DatabaseHelper.instance.readUser(editId);
    if (fetched != null) {
      setState(() {
        _user = fetched;
        _nameController.text = fetched.name;
        _gender = fetched.gender;
        _birthDate = fetched.birthDate.isNotEmpty
            ? DateTime.tryParse(fetched.birthDate)
            : null;
        _grade = fetched.grade;
        _schoolController.text = fetched.school;
        _province = fetched.province;
        _selectedAvatarId = fetched.avatarId;
        _parentNameController.text = fetched.parentName;
        _phoneController.text = fetched.phone;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
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

  Future<void> _updateProfile() async {
    if (_user == null) return;

    final name = _nameController.text.trim();
    final parentName = _parentNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showSnackBar('ກະລຸນາປ້ອນຊື່ຫຼານນ້ອຍ!', isError: true);
      return;
    }
    if (_gender.isEmpty) {
      _showSnackBar('ກະລຸນາເລືອກເພດ!', isError: true);
      return;
    }
    if (_grade.isEmpty) {
      _showSnackBar('ກະລຸນາເລືອກຊັ້ນຮຽນ!', isError: true);
      return;
    }
    if (phone.isEmpty || phone.replaceAll(' ', '').length < 8) {
      _showSnackBar('ກະລຸນາປ້ອນເບີໂທທີ່ຖືກຕ້ອງ!', isError: true);
      return;
    }

    final updated = _user!.copyWith(
      name: name,
      gender: _gender,
      birthDate: _birthDate?.toIso8601String() ?? _user!.birthDate,
      grade: _grade,
      school: _schoolController.text.trim(),
      province: _province,
      avatarId: _selectedAvatarId,
      parentName: parentName,
      phone: phone,
    );

    await DatabaseHelper.instance.updateUser(updated);

    if (_isCurrentUser) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_name', name);
    }

    if (!mounted) return;
    _showSnackBar('ອັບເດດໂປຣໄຟລ໌ "$name" ສຳເລັດ! 🎉');
    context.pop(true);
  }

  Future<void> _deleteProfile() async {
    if (_user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('ຢືນຢັນການລຶບ ⚠️', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'ຫຼານແນ່ໃຈແລ້ວບໍ ວ່າຕ້ອງການລຶບໂປຣໄຟລ໌ "${_user!.name}"?\nຂໍ້ມູນທັງໝົດຈະຖືກລຶບຖາວອນ!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ຍົກເລີກ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ຢືນຢັນລຶບ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteUser(_user!.id!);
      if (_isCurrentUser) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('current_user_id');
        await prefs.remove('current_user_name');
        if (!mounted) return;
        context.go('/login');
      } else {
        if (!mounted) return;
        _showSnackBar('ລຶບໂປຣໄຟລ໌ສຳເລັດ!');
        context.pop(true);
      }
    }
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

  InputDecoration _dec({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF3E8EF7), size: 22),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3E8EF7), width: 2)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
  );

  Widget _genderBtn(String g, String emoji) {
    final sel = _gender == g;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = g),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF3E8EF7).withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sel ? const Color(0xFF3E8EF7) : Colors.grey.shade300, width: sel ? 2.5 : 1.5),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 2),
              Text(g, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: sel ? const Color(0xFF3E8EF7) : Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradeBtn(String value, String label) {
    final sel = _grade == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _grade = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? AppTheme.primaryPink.withValues(alpha: 0.10) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sel ? AppTheme.primaryPink : Colors.grey.shade300, width: sel ? 2.5 : 1.5),
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: sel ? AppTheme.primaryPink : Colors.grey.shade600)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_user == null) {
      return Scaffold(appBar: AppBar(title: const Text('ບໍ່ພົບຜູ້ໃຊ້')),
          body: const Center(child: Text('ບໍ່ພົບຂໍ້ມູນ')));
    }

    final birthStr = _birthDate == null
        ? 'ແຕະເພື່ອເລືອກວັນ'
        : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('ແກ້ໄຂຂໍ້ມູນ ✏️',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.textColor)),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar preview ────────────────────────────
            Center(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AvatarHelper.getColor(_selectedAvatarId).withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: AvatarHelper.getColor(_selectedAvatarId), width: 3.5),
                    ),
                    child: Center(
                      child: Text(AvatarHelper.getEmoji(_selectedAvatarId), style: const TextStyle(fontSize: 52)),
                    ),
                  ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 10),
                  Text(_user!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 4),
                      Text('${_user!.score} ດາວ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── ໂປຣໄຟລ໌ Avatar ───────────────────────────
            _sectionCard(
              title: '🐻 ຮູບໂປຣໄຟລ໌',
              child: SizedBox(
                height: 86,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: AvatarHelper.avatars.length,
                  itemBuilder: (context, i) {
                    final id = i + 1;
                    final emoji = AvatarHelper.getEmoji(id);
                    final name = AvatarHelper.getName(id);
                    final color = AvatarHelper.getColor(id);
                    final isSel = _selectedAvatarId == id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatarId = id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(6),
                        width: 70,
                        decoration: BoxDecoration(
                          color: isSel ? color.withValues(alpha: 0.2) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSel ? color : Colors.grey.shade200, width: isSel ? 3 : 1.5),
                          boxShadow: isSel ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 4))] : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 2),
                            Text(name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSel ? color : Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── ຂໍ້ມູນຫຼານ ─────────────────────────────────
            _sectionCard(
              title: '👦 ຂໍ້ມູນຫຼານນ້ອຍ',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                    decoration: _dec(label: 'ຊື່ຫຼານ *', hint: 'ພິມຊື່ຫຼານ', icon: Icons.person_rounded),
                  ),
                  const SizedBox(height: 14),
                  _label('ເພດ *'),
                  Row(children: [_genderBtn('ຊາຍ', '👦'), const SizedBox(width: 10), _genderBtn('ຍິງ', '👧')]),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _pickBirthDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                Text('ວັນເດືອນປີເກີດ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                const SizedBox(height: 2),
                                Text(birthStr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _birthDate == null ? Colors.grey.shade400 : AppTheme.textColor)),
                              ],
                            ),
                          ),
                          Icon(Icons.calendar_month_rounded, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label('ຊັ້ນຮຽນ *'),
                  Row(children: [_gradeBtn('P1', 'ປ.1'), const SizedBox(width: 10), _gradeBtn('P2', 'ປ.2')]),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _schoolController,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                    decoration: _dec(label: 'ໂຮງຮຽນ', hint: 'ຊື່ໂຮງຮຽນ (ບໍ່ບັງຄັບ)', icon: Icons.school_rounded),
                  ),
                  const SizedBox(height: 14),
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
                        hint: Row(children: [const Icon(Icons.location_on_rounded, color: Color(0xFF3E8EF7), size: 20), const SizedBox(width: 10), Text('ເລືອກແຂວງ', style: TextStyle(color: Colors.grey.shade400, fontSize: 14))]),
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500),
                        items: kLaoProvinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (v) => setState(() => _province = v ?? ''),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── ຂໍ້ມູນຜູ້ປົກຄອງ ─────────────────────────────
            _sectionCard(
              title: '👨‍👩‍👧 ຂໍ້ມູນຜູ້ປົກຄອງ',
              child: Column(
                children: [
                  TextField(
                    controller: _parentNameController,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                    decoration: _dec(label: 'ຊື່ຜູ້ປົກຄອງ', hint: 'ຊື່ຜູ້ໃຊ້ app', icon: Icons.supervisor_account_rounded),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                    decoration: _dec(label: 'ເບີໂທ *', hint: '020 99XXXXXX', icon: Icons.phone_iphone_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Save Button ──────────────────────────────────
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38B264),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: const Color(0xFF38B264).withValues(alpha: 0.3),
              ),
              onPressed: _updateProfile,
              icon: const Icon(Icons.save_rounded, color: Colors.white, size: 22),
              label: const Text('ບັນທຶກການປ່ຽນແປງ', style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
            ).animate().scale(delay: 200.ms),
            const SizedBox(height: 12),

            // ── Delete Button ────────────────────────────────
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 50),
                side: BorderSide(color: Colors.red.shade400, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _deleteProfile,
              icon: Icon(Icons.delete_forever_rounded, color: Colors.red.shade400),
              label: Text('ລຶບໂປຣໄຟລ໌ ❌', style: TextStyle(fontSize: 15, color: Colors.red.shade500, fontWeight: FontWeight.bold)),
            ).animate().fade(delay: 300.ms),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
