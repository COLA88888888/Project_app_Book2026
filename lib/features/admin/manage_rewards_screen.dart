import 'package:flutter/material.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/user_profile.dart';
import '../../core/models/reward.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ManageRewardsScreen extends StatefulWidget {
  const ManageRewardsScreen({super.key});

  @override
  State<ManageRewardsScreen> createState() => _ManageRewardsScreenState();
}

class _ManageRewardsScreenState extends State<ManageRewardsScreen> {
  List<UserProfile> students = [];
  bool isLoading = true;
  String searchQuery = '';
  UserProfile? selectedStudent;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final users = await DatabaseHelper.instance.readAllUsers();
    setState(() {
      students = users;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = students.where((student) {
      final nameMatch = student.name.toLowerCase().contains(searchQuery.toLowerCase());
      final phoneMatch = student.phone.contains(searchQuery);
      return nameMatch || phoneMatch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'ຈັດການລາງວັນ',
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar Section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: TextField(
                    onChanged: (val) => setState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'ຄົ້ນຫາຊື່ຜູ້ຫຼິ້ນ ຫຼື ເບີໂທຜູ້ປົກຄອງ...',
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFF59E0B)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),

                // Student List
                Expanded(
                  child: filteredStudents.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            final isSelected = selectedStudent?.id == student.id;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFF59E0B) : Colors.grey.shade100,
                                  width: isSelected ? 2 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: const CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppTheme.primaryPink,
                                  child: Icon(Icons.face_rounded, color: Colors.white, size: 36),
                                ),
                                title: Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'ເບີໂທ: ${student.phone}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ຄະແນນລວມ: ${student.score} ດາວ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFF59E0B),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton.icon(
                                  onPressed: () => _showRewardsDetailsSheet(context, student),
                                  icon: const Icon(Icons.emoji_events_rounded, size: 16, color: Colors.white),
                                  label: const Text(
                                    'ລາງວັນ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                            ).animate().fade(duration: 300.ms, delay: (index * 50).ms).slideY(begin: 0.05, end: 0);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showRewardsDetailsSheet(BuildContext context, UserProfile student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _RewardsDetailsSheet(student: student);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'ບໍ່ພົບຜູ້ຫຼິ້ນໃນລະບົບ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _RewardsDetailsSheet extends StatefulWidget {
  final UserProfile student;
  const _RewardsDetailsSheet({required this.student});

  @override
  State<_RewardsDetailsSheet> createState() => _RewardsDetailsSheetState();
}

class _RewardsDetailsSheetState extends State<_RewardsDetailsSheet> {
  List<Reward> detailedRewards = [];
  bool isRewardsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetailedRewards();
  }

  Future<void> _loadDetailedRewards() async {
    final rewards = await DatabaseHelper.instance.getRewardsForUser(widget.student.id!);
    if (mounted) {
      setState(() {
        detailedRewards = rewards;
        isRewardsLoading = false;
      });
    }
  }

  Future<void> _toggleRewardStatus(Reward reward, bool isUnlocked) async {
    await DatabaseHelper.instance.updateRewardUnlockStatus(
      widget.student.id!,
      reward.rewardName,
      isUnlocked,
    );

    // Refresh rewards list locally in the sheet
    final updatedRewards = await DatabaseHelper.instance.getRewardsForUser(widget.student.id!);
    if (mounted) {
      setState(() {
        detailedRewards = updatedRewards;
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isUnlocked 
              ? 'ປົດລັອກລາງວັນ "${reward.rewardName}" ສຳເລັດແລ້ວ! 🏆' 
              : 'ລັອກລາງວັນ "${reward.rewardName}" ແລ້ວ!',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryPink,
                      child: Icon(Icons.face_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ລາຍການລາງວັນຂອງ ${widget.student.name}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ຈັດການ ແລະ ປົດລັອກຫຼຽນລາງວັນກຽດຕິຍົດ',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Rewards Grid
          Expanded(
            child: isRewardsLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: detailedRewards.length,
                    itemBuilder: (context, idx) {
                      final reward = detailedRewards[idx];
                      final isUnlocked = reward.isUnlocked;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isUnlocked ? const Color(0xFFF59E0B) : Colors.grey.shade200,
                            width: isUnlocked ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Reward Emoji / Icon
                              Text(
                                reward.imagePath,
                                style: TextStyle(
                                  fontSize: 40,
                                  color: isUnlocked ? null : Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                reward.rewardName,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? AppTheme.textColor : Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Switch to lock/unlock
                              Transform.scale(
                                scale: 0.85,
                                child: Switch(
                                  value: isUnlocked,
                                  activeThumbColor: const Color(0xFFF59E0B),
                                  onChanged: (val) async {
                                    await _toggleRewardStatus(reward, val);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
