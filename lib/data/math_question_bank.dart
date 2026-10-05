import 'models.dart';

class MathQuestionBank {
  static List<Question> build(List<LessonInfo> lessons) {
    final out=<Question>[];
    for(final lesson in lessons.where((l)=>l.subjectId=='math')){
      out.addAll(_forLesson(lesson));
    }
    return out;
  }

  static List<Question> _forLesson(LessonInfo l){
    switch(l.id){
      case 'math_c1_l1': return _placeValue(l, maxMillions:false);
      case 'math_c1_l2': return _millionExplore(l);
      case 'math_c1_l3': return _placeValue(l, maxMillions:true);
      case 'math_c1_l4': return _fourSteps(l);
      case 'math_c1_l5': return _compare(l);
      case 'math_c1_l6': return _order(l);
      case 'math_c1_l7': return _rounding(l);
      case 'math_c2_l1': return _properties(l);
      case 'math_c2_l2': return _estimateAddSub(l);
      case 'math_c2_l3': return _estimateOrExact(l);
      case 'math_c2_l4': return _addition(l);
      case 'math_c2_l5': return _subtraction(l,zeros:false);
      case 'math_c2_l6': return _subtraction(l,zeros:true);
      case 'math_c3_l1': return _dataCollection(l);
      case 'math_c3_l2': return _tables(l);
      case 'math_c3_l3': return _barData(l);
      case 'math_c3_l4': return _lineData(l);
      case 'math_c3_l5': return _sectorData(l);
      case 'math_c3_l6': return _probability(l);
      case 'math_c4_l1': return _expressions(l);
      case 'math_c4_l2': return _numberSentences(l);
      case 'math_c4_l3': return _logic(l);
      case 'math_c4_l4': return _tableRule(l, multiply:false);
      case 'math_c4_l5': return _functionTable(l, multiply:false);
      case 'math_c4_l7': return _functionTable(l, multiply:true);
      case 'math_c5_l1': return _factorsMultiples(l);
      case 'math_c5_l2': return _multiplyPowers10(l);
      case 'math_c5_l3': return _reasonableness(l);
      case 'math_c5_l4': return _estimateProducts(l);
      case 'math_c5_l5': return _multiplyOneDigit(l,regroup:false,threeDigits:false);
      case 'math_c5_l6': return _multiplyOneDigit(l,regroup:true,threeDigits:false);
      case 'math_c5_l8': return _multiplyOneDigit(l,regroup:true,threeDigits:true);
      case 'math_c6_l1': return _multiplyTens(l);
      case 'math_c6_l2': return _estimateProducts(l);
      case 'math_c6_l3': return _wordMultiplication(l);
      case 'math_c6_l4': return _multiplyTwoDigits(l,threeDigits:false);
      case 'math_c6_l5': return _multiplyTwoDigits(l,threeDigits:true);
      default: return const [];
    }
  }

  static Difficulty _d(int i)=>Difficulty.values[i%3];
  static String _skill(LessonInfo l)=>'${l.id}_skill';
  static Question _q(LessonInfo l,int i,{required QuestionType type,required String text,required String answer,List<String> options=const [],String explanation=''})=>Question(
    id:'${l.id}_q_$i',subjectId:l.subjectId,unitId:l.unitId,lessonId:l.id,skillId:_skill(l),type:type,difficulty:_d(i),question:text,options:options,correctAnswer:answer,
    explanation:explanation.isEmpty?'سؤال تدريبي أصلي مبني على مهارة الدرس الموثق.':explanation,score:1,isOfficial:false,
  );
  static List<String> _opts(int answer,{int step=10}){
    final vals=<int>{answer,answer+step,answer+step*2};
    if(answer-step>=0) vals.add(answer-step); else vals.add(answer+step*3);
    return vals.take(4).map((e)=>'$e').toList();
  }

