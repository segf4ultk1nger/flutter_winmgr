import 'package:flutter/material.dart';
import 'package:flutter_winmgr/src/window_manager.dart';

/// A widget for drag to move window.
///
/// When you have hidden the title bar, you can add this widget to move the window position.
///
/// {@tool snippet}
///
/// The sample creates a red box, drag the box to move the window.
///
/// ```dart
/// DragToMoveArea(
///   child: Container(
///     width: 300,
///     height: 32,
///     color: Colors.red,
///   ),
/// )
/// ```
/// {@end-tool}
class DragToMoveArea extends StatelessWidget {
  const DragToMoveArea({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) {
        WindowManagerPlus.current.startDragging();
      },
      onDoubleTap: () async {
        bool isMaximized = await WindowManagerPlus.current.isMaximized();
        if (!isMaximized) {
          WindowManagerPlus.current.maximize();
        } else {
          WindowManagerPlus.current.unmaximize();
        }
      },
      child: child,
    );
  }
}
