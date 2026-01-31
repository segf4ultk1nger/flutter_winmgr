import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_winmgr/window_manager_plus.dart';
import 'package:flutter_winmgr_example/pages/home.dart';
import 'package:flutter_winmgr_example/utils/config.dart';

void main(List<String> args) async {
  if (kDebugMode) {
    print(args);
  }

  WidgetsFlutterBinding.ensureInitialized();

  final windowId = args.isEmpty ? 0 : int.tryParse(args[0]) ?? 0;
  await WindowManagerPlus.ensureInitialized(windowId);

  WindowOptions windowOptions = WindowOptions(
    size: const Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
    title: 'Window ID ${WindowManagerPlus.current.id}',
  );
  WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
    await WindowManagerPlus.current.show();
    await WindowManagerPlus.current.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    sharedConfigManager.addListener(_configListen);
    super.initState();
  }

  @override
  void dispose() {
    sharedConfigManager.removeListener(_configListen);
    super.dispose();
  }

  void _configListen() {
    _themeMode = sharedConfig.themeMode;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final virtualWindowFrameBuilder = VirtualWindowFrameInit();
    final botToastBuilder = BotToastInit();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      builder: (context, child) {
        child = virtualWindowFrameBuilder(context, child);
        child = botToastBuilder(context, child);
        return child;
      },
      navigatorObservers: [BotToastNavigatorObserver()],
      home: const HomePage(),
    );
  }
}
