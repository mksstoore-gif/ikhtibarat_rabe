import 'package:flutter/material.dart';
import 'data/app_database.dart';
import 'data/curriculum_repository.dart';
import 'screens/home_screen.dart';

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
    final scheme=ColorScheme.fromSeed(
      seedColor:const Color(0xFF2563EB),
      brightness:Brightness.light,
      surface:Colors.white,
    );
    return MaterialApp(
      debugShowCheckedModeBanner:false,
      title:'اختبارات الصف الرابع',
      locale:const Locale('ar'),
      theme:ThemeData(
        useMaterial3:true,
        colorScheme:scheme,
        scaffoldBackgroundColor:Colors.white,
        appBarTheme:const AppBarTheme(
          backgroundColor:Colors.white,
          foregroundColor:Color(0xFF111827),
          elevation:0,
          surfaceTintColor:Colors.transparent,
          centerTitle:false,
        ),
        cardTheme:CardThemeData(
          color:Colors.white,
          elevation:0,
          surfaceTintColor:Colors.transparent,
          shape:RoundedRectangleBorder(
            side:const BorderSide(color:Color(0xFFE5E7EB)),
            borderRadius:BorderRadius.circular(18),
          ),
        ),
        dividerColor:const Color(0xFFE5E7EB),
        inputDecorationTheme:InputDecorationTheme(
          filled:true,
          fillColor:const Color(0xFFF8FAFC),
          border:OutlineInputBorder(
            borderRadius:BorderRadius.circular(14),
            borderSide:const BorderSide(color:Color(0xFFE5E7EB)),
          ),
          enabledBorder:OutlineInputBorder(
            borderRadius:BorderRadius.circular(14),
            borderSide:const BorderSide(color:Color(0xFFE5E7EB)),
          ),
          focusedBorder:OutlineInputBorder(
            borderRadius:BorderRadius.circular(14),
            borderSide:const BorderSide(color:Color(0xFF2563EB),width:1.5),
          ),
        ),
        filledButtonTheme:FilledButtonThemeData(
          style:FilledButton.styleFrom(
            minimumSize:const Size.fromHeight(54),
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),
          ),
        ),
      ),
      builder:(context,child)=>Directionality(
        textDirection:TextDirection.rtl,
        child:child??const SizedBox.shrink(),
      ),
      home:const HomeScreen(),
    );
  }
}
