import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import 'package:file_saver/file_saver.dart';

class VideoMaker {
  static String _quote(String value) => "'${value.replaceAll("'", "'\\''")}'";

  static String _stamp(double seconds) {
    final ms=(seconds*1000).round();
    final h=ms~/3600000, m=(ms%3600000)~/60000, s=(ms%60000)~/1000, milli=ms%1000;
    String two(int n)=>n.toString().padLeft(2,'0');
    return '${two(h)}:${two(m)}:${two(s)},${milli.toString().padLeft(3,'0')}';
  }

  static String _makeSrt(String script) {
    final clean=script.replaceAll(RegExp(r'[#*_]+'), '').replaceAll('\r','');
    final words=clean.split(RegExp(r'\s+')).where((w)=>w.isNotEmpty).toList();
    final chunks=<String>[];
    for(var i=0;i<words.length;i+=9) {
      chunks.add(words.skip(i).take(9).join(' '));
    }
    final buffer=StringBuffer();
    var index=1;
    var start=0.0;
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
    required void Function(String) onStatus,
  }) async {
    final dir=await getApplicationDocumentsDirectory();
    final work=Directory('${dir.path}/motiva_work');
    if(!await work.exists()) await work.create(recursive:true);
    final safe=title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_').replaceAll(RegExp(r'_+'),'_');
    final audio=File('${work.path}/narration.wav');
    final srt=File('${work.path}/captions.srt');
    final titleFile=File('${work.path}/title.txt');
    final output=File('${work.path}/MotivaAI_${safe}_${DateTime.now().millisecondsSinceEpoch}.mp4');
    await tts.stop();
    await tts.setLanguage('hi-IN');
    await tts.setSpeechRate(.43);
    await tts.setPitch(voiceStyle==0 ? .92 : 1.08);
    await tts.awaitSynthCompletion(true);
    onStatus('Hindi voice तयार होत आहे...');
    final synth=await tts.synthesizeToFile(script,audio.path,true);
    if(synth!=1 || !await audio.exists() || await audio.length()<1000) {
      throw Exception('फोनचा Hindi TTS आवाज audio file तयार करू शकला नाही. Settings मध्ये Hindi voice install करून पुन्हा प्रयत्न करा.');
    }
    await srt.writeAsString(_makeSrt(script),flush:true);
    await titleFile.writeAsString(title,flush:true);
    onStatus('1080p video आणि subtitles तयार होत आहेत...');
    final font='/system/fonts/NotoSansDevanagari-Regular.ttf';
    final vf="drawbox=x=55:y=65:w=1810:h=950:color=0x0B2224@0.78:t=fill,drawbox=x=80:y=90:w=1760:h=5:color=0x20D6C2@0.9:t=fill,drawtext=fontfile=$font:textfile=${titleFile.path}:fontcolor=0x20D6C2:fontsize=58:x=(w-text_w)/2:y=150,subtitles=${srt.path}";
    final command="-y -f lavfi -i color=c=0x050B0D:s=1920x1080:r=25 -i ${_quote(audio.path)} -vf ${_quote(vf)} -shortest -c:v mpeg4 -q:v 4 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart ${_quote(output.path)}";
    final session=await FFmpegKit.execute(command);
    final code=await session.getReturnCode();
    if(!ReturnCode.isSuccess(code) || !await output.exists() || await output.length()<100000) {
      final logs=await session.getLogsAsString();
      throw Exception('Video render अयशस्वी. ${logs.length>900 ? logs.substring(logs.length-900) : logs}');
    }
    onStatus('Video Downloads मध्ये save होत आहे...');
    await FileSaver.instance.saveToDownloads(
      name:'MotivaAI_${safe}_${DateTime.now().millisecondsSinceEpoch}',
      filePath:output.path,
      fileExtension:'mp4',
      mimeType:MimeType.mp4,
      subfolder:'MotivaAI',
    );
    onStatus('Video फोनच्या Downloads/MotivaAI फोल्डरमध्ये सेव्ह झाला.');
    return output.path;
  }
}
