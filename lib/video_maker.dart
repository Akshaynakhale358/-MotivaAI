import 'dart:io';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit_config.dart';
import 'package:file_saver/file_saver.dart';

class VideoMaker {
  static String _quote(String value) => "'${value.replaceAll("'", "'\\''")}'";

  static String _stamp(double seconds) {
    final ms=(seconds*1000).round();
    final h=ms~/3600000, m=(ms%3600000)~/60000, s=(ms%60000)~/1000, milli=ms%1000;
    String two(int n)=>n.toString().padLeft(2,'0');
    return '${two(h)}:${two(m)}:${two(s)},${milli.toString().padLeft(3,'0')}';
  }

  static List<String> _splitForTts(String script) {
    final sentences=script.split(RegExp(r'(?<=[।.!?])\\s+'));
    final chunks=<String>[];
    var current=StringBuffer();
    for(final sentence in sentences) {
      if(sentence.length>2600) {
        for(final word in sentence.split(RegExp(r'\\s+'))) {
          if(current.length+word.length+1>2600 && current.isNotEmpty) { chunks.add(current.toString().trim()); current=StringBuffer(); }
          current.write('$word ');
        }
      } else {
        if(current.length+sentence.length+2>2600 && current.isNotEmpty) { chunks.add(current.toString().trim()); current=StringBuffer(); }
        current.write('$sentence ');
      }
    }
    if(current.isNotEmpty) chunks.add(current.toString().trim());
    return chunks.where((x)=>x.isNotEmpty).toList();
  }

  static String _makeSrt(String script) {
    final clean=script.replaceAll(RegExp(r'[#*_]+'), '').replaceAll('\r','');
    final words=clean.split(RegExp(r'\s+')).where((w)=>w.isNotEmpty).toList();
    final chunks=<String>[];
    for(var i=0;i<words.length;i+=9) chunks.add(words.skip(i).take(9).join(' '));
    final buffer=StringBuffer();
    var index=1, start=0.0;
    for(final chunk in chunks) {
      final duration=(chunk.split(' ').length/1.8).clamp(3.0,7.0).toDouble();
      buffer.writeln(index++);
      buffer.writeln('${_stamp(start)} --> ${_stamp(start+duration)}');
      buffer.writeln(chunk);
      buffer.writeln();
      start+=duration;
    }
    return buffer.toString();
  }

