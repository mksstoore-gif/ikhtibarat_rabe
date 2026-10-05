import 'package:flutter/material.dart';
import 'data/app_database.dart';
import 'data/curriculum_repository.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CurriculumRepository.instance.load();
  await AppDatabase.instance.database;
  runApp(const IkhtibaratApp());
}

class IkhtibaratApp extends StatelessWidget{
  const IkhtibaratApp({super.key});
  @override Widget build(BuildContext context){
    final scheme=ColorScheme.fromSeed(seedColor:const Color(0xFF4F46E5),brightness:Brightness.light);
    return MaterialApp(
      debugShowCheckedModeBanner:false,
      title:'اختبارات رابع',
      locale:const Locale('ar'),
      theme:ThemeData(colorScheme:scheme,useMaterial3:true,scaffoldBackgroundColor:const Color(0xFFF7F8FC),inputDecorationTheme:const InputDecorationTheme(filled:true)),
      builder:(context,child)=>Directionality(textDirection:TextDirection.rtl,child:child??const SizedBox.shrink()),
      home:const HomeScreen(),
    );
  }
}
