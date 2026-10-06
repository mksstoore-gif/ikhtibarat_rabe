import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../data/curriculum_repository.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import 'create_test_screen.dart';
import 'history_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'study_summary_screen.dart';
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
    'math': Color(0xFF7259F7),
    'arabic': Color(0xFF4A7CF7),
    'science': Color(0xFF20B486),
    'social': Color(0xFFF29A3F),
    'islamic': Color(0xFF258D7C),
  };

  @override
  Widget build(BuildContext context) {
    final curriculum = CurriculumRepository.instance;
    final activeSubjects = curriculum.subjects
        .where((subject) => curriculum.questionCountForSubject(subject.id) > 0)
        .toList();

    return Scaffold(
      bottomNavigationBar: _HomeDock(
        onCreate: () => _open(context, const CreateTestScreen()),
        onProgress: () => _open(context, const ProgressScreen()),
        onHistory: () => _open(context, const HistoryScreen()),
      ),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<TestHistoryItem>>(
          future: AppDatabase.instance.loadHistory(),
          builder: (context, snapshot) {
            final history = snapshot.data ?? const <TestHistoryItem>[];
            final average = history.isEmpty
                ? 0
                : (history
                            .map((item) => item.percentage)
                            .reduce((a, b) => a + b) /
                        history.length)
                    .round();
            final best = history.isEmpty
                ? 0
                : history
                    .map((item) => item.percentage.round())
                    .reduce((a, b) => a > b ? a : b);

            return RefreshIndicator(
              onRefresh: () async {
                await AppDatabase.instance.loadHistory();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                children: [
                  _TopBar(
                    onSettings: () => _open(context, const SettingsScreen()),
                  ),
                  const SizedBox(height: 22),
                  _HeroCard(
                    average: average,
                    testCount: history.length,
                    onStart: () => _open(context, const CreateTestScreen()),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.bolt_rounded,
                          value: history.length.toString(),
                          label: 'اختبار مكتمل',
                          accent: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.auto_graph_rounded,
                          value: average.toString() + '%',
                          label: 'متوسط النتائج',
                          accent: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.emoji_events_rounded,
                          value: best.toString() + '%',
                          label: 'أفضل نتيجة',
                          accent: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                  if (history.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _LastResultCard(
                      item: history.first,
                      onTap: () => _open(context, const HistoryScreen()),
                    ),
                  ],
                  const SizedBox(height: 30),
                  _SectionHeader(
                    title: 'المواد',
                    subtitle: 'اختر المادة، والباقي يصممه لك التطبيق',
                    action: 'إدارة الدروس',
                    onAction: () => _open(
                      context,
                      SubjectsScreen(repository: curriculum),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeSubjects.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.04,
                    ),
                    itemBuilder: (context, index) {
                      final subject = activeSubjects[index];
                      final accent =
                          _subjectColors[subject.id] ?? AppColors.primary;
                      return _SubjectCard(
                        icon: _subjectIcons[subject.id] ?? Icons.school_rounded,
                        color: accent,
                        name: subject.name,
                        count: curriculum.questionCountForSubject(subject.id),
                        onTap: () => _open(
                          context,
                          CreateTestScreen(initialSubjectId: subject.id),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  const _SectionHeader(
                    title: 'لوحة ولي الأمر',
                    subtitle: 'متابعة ذكية بدون تعقيد أو حسابات',
                  ),
                  const SizedBox(height: 14),
                  _ParentAction(
                    icon: Icons.menu_book_rounded,
                    title: 'إنشاء ملخص للمذاكرة',
                    subtitle: 'اختر الدروس واحصل على ملخص مرتب جاهز للطباعة PDF.',
                    tint: AppColors.infoSoft,
                    iconColor: AppColors.info,
                    onTap: () => _open(context, const StudySummaryScreen()),
                  ),
                  const SizedBox(height: 10),
                  _ParentAction(
                    icon: Icons.checklist_rtl_rounded,
                    title: 'الدروس المدروسة',
                    subtitle: 'حدد ما تم شرحه، ولن يخرج الاختبار عنه.',
                    tint: AppColors.primarySoft,
                    iconColor: AppColors.primary,
                    onTap: () => _open(
                      context,
                      SubjectsScreen(repository: curriculum),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ParentAction(
                    icon: Icons.insights_rounded,
                    title: 'تحليل المستوى',
                    subtitle: 'شاهد المهارات القوية وما يحتاج إلى مراجعة.',
                    tint: AppColors.successSoft,
                    iconColor: AppColors.success,
                    onTap: () => _open(context, const ProgressScreen()),
                  ),
                  const SizedBox(height: 10),
                  _ParentAction(
                    icon: Icons.history_rounded,
                    title: 'سجل الاختبارات',
                    subtitle: 'النتائج والتواريخ محفوظة على الجهاز.',
                    tint: AppColors.goldSoft,
                    iconColor: const Color(0xFFC68A16),
                    onTap: () => _open(context, const HistoryScreen()),
                  ),
                  const SizedBox(height: 22),
                  const _PrivacyCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static void _open(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
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
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [AppColors.primary, Color(0xFF9A84FF)],
            ),
            boxShadow: AppShadows.glow(AppColors.primary),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 29,
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختبارات رابع',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'مراجعة أذكى. نتيجة أوضح.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _RoundIconButton(
          icon: Icons.tune_rounded,
          onTap: onSettings,
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int average;
  final int testCount;
  final VoidCallback onStart;

  const _HeroCard({
    required this.average,
    required this.testCount,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF11162F),
            Color(0xFF29245A),
            Color(0xFF6655E7),
          ],
        ),
        boxShadow: AppShadows.glow(AppColors.primary),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -55,
            top: -55,
            child: _GlowCircle(
              size: 190,
              color: Colors.white.withOpacity(.07),
            ),
          ),
          Positioned(
            right: -70,
            bottom: -85,
            child: _GlowCircle(
              size: 210,
              color: AppColors.gold.withOpacity(.12),
            ),
          ),
          Positioned(
            left: 26,
            bottom: 24,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 68,
              color: Colors.white.withOpacity(.065),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(.08)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.gold,
                        size: 17,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'اختبار مخصص خلال ثوانٍ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'كل مراجعة\nتقربك من الإتقان.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    height: 1.13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  testCount == 0
                      ? 'ابدأ أول اختبار، وسيتولى التطبيق تنظيم الباقي.'
                      : 'متوسطك الحالي ' +
                          average.toString() +
                          '% — واصل التقدم.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.72),
                    fontSize: 13.5,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: onStart,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(
                    'إنشاء اختبار جديد',
                    style: TextStyle(fontWeight: FontWeight.w900),
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

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
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
      height: 112,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withOpacity(.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 19),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LastResultCard extends StatelessWidget {
  final TestHistoryItem item;
  final VoidCallback onTap;
  const _LastResultCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final percent = item.percentage.round();
    final accent = percent >= 80
        ? AppColors.success
        : percent >= 60
            ? AppColors.gold
            : AppColors.danger;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.11),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Text(
                  percent.toString() + '%',
                  style: TextStyle(
                    color: accent,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'آخر نتيجة',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subjectName,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.questionCount.toString() + ' سؤال',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
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
                  color: AppColors.text,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.25,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!),
          ),
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
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(27),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(27),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.soft(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: color.withOpacity(.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  Container(
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 17,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                count.toString() + ' سؤال تدريبي',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final Color iconColor;
  final VoidCallback onTap;

  const _ParentAction({
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
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: AppColors.border),
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
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.4,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.09),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.lock_rounded, color: Colors.white),
          ),
          const SizedBox(width: 13),
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
                  'لا حسابات ولا خادم. كل البيانات محفوظة محليًا على الجهاز.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.67),
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
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: 49,
          height: 49,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(icon, color: AppColors.text),
        ),
      ),
    );
  }
}

class _HomeDock extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onProgress;
  final VoidCallback onHistory;

  const _HomeDock({
    required this.onCreate,
    required this.onProgress,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.glow(AppColors.navy),
        ),
        child: Row(
          children: [
            const Expanded(
              child: _DockItem(
                icon: Icons.home_rounded,
                label: 'الرئيسية',
                active: true,
              ),
            ),
            Expanded(
              child: _DockItem(
                icon: Icons.add_circle_outline_rounded,
                label: 'اختبار',
                onTap: onCreate,
              ),
            ),
            Expanded(
              child: _DockItem(
                icon: Icons.insights_rounded,
                label: 'المستوى',
                onTap: onProgress,
              ),
            ),
            Expanded(
              child: _DockItem(
                icon: Icons.history_rounded,
                label: 'السجل',
                onTap: onHistory,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _DockItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : Colors.white.withOpacity(.55);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 21, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: active ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
