import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../data/curriculum_repository.dart';
import '../data/models.dart';
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

          var correctTotal = 0;
          var wrongTotal = 0;
          for (final row in rows) {
            correctTotal += row['correct_count'] as int;
            wrongTotal += row['wrong_count'] as int;
          }
          final attempts = correctTotal + wrongTotal;
          final overall =
              attempts == 0 ? 0 : (correctTotal / attempts * 100).round();

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              _OverallCard(
                percentage: overall,
                skillCount: rows.length,
                attempts: attempts,
              ),
              const SizedBox(height: 24),
              const Text(
                'تحليل المهارات',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'ابدأ بالمهارات الأقل نسبة ثم أعد الاختبار',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              ...rows.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: _SkillCard(row: row),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  final int percentage;
  final int skillCount;
  final int attempts;

  const _OverallCard({
    required this.percentage,
    required this.skillCount,
    required this.attempts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
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
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    color: AppColors.gold,
                    backgroundColor: Colors.white.withOpacity(.09),
                  ),
                ),
                Text(
                  percentage.toString() + '%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مؤشر الإتقان',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  skillCount.toString() +
                      ' مهارة  •  ' +
                      attempts.toString() +
                      ' إجابة محللة',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.60),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  percentage >= 80
                      ? 'المستوى ممتاز. حافظ على المراجعة.'
                      : percentage >= 60
                          ? 'المستوى جيد، وبعض المهارات تحتاج تثبيت.'
                          : 'ابدأ بالمهارات الأقل نسبة وكرر التدريب.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.82),
                    height: 1.45,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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

class _SkillCard extends StatelessWidget {
  final Map<String, Object?> row;
  const _SkillCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final correct = row['correct_count'] as int;
    final wrong = row['wrong_count'] as int;
    final total = correct + wrong;
    final percent = total == 0 ? 0 : (correct / total * 100).round();
    final info = _skillInfo(row['skill_id'].toString());
    final color = percent >= 80
        ? AppColors.success
        : percent >= 60
            ? AppColors.gold
            : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft(),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _subjectIcon(info.subjectId),
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.lessonName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      info.subjectName,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                percent.toString() + '%',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 7,
              color: color,
              backgroundColor: color.withOpacity(.10),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'صحيح ' + correct.toString(),
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'خطأ ' + wrong.toString(),
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                percent >= 80
                    ? 'متقنة'
                    : percent >= 60
                        ? 'تحتاج تثبيت'
                        : 'أولوية للمراجعة',
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _SkillInfo _skillInfo(String skillId) {
    final repo = CurriculumRepository.instance;
    Question? question;
    for (final candidate in repo.questions) {
      if (candidate.skillId == skillId) {
        question = candidate;
        break;
      }
    }
    if (question == null) {
      return const _SkillInfo(
        subjectId: '',
        subjectName: 'مهارة تدريبية',
        lessonName: 'مهارة تدريبية',
      );
    }
    return _SkillInfo(
      subjectId: question.subjectId,
      subjectName: repo.subjectName(question.subjectId),
      lessonName: repo.lessonName(question.lessonId),
    );
  }

  IconData _subjectIcon(String id) => switch (id) {
        'math' => Icons.calculate_rounded,
        'arabic' => Icons.menu_book_rounded,
        'science' => Icons.science_rounded,
        'social' => Icons.public_rounded,
        'islamic' => Icons.auto_stories_rounded,
        _ => Icons.insights_rounded,
      };
}

class _SkillInfo {
  final String subjectId;
  final String subjectName;
  final String lessonName;

  const _SkillInfo({
    required this.subjectId,
    required this.subjectName,
    required this.lessonName,
  });
}

class _EmptyProgress extends StatelessWidget {
  const _EmptyProgress();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 36,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'نحتاج أول اختبار',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'بعد حل الاختبارات سيحلل التطبيق المهارات ويعرض نقاط القوة وما يحتاج مراجعة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}
