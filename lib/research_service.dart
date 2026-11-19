import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'topic_library.dart';

class ResearchSource {
  final String title, url, extract;
  const ResearchSource(this.title,this.url,this.extract);
}

class ResearchImage {
  final String path, credit, license, sourceUrl;
  const ResearchImage(this.path,this.credit,this.license,this.sourceUrl);
}

class ResearchBundle {
  final String script, credits;
  final List<ResearchImage> images;
  final List<ResearchSource> sources;
  const ResearchBundle({required this.script,required this.credits,required this.images,required this.sources});
}

class ResearchService {
  static final http.Client _client=http.Client();
  static String _clean(String s)=>s.replaceAll(RegExp(r'\[[0-9]+\]'),' ').replaceAll(RegExp(r'\s+'),' ').trim();
  static int _words(String s)=>s.split(RegExp(r'\s+')).where((w)=>w.isNotEmpty).length;

  static Future<List<ResearchSource>> _searchHindi(String query) async {
    final uri=Uri.https('hi.wikipedia.org','/w/api.php',{
      'action':'query','generator':'search','gsrsearch':query,'gsrnamespace':'0',
      'gsrlimit':'6','prop':'extracts|info','explaintext':'1','exchars':'6500',
      'inprop':'url','format':'json','formatversion':'2'
    });
    final response=await _client.get(uri,headers:{'User-Agent':'MotivaAI/1.0 (Android app; source research)'})
      .timeout(const Duration(seconds:25));
    if(response.statusCode!=200) throw Exception('Hindi Wikipedia शोध सेवा सध्या उपलब्ध नाही.');
    final data=jsonDecode(utf8.decode(response.bodyBytes)) as Map<String,dynamic>;
    final queryData=data['query'] as Map<String,dynamic>?;
    final pages=(queryData?['pages'] as List<dynamic>?)??[];
    final result=<ResearchSource>[];
    for(final raw in pages) {
      final p=raw as Map<String,dynamic>;
      final title=(p['title']??'').toString();
      final extract=_clean((p['extract']??'').toString());
      final url=(p['fullurl']??'https://hi.wikipedia.org/wiki/${Uri.encodeComponent(title.replaceAll(' ','_'))}').toString();
      if(extract.length>250) result.add(ResearchSource(title,url,extract));
    }
    return result;
  }

  static Future<List<ResearchImage>> _images(String query) async {
    final uri=Uri.https('commons.wikimedia.org','/w/api.php',{
      'action':'query','generator':'search','gsrsearch':'filetype:bitmap $query',
      'gsrnamespace':'6','gsrlimit':'12','prop':'imageinfo',
      'iiprop':'url|extmetadata','iiurlwidth':'1600','format':'json','formatversion':'2'
    });
    final response=await _client.get(uri,headers:{'User-Agent':'MotivaAI/1.0 (Android app; Wikimedia Commons image attribution)'})
      .timeout(const Duration(seconds:30));
    if(response.statusCode!=200) return [];
    final data=jsonDecode(utf8.decode(response.bodyBytes)) as Map<String,dynamic>;
    final pages=((data['query'] as Map<String,dynamic>?)?['pages'] as List<dynamic>?)??[];
    final dir=await getApplicationDocumentsDirectory();
    final folder=Directory('${dir.path}/motiva_images');
    if(!await folder.exists()) await folder.create(recursive:true);
    final result=<ResearchImage>[];
    for(final raw in pages) {
      if(result.length>=7) break;
      final p=raw as Map<String,dynamic>;
      final infos=p['imageinfo'] as List<dynamic>?;
      if(infos==null||infos.isEmpty) continue;
      final info=infos.first as Map<String,dynamic>;
      final meta=(info['extmetadata'] as Map<String,dynamic>?)??{};
      String metaValue(String key)=>(meta[key] as Map<String,dynamic>?)?['value']?.toString()??'';
      final license=metaValue('LicenseShortName').replaceAll(RegExp(r'<[^>]*>'),'').trim();
      final allowed=license.toLowerCase().contains('public domain')||
        license.toLowerCase().contains('cc0')||
        license.toLowerCase().contains('cc by')||
        license.toLowerCase().contains('cc-by');
      if(!allowed) continue;
      final imageUrl=(info['thumburl']??info['url']??'').toString();
      if(!imageUrl.startsWith('https://')) continue;
      try {
        final bytes=await _client.get(Uri.parse(imageUrl)).timeout(const Duration(seconds:25));
        if(bytes.statusCode!=200||bytes.bodyBytes.length<8000) continue;
        final file=File('${folder.path}/motiva_${result.length}.jpg');
        await file.writeAsBytes(bytes.bodyBytes,flush:true);
        final artist=metaValue('Artist').replaceAll(RegExp(r'<[^>]*>'),'').trim();
        final pageUrl=(p['title']??'').toString();
        final source='https://commons.wikimedia.org/wiki/${Uri.encodeComponent(pageUrl.replaceAll(' ','_'))}';
        result.add(ResearchImage(file.path,'${p['title']} — ${artist.isEmpty?'Author not stated':artist}',license,source));
      } catch (_) {}
    }
    return result;
  }

