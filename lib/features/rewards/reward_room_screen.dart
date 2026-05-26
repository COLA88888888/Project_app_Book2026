import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/db_helper.dart';
import '../../core/models/reward.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RewardRoomScreen extends StatefulWidget {
  const RewardRoomScreen({super.key});

  @override
  State<RewardRoomScreen> createState() => _RewardRoomScreenState();
}

class _RewardRoomScreenState extends State<RewardRoomScreen> {
  int currentUserId = 1;
  String currentUserName = 'ນ້ອງນ້ອຍ';
  List<Reward> rewards = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('current_user_id') ?? 1;
    currentUserName = prefs.getString('current_user_name') ?? 'ນ້ອງນ້ອຍ';

    final userRewards = await DatabaseHelper.instance.getRewardsForUser(currentUserId);

    setState(() {
      rewards = userRewards;
      isLoading = false;
    });
  }

  String _getRequirementText(String rewardName) {
    switch (rewardName) {
      case 'ຍອດນັກອ່ານ ປ.1':
        return 'ຮຽນໄດ້ 3 ດາວ ໃນວິຊາພາສາລາວ ປ.1';
      case 'ຍອດນັກອ່ານ ປ.2':
        return 'ຮຽນໄດ້ 3 ດາວ ໃນວິຊາພາສາລາວ ປ.2';
      case 'ນັກຄິດໄວ ປ.1':
        return 'ຮຽນໄດ້ 3 ດາວ ໃນວິຊາຄະນິດສາດ ປ.1';
      case 'ນັກຄິດໄວ ປ.2':
        return 'ຮຽນໄດ້ 3 ດາວ ໃນວິຊາຄະນິດສາດ ປ.2';
      case 'ດາວເດັ່ນຮຽນເກັ່ງ':
        return 'ສະສົມດາວໃຫ້ໄດ້ 10 ດາວ';
      case 'ແຊມປ້ຽນຫຼຽນທອງ':
        return 'ສະສົມດາວໃຫ້ໄດ້ 15 ດາວ';
      case 'ແຊມປ້ຽນຫຼຽນເງິນ':
        return 'ສະສົມດາວໃຫ້ໄດ້ 25 ດາວ';
      case 'ແຊມປ້ຽນຫຼຽນຄຳ':
        return 'ສະສົມດາວໃຫ້ໄດ້ 35 ດາວ';
      case 'ອັດສະລິຍະຕົວນ້ອຍ':
        return 'ຮຽນຄົບທັງໝົດ 16 ບົດຮຽນ';
      default:
        return 'ສຳເລັດພາລະກິດຕາມທີ່ກຳນົດ';
    }
  }

  void _showRewardDetail(Reward reward) {
    final isUnlocked = reward.isUnlocked;
    final reqText = _getRequirementText(reward.rewardName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isUnlocked ? 'ປົດລັອກແລ້ວ! 🎉' : 'ລາງວັນຍັງຖືກລັອກ 🔒',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isUnlocked ? const Color(0xFFFFFBEB) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnlocked ? const Color(0xFFFBBF24) : Colors.grey.shade300,
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Text(
                    reward.imagePath,
                    style: TextStyle(fontSize: 48, color: isUnlocked ? null : Colors.grey),
                  ),
                ),
              ).animate(target: isUnlocked ? 1 : 0).scale(curve: Curves.bounceOut, duration: 800.ms),
              const SizedBox(height: 20),
              Text(
                reward.rewardName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                reqText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUnlocked ? const Color(0xFF38B264) : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'ຕົກລົງ',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = rewards.where((r) => r.isUnlocked).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'ຫ້ອງສະສົມລາງວັນ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dynamic Header Card showing total rewards unlocked
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFFDE68A),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ).animate().scale(curve: Curves.bounceOut, duration: 600.ms),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ຫຼຽນລາງວັນຂອງ $currentUserName',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFB45309),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ປົດລັອກໄດ້ $unlockedCount ຈາກ ${rewards.length} ລາງວັນ',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'ລາຍການຫຼຽນກຽດຕິຍົດ 🏅',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: rewards.length,
                        itemBuilder: (context, index) {
                          final reward = rewards[index];
                          final isUnlocked = reward.isUnlocked;

                          return GestureDetector(
                            onTap: () => _showRewardDetail(reward),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isUnlocked ? Colors.white : const Color(0xFFECEFF1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isUnlocked ? const Color(0xFFFFD54F) : Colors.grey.shade300,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  if (isUnlocked)
                                    BoxShadow(
                                      color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  else
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    )
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Center(
                                          child: Text(
                                            reward.imagePath,
                                            style: TextStyle(
                                              fontSize: 48,
                                              color: isUnlocked ? null : Colors.grey.shade400,
                                            ),
                                          ),
                                        ).animate(target: isUnlocked ? 1 : 0).scale(
                                              curve: Curves.easeOutBack,
                                              duration: 500.ms,
                                              delay: (100 * index).ms,
                                            ),
                                        const SizedBox(height: 12),
                                        Text(
                                          reward.rewardName,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isUnlocked ? AppTheme.textColor : Colors.grey.shade500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isUnlocked ? 'ປົດລັອກແລ້ວ' : 'ລັອກຢູ່',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isUnlocked ? const Color(0xFF38B264) : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isUnlocked)
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade400,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.lock_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  else
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE8F5E9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: Color(0xFF2E7D32),
                                        ),
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
              ),
            ),
    );
  }
}
