import 'package:flutter/material.dart';

import 'package:flutter_winmgr/src/widgets/drag_to_move_area.dart';
import 'package:flutter_winmgr/src/widgets/window_caption_button.dart';
import 'package:flutter_winmgr/src/window_listener.dart';
import 'package:flutter_winmgr/src/window_manager.dart';

const double kWindowCaptionHeight = 32;

/// A widget to simulate the title bar of windows 11.
///
/// {@tool snippet}
///
/// ```dart
/// Scaffold(
///   appBar: PreferredSize(
///     child: WindowCaption(
///       brightness: Theme.of(context).brightness,
///       title: Text('window_manager_example'),
///     ),
///     preferredSize: const Size.fromHeight(kWindowCaptionHeight),
///   ),
/// )
/// ```
/// {@end-tool}
class WindowCaption extends StatefulWidget {
  const WindowCaption({
    super.key,
    this.title,
    this.backgroundColor,
    this.brightness,
  });

  final Widget? title;
  final Color? backgroundColor;
  final Brightness? brightness;

  @override
  State<WindowCaption> createState() => _WindowCaptionState();
}

class _WindowCaptionState extends State<WindowCaption> with WindowListener {
  @override
  void initState() {
    WindowManagerPlus.current.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    WindowManagerPlus.current.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.backgroundColor ??
            (widget.brightness == Brightness.dark
                ? const Color(0xff1C1C1C)
                : Colors.transparent),
      ),
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: SizedBox(
                height: double.infinity,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 16),
                      child: DefaultTextStyle(
                        style: TextStyle(
                          color: widget.brightness == Brightness.light
                              ? Colors.black.withOpacity(0.8956)
                              : Colors.white,
                          fontSize: 14,
                        ),
                        child: widget.title ?? Container(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          WindowCaptionButton.minimize(
            brightness: widget.brightness,
            onPressed: () async {
              bool isMinimized = await WindowManagerPlus.current.isMinimized();
              if (isMinimized) {
                WindowManagerPlus.current.restore();
              } else {
                WindowManagerPlus.current.minimize();
              }
            },
          ),
          FutureBuilder<bool>(
            future: WindowManagerPlus.current.isMaximized(),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.data == true) {
                return WindowCaptionButton.unmaximize(
                  brightness: widget.brightness,
                  onPressed: () {
                    WindowManagerPlus.current.unmaximize();
                  },
                );
              }
              return WindowCaptionButton.maximize(
                brightness: widget.brightness,
                onPressed: () {
                  WindowManagerPlus.current.maximize();
                },
              );
            },
          ),
          WindowCaptionButton.close(
            brightness: widget.brightness,
            onPressed: () {
              WindowManagerPlus.current.close();
            },
          ),
        ],
      ),
    );
  }

  @override
  void onWindowMaximize([int? windowId]) {
    setState(() {});
  }

  @override
  void onWindowUnmaximize([int? windowId]) {
    setState(() {});
  }
}