  static List<Question> _placeValue(LessonInfo l,{required bool maxMillions}){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final base=(maxMillions?2345678:234567)+(i*137);
      final places=maxMillions?<int>[10,100,1000,10000,100000,1000000]:<int>[10,100,1000,10000,100000];
      final p=places[i%places.length];
      final digit=(base~/p)%10, value=digit*p;
      final type=i%3==0?QuestionType.multipleChoice:QuestionType.numeric;
      out.add(_q(l,i,type:type,text:'ما القيمة المنزلية للرقم $digit في العدد $base؟',answer:'$value',options:type==QuestionType.multipleChoice?_opts(value,step:p):const []));
    }
    return out;
  }

  static List<Question> _millionExplore(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      if(i%3==0){
        out.add(_q(l,i,type:QuestionType.multipleChoice,text:'أي عدد يساوي مليونًا واحدًا؟',answer:'1000000',options:const ['100000','1000000','10000','10000000']));
      }else if(i%3==1){
        final n=1000000+(i*100000);
        out.add(_q(l,i,type:QuestionType.trueFalse,text:'العدد $n أكبر من 1000000.',answer:n>1000000?'صح':'خطأ',options:const ['صح','خطأ']));
      }else{
        final thousands=1000+(i*10);
        out.add(_q(l,i,type:QuestionType.numeric,text:'كم يساوي $thousands ألفًا بالأرقام؟',answer:'${thousands*1000}'));
      }
    }
    return out;
  }

  static List<Question> _fourSteps(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final a=120+i*7,b=35+i*3,answer=a+b;
      out.add(_q(l,i,type:i%2==0?QuestionType.applied:QuestionType.numeric,text:'لدى مكتبة $a كتابًا، وأضافت $b كتابًا. كم كتابًا أصبح لديها؟',answer:'$answer',explanation:'أفهم المطلوب، أخطط، أحل بجمع العددين، ثم أتحقق من معقولية الناتج.'));
    }
    return out;
  }

  static List<Question> _compare(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final a=120000+i*731,b=119500+i*709;
      final ans=a>b?'>':a<b?'<':'=';
      out.add(_q(l,i,type:QuestionType.multipleChoice,text:'اختر الرمز المناسب: $a □ $b',answer:ans,options:const ['>','<','='])) ;
    }
    return out;
  }

  static List<Question> _order(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final a=32000+i*11,b=a+700,c=a-500;
      final sorted=[a,b,c]..sort();
      final ans=sorted.join('، ');
      out.add(_q(l,i,type:QuestionType.shortAnswer,text:'رتب الأعداد تصاعديًا: $a، $b، $c',answer:ans,explanation:'نقارن القيم المنزلية من أكبر منزلة إلى أصغر منزلة.'));
    }
    return out;
  }

  static List<Question> _rounding(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final n=1250+i*137;
      final toHundred=i%2==0;
      final unit=toHundred?100:1000;
      final rounded=((n+unit~/2)~/unit)*unit;
      out.add(_q(l,i,type:i%3==0?QuestionType.multipleChoice:QuestionType.numeric,text:'قرّب العدد $n إلى أقرب ${toHundred?'مئة':'ألف'}.',answer:'$rounded',options:i%3==0?_opts(rounded,step:unit):const []));
    }
    return out;
  }

  static List<Question> _properties(LessonInfo l){
    final out=<Question>[];
    const names=['خاصية الإبدال','خاصية التجميع','خاصية العنصر المحايد'];
    for(var i=0;i<36;i++){
      final a=3+i%7,b=5+i%5,c=2+i%4;
      if(i%3==0) out.add(_q(l,i,type:QuestionType.multipleChoice,text:'ما الخاصية التي توضح: $a + $b = $b + $a ؟',answer:names[0],options:names));
      else if(i%3==1) out.add(_q(l,i,type:QuestionType.multipleChoice,text:'ما الخاصية التي توضح: ($a + $b) + $c = $a + ($b + $c) ؟',answer:names[1],options:names));
      else out.add(_q(l,i,type:QuestionType.fillBlank,text:'أكمل: $a + 0 = ____',answer:'$a'));
    }
    return out;
  }

  static int _round100(int n)=>((n+50)~/100)*100;
  static List<Question> _estimateAddSub(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final a=1250+i*43,b=640+i*17,add=i%2==0;
      final answer=add?_round100(a)+_round100(b):_round100(a)-_round100(b);
      out.add(_q(l,i,type:QuestionType.numeric,text:'قدّر ${add?'مجموع':'فرق'} $a و $b بالتقريب إلى أقرب مئة.',answer:'$answer'));
    }
    return out;
  }

  static List<Question> _estimateOrExact(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final exact=i%2==0;
      out.add(_q(l,i,type:QuestionType.multipleChoice,text:exact?'تريد معرفة المبلغ الذي ستدفعه عند الصندوق. هل تحتاج إلى تقدير أم إجابة دقيقة؟':'تريد معرفة تكلفة تقريبية قبل التسوق. هل تحتاج إلى تقدير أم إجابة دقيقة؟',answer:exact?'إجابة دقيقة':'تقدير',options:const ['تقدير','إجابة دقيقة']));
    }
    return out;
  }

  static List<Question> _addition(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final a=2345+i*37,b=1678+i*23,answer=a+b;
      final type=i%3==0?QuestionType.multipleChoice:QuestionType.numeric;
      out.add(_q(l,i,type:type,text:'أوجد ناتج: $a + $b',answer:'$answer',options:type==QuestionType.multipleChoice?_opts(answer,step:100):const []));
    }
    return out;
  }

  static List<Question> _subtraction(LessonInfo l,{required bool zeros}){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final a=zeros?5000+i*100:5000+i*41;
      final b=zeros?1780+i*7:1780+i*19;
      final answer=a-b;
      final type=i%3==0?QuestionType.multipleChoice:QuestionType.numeric;
      out.add(_q(l,i,type:type,text:'أوجد ناتج: $a - $b',answer:'$answer',options:type==QuestionType.multipleChoice?_opts(answer,step:100):const []));
    }
    return out;
  }

  static List<Question> _dataCollection(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      out.add(_q(l,i,type:QuestionType.multipleChoice,text:'إذا أردنا معرفة الفاكهة المفضلة لدى طلاب الصف، فما الخطوة الأنسب لجمع البيانات؟',answer:'طرح سؤال وتسجيل الإجابات',options:const ['طرح سؤال وتسجيل الإجابات','التخمين فقط','حذف الإجابات','اختيار إجابة واحدة للجميع']));
    }
    return out;
  }
  static List<Question> _tables(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final apples=3+i%6,oranges=5+i%5;
      out.add(_q(l,i,type:QuestionType.numeric,text:'في جدول: التفاح=$apples، البرتقال=$oranges. كم المجموع؟',answer:'${apples+oranges}'));
    }
    return out;
  }
  static List<Question> _barData(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final a=4+i%4,b=7+i%5;
      out.add(_q(l,i,type:QuestionType.numeric,text:'يمثل عمود الكتب المقروءة: خالد=$a كتب، سعد=$b كتب. كم يزيد ما قرأه سعد على خالد؟',answer:'${b-a}'));
    }
    return out;
  }
  static List<Question> _lineData(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final a=20+i%5,b=a+3+(i%4);
      out.add(_q(l,i,type:QuestionType.numeric,text:'كانت درجة الحرارة صباحًا $a° ثم أصبحت ظهرًا $b°. كم مقدار الزيادة؟',answer:'${b-a}'));
    }
    return out;
  }
  static List<Question> _sectorData(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final total=20,football=5+i%6;
      out.add(_q(l,i,type:QuestionType.numeric,text:'في مسح شمل $total طالبًا، اختار $football منهم كرة القدم. كم طالبًا اختار نشاطًا آخر؟',answer:'${total-football}'));
    }
    return out;
  }
  static List<Question> _probability(LessonInfo l){
    final out=<Question>[];
    const opts=['مؤكد','محتمل','مستحيل'];
    for(var i=0;i<36;i++){
      final mode=i%3;
      final text=mode==0?'كيس فيه كرات حمراء فقط. سحب كرة حمراء هو حدث ...':mode==1?'كيس فيه كرات حمراء وزرقاء. سحب كرة زرقاء هو حدث ...':'كيس فيه كرات حمراء فقط. سحب كرة خضراء هو حدث ...';
      out.add(_q(l,i,type:QuestionType.multipleChoice,text:text,answer:opts[mode],options:opts));
    }
    return out;
  }

  static List<Question> _expressions(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final a=4+i%7,b=3+i%5,c=2+i%4,answer=a+b*c;
      out.add(_q(l,i,type:QuestionType.numeric,text:'أوجد قيمة العبارة العددية: $a + ($b × $c)',answer:'$answer'));
    }
    return out;
  }
  static List<Question> _numberSentences(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final a=5+i%6,b=2+i%4,answer=a+b;
      out.add(_q(l,i,type:QuestionType.fillBlank,text:'أكمل الجملة العددية: $a + $b = ____',answer:'$answer'));
    }
    return out;
  }
  static List<Question> _logic(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final trueStatement=i.isEven;
      out.add(_q(
        l,i,
        type:QuestionType.trueFalse,
        text:trueStatement
          ?'إذا كان عدد ما زوجيًا، فإن إضافة 2 إليه تعطي عددًا زوجيًا أيضًا.'
          :'إذا كان عدد ما زوجيًا، فإن إضافة 1 إليه تعطي عددًا زوجيًا أيضًا.',
        answer:trueStatement?'صح':'خطأ',
        options:const ['صح','خطأ'],
      ));
    }
    return out;
  }
  static List<Question> _tableRule(LessonInfo l,{required bool multiply}){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final input=2+i%8,rule=2+i%4,answer=multiply?input*rule:input+rule;
      out.add(_q(l,i,type:QuestionType.numeric,text:'قاعدة الجدول: ${multiply?'اضرب في':'أضف'} $rule. إذا كانت المدخلة $input فما المخرجة؟',answer:'$answer'));
    }
    return out;
  }
  static List<Question> _functionTable(LessonInfo l,{required bool multiply})=>_tableRule(l,multiply:multiply);

  static List<Question> _factorsMultiples(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final n=12+(i%6)*2;
      if(i%2==0){
        final f=2;
        out.add(_q(l,i,type:QuestionType.trueFalse,text:'العدد $f قاسم للعدد $n.',answer:n%f==0?'صح':'خطأ',options:const ['صح','خطأ']));
      }else{
        final m=3+i%5;
        out.add(_q(l,i,type:QuestionType.numeric,text:'اكتب المضاعف الرابع للعدد $m.',answer:'${m*4}'));
      }
    }
    return out;
  }
  static List<Question> _multiplyPowers10(LessonInfo l){
    final out=<Question>[];
    final factors=[10,100,1000];
    for(var i=0;i<36;i++){
      final a=2+i%8,b=factors[i%3],answer=a*b;
      out.add(_q(l,i,type:i%3==0?QuestionType.multipleChoice:QuestionType.numeric,text:'أوجد ناتج: $a × $b',answer:'$answer',options:i%3==0?_opts(answer,step:b):const []));
    }
    return out;
  }
  static List<Question> _reasonableness(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final a=21+i%9,b=4+i%4,exact=a*b,claim=i%2==0?exact:exact+50;
      out.add(_q(l,i,type:QuestionType.trueFalse,text:'الناتج $claim إجابة معقولة للمسألة $a × $b.',answer:i%2==0?'صح':'خطأ',options:const ['صح','خطأ']));
    }
    return out;
  }
  static List<Question> _estimateProducts(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final a=21+i%29,b=3+i%6,rounded=((a+5)~/10)*10,answer=rounded*b;
      out.add(_q(l,i,type:QuestionType.numeric,text:'قدّر ناتج $a × $b بتقريب العدد $a إلى أقرب عشرة.',answer:'$answer'));
    }
    return out;
  }
  static List<Question> _multiplyOneDigit(LessonInfo l,{required bool regroup,required bool threeDigits}){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final a=threeDigits?120+i*7:(regroup?27+i%30:21+(i%7)*10);
      final b=2+i%7,answer=a*b;
      out.add(_q(l,i,type:i%3==0?QuestionType.multipleChoice:QuestionType.numeric,text:'أوجد ناتج: $a × $b',answer:'$answer',options:i%3==0?_opts(answer,step:10):const []));
    }
    return out;
  }
  static List<Question> _multiplyTens(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final a=10*(2+i%8),b=10*(2+(i*2)%7),answer=a*b;
      out.add(_q(l,i,type:QuestionType.numeric,text:'أوجد ناتج: $a × $b',answer:'$answer'));
    }
    return out;
  }
  static List<Question> _wordMultiplication(LessonInfo l){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final groups=12+i%9,each=14+i%6,answer=groups*each;
      out.add(_q(l,i,type:QuestionType.applied,text:'في كل صندوق $each قطعة، وعدد الصناديق $groups. كم قطعة في المجموع؟',answer:'$answer'));
    }
    return out;
  }
  static List<Question> _multiplyTwoDigits(LessonInfo l,{required bool threeDigits}){
    final out=<Question>[];
    for(var i=0;i<36;i++){
      final a=threeDigits?120+i*9:21+i%30,b=12+i%18,answer=a*b;
      out.add(_q(l,i,type:i%3==0?QuestionType.multipleChoice:QuestionType.numeric,text:'أوجد ناتج: $a × $b',answer:'$answer',options:i%3==0?_opts(answer,step:100):const []));
    }
    return out;
  }
}
