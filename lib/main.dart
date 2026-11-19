import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'video_maker.dart';
import 'topic_library.dart';
import 'research_service.dart';
import 'daily_worker.dart';
import 'package:workmanager/workmanager.dart';

Future<void> main() async { WidgetsFlutterBinding.ensureInitialized(); await Workmanager().initialize(motivaCallbackDispatcher); runApp(const MotivaAI()); }
const teal = Color(0xFF20D6C2);
const bg = Color(0xFF050708);
const panel = Color(0xFF111719);

class MotivaAI extends StatelessWidget {
  const MotivaAI({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner:false, title:'MotivaAI',
    theme:ThemeData(brightness:Brightness.dark,scaffoldBackgroundColor:bg,colorScheme:const ColorScheme.dark(primary:teal,surface:panel),useMaterial3:true),
    home:const Home(),
  );
}
class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState()=>_HomeState();
}
class _HomeState extends State<Home> {
  final tts=FlutterTts();
  final custom=TextEditingController();
  int tab=0,voice=0;
  bool ready=false,speaking=false,generating=false,autoDaily=false;
  List<Map<String,String>> hindiVoices=[];
  Map<String,String>? maleVoice,femaleVoice;
  List<String> used=[],usedTitles=[];
  Topic? topic;
  String script='',status='मोफत ऑफलाइन कथा निर्मिती.';
  @override
  void initState(){
    super.initState();
    tts.setCompletionHandler(()=>setState(()=>speaking=false));
    tts.setErrorHandler((_)=>setState(()=>status='फोनमध्ये हिंदी आवाज उपलब्ध नाही.'));
    init();
  }
  String day(DateTime d)=>d.year.toString()+'-'+d.month.toString()+'-'+d.day.toString();
  Future<void> init() async {
    final p=await SharedPreferences.getInstance();
    used=p.getStringList('used_topics')??[];
    usedTitles=p.getStringList('used_titles')??[];
    autoDaily=p.getBool('daily_auto')??false;
    status=p.getString('daily_status')??status;
    final savedMale=p.getString('male_voice'), savedFemale=p.getString('female_voice');
    if(savedMale!=null) maleVoice=_decodeVoice(savedMale);
    if(savedFemale!=null) femaleVoice=_decodeVoice(savedFemale);
    await loadHindiVoices();
    if(autoDaily) await scheduleDaily(true);
    if(p.getString('topic_day')==day(DateTime.now())){
      final id=p.getString('topic_id');
      for(final t in topics){if(t.id==id) topic=t;}
      script=p.getString('daily_script')??'';
    }
    if(topic==null) await nextTopic();
    if(mounted)setState(()=>ready=true);
  }
  Map<String,String>? _decodeVoice(String value) { try { final d=jsonDecode(value); if(d is Map) return d.map((k,v)=>MapEntry(k.toString(),v.toString())); } catch (_) {} return null; }
  String _voiceKey(Map<String,String> v)=>'${v['name']??''}|${v['locale']??''}';
  Future<void> loadHindiVoices() async {
    try {
      final raw=await tts.getVoices;
      final found=<Map<String,String>>[];
      for(final item in raw) {
        if(item is! Map) continue;
        final locale=(item['locale']??'').toString();
        if(!locale.toLowerCase().startsWith('hi')) continue;
        final name=(item['name']??'Hindi voice').toString();
        found.add({'name':name,'locale':locale});
      }
      hindiVoices=found;
      if(hindiVoices.isNotEmpty) {
        final validKeys=hindiVoices.map(_voiceKey).toSet();
        if(maleVoice==null||!validKeys.contains(_voiceKey(maleVoice!))) {
          maleVoice=hindiVoices.firstWhere((v)=>v['name']!.toLowerCase().contains('male')&&!v['name']!.toLowerCase().contains('female'),orElse:()=>hindiVoices.first);
        }
        if(femaleVoice==null||!validKeys.contains(_voiceKey(femaleVoice!))) {
          femaleVoice=hindiVoices.firstWhere((v)=>v['name']!.toLowerCase().contains('female'),orElse:()=>hindiVoices.length>1?hindiVoices[1]:hindiVoices.first);
        }
        final p=await SharedPreferences.getInstance();
        await p.setString('male_voice',jsonEncode(maleVoice));
        await p.setString('female_voice',jsonEncode(femaleVoice));
        await p.setString('daily_voice',jsonEncode(maleVoice));
      }
    } catch (_) { if(mounted)setState(()=>status='फोनमधील Hindi voices शोधता आले नाहीत.'); }
  }
  Future<void> scheduleDaily(bool enabled) async {
    final p=await SharedPreferences.getInstance();
    await p.setBool('daily_auto',enabled);
    if(enabled) {
      await Workmanager().registerPeriodicTask(dailyUniqueName,dailyTaskName,
        frequency:const Duration(hours:24),
        existingPeriodicWorkPolicy:ExistingPeriodicWorkPolicy.update,
        constraints:Constraints(networkType:NetworkType.connected,requiresBatteryNotLow:true),
        foregroundServiceConfig:ForegroundServiceConfig(notificationTitle:'MotivaAI',notificationText:'आजचा नवीन Mystery व्हिडिओ तयार होत आहे.',notificationChannelName:'MotivaAI Video Generation',foregroundServiceType:ForegroundServiceType.dataSync));
      await p.setString('daily_status','रोजच्या स्वयंचलित निर्मितीचे वेळापत्रक सुरू आहे. Android योग्य वेळी चालवेल.');
    } else {
      await Workmanager().cancelByUniqueName(dailyUniqueName);
      await p.setString('daily_status','स्वयंचलित निर्मिती बंद आहे.');
    }
    if(mounted)setState(()=>autoDaily=enabled);
  }
  Future<void> previewVoice(Map<String,String>? selected) async {
    if(selected==null){msg('फोनमध्ये हा Hindi voice उपलब्ध नाही.');return;}
    await tts.stop();await tts.setLanguage('hi-IN');await tts.setVoice(selected);await tts.speak('नमस्कार दोस्तों, MotivaAI में आपका स्वागत है।');
  }
  Widget voicePicker(String label,Map<String,String>? selected,bool male) => Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(label,style:const TextStyle(fontWeight:FontWeight.w700)),
    DropdownButtonFormField<String>(value:selected==null?null:_voiceKey(selected),isExpanded:true,decoration:const InputDecoration(filled:true,fillColor:panel),items:hindiVoices.map((v)=>DropdownMenuItem(value:_voiceKey(v),child:Text(v['name']??'Hindi voice',overflow:TextOverflow.ellipsis))).toList(),onChanged:(key)async{if(key==null)return;final chosen=hindiVoices.firstWhere((v)=>_voiceKey(v)==key);setState(()=>male?maleVoice=chosen:femaleVoice=chosen);final p=await SharedPreferences.getInstance();await p.setString(male?'male_voice':'female_voice',jsonEncode(chosen));if(male)await p.setString('daily_voice',jsonEncode(chosen));}),
    TextButton.icon(onPressed:()=>previewVoice(selected),icon:const Icon(Icons.play_arrow,color:teal),label:const Text('आवाज ऐकून पाहा')),
  ]);
  Future<void> nextTopic() async {
    var options=topics.where((t)=>!used.contains(t.id)).toList();
    if(options.isEmpty){if(mounted)setState(()=>status='या App मधील सर्व सध्याचे विषय वापरले गेले आहेत. जुना विषय पुन्हा निवडला जाणार नाही. नवीन विषय जोडणे आवश्यक आहे.');return;}
    final t=options[DateTime.now().microsecondsSinceEpoch%options.length];
    await setTopic(t);
  }
  String titleKey(String value)=>value.trim().toLowerCase().replaceAll(RegExp(r'\s+'),' ');
  Future<void> setTopic(Topic t) async {
    if(usedTitles.contains(titleKey(t.title))){if(mounted)msg('हा विषय आधी वापरला आहे. दुसरा विषय निवडा.');return;}
    topic=t;
    if(!used.contains(t.id))used.add(t.id);
    usedTitles.add(titleKey(t.title));
    script=makeScript(t);
    final p=await SharedPreferences.getInstance();
    await p.setStringList('used_topics',used);
    await p.setStringList('used_titles',usedTitles);
    await p.setString('topic_day',day(DateTime.now()));
    await p.setString('topic_id',t.id);
    await p.setString('daily_script',script);
    if(mounted)setState(()=>status='नवीन विषय आणि हिंदी Script तयार झाली.');
  }
  String makeScript(Topic t){
    final seed=t.id.codeUnits.fold<int>(0,(a,b)=>a+b);
    const openings=['दुनिया में कुछ सवाल ऐसे हैं जिनका जवाब आज भी पूरी तरह हमारे पास नहीं है। आज की कहानी ऐसे ही एक रहस्य की है।','इतिहास के पन्नों में कई ऐसी घटनाएँ दर्ज हैं जो हमें सोचने पर मजबूर कर देती हैं।','कल्पना कीजिए, आप ऐसी जगह पर हैं जहाँ हर पत्थर एक अनकही कहानी छिपाए हुए है।'];
    const turns=['समय के साथ इस घटना को लेकर अलग-अलग विचार सामने आए। कुछ बातें प्रमाणों पर आधारित हैं, जबकि कुछ केवल लोककथाएँ हैं।','जितनी जानकारी सामने आई, उतना ही यह सवाल गहरा होता गया कि आखिर उस समय वास्तव में हुआ क्या था।','इस विषय को समझने के लिए इतिहास, भूगोल और उपलब्ध वैज्ञानिक प्रमाणों को साथ देखना जरूरी है।'];
    const endings=['रहस्य का आनंद लेते हुए तथ्य और कल्पना के बीच फर्क बनाए रखना जरूरी है। आपकी राय में इसकी सबसे संभावित वजह क्या हो सकती है?','शायद आने वाले समय में नई खोजें इस कहानी को और स्पष्ट करें। तब तक यह सवाल हमारी जिज्ञासा बनाए रखेगा।','इस कहानी से पता चलता है कि हर रहस्य का जवाब खोजने के लिए धैर्य और प्रमाण दोनों जरूरी हैं।'];
    return t.title+'\n\n'+openings[seed%3]+'\n\nआज हम बात कर रहे हैं '+t.place+' से जुड़े इस रहस्य की। इसका मुख्य संकेत है: '+t.clue+'।\n\nसबसे पहले इसकी पृष्ठभूमि समझते हैं। किसी भी रहस्यमयी घटना को समझने के लिए उसके समय, स्थान और उपलब्ध जानकारी को ध्यान में रखना जरूरी है। '+t.place+' का नाम इस विषय के साथ इसलिए जुड़ा है क्योंकि यहाँ से जुड़ी कुछ घटनाओं और खोजों ने लोगों की जिज्ञासा बढ़ाई।\n\nअब सबसे बड़ा सवाल है — '+t.clue+'। इस सवाल को लेकर कई तरह की व्याख्याएँ की गई हैं। एक ओर वे तथ्य हैं जिन्हें दस्तावेज़ों, शोध या प्रत्यक्ष अवलोकन से समझा जा सकता है। दूसरी ओर ऐसी कहानियाँ भी हैं जिनकी स्वतंत्र पुष्टि जरूरी है।\n\n'+turns[(seed+1)%3]+'\n\nसंभावित वजहों पर नज़र डालें तो प्राकृतिक, ऐतिहासिक और मानवीय कारणों की जाँच करनी होगी। कई बार कोई घटना उस समय के सीमित ज्ञान के कारण असाधारण लगती है, लेकिन बाद में विज्ञान और शोध उसकी बेहतर व्याख्या कर देते हैं। कुछ मामलों में जरूरी जानकारी समय के साथ खो जाती है। पुराने रिकॉर्ड, भौगोलिक बदलाव और मानवीय याददाश्त हमारी समझ को प्रभावित कर सकते हैं।\n\nइस कहानी का एक और पहलू है लोगों की कल्पना। जब किसी सवाल का पूरा जवाब नहीं मिलता, तो उसके आसपास कई किस्से बन जाते हैं। इसलिए हर दावे को सच मानने के बजाय प्रमाणों को प्राथमिकता देना जरूरी है।\n\nतो आज हमने जाना '+t.title+' के बारे में। इस विषय से जुड़े कुछ सवाल अब भी चर्चा में हैं और नई जानकारी मिलने पर हमारी समझ बदल सकती है।\n\n'+endings[(seed+2)%3]+'\n\nअगर आपको ऐसी रहस्यमयी कहानियाँ पसंद हैं, तो अगली कहानी के लिए जुड़े रहिए।';
  }
  Future<void> makeVideo() async {
    if(generating || topic==null || script.isEmpty)return;
    setState((){generating=true;status='Video तयार करण्याची तयारी...';});
    try {
      final p=await SharedPreferences.getInstance();
      setState(()=>status='Hindi संदर्भांमधून माहिती तपासत आहे...');
      final bundle=await ResearchService.research(topic!);
      script=bundle.script;
      await p.setString('daily_script',script);
      if(mounted)setState(()=>status='स्रोत तपासले. चित्रे आणि आवाज जोडत आहे...');
      final chosenVoice=voice==0?maleVoice:femaleVoice;
      final path=await VideoMaker.create(title:topic!.title,script:script,tts:tts,voiceStyle:voice,voice:chosenVoice,imagePaths:bundle.images.map((i)=>i.path).toList(),creditsText:bundle.credits,onStatus:(s){if(mounted)setState(()=>status=s);});
      final today=day(DateTime.now());
      await p.setString('daily_generated_day',today);
      await p.setString('daily_video_path',path);
      await p.setString('daily_video_title',topic!.title);
      await p.setString('daily_status','आजचा स्रोतांसह व्हिडिओ तयार झाला आहे.');
      if(mounted)msg('Video आणि Credits Downloads/MotivaAI मध्ये सेव्ह झाले.');
    } catch(e) {
      if(mounted){setState(()=>status='Video तयार झाला नाही.');msg(e.toString().replaceFirst('Exception: ',''));}
    } finally {if(mounted)setState(()=>generating=false);}
  }
  Future<void> customScript() async {
    final s=custom.text.trim();if(s.isEmpty){msg('आधी विषय लिहा.');return;}
    await setTopic(Topic('custom_'+DateTime.now().millisecondsSinceEpoch.toString(),s,'आपके चुने हुए विषय पर','इस विषय से जुड़ा अनसुलझा सवाल'));
    custom.clear();setState(()=>tab=2);
  }
  Future<void> speak() async {
    if(script.isEmpty)return;
    await tts.stop();await tts.setLanguage('hi-IN');final chosenVoice=voice==0?maleVoice:femaleVoice;if(chosenVoice!=null)await tts.setVoice(chosenVoice);await tts.setSpeechRate(.45);
    final r=await tts.speak(script);
    if(mounted)setState(()=>speaking=r==1);
  }
  Future<void> stop() async {await tts.stop();if(mounted)setState(()=>speaking=false);}
  void msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  @override
  void dispose(){tts.stop();custom.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(backgroundColor:bg,title:const Row(children:[Icon(Icons.visibility_outlined,color:teal),SizedBox(width:9),Text('MotivaAI',style:TextStyle(fontWeight:FontWeight.w800))])),
    body:SafeArea(child:!ready?const Center(child:CircularProgressIndicator(color:teal)):IndexedStack(index:tab,children:[home(),create(),scriptPage(),settings()])),
    bottomNavigationBar:NavigationBar(backgroundColor:const Color(0xFF0C1112),indicatorColor:teal.withValues(alpha:.16),selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const[
      NavigationDestination(icon:Icon(Icons.home_outlined),label:'Home'),
      NavigationDestination(icon:Icon(Icons.auto_awesome_outlined),label:'Create'),
      NavigationDestination(icon:Icon(Icons.article_outlined),label:'Script'),
      NavigationDestination(icon:Icon(Icons.settings_outlined),label:'Settings'),
    ]),
  );
  Widget home()=>ListView(padding:const EdgeInsets.all(18),children:[
    Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),gradient:const LinearGradient(colors:[Color(0xFF123A39),Color(0xFF101719)]),border:Border.all(color:teal.withValues(alpha:.2))),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('YOUR DAILY MYSTERY STUDIO',style:TextStyle(color:teal,fontSize:10,letterSpacing:2)),
      SizedBox(height:12),Text('हर दिन एक नया रहस्य.',style:TextStyle(fontSize:27,fontWeight:FontWeight.w800)),
      SizedBox(height:8),Text('मोफत ऑफलाइन विषय आणि हिंदी Script निर्मिती.',style:TextStyle(color:Colors.white70)),
    ])),
    const SizedBox(height:22),const Text('आजचा नवीन विषय',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
    const SizedBox(height:10),Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(topic?.place??'',style:const TextStyle(color:teal)),const SizedBox(height:8),Text(topic?.title??'',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:8),Text(topic?.clue??'',style:const TextStyle(color:Colors.white60)),
    ])),
    const SizedBox(height:12),FilledButton.icon(onPressed:nextTopic,icon:const Icon(Icons.refresh),label:const Text('दुसरा नवीन विषय निवडा')),
    const SizedBox(height:10),FilledButton.icon(onPressed:generating?null:makeVideo,icon:generating?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.movie_creation_outlined),label:Text(generating?'Video तयार होत आहे...':'आजचा Video तयार करा (1080p)')),
    const SizedBox(height:16),info(Icons.history,'Repeat विषय टाळणे','वापरलेले विषय फोनमध्ये सेव्ह राहतात.'),info(Icons.record_voice_over,'Hindi Voice','फोनमध्ये उपलब्ध असलेला TTS आवाज वापरतो.'),info(Icons.cloud_off,'Free Offline Mode','या टप्प्यासाठी API key किंवा paid service लागत नाही.'),Text(status,style:const TextStyle(color:teal,fontSize:12)),
  ]);
  Widget create()=>ListView(padding:const EdgeInsets.all(20),children:[
    const Text('Create Story',style:TextStyle(fontSize:25,fontWeight:FontWeight.w800)),const SizedBox(height:8),const Text('स्वतःचा विषय लिहा आणि हिंदी Script तयार करा.',style:TextStyle(color:Colors.white60)),
    const SizedBox(height:18),TextField(controller:custom,maxLines:3,decoration:InputDecoration(hintText:'हिंदी रहस्यकथेचा विषय लिहा...',filled:true,fillColor:panel,border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide.none))),
    const SizedBox(height:12),FilledButton.icon(onPressed:customScript,icon:const Icon(Icons.auto_awesome),label:const Text('Script तयार करा')),
    const SizedBox(height:22),const Text('Voice style',style:TextStyle(fontWeight:FontWeight.bold)),Wrap(spacing:10,children:[
      ChoiceChip(label:const Text('पुरुष शैली'),selected:voice==0,onSelected:(_)=>setState(()=>voice=0)),ChoiceChip(label:const Text('महिला शैली'),selected:voice==1,onSelected:(_)=>setState(()=>voice=1)),
    ]),
    const SizedBox(height:8),const Text('खरे Hindi voices फोनच्या TTS engine मधून येतात. दोन वेगळे आवाज निवडा आणि Preview करून कोणता पुरुष/महिला आहे ते तपासा; प्रत्येक फोनमध्ये gender माहिती उपलब्ध नसते.',style:TextStyle(color:Colors.white54,fontSize:12)),
    const SizedBox(height:20),info(Icons.high_quality,'1080p MP4 Export','Script आणि फोनचा Hindi TTS आवाज वापरून MP4 तयार करा. व्हिडिओची लांबी Script वर अवलंबून असेल.'),
  ]);
  Widget scriptPage()=>Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(16,12,16,4),child:Row(children:[const Expanded(child:Text('Hindi Script',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800))),IconButton(onPressed:speak,icon:const Icon(Icons.play_circle_fill,color:teal,size:30)),IconButton(onPressed:stop,icon:const Icon(Icons.stop_circle_outlined)),IconButton(onPressed:generating?null:makeVideo,icon:const Icon(Icons.download_for_offline_outlined,color:teal))])),
    Expanded(child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('टीप: ही ऑफलाइन Template Script आहे; ऐतिहासिक/वैज्ञानिक तथ्ये YouTube वर टाकण्यापूर्वी तपासा.',style:TextStyle(color:teal,fontSize:12)),const SizedBox(height:12),SelectableText(script,style:const TextStyle(fontSize:15,height:1.7))]))),
    Padding(padding:const EdgeInsets.all(10),child:Column(children:[if(generating)const LinearProgressIndicator(color:teal),Text(speaking?'निवेदन सुरू आहे...':status,style:const TextStyle(color:teal,fontSize:12))])),
  ]);
  Widget settings()=>ListView(padding:const EdgeInsets.all(20),children:[
    const Text('Settings',style:TextStyle(fontSize:25,fontWeight:FontWeight.w800)),
    SwitchListTile(value:autoDaily,activeColor:teal,title:const Text('दररोज आपोआप व्हिडिओ तयार करा'),subtitle:const Text('App बंद असतानाही Android WorkManager वापरेल. Wi-Fi/Internet आणि Battery पुरेशी असणे आवश्यक.'),onChanged:(v)=>scheduleDaily(v)),
    info(Icons.schedule,'Background वेळापत्रक','साधारण 24 तासांनी. Android वेळ बदलू शकतो; नेमक्या वेळी चालण्याची हमी नाही.'),
    info(Icons.source,'माहितीचे स्रोत','हिंदी Wikipedia संदर्भ; संदर्भ आणि चित्रांचे परवाने Credits.txt मध्ये.'), 
    if(hindiVoices.isEmpty)info(Icons.record_voice_over,'Hindi voices','फोनमध्ये Hindi voice install करा: Android Text-to-Speech settings.'),
    if(hindiVoices.isNotEmpty)voicePicker('पुरुष आवाज निवडा / Preview',maleVoice,true),
    if(hindiVoices.isNotEmpty)voicePicker('महिला आवाज निवडा / Preview',femaleVoice,false),
    info(Icons.music_note,'Background Music','व्हिडिओसाठी App मध्ये तयार केलेला साधा ambient soundtrack.'),info(Icons.palette_outlined,'Theme','Pure Black • Teal'),info(Icons.upload_file_outlined,'YouTube upload','Manual upload — तुझ्या नियंत्रणात.'),info(Icons.history,'Topic history',used.length.toString()+' विषय वापरले गेले.'),Text(status,style:const TextStyle(color:teal,fontSize:12)),
  ]);
  Widget info(IconData icon,String title,String subtitle)=>Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(16)),child:Row(children:[Icon(icon,color:teal),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:4),Text(subtitle,style:const TextStyle(color:Colors.white60,fontSize:12))]))]));
}
