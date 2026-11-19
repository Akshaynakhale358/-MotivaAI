import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'video_maker.dart';

void main() => runApp(const MotivaAI());
const teal = Color(0xFF20D6C2);
const bg = Color(0xFF050708);
const panel = Color(0xFF111719);

class Topic {
  final String id, title, place, clue;
  const Topic(this.id, this.title, this.place, this.clue);
}
const topics = <Topic>[
  Topic('01','भारत की रहस्यमयी कंकाल झील','रूपकुंड, उत्तराखंड','बर्फ में मिले प्राचीन मानव कंकाल'),
  Topic('02','भानगढ़ किले की अनसुलझी कहानी','राजस्थान','खंडहरों से जुड़ी लोककथाएँ'),
  Topic('03','जतिंगा में पक्षियों का रहस्य','असम','पक्षियों का असामान्य व्यवहार'),
  Topic('04','सिंधु घाटी की लिपि का रहस्य','प्राचीन भारत','आज तक पूरी तरह न पढ़े जा सके चिह्न'),
  Topic('05','द्वारका के समुद्र के नीचे के अवशेष','गुजरात','समुद्र में मिले पुरातात्विक संकेत'),
  Topic('06','लोनार झील कैसे बनी?','महाराष्ट्र','उल्कापिंड से बनी मानी जाने वाली झील'),
  Topic('07','कुलधरा गाँव खाली क्यों हुआ?','राजस्थान','एक रात में गाँव छोड़ने की लोककथा'),
  Topic('08','मैग्नेटिक हिल का सच','लद्दाख','आँखों को चढ़ाई पर जाती गाड़ी का भ्रम'),
  Topic('09','अजंता की गुफाओं के रंग','महाराष्ट्र','सदियों बाद भी बची प्राचीन चित्रकारी'),
  Topic('10','कोणार्क मंदिर का वास्तु रहस्य','ओडिशा','पत्थर के रथ जैसी अद्भुत रचना'),
  Topic('11','बरमूडा त्रिकोण का रहस्य','अटलांटिक महासागर','जहाज़ों और विमानों से जुड़ी चर्चाएँ'),
  Topic('12','नाज़्का की विशाल आकृतियाँ','पेरू','रेगिस्तान में बनी विशाल रेखाएँ'),
  Topic('13','स्टोनहेंज किसने बनाया?','इंग्लैंड','प्राचीन पत्थरों का गोलाकार स्मारक'),
  Topic('14','डायटलोव पास की घटना','रूस','बर्फीले पहाड़ों में हुई दुखद घटना'),
  Topic('15','मैरी सेलेस्ट जहाज़ खाली क्यों मिला?','अटलांटिक महासागर','बिना चालक दल के मिला जहाज़'),
  Topic('16','वॉयनिच पांडुलिपि','यूरोप','अज्ञात लिपि में लिखी पुरानी किताब'),
  Topic('17','एंटीकाइथेरा मशीन','ग्रीस','प्राचीन खगोलीय गणना करने वाला यंत्र'),
  Topic('18','ब्लड फॉल्स का लाल पानी','अंटार्कटिका','लाल रंग का बहता नमकीन पानी'),
  Topic('19','मंगल ग्रह का चेहरा','मंगल ग्रह','पहली तस्वीरों में दिखा चेहरा जैसा आकार'),
  Topic('20','वाह! सिग्नल क्या था?','अंतरिक्ष','रेडियो टेलीस्कोप में पकड़ा गया अनोखा संकेत'),
  Topic('21','एलोरा की कैलाश गुफा कैसे तराशी गई?','महाराष्ट्र','एक ही चट्टान को काटकर बना विशाल मंदिर'),
  Topic('22','शनि शिंगणापुर की खुली चौखटों की परंपरा','महाराष्ट्र','बिना दरवाजों वाले घरों की परंपरा और उसका इतिहास'),
  Topic('23','अशोक के स्तंभों का निर्माण रहस्य','भारत','प्राचीन पत्थर के स्तंभों की तकनीक'),
  Topic('24','मेहरानगढ़ किले की लोककथाएँ','जोधपुर','किले से जुड़ी ऐतिहासिक और स्थानीय कहानियाँ'),
  Topic('25','जैसलमेर का भूतिया गाँव कहा जाने वाला कुलधरा','राजस्थान','गाँव खाली होने के पीछे के ऐतिहासिक सवाल'),
  Topic('26','सेंटिनल द्वीप इतना अलग क्यों है?','अंडमान','द्वीप की भौगोलिक अलगाव और सुरक्षा'),
  Topic('27','निधिवन की रात की मान्यता','वृंदावन','स्थानीय धार्मिक मान्यता और उसके प्रमाण'),
  Topic('28','रामसेतु की भूवैज्ञानिक कहानी','भारत और श्रीलंका','समुद्र में दिखाई देने वाली प्राकृतिक संरचना'),
  Topic('29','शिलांग की जीवित जड़ पुलों की कला','मेघालय','पेड़ों की जड़ों से बने पुल'),
  Topic('30','माचू पिच्चू कैसे बनाया गया?','पेरू','पहाड़ों पर बने इंका नगर की इंजीनियरिंग'),
  Topic('31','ईस्टर द्वीप के मोआई सिर कैसे बने?','चिली','विशाल पत्थर की मूर्तियों का निर्माण'),
  Topic('32','पूमापुंकु के पत्थरों की सटीक कटाई','बोलीविया','प्राचीन पत्थर निर्माण की तकनीक'),
  Topic('33','नॉर्स जहाज़ों की समुद्री यात्रा','स्कैंडिनेविया','वाइकिंग नावों की तकनीक और खोजें'),
  Topic('34','टेराकोटा सेना का रहस्य','चीन','सम्राट की कब्र के पास मिली हजारों मूर्तियाँ'),
  Topic('35','पेट्रा का गुलाबी शहर','जॉर्डन','चट्टानों को काटकर बनाए गए प्राचीन भवन'),
  Topic('36','गोबेक्ली तेपे किसने बनाया?','तुर्किये','अत्यंत प्राचीन धार्मिक परिसर की खोज'),
  Topic('37','अंगकोर वाट का जल प्रबंधन','कंबोडिया','प्राचीन शहर की नहरों और जलाशयों की व्यवस्था'),
  Topic('38','रोमन कंक्रीट आज भी क्यों टिकता है?','प्राचीन रोम','प्राचीन निर्माण सामग्री पर आधुनिक शोध'),
  Topic('39','समुद्र के नीचे डूबे प्राचीन शहर','भूमध्य सागर','समुद्र स्तर और पुरातात्विक खोजें'),
  Topic('40','सहारा की आँख जैसी संरचना','मॉरिटानिया','रिचैट संरचना की भूवैज्ञानिक व्याख्या'),
];
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
  bool ready=false,speaking=false,generating=false;
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
    if(p.getString('topic_day')==day(DateTime.now())){
      final id=p.getString('topic_id');
      for(final t in topics){if(t.id==id) topic=t;}
      script=p.getString('daily_script')??'';
    }
    if(topic==null) await nextTopic();
    if(mounted)setState(()=>ready=true);
  }
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
      await VideoMaker.create(title:topic!.title,script:script,tts:tts,voiceStyle:voice,onStatus:(s){if(mounted)setState(()=>status=s);});
      if(mounted)msg('Video Downloads/MotivaAI मध्ये सेव्ह झाला.');
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
    await tts.stop();await tts.setLanguage('hi-IN');await tts.setSpeechRate(.45);await tts.setPitch(voice == 0 ? 0.82 : 1.18);
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
    const SizedBox(height:8),const Text('टीप: खरा पुरुष/महिला आवाज फोनमध्ये install असलेल्या Hindi voices वर अवलंबून आहे. Pitch बदलल्याने प्रत्येक फोनवर वेगळा gender voice मिळेलच असे नाही.',style:TextStyle(color:Colors.white54,fontSize:12)),
    const SizedBox(height:20),info(Icons.high_quality,'Video Export पुढील टप्प्यात','16:9 • 1080p • 5–10 मिनिटे हे लक्ष्य आहे.'),
  ]);
  Widget scriptPage()=>Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(16,12,16,4),child:Row(children:[const Expanded(child:Text('Hindi Script',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800))),IconButton(onPressed:speak,icon:const Icon(Icons.play_circle_fill,color:teal,size:30)),IconButton(onPressed:stop,icon:const Icon(Icons.stop_circle_outlined)),IconButton(onPressed:generating?null:makeVideo,icon:const Icon(Icons.download_for_offline_outlined,color:teal))])),
    Expanded(child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:SelectableText(script,style:const TextStyle(fontSize:15,height:1.7)))),
    Padding(padding:const EdgeInsets.all(10),child:Column(children:[if(generating)const LinearProgressIndicator(color:teal),Text(speaking?'निवेदन सुरू आहे...':status,style:const TextStyle(color:teal,fontSize:12))])),
  ]);
  Widget settings()=>ListView(padding:const EdgeInsets.all(20),children:[
    const Text('Settings',style:TextStyle(fontSize:25,fontWeight:FontWeight.w800)),info(Icons.palette_outlined,'Theme','Pure Black • Teal'),info(Icons.video_settings_outlined,'Video quality','1080p Full HD हे पुढील export टप्प्याचे लक्ष्य.'),info(Icons.upload_file_outlined,'YouTube upload','Manual upload — तुझ्या नियंत्रणात.'),info(Icons.history,'Topic history',used.length.toString()+' विषय वापरले गेले.'),
  ]);
  Widget info(IconData icon,String title,String subtitle)=>Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(16)),child:Row(children:[Icon(icon,color:teal),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:4),Text(subtitle,style:const TextStyle(color:Colors.white60,fontSize:12))]))]));
}