  static Future<String> create({
    required String title,
    required String script,
    required FlutterTts tts,
    required int voiceStyle,
    Map<String,String>? voice,
    required List<String> imagePaths,
    required String creditsText,
    required void Function(String) onStatus,
  }) async {
    if(imagePaths.length<3) throw Exception('Video साठी किमान तीन चित्रे आवश्यक आहेत.');
    final dir=await getApplicationDocumentsDirectory();
    final work=Directory('${dir.path}/motiva_work');
    if(!await work.exists()) await work.create(recursive:true);
    final safe=title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_').replaceAll(RegExp(r'_+'),'_');
    final audio=File('${work.path}/narration.wav');
    final srt=File('${work.path}/captions.srt');
    final titleFile=File('${work.path}/title.txt');
    final credits=File('${work.path}/MotivaAI_${safe}_credits.txt');
    final output=File('${work.path}/MotivaAI_${safe}_${DateTime.now().millisecondsSinceEpoch}.mp4');
    await tts.stop();
    await tts.setLanguage('hi-IN');
    if(voice!=null && voice.isNotEmpty) await tts.setVoice(voice);
    await tts.setSpeechRate(.43);
    await tts.setPitch(voiceStyle==0 ? .92 : 1.08);
    await tts.awaitSynthCompletion(true);
    onStatus('Hindi निवेदन तयार होत आहे...');
    final speechChunks=_splitForTts(script);
    if(speechChunks.isEmpty) throw Exception('निवेदनासाठी Script रिकामी आहे.');
    final audioParts=<File>[];
    for(var i=0;i<speechChunks.length;i++) {
      onStatus('Hindi voice तयार होत आहे... ${i+1}/${speechChunks.length}');
      final part=File('${work.path}/voice_${i.toString().padLeft(3,'0')}.wav');
      final synth=await tts.synthesizeToFile(speechChunks[i],part.path,true);
      if(synth!=1 || !await part.exists() || await part.length()<1000) {
        throw Exception('Hindi TTS voice chunk ${i+1} तयार करू शकला नाही. फोनमध्ये Hindi voice pack install करा.');
      }
      audioParts.add(part);
    }
    final concatList=File('${work.path}/audio_parts.txt');
    await concatList.writeAsString(audioParts.map((f)=>"file '${f.path}'").join('\\n'),flush:true);
    final audioJoin=await FFmpegKit.execute('-y -f concat -safe 0 -i ${_quote(concatList.path)} -c:a pcm_s16le ${_quote(audio.path)}');
    if(!ReturnCode.isSuccess(await audioJoin.getReturnCode()) || !await audio.exists() || await audio.length()<1000) {
      throw Exception('Hindi voice चे audio भाग जोडता आले नाहीत.');
    }
    await srt.writeAsString(_makeSrt(script),flush:true);
    await titleFile.writeAsString(title,flush:true);
    await credits.writeAsString(creditsText,flush:true);
    onStatus('विषयानुसार चित्रे, subtitles आणि background ambient music जोडत आहे...');
    final words=script.split(RegExp(r'\s+')).where((w)=>w.isNotEmpty).length;
    final targetSeconds=(words/1.8).clamp(300,600).toDouble()+35;
    final perImage=targetSeconds/imagePaths.length;
    final args=StringBuffer('-y ');
    for(final path in imagePaths) {
      args.write('-loop 1 -t ${perImage.toStringAsFixed(2)} -i ${_quote(path)} ');
    }
    final narrationIndex=imagePaths.length;
    final musicIndex=narrationIndex+1;
    args.write('-i ${_quote(audio.path)} ');
    args.write('-f lavfi -i "aevalsrc=0.012*sin(2*PI*110*t)+0.008*sin(2*PI*164.81*t)+0.006*sin(2*PI*220*t):s=44100:d=3600" ');
    final filters=<String>[];
    for(var i=0;i<imagePaths.length;i++) {
      filters.add('[$i:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,setsar=1,fps=25,format=yuv420p[v$i]');
    }
    final concatInputs=List.generate(imagePaths.length,(i)=>'[v$i]').join();
    filters.add('$concatInputs concat=n=${imagePaths.length}:v=1:a=0,drawbox=x=0:y=0:w=iw:h=ih:color=0x050B0D@0.24:t=fill,drawbox=x=70:y=70:w=1780:h=940:color=0x071516@0.18:t=6,drawtext=fontfile=/system/fonts/NotoSansDevanagari-Regular.ttf:textfile=${titleFile.path}:fontcolor=0x20D6C2:fontsize=52:x=(w-text_w)/2:y=90,subtitles=${srt.path}:force_style=FontName=Noto Sans Devanagari\,FontSize=22\,PrimaryColour=&H00FFFFFF\,OutlineColour=&H80000000\,BorderStyle=1\,Outline=2\,Alignment=2\,MarginV=85[vout]');
    filters.add('[$narrationIndex:a]volume=1.0[narr]');
    filters.add('[$musicIndex:a]volume=0.055[music]');
    filters.add('[narr][music]amix=inputs=2:duration=first:dropout_transition=3[aout]');
    args.write('-filter_complex ${_quote(filters.join(';'))} ');
    args.write('-map [vout] -map [aout] -shortest -c:v mpeg4 -q:v 4 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart ${_quote(output.path)}');
    FFmpegKitConfig.setFontDirectoryList(['/system/fonts']);
    final session=await FFmpegKit.execute(args.toString());
    final code=await session.getReturnCode();
    if(!ReturnCode.isSuccess(code) || !await output.exists() || await output.length()<100000) {
      final logItems=await session.getLogs();
      final logs=logItems.map((item)=>item.getMessage()).join('\n');
      throw Exception('Video render अयशस्वी. ${logs.length>900 ? logs.substring(logs.length-900) : logs}');
    }
    onStatus('MP4 आणि संदर्भांची यादी Downloads मध्ये सेव्ह होत आहे...');
    await FileSaver.instance.saveToDownloads(
      name:'MotivaAI_${safe}_${DateTime.now().millisecondsSinceEpoch}',
      filePath:output.path,
      fileExtension:'mp4',
      mimeType:MimeType.mp4,
      subfolder:'MotivaAI',
    );
    await FileSaver.instance.saveToDownloads(
      name:'MotivaAI_${safe}_credits',
      file:credits,
      fileExtension:'txt',
      mimeType:MimeType.other,
      subfolder:'MotivaAI',
    );
    onStatus('Video आणि त्याचे स्रोत/चित्र credits Downloads/MotivaAI मध्ये सेव्ह झाले.');
    return output.path;
  }
}
