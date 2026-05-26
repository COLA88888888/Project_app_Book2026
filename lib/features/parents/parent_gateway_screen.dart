import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'dart:math';

class ParentGatewayScreen extends StatefulWidget {
  const ParentGatewayScreen({super.key});

  @override
  State<ParentGatewayScreen> createState() => _ParentGatewayScreenState();
}

class _ParentGatewayScreenState extends State<ParentGatewayScreen> {
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

  void _generateMathProblem() {
    final random = Random();
    num1 = random.nextInt(15) + 5; // 5 to 19
    num2 = random.nextInt(10) + 1; // 1 to 10
    correctAnswer = num1 + num2;
  }

  void _verifyAnswer() {
    if (int.tryParse(_controller.text) == correctAnswer) {
      // TODO: Navigate to real Parent Dashboard
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ເຂົ້າສູ່ລະບົບສຳເລັດ!')));
      context.pop(); // Pop back for now
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
      appBar: AppBar(title: const Text('ສຳລັບຜູ້ປົກຄອງເທົ່ານັ້ນ')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ເພື່ອປ້ອງກັນເດັກນ້ອຍ, ກະລຸນາແກ້ເລກລຸ່ມນີ້:',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                '$num1 + $num2 = ?',
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(color: AppTheme.primaryPink),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24),
                decoration: InputDecoration(
                  hintText: 'ພິມຄຳຕອບຢູ່ນີ້',
                  errorText: _errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _verifyAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'ຢືນຢັນ',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (int.tryParse(_controller.text) == correctAnswer) {
                        context.push('/admin');
                      } else {
                        setState(() {
                          _errorText = 'ແກ້ເລກໃຫ້ຖືກກ່ອນເຂົ້າຫຼັງບ້ານ';
                          _controller.clear();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(fontSize: 18, color: Colors.white),
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
