import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'dart:math';

class ParentGatewayScreen extends StatelessWidget {
  const ParentGatewayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ParentGatewayBody(showBackButton: true),
    );
  }
}

class ParentGatewayBody extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onSuccess;

  const ParentGatewayBody({
    super.key,
    required this.showBackButton,
    this.onSuccess,
  });

  @override
  State<ParentGatewayBody> createState() => _ParentGatewayBodyState();
}

class _ParentGatewayBodyState extends State<ParentGatewayBody> {
  late int num1;
  late int num2;
  late int correctAnswer;
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _generateMathProblem();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateMathProblem() {
    final random = Random();
    num1 = random.nextInt(15) + 5; // 5 to 19
    num2 = random.nextInt(10) + 1; // 1 to 10
    correctAnswer = num1 + num2;
  }

  void _verifyAnswer({bool goToAdmin = false}) {
    if (int.tryParse(_controller.text) == correctAnswer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ເຂົ້າສູ່ລະບົບສຳເລັດ! 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _controller.clear();
      
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }
      
      if (goToAdmin) {
        context.push('/admin');
      } else {
        context.push('/admin');
      }
    } else {
      setState(() {
        _errorText = 'ຄຳຕອບບໍ່ຖືກຕ້ອງ ລອງໃໝ່ອີກຄັ້ງ';
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'ສຳລັບຜູ້ປົກຄອງເທົ່ານັ້ນ 🔒',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textColor),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textColor),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.security_rounded,
                size: 80,
                color: AppTheme.primaryPink,
              ),
              const SizedBox(height: 24),
              Text(
                'ເພື່ອປ້ອງກັນເດັກນ້ອຍ, ກະລຸນາແກ້ເລກລຸ່ມນີ້:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                '$num1 + $num2 = ?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryPink,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'ພິມຄຳຕອບຢູ່ນີ້',
                  errorText: _errorText,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppTheme.primaryPink, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _verifyAnswer(goToAdmin: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'ຢືນຢັນ',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _verifyAnswer(goToAdmin: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'ເຂົ້າລະບົບ Admin',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
