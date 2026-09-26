import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'app_services.dart';
import 'ui/chat_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.init();

  // 当前 IANA 时区，写入消息的 sent_tz（schema §2.1）。
  var tz = 'Asia/Shanghai';
  try {
    tz = (await FlutterTimezone.getLocalTimezone()).identifier;
  } catch (_) {
    // 取不到时区时用默认值；首次引导（M4）会让用户确认。
  }

  runApp(App(services: services, tz: tz));
}

class App extends StatelessWidget {
  const App({super.key, required this.services, required this.tz});

  final AppServices services;
  final String tz;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '长寿记',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal, brightness: Brightness.dark),
      ),
      home: ChatPage(services: services, tz: tz),
    );
  }
}
