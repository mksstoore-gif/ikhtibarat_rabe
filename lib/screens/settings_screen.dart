import 'package:flutter/material.dart';
import '../data/curriculum_repository.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CurriculumRepository.instance;
    final active =
        repo.subjects.where((s) => repo.questionCountForSubject(s.id) > 0).length;

    return Scaffold(
      appBar: AppBar(title: const Text('معلومات التطبيق')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [AppColors.navy, AppColors.navySoft],
              ),
              borderRadius: BorderRadius.circular(29),
              boxShadow: AppShadows.glow(AppColors.navy),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF9A84FF)],
                    ),
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'اختبارات رابع',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'نسخة Premium للاستخدام الشخصي',
                        style: TextStyle(
                          color: Colors.white.withOpacity(.60),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'عن التطبيق',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.school_rounded,
            title: 'الصف',
            value: 'الرابع الابتدائي',
            tint: AppColors.primarySoft,
            color: AppColors.primary,
          ),
          _InfoTile(
            icon: Icons.calendar_month_rounded,
            title: 'العام الدراسي',
            value: '1448هـ / 2026-2027م',
            tint: AppColors.infoSoft,
            color: AppColors.info,
          ),
          _InfoTile(
            icon: Icons.quiz_rounded,
            title: 'بنوك الأسئلة',
            value: active.toString() +
                ' مواد مفعلة — ' +
                repo.questions.length.toString() +
                ' سؤال تدريبي محلي',
            tint: AppColors.goldSoft,
            color: const Color(0xFFC68A16),
          ),
          _InfoTile(
            icon: Icons.picture_as_pdf_rounded,
            title: 'الطباعة',
            value: 'نسخة طالب + نموذج إجابة + ملف PDF كامل',
            tint: const Color(0xFFFFEEEE),
            color: AppColors.danger,
          ),
          _InfoTile(
            icon: Icons.lock_rounded,
            title: 'الخصوصية',
            value: 'لا تسجيل دخول ولا خادم؛ البيانات محفوظة محليًا.',
            tint: AppColors.successSoft,
            color: AppColors.success,
          ),
          _InfoTile(
            icon: Icons.block_rounded,
            title: 'الدراسات الإسلامية',
            value: 'القرآن الكريم غير مدرج حسب إعداد المشروع.',
            tint: AppColors.surfaceSoft,
            color: AppColors.muted,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_rounded, color: AppColors.primary),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'المحتوى الدراسي يعتمد على الهيكل الرسمي المعتمد للمشروع، والأسئلة التدريبية محلية داخل التطبيق.',
                    style: TextStyle(
                      color: AppColors.muted,
                      height: 1.5,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color tint;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.tint,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft(),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.45,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
