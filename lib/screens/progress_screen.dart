import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مستوى الطالب')),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: AppDatabase.instance.loadSkillProgress(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rows = snapshot.data!;
          if (rows.isEmpty) {
            return const _EmptyProgress();
          }

          final correct = rows.fold<int>(
            0,
            (sum, row) => sum + ((row['correct_count'] as int?) ?? 0),
          );
          final wrong = rows.fold<int>(
            0,
            (sum, row) => sum + ((row['wrong_count'] as int?) ?? 0),
          );
          final total = correct + wrong;
          final average = total == 0 ? 0 : (correct / total * 100).round();

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              _ProgressHero(
                percentage: average,
                correct: correct,
                wrong: wrong,
                skills: rows.length,
              ),
              const SizedBox(height: 24),
              const Text(
                'تحليل المهارات',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'مرتبة حسب أكثر المهارات احتياجًا للمراجعة.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              ...rows.map((row) {
                final ok = (row['correct_count'] as int?) ?? 0;
                final bad = (row['wrong_count'] as int?) ?? 0;
                final attempts = ok + bad;
                final percentage =
                    attempts == 0 ? 0 : (ok / attempts * 100).round();
                final skillId = row['skill_id']?.toString() ?? '';
                return _SkillCard(
                  label: _prettySkill(skillId),
                  correct: ok,
                  wrong: bad,
                  percentage: percentage,
                );
              }),
            ],
          );
        },
      ),
    );
  }

  static String _prettySkill(String id) {
    if (id.trim().isEmpty) return 'مهارة عامة';
    final value = id
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return value;
  }
}

class _ProgressHero extends StatelessWidget {
  final int percentage;
  final int correct;
  final int wrong;
  final int skills;

  const _ProgressHero({
    required this.percentage,
    required this.correct,
    required this.wrong,
    required this.skills,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.navy, Color(0xFF30285A), AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'صورة واضحة عن التقدم',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'تتحدث تلقائيًا بعد كل اختبار',
                      style: TextStyle(
                        color: Color(0xFFCBC8E8),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _ScoreRing(value: percentage),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  value: '$correct',
                  label: 'إجابة صحيحة',
                  icon: Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  value: '$wrong',
                  label: 'تحتاج مراجعة',
                  icon: Icons.refresh_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  value: '$skills',
                  label: 'مهارة مقاسة',
                  icon: Icons.auto_graph_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int value;
  const _ScoreRing({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value / 100,
            strokeWidth: 7,
            backgroundColor: Colors.white.withOpacity(.12),
            color: AppColors.gold,
          ),
          Text(
            '$value%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _HeroMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withOpacity(.88), size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(.62),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  final String label;
  final int correct;
  final int wrong;
  final int percentage;

  const _SkillCard({
    required this.label,
    required this.correct,
    required this.wrong,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = percentage >= 80
        ? AppColors.success
        : percentage >= 60
            ? AppColors.gold
            : AppColors.danger;
    final status = percentage >= 80
        ? 'متقن'
        : percentage >= 60
            ? 'جيد'
            : 'يحتاج تقوية';

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.bolt_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withOpacity(.09),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 9,
              backgroundColor: AppColors.background,
              color: accent,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '$correct صحيح  •  $wrong مراجعة',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyProgress extends StatelessWidget {
  const _EmptyProgress();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insights_rounded,
                size: 54,
                color: AppColors.primary,
              ),
              SizedBox(height: 14),
              Text(
                'لا توجد بيانات كافية بعد',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'بعد حل أول اختبار سيظهر هنا مستوى الطالب والمهارات التي تحتاج مراجعة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
