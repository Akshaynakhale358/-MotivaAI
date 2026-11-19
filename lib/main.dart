import 'package:flutter/material.dart';

void main() => runApp(const MotivaAIApp());

const teal = Color(0xFF20D6C2);
const pageBg = Color(0xFF050708);
const panel = Color(0xFF111719);

class MotivaAIApp extends StatelessWidget {
  const MotivaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MotivaAI',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: pageBg,
        colorScheme: const ColorScheme.dark(primary: teal, surface: panel),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selected = 0;
  String voice = 'पुरुष आवाज';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: pageBg,
        titleSpacing: 20,
        title: const Row(children: [
          Icon(Icons.visibility_outlined, color: teal, size: 27),
          SizedBox(width: 10),
          Text('MotivaAI', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .3)),
        ]),
        actions: const [Padding(padding: EdgeInsets.only(right: 18), child: Icon(Icons.account_circle_outlined, color: teal, size: 27))],
      ),
      body: SafeArea(
        child: IndexedStack(index: selected, children: [
          _home(),
          _create(),
          _videos(),
          _settings(),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0C1112),
        indicatorColor: teal.withValues(alpha: .16),
        selectedIndex: selected,
        onDestinationSelected: (v) => setState(() => selected = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: teal), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.movie_creation_outlined), selectedIcon: Icon(Icons.movie_creation, color: teal), label: 'Create'),
          NavigationDestination(icon: Icon(Icons.video_library_outlined), selectedIcon: Icon(Icons.video_library, color: teal), label: 'My Videos'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: teal), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _home() => ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 28), children: [
    Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF123A39), Color(0xFF101719), Color(0xFF111719)]),
        border: Border.all(color: teal.withValues(alpha: .22)),
      ),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('YOUR DAILY MYSTERY STUDIO', style: TextStyle(color: teal, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
        SizedBox(height: 13),
        Text('रहस्यों की दुनिया\nअब आपके हाथ में.', style: TextStyle(fontSize: 27, height: 1.25, fontWeight: FontWeight.w800)),
        SizedBox(height: 9),
        Text('Hindi mystery videos बनाएं — script से Full HD export तक.', style: TextStyle(color: Colors.white70, height: 1.5)),
      ]),
    ),
    const SizedBox(height: 22),
    const Text('आजचा व्हिडिओ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    _tile(Icons.auto_awesome, 'नवीन रहस्यकथा तयार करा', '5–10 मिनिटांची हिंदी कथा', () => setState(() => selected = 1)),
    const SizedBox(height: 12),
    const Text('तुमचा व्हिडिओ प्रवास', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _stat('01', 'Daily video')),
      const SizedBox(width: 10),
      Expanded(child: _stat('1080p', 'Full HD')),
      const SizedBox(width: 10),
      Expanded(child: _stat('2', 'AI voices')),
    ]),
    const SizedBox(height: 20),
    const Text('कसे काम करेल?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 10),
    _step('01', 'रहस्य निवडा', 'नवीन विषय किंवा सुचवलेली कथा'),
    _step('02', 'AI व्हिडिओ तयार करेल', 'स्क्रिप्ट, आवाज, दृश्ये आणि subtitles'),
    _step('03', 'Preview आणि Export', 'तपासून फोनमध्ये सेव्ह करा'),
  ]);

  Widget _create() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Create Video', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    const Text('तुमच्या पुढील हिंदी रहस्यकथेची सुरुवात करा.', style: TextStyle(color: Colors.white60)),
    const SizedBox(height: 22),
    _tile(Icons.lightbulb_outline, 'आजचा विषय सुचवा', 'AI कडून नवीन mystery topic', () => _notice('विषय सुचवण्याची सुविधा पुढील टप्प्यात जोडली जाईल.')),
    const SizedBox(height: 18),
    const Text('कथेचा विषय', style: TextStyle(fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    TextField(maxLines: 3, decoration: InputDecoration(hintText: 'उदा. रात्री 12 वाजता दिसणारे रहस्यमय स्टेशन...', filled: true, fillColor: panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
    const SizedBox(height: 18),
    const Text('AI आवाज निवडा', style: TextStyle(fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    Wrap(spacing: 10, children: ['पुरुष आवाज', 'महिला आवाज'].map((v) => ChoiceChip(label: Text(v), selected: voice == v, selectedColor: teal.withValues(alpha: .2), onSelected: (_) => setState(() => voice = v))).toList()),
    const SizedBox(height: 18),
    _tile(Icons.high_quality, '1080p Full HD', 'Landscape YouTube video • 5–10 min', () {}),
    const SizedBox(height: 22),
    FilledButton.icon(onPressed: () => _notice('AI script, voice आणि video generation पुढील टप्प्यात जोडले जातील.'), icon: const Icon(Icons.auto_awesome), label: const Padding(padding: EdgeInsets.all(14), child: Text('व्हिडिओ तयार करा'))),
    const SizedBox(height: 10),
    const Text('टीप: हा पहिला अॅप नमुना आहे. प्रत्यक्ष AI निर्मितीसाठी सुरक्षित backend आणि AI सेवांची जोडणी आवश्यक आहे.', style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5)),
  ]);

  Widget _videos() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('My Videos', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
    const SizedBox(height: 12),
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(20)), child: const Column(children: [
      Icon(Icons.video_library_outlined, color: teal, size: 48),
      SizedBox(height: 12),
      Text('अजून व्हिडिओ नाहीत', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      SizedBox(height: 6),
      Text('तयार केलेले व्हिडिओ येथे दिसतील.', style: TextStyle(color: Colors.white60)),
    ])),
  ]);

  Widget _settings() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Settings', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
    const SizedBox(height: 18),
    _tile(Icons.palette_outlined, 'Theme', 'Pure Black • Teal', () {}),
    _tile(Icons.video_settings_outlined, 'Video quality', '1080p Full HD', () {}),
    _tile(Icons.upload_file_outlined, 'YouTube upload', 'Manual upload — तुमच्या नियंत्रणात', () {}),
    _tile(Icons.info_outline, 'About MotivaAI', 'Hindi Mystery Video Maker', () {}),
  ]);

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap) => Material(
    color: panel, borderRadius: BorderRadius.circular(17),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: teal.withValues(alpha: .12), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: teal)),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ])),
      const Icon(Icons.chevron_right, color: Colors.white38),
    ]))),
  );

  Widget _stat(String value, String label) => Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16)), child: Column(children: [
    Text(value, style: const TextStyle(color: teal, fontSize: 20, fontWeight: FontWeight.w800)),
    const SizedBox(height: 5),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
  ]));

  Widget _step(String number, String title, String subtitle) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
    Text(number, style: const TextStyle(color: teal, fontWeight: FontWeight.w800)),
    const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
    ])),
  ]));

  void _notice(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: const Color(0xFF173C3A)));
}
