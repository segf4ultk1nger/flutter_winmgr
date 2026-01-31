// ignore_for_file: avoid_print

import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:preference_list/preference_list.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:flutter_winmgr/window_manager_plus.dart';
import 'package:flutter_winmgr_example/utils/config.dart';

const _kSizes = [
  Size(400, 400),
  Size(600, 600),
  Size(800, 800),
];

const _kMinSizes = [
  Size(400, 400),
  Size(600, 600),
];

const _kMaxSizes = [
  Size(600, 600),
  Size(800, 800),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

const _kIconTypeDefault = 'default';
const _kIconTypeOriginal = 'original';

class _HomePageState extends State<HomePage> with TrayListener, WindowListener {
  bool _isPreventClose = false;
  Size _size = _kSizes.first;
  Size? _minSize;
  Size? _maxSize;
  bool _isFullScreen = false;
  bool _isResizable = true;
  bool _isMovable = true;
  bool _isMinimizable = true;
  bool _isMaximizable = true;
  bool _isClosable = true;
  bool _isAlwaysOnTop = false;
  bool _isAlwaysOnBottom = false;
  bool _isSkipTaskbar = false;
  double _progress = 0;
  bool _hasShadow = true;
  double _opacity = 1;
  bool _isIgnoreMouseEvents = false;
  String _iconType = _kIconTypeOriginal;
  bool _isVisibleOnAllWorkspaces = false;

  final TextEditingController _methodNameController =
      TextEditingController(text: 'testMethodName');
  final TextEditingController _firstArgController = TextEditingController();

  @override
  void initState() {
    trayManager.addListener(this);
    WindowManagerPlus.current.addListener(this);
    // WindowManagerPlus.addGlobalListener(this);
    _init();
    super.initState();
  }

  @override
  void dispose() {
    _methodNameController.dispose();
    _firstArgController.dispose();
    trayManager.removeListener(this);
    WindowManagerPlus.current.removeListener(this);
    // WindowManagerPlus.removeGlobalListener(this);
    super.dispose();
  }

  Future<void> _init() async {
    await trayManager.setIcon(
      Platform.isWindows
          ? 'images/tray_icon_original.ico'
          : 'images/tray_icon_original.png',
    );
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Show Window',
        ),
        MenuItem(
          key: 'set_ignore_mouse_events',
          label: 'setIgnoreMouseEvents(false)',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit App',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
    setState(() {});
  }

  Future<void> _handleSetIcon(String iconType) async {
    _iconType = iconType;
    String iconPath =
        Platform.isWindows ? 'images/tray_icon.ico' : 'images/tray_icon.png';

    if (_iconType == 'original') {
      iconPath = Platform.isWindows
          ? 'images/tray_icon_original.ico'
          : 'images/tray_icon_original.png';
    }

    await WindowManagerPlus.current.setIcon(iconPath);
  }

  Widget _buildBody(BuildContext context) {
    return PreferenceList(
      children: <Widget>[
        PreferenceListSection(
          children: [
            PreferenceListItem(
              title: const Text('ThemeMode'),
              detailText: Text('${sharedConfig.themeMode}'),
              onTap: () async {
                ThemeMode newThemeMode =
                    sharedConfig.themeMode == ThemeMode.light
                        ? ThemeMode.dark
                        : ThemeMode.light;

                await sharedConfigManager.setThemeMode(newThemeMode);
                await WindowManagerPlus.current.setBrightness(
                  newThemeMode == ThemeMode.light
                      ? Brightness.light
                      : Brightness.dark,
                );
                setState(() {});
              },
            ),
          ],
        ),
        PreferenceListSection(
          title: const Text('METHODS'),
          children: [
            PreferenceListItem(
              title: const Text('createWindow'),
              onTap: () async {
                final newWindow = await WindowManagerPlus.createWindow(
                    ['test args 1', 'test args 2']);
                BotToast.showText(text: 'New Created Window: $newWindow');
              },
            ),
            PreferenceListItem(
              title: const Text('getAllWindowManagerIds'),
              onTap: () async {
                final windowManagerIds =
                    await WindowManagerPlus.getAllWindowManagerIds();
                BotToast.showText(
                    text: 'WindowManager ID List: $windowManagerIds');
              },
            ),
            PreferenceListItem(
              title: const Text('invokeMethodToWindow'),
              onTap: () async {
                final sortedWindowManagerIds =
                    (await WindowManagerPlus.getAllWindowManagerIds())
                        .where((wId) => wId != WindowManagerPlus.current.id)
                        .toList();
                sortedWindowManagerIds.sort();
                int? selectedWindowTargetId = await showDialog(
                  context: context,
                  builder: (_) {
                    return AlertDialog(
                      title: const Text(
                          'Select the Target Window to invoke the method'),
                      content: SizedBox(
                        width: 300,
                        height: 300,
                        child: ListView(
                          children: [
                            TextField(
                              controller: _methodNameController,
                              decoration: const InputDecoration(
                                labelText: 'Method name to be invoked',
                              ),
                            ),
                            TextField(
                              controller: _firstArgController,
                              decoration: const InputDecoration(
                                labelText: 'First argument to be passed',
                              ),
                            ),
                            for (var id in sortedWindowManagerIds)
                              ListTile(
                                title: Text('WindowManager ID: $id'),
                                onTap: () {
                                  Navigator.of(context).pop(id);
                                },
                              ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );

                if (selectedWindowTargetId != null) {
                  final response = await WindowManagerPlus.current
                      .invokeMethodToWindow(
                          selectedWindowTargetId,
                          _methodNameController.text,
                          _firstArgController.text.trim().isNotEmpty
                              ? [_firstArgController.text.trim()]
                              : null);
                  BotToast.showText(
                      text: 'Response from $selectedWindowTargetId: $response');
                }
              },
            ),
            PreferenceListItem(
              title: const Text('setAsFrameless'),
              onTap: () async {
                await WindowManagerPlus.current.setAsFrameless();
              },
            ),
            PreferenceListItem(
              title: const Text('close'),
              onTap: () async {
                await WindowManagerPlus.current.close();
                await Future.delayed(const Duration(seconds: 2));
                await WindowManagerPlus.current.show();
              },
            ),
            PreferenceListSwitchItem(
              title: const Text('isPreventClose / setPreventClose'),
              onTap: () async {
                _isPreventClose =
                    await WindowManagerPlus.current.isPreventClose();
                BotToast.showText(text: 'isPreventClose: $_isPreventClose');
              },
              value: _isPreventClose,
              onChanged: (newValue) async {
                _isPreventClose = newValue;
                await WindowManagerPlus.current
                    .setPreventClose(_isPreventClose);
                setState(() {});
              },
            ),
            PreferenceListItem(
              title: const Text('focus / blur'),
              onTap: () async {
                await WindowManagerPlus.current.blur();
                await Future.delayed(const Duration(seconds: 2));
                print(
                    'isFocused: ${await WindowManagerPlus.current.isFocused()}');
                await Future.delayed(const Duration(seconds: 2));
                await WindowManagerPlus.current.focus();
                await Future.delayed(const Duration(seconds: 2));
                print(
                    'isFocused: ${await WindowManagerPlus.current.isFocused()}');
              },
            ),
            PreferenceListItem(
              title: const Text('show / hide'),
              onTap: () async {
                await WindowManagerPlus.current.hide();
                await Future.delayed(const Duration(seconds: 2));
                await WindowManagerPlus.current.show();
                await WindowManagerPlus.current.focus();
              },
            ),
            PreferenceListItem(
              title: const Text('isVisible'),
              onTap: () async {
                bool isVisible = await WindowManagerPlus.current.isVisible();
                BotToast.showText(
                  text: 'isVisible: $isVisible',
                );

                await Future.delayed(const Duration(seconds: 2));
                WindowManagerPlus.current.hide();
                isVisible = await WindowManagerPlus.current.isVisible();
                print('isVisible: $isVisible');
                await Future.delayed(const Duration(seconds: 2));
                WindowManagerPlus.current.show();
              },
            ),
            PreferenceListItem(
              title: const Text('isMaximized'),
              onTap: () async {
                bool isMaximized =
                    await WindowManagerPlus.current.isMaximized();
                BotToast.showText(
                  text: 'isMaximized: $isMaximized',
                );
              },
            ),
            PreferenceListItem(
              title: const Text('maximize / unmaximize'),
              onTap: () async {
                WindowManagerPlus.current.maximize();
                await Future.delayed(const Duration(seconds: 2));
                WindowManagerPlus.current.unmaximize();
              },
            ),
            PreferenceListItem(
              title: const Text('isMinimized'),
              onTap: () async {
                bool isMinimized =
                    await WindowManagerPlus.current.isMinimized();
                BotToast.showText(
                  text: 'isMinimized: $isMinimized',
                );

                await Future.delayed(const Duration(seconds: 2));
                WindowManagerPlus.current.minimize();
                await Future.delayed(const Duration(seconds: 2));
                isMinimized = await WindowManagerPlus.current.isMinimized();
                print('isMinimized: $isMinimized');
                WindowManagerPlus.current.restore();
              },
            ),
            PreferenceListItem(
              title: const Text('minimize / restore'),
              onTap: () async {
                WindowManagerPlus.current.minimize();
                await Future.delayed(const Duration(seconds: 2));
                WindowManagerPlus.current.restore();
              },
            ),
            PreferenceListItem(
              title: const Text('dock / undock'),
              onTap: () async {
                DockSide? isDocked = await WindowManagerPlus.current.isDocked();
                BotToast.showText(text: 'isDocked: $isDocked');
              },
              accessoryView: Row(
                children: [
                  CupertinoButton(
                    child: const Text('dock left'),
                    onPressed: () async {
                      WindowManagerPlus.current
                          .dock(side: DockSide.left, width: 500);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('dock right'),
                    onPressed: () async {
                      WindowManagerPlus.current
                          .dock(side: DockSide.right, width: 500);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('undock'),
                    onPressed: () async {
                      WindowManagerPlus.current.undock();
                    },
                  ),
                ],
              ),
            ),
            PreferenceListSwitchItem(
              title: const Text('isFullScreen / setFullScreen'),
              onTap: () async {
                bool isFullScreen =
                    await WindowManagerPlus.current.isFullScreen();
                BotToast.showText(text: 'isFullScreen: $isFullScreen');
              },
              value: _isFullScreen,
              onChanged: (newValue) {
                _isFullScreen = newValue;
                WindowManagerPlus.current.setFullScreen(_isFullScreen);
                setState(() {});
              },
            ),
            PreferenceListItem(
              title: const Text('setAspectRatio'),
              accessoryView: Row(
                children: [
                  CupertinoButton(
                    child: const Text('reset'),
                    onPressed: () async {
                      WindowManagerPlus.current.setAspectRatio(0);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('1:1'),
                    onPressed: () async {
                      WindowManagerPlus.current.setAspectRatio(1);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('16:9'),
                    onPressed: () async {
                      WindowManagerPlus.current.setAspectRatio(16 / 9);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('4:3'),
                    onPressed: () async {
                      WindowManagerPlus.current.setAspectRatio(4 / 3);
                    },
                  ),
                ],
              ),
            ),
            PreferenceListItem(
              title: const Text('setBackgroundColor'),
              accessoryView: Row(
                children: [
                  CupertinoButton(
                    child: const Text('transparent'),
                    onPressed: () async {
                      WindowManagerPlus.current
                          .setBackgroundColor(Colors.transparent);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('red'),
                    onPressed: () async {
                      WindowManagerPlus.current.setBackgroundColor(Colors.red);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('green'),
                    onPressed: () async {
                      WindowManagerPlus.current
                          .setBackgroundColor(Colors.green);
                    },
                  ),
                  CupertinoButton(
                    child: const Text('blue'),
                    onPressed: () async {
                      WindowManagerPlus.current.setBackgroundColor(Colors.blue);
                    },
                  ),
                ],
              ),
            ),
            PreferenceListItem(
              title: const Text('setBounds / setBounds'),
              accessoryView: ToggleButtons(
                onPressed: (int index) async {
                  _size = _kSizes[index];
                  Offset newPosition = await calcWindowPosition(
                    _size,
                    Alignment.center,
                  );
                  await WindowManagerPlus.current.setBounds(
                    // Rect.fromLTWH(
                    //   bounds.left + 10,
                    //   bounds.top + 10,
                    //   _size.width,
                    //   _size.height,
                    // ),
                    null,
                    position: newPosition,
                    size: _size,
                    animate: true,
                  );
                  setState(() {});
                },
                isSelected: _kSizes.map((e) => e == _size).toList(),
                children: <Widget>[
                  for (var size in _kSizes)
                    Text(' ${size.width.toInt()}x${size.height.toInt()} '),
                ],
              ),
              onTap: () async {
                Rect bounds = await WindowManagerPlus.current.getBounds();
                Size size = bounds.size;
                Offset origin = bounds.topLeft;
                BotToast.showText(
                  text: '${size.toString()}\n${origin.toString()}',
                );
              },
            ),
            PreferenceListItem(
              title: const Text('setAlignment'),
              accessoryView: SizedBox(
                width: 300,
                child: Wrap(
                  children: [
                    CupertinoButton(
                      child: const Text('topLeft'),
                      onPressed: () async {
                        await WindowManagerPlus.current.setAlignment(
                          Alignment.topLeft,
                          animate: true,
                        );
                      },
                    ),
                    CupertinoButton(
                      child: const Text('topCenter'),
                      onPressed: () async {
                        await WindowManagerPlus.current.setAlignment(
                          Alignment.topCenter,
                          animate: true,
                        );
                      },
                    ),
                    CupertinoButton(
                      child: const Text('topRight'),
                      onPressed: () async {
                        await WindowManagerPlus.current.setAlignment(
                          Alignment.topRight,
                          animate: true,
                        );
                      },
                    ),
                    CupertinoButton(
                      child: const Text('centerLeft'),
                      onPressed: () async {
                        await WindowManagerPlus.current.setAlignment(
                          Alignment.centerLeft,
                          animate: true,
                        );
                      },
                    ),
                    CupertinoButton(
                      child: const Text('center'),
                      onPressed: () async {
                        await WindowManagerPlus.current.setAlignment(
                          Alignment.center,
                          animate: true,
                        );
                      },
                    ),
                    CupertinoButton(
                      child: const Text('centerRight'),
                      onPressed: () async {
                        await WindowManagerPlus.current.setAlignment(
                          Alignment.centerRight,
                          animate: true,
                        );
                      },
                    ),
                    CupertinoButton(
                      child: const Text('bottomLeft'),
                      onPressed: () async {
                        await WindowManagerPlus.current.setAlignment(
                          Alignment.bottomLeft,
                          animate: true,
                        );
                      },
                    ),
                    CupertinoButton(
                      child: const Text('bottomCenter'),
                      onPressed: () async {
                        await WindowManagerPlus.current.setAlignment(
                          Alignment.bottomCenter,
                          animate: true,
                        );
                      },
                    ),
                    CupertinoButton(
                      child: const Text('bottomRight'),
                      onPressed: () async {
                        await WindowManagerPlus.current.setAlignment(
                          Alignment.bottomRight,
                          animate: true,
                        );
                      },
                    ),
                  ],
                ),
              ),
              onTap: () async {},
            ),
            PreferenceListItem(
              title: const Text('center'),
              onTap: () async {
                await WindowManagerPlus.current.center();
              },
            ),
            PreferenceListItem(
              title: const Text('getPosition / setPosition'),
              accessoryView: Row(
                children: [
                  CupertinoButton(
                    child: const Text('xy>zero'),
                    onPressed: () async {
                      WindowManagerPlus.current.setPosition(const Offset(0, 0));
                      setState(() {});
                    },
                  ),
                  CupertinoButton(
                    child: const Text('x+20'),
                    onPressed: () async {
                      Offset p = await WindowManagerPlus.current.getPosition();
                      WindowManagerPlus.current
                          .setPosition(Offset(p.dx + 20, p.dy));
                      setState(() {});
                    },
                  ),
                  CupertinoButton(
                    child: const Text('x-20'),
                    onPressed: () async {
                      Offset p = await WindowManagerPlus.current.getPosition();
                      WindowManagerPlus.current
                          .setPosition(Offset(p.dx - 20, p.dy));
                      setState(() {});
                    },
                  ),
                  CupertinoButton(
                    child: const Text('y+20'),
                    onPressed: () async {
                      Offset p = await WindowManagerPlus.current.getPosition();
                      WindowManagerPlus.current
                          .setPosition(Offset(p.dx, p.dy + 20));
                      setState(() {});
                    },
                  ),
                  CupertinoButton(
                    child: const Text('y-20'),
                    onPressed: () async {
                      Offset p = await WindowManagerPlus.current.getPosition();
                      WindowManagerPlus.current
                          .setPosition(Offset(p.dx, p.dy - 20));
                      setState(() {});
                    },
                  ),
                ],
              ),
              onTap: () async {
                Offset position = await WindowManagerPlus.current.getPosition();
                BotToast.showText(
                  text: position.toString(),
                );
              },
            ),
            PreferenceListItem(
              title: const Text('getSize / setSize'),
              accessoryView: CupertinoButton(
                child: const Text('Set'),
                onPressed: () async {
                  Size size = await WindowManagerPlus.current.getSize();
                  WindowManagerPlus.current.setSize(
                    Size(size.width + 100, size.height + 100),
                  );
                  setState(() {});
                },
              ),
              onTap: () async {
                Size size = await WindowManagerPlus.current.getSize();
                BotToast.showText(
                  text: size.toString(),
                );
              },
            ),
            PreferenceListItem(
              title: const Text('getMinimumSize / setMinimumSize'),
              accessoryView: ToggleButtons(
                onPressed: (int index) {
                  _minSize = _kMinSizes[index];
                  WindowManagerPlus.current.setMinimumSize(_minSize!);
                  setState(() {});
                },
                isSelected: _kMinSizes.map((e) => e == _minSize).toList(),
                children: <Widget>[
                  for (var size in _kMinSizes)
                    Text(' ${size.width.toInt()}x${size.height.toInt()} '),
                ],
              ),
            ),
            PreferenceListItem(
              title: const Text('getMaximumSize / setMaximumSize'),
              accessoryView: ToggleButtons(
                onPressed: (int index) {
                  _maxSize = _kMaxSizes[index];
                  WindowManagerPlus.current.setMaximumSize(_maxSize!);
                  setState(() {});
                },
                isSelected: _kMaxSizes.map((e) => e == _maxSize).toList(),
                children: <Widget>[
                  for (var size in _kMaxSizes)
                    Text(' ${size.width.toInt()}x${size.height.toInt()} '),
                ],
              ),
            ),
            PreferenceListSwitchItem(
              title: const Text('isResizable / setResizable'),
              onTap: () async {
                bool isResizable =
                    await WindowManagerPlus.current.isResizable();
                BotToast.showText(text: 'isResizable: $isResizable');
              },
              value: _isResizable,
              onChanged: (newValue) {
                _isResizable = newValue;
                WindowManagerPlus.current.setResizable(_isResizable);
                setState(() {});
              },
            ),
            PreferenceListSwitchItem(
              title: const Text('isMovable / setMovable'),
              onTap: () async {
                bool isMovable = await WindowManagerPlus.current.isMovable();
                BotToast.showText(text: 'isMovable: $isMovable');
              },
              value: _isMovable,
              onChanged: (newValue) {
                _isMovable = newValue;
                WindowManagerPlus.current.setMovable(_isMovable);
                setState(() {});
              },
            ),
            PreferenceListSwitchItem(
              title: const Text('isMinimizable / setMinimizable'),
              onTap: () async {
                _isMinimizable =
                    await WindowManagerPlus.current.isMinimizable();
                setState(() {});
                BotToast.showText(text: 'isMinimizable: $_isMinimizable');
              },
              value: _isMinimizable,
              onChanged: (newValue) async {
                await WindowManagerPlus.current.setMinimizable(newValue);
                _isMinimizable =
                    await WindowManagerPlus.current.isMinimizable();
                print('isMinimizable: $_isMinimizable');
                setState(() {});
              },
            ),
            PreferenceListSwitchItem(
              title: const Text('isMaximizable / setMaximizable'),
              onTap: () async {
                _isMaximizable =
                    await WindowManagerPlus.current.isMaximizable();
                setState(() {});
                BotToast.showText(text: 'isClosable: $_isMaximizable');
              },
              value: _isMaximizable,
              onChanged: (newValue) async {
                await WindowManagerPlus.current.setMaximizable(newValue);
                _isMaximizable =
                    await WindowManagerPlus.current.isMaximizable();
                print('isMaximizable: $_isMaximizable');
                setState(() {});
              },
            ),
            PreferenceListSwitchItem(
              title: const Text('isClosable / setClosable'),
              onTap: () async {
                _isClosable = await WindowManagerPlus.current.isClosable();
                setState(() {});
                BotToast.showText(text: 'isClosable: $_isClosable');
              },
              value: _isClosable,
              onChanged: (newValue) async {
                await WindowManagerPlus.current.setClosable(newValue);
                _isClosable = await WindowManagerPlus.current.isClosable();
                print('isClosable: $_isClosable');
                setState(() {});
              },
            ),
            PreferenceListSwitchItem(
              title: const Text('isAlwaysOnTop / setAlwaysOnTop'),
              onTap: () async {
                bool isAlwaysOnTop =
                    await WindowManagerPlus.current.isAlwaysOnTop();
                BotToast.showText(text: 'isAlwaysOnTop: $isAlwaysOnTop');
              },
              value: _isAlwaysOnTop,
              onChanged: (newValue) {
                _isAlwaysOnTop = newValue;
                WindowManagerPlus.current.setAlwaysOnTop(_isAlwaysOnTop);
                setState(() {});
              },
            ),
            PreferenceListSwitchItem(
              title: const Text('isAlwaysOnBottom / setAlwaysOnBottom'),
              onTap: () async {
                bool isAlwaysOnBottom =
                    await WindowManagerPlus.current.isAlwaysOnBottom();
                BotToast.showText(text: 'isAlwaysOnBottom: $isAlwaysOnBottom');
              },
              value: _isAlwaysOnBottom,
              onChanged: (newValue) async {
                _isAlwaysOnBottom = newValue;
                await WindowManagerPlus.current
                    .setAlwaysOnBottom(_isAlwaysOnBottom);
                setState(() {});
              },
            ),
            PreferenceListItem(
              title: const Text('getTitle / setTitle'),
              onTap: () async {
                String title = await WindowManagerPlus.current.getTitle();
                BotToast.showText(
                  text: title.toString(),
                );
                title =
                    'Window ID ${WindowManagerPlus.current.id} - ${DateTime.now().millisecondsSinceEpoch}';
                await WindowManagerPlus.current.setTitle(title);
              },
            ),
            PreferenceListItem(
              title: const Text('setTitleBarStyle'),
              accessoryView: Row(
                children: [
                  CupertinoButton(
                    child: const Text('normal'),
                    onPressed: () async {
                      WindowManagerPlus.current.setTitleBarStyle(
                        TitleBarStyle.normal,
                        windowButtonVisibility: true,
                      );
                      setState(() {});
                    },
                  ),
                  CupertinoButton(
                    child: const Text('hidden'),
                    onPressed: () async {
                      WindowManagerPlus.current.setTitleBarStyle(
                        TitleBarStyle.hidden,
                        windowButtonVisibility: false,
                      );
                      setState(() {});
                    },
                  ),
                ],
              ),
              onTap: () {},
            ),
            PreferenceListItem(
              title: const Text('getTitleBarHeight'),
              onTap: () async {
                int titleBarHeight =
                    await WindowManagerPlus.current.getTitleBarHeight();
                BotToast.showText(
                  text: 'titleBarHeight: $titleBarHeight',
                );
              },
            ),
            PreferenceListItem(
              title: const Text('isSkipTaskbar'),
              onTap: () async {
                bool isSkipping =
                    await WindowManagerPlus.current.isSkipTaskbar();
                BotToast.showText(
                  text: 'isSkipTaskbar: $isSkipping',
                );
              },
            ),
            PreferenceListItem(
              title: const Text('setSkipTaskbar'),
              onTap: () async {
                setState(() {
                  _isSkipTaskbar = !_isSkipTaskbar;
                });
                await WindowManagerPlus.current.setSkipTaskbar(_isSkipTaskbar);
                await Future.delayed(const Duration(seconds: 3));
                WindowManagerPlus.current.show();
              },
            ),
            PreferenceListItem(
              title: const Text('setProgressBar'),
              onTap: () async {
                for (var i = 0; i <= 100; i++) {
                  setState(() {
                    _progress = i / 100;
                  });
                  print(_progress);
                  await WindowManagerPlus.current.setProgressBar(_progress);
                  await Future.delayed(const Duration(milliseconds: 100));
                }
                await Future.delayed(const Duration(milliseconds: 1000));
                await WindowManagerPlus.current.setProgressBar(-1);
              },
            ),
            PreferenceListItem(
              title: const Text('setIcon'),
              accessoryView: Row(
                children: [
                  CupertinoButton(
                    child: const Text('Default'),
                    onPressed: () => _handleSetIcon(_kIconTypeDefault),
                  ),
                  CupertinoButton(
                    child: const Text('Original'),
                    onPressed: () => _handleSetIcon(_kIconTypeOriginal),
                  ),
                ],
              ),
              onTap: () => _handleSetIcon(_kIconTypeDefault),
            ),
            PreferenceListSwitchItem(
              title: const Text(
                'isVisibleOnAllWorkspaces / setVisibleOnAllWorkspaces',
              ),
              onTap: () async {
                bool isVisibleOnAllWorkspaces =
                    await WindowManagerPlus.current.isVisibleOnAllWorkspaces();
                BotToast.showText(
                  text: 'isVisibleOnAllWorkspaces: $isVisibleOnAllWorkspaces',
                );
              },
              value: _isVisibleOnAllWorkspaces,
              onChanged: (newValue) {
                _isVisibleOnAllWorkspaces = newValue;
                WindowManagerPlus.current.setVisibleOnAllWorkspaces(
                  _isVisibleOnAllWorkspaces,
                  visibleOnFullScreen: _isVisibleOnAllWorkspaces,
                );
                setState(() {});
              },
            ),
            PreferenceListItem(
              title: const Text('setBadgeLabel'),
              accessoryView: Row(
                children: [
                  CupertinoButton(
                    child: const Text('null'),
                    onPressed: () async {
                      await WindowManagerPlus.current.setBadgeLabel();
                    },
                  ),
                  CupertinoButton(
                    child: const Text('99+'),
                    onPressed: () async {
                      await WindowManagerPlus.current.setBadgeLabel('99+');
                    },
                  ),
                ],
              ),
              onTap: () => _handleSetIcon(_kIconTypeDefault),
            ),
            PreferenceListSwitchItem(
              title: const Text('hasShadow / setHasShadow'),
              onTap: () async {
                bool hasShadow = await WindowManagerPlus.current.hasShadow();
                BotToast.showText(
                  text: 'hasShadow: $hasShadow',
                );
              },
              value: _hasShadow,
              onChanged: (newValue) {
                _hasShadow = newValue;
                WindowManagerPlus.current.setHasShadow(_hasShadow);
                setState(() {});
              },
            ),
            PreferenceListItem(
              title: const Text('getOpacity / setOpacity'),
              onTap: () async {
                double opacity = await WindowManagerPlus.current.getOpacity();
                BotToast.showText(
                  text: 'opacity: $opacity',
                );
              },
              accessoryView: Row(
                children: [
                  CupertinoButton(
                    child: const Text('1'),
                    onPressed: () async {
                      _opacity = 1;
                      WindowManagerPlus.current.setOpacity(_opacity);
                      setState(() {});
                    },
                  ),
                  CupertinoButton(
                    child: const Text('0.8'),
                    onPressed: () async {
                      _opacity = 0.8;
                      WindowManagerPlus.current.setOpacity(_opacity);
                      setState(() {});
                    },
                  ),
                  CupertinoButton(
                    child: const Text('0.6'),
                    onPressed: () async {
                      _opacity = 0.5;
                      WindowManagerPlus.current.setOpacity(_opacity);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            PreferenceListSwitchItem(
              title: const Text('setIgnoreMouseEvents'),
              value: _isIgnoreMouseEvents,
              onChanged: (newValue) async {
                _isIgnoreMouseEvents = newValue;
                await WindowManagerPlus.current.setIgnoreMouseEvents(
                  _isIgnoreMouseEvents,
                  forward: false,
                );
                setState(() {});
              },
            ),
            PreferenceListItem(
              title: const Text('popUpWindowMenu'),
              onTap: () async {
                await WindowManagerPlus.current.popUpWindowMenu();
              },
            ),
            // PreferenceListItem(
            //   title: const Text('grabKeyboard'),
            //   onTap: () async {
            //     await WindowManagerPlus.current.grabKeyboard();
            //   },
            // ),
            // PreferenceListItem(
            //   title: const Text('ungrabKeyboard'),
            //   onTap: () async {
            //     await WindowManagerPlus.current.ungrabKeyboard();
            //   },
            // ),
          ],
        ),
      ],
    );
  }

  Widget _build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(0),
          decoration: const BoxDecoration(
            color: Colors.white,
            // border: Border.all(color: Colors.grey.withOpacity(0.4), width: 1),
            // boxShadow: <BoxShadow>[
            //   BoxShadow(
            //     color: Colors.black.withOpacity(0.2),
            //     offset: Offset(1.0, 1.0),
            //     blurRadius: 6.0,
            //   ),
            // ],
          ),
          child: Scaffold(
            appBar: _isFullScreen
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(kWindowCaptionHeight),
                    child: WindowCaption(
                      brightness: Theme.of(context).brightness,
                      title: Text('Window ID ${WindowManagerPlus.current.id}'),
                    ),
                  ),
            body: Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (details) {
                    WindowManagerPlus.current.startDragging();
                  },
                  onDoubleTap: () async {
                    bool isMaximized =
                        await WindowManagerPlus.current.isMaximized();
                    if (!isMaximized) {
                      WindowManagerPlus.current.maximize();
                    } else {
                      WindowManagerPlus.current.unmaximize();
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(0),
                    width: double.infinity,
                    height: 54,
                    color: Colors.grey.withOpacity(0.3),
                    child: const Center(
                      child: Text('DragToMoveArea'),
                    ),
                  ),
                ),
                if (Platform.isLinux || Platform.isWindows)
                  Container(
                    height: 100,
                    margin: const EdgeInsets.all(20),
                    child: DragToResizeArea(
                      resizeEdgeSize: 6,
                      resizeEdgeColor: Colors.red.withOpacity(0.2),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.grey.withOpacity(0.3),
                        child: Center(
                          child: GestureDetector(
                            child: const Text('DragToResizeArea'),
                            onTap: () {
                              BotToast.showText(
                                text: 'DragToResizeArea example',
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: _buildBody(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (_isIgnoreMouseEvents) {
          WindowManagerPlus.current.setOpacity(1.0);
        }
      },
      onExit: (_) {
        if (_isIgnoreMouseEvents) {
          WindowManagerPlus.current.setOpacity(0.5);
        }
      },
      child: _build(context),
    );
  }

  @override
  void onTrayIconMouseDown() {
    WindowManagerPlus.current.show();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_window':
        await WindowManagerPlus.current.focus();
        break;
      case 'set_ignore_mouse_events':
        _isIgnoreMouseEvents = false;
        await WindowManagerPlus.current
            .setIgnoreMouseEvents(_isIgnoreMouseEvents);
        setState(() {});
        break;
    }
  }

  @override
  void onWindowFocus([int? windowId]) {
    if (windowId != null) {
      return;
    }
    setState(() {});
  }

  @override
  void onWindowClose([int? windowId]) {
    if (windowId != null) {
      return;
    }
    if (_isPreventClose) {
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Are you sure you want to close this window?'),
            actions: [
              TextButton(
                child: const Text('No'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Yes'),
                onPressed: () {
                  Navigator.of(context).pop();
                  WindowManagerPlus.current.destroy();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void onWindowEvent(String eventName, [int? windowId]) {
    print(
        '[${windowId != null ? "Global Event for Window $windowId from ${WindowManagerPlus.current}" : WindowManagerPlus.current}] onWindowEvent: $eventName');
  }

  @override
  Future<dynamic> onEventFromWindow(
      String eventName, int fromWindowId, dynamic arguments) async {
    BotToast.showText(
        text:
            '[${WindowManagerPlus.current}] Event $eventName from Window $fromWindowId with arguments $arguments');
    return 'Hello from ${WindowManagerPlus.current}';
  }
}
