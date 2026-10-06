import 'package:flutter/material.dart';
import 'data/app_database.dart';
import 'data/curriculum_repository.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CurriculumRepository.instance.load();
  await AppDatabase.instance.database;
  runApp(const GradeFourTestsApp());
}

class GradeFourTestsApp extends StatelessWidget {
  const GradeFourTestsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اختبارات الصف الرابع',
      locale: const Locale('ar'),
      theme: AppTheme.light,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const HomeScreen(),
    );
  }
}
