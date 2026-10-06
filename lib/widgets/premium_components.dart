import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumPageHeader extends StatelessWidget {
  final String eyebrow, title, subtitle;
  final IconData icon;
  const PremiumPageHeader({super.key, required this.eyebrow, required this.title, required this.subtitle, required this.icon});
  @override Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(30),
      gradient: const LinearGradient(begin: Alignment.topRight,end: Alignment.bottomLeft,
        colors:[AppColors.navy,AppColors.navySoft,AppColors.primaryDeep]),
      boxShadow: AppShadows.glow(AppColors.primary)),
    child: Row(children:[
      Container(width:58,height:58,decoration:BoxDecoration(color:Colors.white.withOpacity(.10),borderRadius:BorderRadius.circular(19)),
        child:Icon(icon,color:Colors.white,size:29)),
      const SizedBox(width:15),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(eyebrow,style:const TextStyle(color:AppColors.gold,fontSize:11,fontWeight:FontWeight.w900)),
        const SizedBox(height:5),
        Text(title,style:const TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w900)),
        const SizedBox(height:5),
        Text(subtitle,style:TextStyle(color:Colors.white.withOpacity(.68),height:1.45,fontSize:12,fontWeight:FontWeight.w600)),
      ]))
    ])
  );
}

class PremiumStepBar extends StatelessWidget {
  final int current,total;
  const PremiumStepBar({super.key,required this.current,required this.total});
  @override Widget build(BuildContext context) {
    final v=total<=0?0.0:(current/total).clamp(0.0,1.0);
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        Text('الخطوة '+current.toString()+' من '+total.toString(),style:const TextStyle(color:AppColors.muted,fontSize:12,fontWeight:FontWeight.w800)),
        const Spacer(),
        Text(((v*100).round()).toString()+'%',style:const TextStyle(color:AppColors.primaryDeep,fontWeight:FontWeight.w900)),
      ]),
      const SizedBox(height:9),
      ClipRRect(borderRadius:BorderRadius.circular(99),child:LinearProgressIndicator(value:v,minHeight:8)),
    ]);
  }
}

class PremiumEmptyState extends StatelessWidget {
  final IconData icon; final String title,message; final String? actionLabel; final VoidCallback? onAction;
  const PremiumEmptyState({super.key,required this.icon,required this.title,required this.message,this.actionLabel,this.onAction});
  @override Widget build(BuildContext context)=>Container(
    width:double.infinity,padding:const EdgeInsets.all(26),
    decoration:BoxDecoration(color:AppColors.surface,borderRadius:BorderRadius.circular(28),border:Border.all(color:AppColors.border)),
    child:Column(children:[
      Container(width:64,height:64,decoration:BoxDecoration(color:AppColors.primarySoft,borderRadius:BorderRadius.circular(22)),
        child:Icon(icon,color:AppColors.primary,size:31)),
      const SizedBox(height:15),
      Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900,color:AppColors.text)),
      const SizedBox(height:7),
      Text(message,textAlign:TextAlign.center,style:const TextStyle(color:AppColors.muted,height:1.55,fontWeight:FontWeight.w600)),
      if(actionLabel!=null&&onAction!=null)...[const SizedBox(height:18),FilledButton(onPressed:onAction,child:Text(actionLabel!))],
    ])
  );
}