  static Future<ResearchBundle> research(Topic topic) async {
    final queries=<String>[topic.title,topic.place,topic.clue];
    final sources=<ResearchSource>[];
    final seen=<String>{};
    for(final q in queries) {
      final found=await _searchHindi(q);
      for(final s in found) {
        final key=s.title.toLowerCase();
        if(seen.add(key)) sources.add(s);
        if(sources.length>=9) break;
      }
      if(sources.length>=9) break;
    }
    if(sources.length<2) throw Exception('या विषयासाठी किमान दोन हिंदी संदर्भ सापडले नाहीत. वेगळा विषय निवडा.');
    final relevant=sources.take(6).toList();
    final sections=<String>[];
    var total=0;
    for(final s in relevant) {
      final words=s.extract.split(RegExp(r'(?<=[।.!?])\s+')).where((x)=>x.trim().length>25).toList();
      final selected=<String>[];
      var count=0;
      for(final sentence in words) {
        final n=_words(sentence);
        if(count+n>190) break;
        selected.add(sentence.trim());
        count+=n;
      }
      if(count>=45) {
        sections.add('### ${s.title}\n${selected.join(' ')}');
        total+=count;
      }
    }
    if(total<560) throw Exception('या विषयावर पुरेशी तपासता येणारी हिंदी माहिती मिळाली नाही. चुकीची किंवा बनावट माहिती न घालता हा व्हिडिओ थांबवला आहे.');
    final intro='नमस्कार दोस्तों। आज हम एक ऐसे विषय की पड़ताल करेंगे जिसके बारे में कई सवाल पूछे जाते हैं: ${topic.title}। इस वीडियो में हम केवल उपलब्ध लिखित संदर्भों में दर्ज जानकारी पर ध्यान देंगे। लोककथाओं, अनुमान और प्रमाणित जानकारी को अलग-अलग समझेंगे।';
    final outro='इस विषय पर उपलब्ध जानकारी को समझने के बाद एक बात साफ है: किसी रहस्य को सुलझाने के लिए कहानी से ज्यादा जरूरी प्रमाण होते हैं। जहाँ स्रोतों में मतभेद या जानकारी की कमी है, वहाँ हमने उसे निश्चित सच बताने के बजाय खुला सवाल माना है। वीडियो में उपयोग किए गए संदर्भ और चित्रों के लाइसेंस की जानकारी साथ में दी गई है।';
    final script='$intro\n\n${sections.join('\n\n')}\n\n$outro';
    final wordCount=_words(script);
    if(wordCount<620) throw Exception('संदर्भों से केवल ${wordCount} शब्द मिले। 5–10 मिनट की तथ्य-आधारित Script के लिए पर्याप्त स्रोत नहीं हैं; दूसरा विषय चुनें।');
    final images=await _images('${topic.title} ${topic.place}');
    if(images.length<3) throw Exception('या विषयासाठी वापरता येतील असे किमान तीन मुक्त परवान्याचे चित्र सापडले नाहीत. कॉपीराइटचा धोका टाळण्यासाठी व्हिडिओ तयार केला नाही.');
    final sourceLines=relevant.map((s)=>'स्रोत: ${s.title}\n${s.url}').join('\n\n');
    final imageLines=images.map((i)=>'चित्र: ${i.credit}\nपरवाना: ${i.license}\nस्रोत: ${i.sourceUrl}').join('\n\n');
    final credits='MotivaAI — स्रोत और मीडिया श्रेय\n\nयह Script उपलब्ध हिंदी Wikipedia लेखों के आधार पर तैयार किया गया शोध-आधारित मसौदा है। Wikipedia के लेख CC BY-SA लाइसेंस के अंतर्गत हैं; उपयोग से पहले स्रोत पृष्ठों की वर्तमान लाइसेंस शर्तें जाँचें।\n\n$sourceLines\n\nWikimedia Commons चित्र श्रेय\n\n$imageLines\n';
    return ResearchBundle(script:script,credits:credits,images:images,sources:relevant);
  }
}
