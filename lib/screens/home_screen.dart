import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../data/curriculum_repository.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import 'create_test_screen.dart';
import 'history_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'subjects_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _subjectIcons = <String, IconData>{
    'math': Icons.calculate_rounded,
    'arabic': Icons.menu_book_rounded,
    'science': Icons.science_rounded,
    'social': Icons.public_rounded,
    'islamic': Icons.auto_stories_rounded,
  };

  static const _subjectColors = <String, Color>{
    'math': Color(0xFF7B61FF),
    'arabic': Color(0xFF4D7CFE),
    'science': Color(0xFF20B486),
    'social': Color(0xFFFF9F43),
    'islamic': Color(0xFF2A8C7B),
  };

  @override
  Widget build(BuildContext context) {
    final repo = CurriculumRepository.instance;
    final activeSubjects =
        repo.subjects.where((s) => repo.questionCountForSubject(s.id) > 0).toList();

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<TestHistoryItem>>(
          future: AppDatabase.instance.loadHistory(),
          builder: (context, snapshot) {
            final history = snapshot.data ?? const <TestHistoryItem>[];
            final average = history.isEmpty
                ? 0
                : (history.map((e) => e.percentage).reduce((a, b) => a + b) /
                        history.length)
                    .round();

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
              children: [
                _TopBar(
                  onSettings: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                const SizedBox(height: 22),
                _HeroCard(
                  onStart: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateTestScreen()),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.task_alt_rounded,
                        value: history.length.toString(),
                        label: 'اختبارات',
                        accent: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.trending_up_rounded,
                        value: average.toString() + '%',
                        label: 'المتوسط',
                        accent: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.quiz_rounded,
                        value: repo.questions.length.toString(),
                        label: 'سؤال',
                        accent: AppColors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'المواد',
                  subtitle: 'اختر مادة وابدأ تدريبًا مخصصًا',
                  action: 'عرض الكل',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubjectsScreen(repository: repo),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 170,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: activeSubjects.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final subject = activeSubjects[index];
                      return _SubjectCard(
                        icon: _subjectIcons[subject.id] ?? Icons.school_rounded,
                        color: _subjectColors[subject.id] ?? AppColors.primary,
                        name: subject.name,
                        count: repo.questionCountForSubject(subject.id),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateTestScreen(initialSubjectId: subject.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
                const _SectionHeader(
                  title: 'متابعة الطالب',
                  subtitle: 'كل الأدوات المهمة في مكان واحد',
                ),
                const SizedBox(height: 12),
                _QuickAction(
                  icon: Icons.checklist_rounded,
                  title: 'الدروس التي تمت دراستها',
                  subtitle: 'حدد الدروس ولن يخرج الاختبار عنها.',
                  tint: const Color(0xFFEEF2FF),
                  iconColor: AppColors.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubjectsScreen(repository: repo),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _QuickAction(
                  icon: Icons.history_rounded,
                  title: 'سجل النتائج',
                  subtitle: 'راجع الاختبارات والدرجات السابقة.',
                  tint: const Color(0xFFECFDF5),
                  iconColor: AppColors.success,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                _QuickAction(
                  icon: Icons.insights_rounded,
                  title: 'مستوى الطالب',
                  subtitle: 'اعرف المهارات القوية وما يحتاج مراجعة.',
                  tint: const Color(0xFFFFF7E5),
                  iconColor: const Color(0xFFC98500),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProgressScreen()),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.lock_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'خصوصية كاملة',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'كل النتائج والبيانات محفوظة محليًا على الجهاز.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(.66),
                                height: 1.45,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onSettings;
  const _TopBar({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF927BFF)],
            ),
          ),
          child: const Icon(Icons.school_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختبارات رابع',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'تعلّم أذكى، وراجع بثقة',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onSettings,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.tune_rounded, color: AppColors.navy),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onStart;
  const _HeroCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.navy, Color(0xFF30285A), AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.22),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -35,
            top: -45,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.06),
              ),
            ),
          ),
          Positioned(
            left: 28,
            bottom: -62,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(.13),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.11),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: AppColors.gold, size: 17),
                      SizedBox(width: 6),
                      Text(
                        'اختبار مخصص خلال ثوانٍ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'اختبر. افهم.\nتقدّم بثقة.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 33,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'اختر المادة والدروس والصعوبة، والتطبيق يرتب لك الاختبار والتصحيح والمتابعة.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.72),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.navy,
                    minimumSize: const Size(0, 52),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('إنشاء اختبار'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 23),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final int count;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.icon,
    required this.color,
    required this.name,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 158,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [color.withOpacity(.14), Colors.white],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(.17)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(.24),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  count.toString() + ' سؤال تدريبي',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFFB4B3C1),
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
