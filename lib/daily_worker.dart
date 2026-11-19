import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'topic_library.dart';
import 'research_service.dart';
import 'video_maker.dart';

const dailyTaskName='motivaDailyVideo';
const dailyUniqueName='motiva_daily_video_generation';

String _dayKey(DateTime d)=>'${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

@pragma('vm:entry-point')
void motivaCallbackDispatcher() {
  Workmanager().executeTask((taskName,inputData) async {
    if(taskName!=dailyTaskName) return true;
    WidgetsFlutterBinding.ensureInitialized();
    ui.DartPluginRegistrant.ensureInitialized();
    final prefs=await SharedPreferences.getInstance();
    final today=_dayKey(DateTime.now());
    if(!(prefs.getBool('daily_auto')??false)) return true;
    if(prefs.getString('daily_generated_day')==today) return true;
    try {
      await prefs.setString('daily_status','आजचा व्हिडिओ Background मध्ये तयार होत आहे...');
      final used=prefs.getStringList('used_topics')??[];
      final usedTitles=prefs.getStringList('used_titles')??[];
      final available=topics.where((t)=>!used.contains(t.id)&&!usedTitles.contains(t.title.trim().toLowerCase())).toList();
      if(available.isEmpty) {
        await prefs.setString('daily_status','सध्याच्या सर्व विषयांचा वापर झाला आहे. नवीन विषय जोडणे आवश्यक आहे.');
        return true;
      }
      final dayNumber=DateTime.now().difference(DateTime(2020,1,1)).inDays;
      final topic=available[dayNumber%available.length];
      await prefs.setString('daily_status','${topic.title}: विश्वसनीय हिंदी संदर्भ शोधत आहे...');
      final bundle=await ResearchService.research(topic);
      final tts=FlutterTts();
      await tts.setLanguage('hi-IN');
      await tts.awaitSynthCompletion(true);
      final savedVoice=prefs.getString('male_voice');
      final voiceJson=prefs.getString('daily_voice')??savedVoice;
      Map<String,String>? voice;
      if(voiceJson!=null) {
        final decoded=jsonDecode(voiceJson);
        if(decoded is Map) voice=decoded.map((k,v)=>MapEntry(k.toString(),v.toString()));
      }
      await prefs.setString('daily_status','मुक्त चित्रे, आवाज आणि व्हिडिओ तयार होत आहेत...');
      final path=await VideoMaker.create(
        title:topic.title,
        script:bundle.script,
        tts:tts,
        voiceStyle:0,
        voice:voice,
        imagePaths:bundle.images.map((i)=>i.path).toList(),
        creditsText:bundle.credits,
        onStatus:(s){prefs.setString('daily_status',s);},
      );
      if(!used.contains(topic.id)) used.add(topic.id);
      final key=topic.title.trim().toLowerCase();
      if(!usedTitles.contains(key)) usedTitles.add(key);
      await prefs.setStringList('used_topics',used);
      await prefs.setStringList('used_titles',usedTitles);
      await prefs.setString('topic_day',today);
      await prefs.setString('topic_id',topic.id);
      await prefs.setString('daily_script',bundle.script);
      await prefs.setString('daily_generated_day',today);
      await prefs.setString('daily_video_path',path);
      await prefs.setString('daily_video_title',topic.title);
      await prefs.setString('daily_status','आजचा नवीन व्हिडिओ तयार झाला आहे. Downloads/MotivaAI फोल्डर तपासा.');
      await tts.stop();
      return true;
    } catch(e) {
      await prefs.setString('daily_status','स्वयंचलित निर्मिती थांबली: ${e.toString().replaceFirst('Exception: ','')}');
      return false;
    }
  });
}
