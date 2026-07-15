import 'package:flutter/material.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/database/db_helper.dart';

// ── 1. ສ່ວນຟັງຊັນຫຼັກ (Main Function) — ຈຸດເລີ່ມຕົ້ນການເຮັດວຽກຂອງແອັບ ──────────────────
void main() async {
  // ຮັບປະກັນວ່າ Flutter Engine ໄດ້ຖືກໂຫຼດ ແລະ ກຽມພ້ອມເຮັດວຽກກ່ອນເລີ່ມແອັບ
  WidgetsFlutterBinding.ensureInitialized();
  
  // ກຽມເຊື່ອມຕໍ່ຖານຂໍ້ມູນຫຼັງບ້ານ (Backend MySQL/SQLite) ໃນ background
  DatabaseHelper.getBaseUrl().catchError((_) => '');
  
  // ສັ່ງໃຫ້ແອັບພລິເຄຊັນເລີ່ມເຮັດວຽກໂດຍການເອີ້ນໃຊ້ Widget EduApp()
  runApp(const EduApp());
}

// ── 2. ສ່ວນ Widget ຫຼັກຂອງແອັບ (Root Widget) ──────────────────────────────────────────
class EduApp extends StatelessWidget {
  const EduApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ໃຊ້ MaterialApp.router ເພື່ອຮອງຮັບລະບົບເສັ້ນທາງ (Routing) ຂອງ GoRouter
    return MaterialApp.router(
      title: 'Edu App',
      // ກຳນົດຮູບແບບສີສັນ ແລະ ຟອນໂຕໜັງສືທີ່ຕັ້ງຄ່າໄວ້ໃນ AppTheme
      theme: AppTheme.lightTheme,
      // ກຳນົດເສັ້ນທາງໜ້າຈໍທັງໝົດຂອງແອັບທີ່ດຶງມາຈາກ appRouter
      routerConfig: appRouter,
      // ປິດປ້າຍ DEBUG ສີແດງຢູ່ມຸມຂວາເທິງຂອງແອັບ
      debugShowCheckedModeBanner: false,
    );
  }
}
