import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_winmgr/src/resize_edge.dart';
import 'package:flutter_winmgr/src/widgets/drag_to_resize_area.dart';
import 'package:flutter_winmgr/src/window_listener.dart';
import 'package:flutter_winmgr/src/window_manager.dart';

final _kIsLinux = !kIsWeb && Platform.isLinux;
final _kIsWindows = !kIsWeb && Platform.isWindows;

class VirtualWindowFrame extends StatefulWidget {
  const VirtualWindowFrame({
    super.key,
    required this.child,
  });

  /// The [child] contained by the VirtualWindowFrame.
  final Widget child;

  @override
  State<StatefulWidget> createState() => _VirtualWindowFrameState();
}

class _VirtualWindowFrameState extends State<VirtualWindowFrame>
    with WindowListener {
  bool _isFocused = true;
  bool _isMaximized = false;
  bool _isFullScreen = false;

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

  Widget _buildVirtualWindowFrame(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: (_isMaximized || _isFullScreen) ? 0 : 1,
        ),
        borderRadius: BorderRadius.circular(
          (_isMaximized || _isFullScreen) ? 0 : 6,
        ),
        boxShadow: <BoxShadow>[
          if (!_isMaximized && !_isFullScreen)
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(0.0, _isFocused ? 4 : 2),
              blurRadius: 6,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          (_isMaximized || _isFullScreen) ? 0 : 6,
        ),
        child: widget.child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_kIsLinux) {
      return DragToResizeArea(
        enableResizeEdges: (_isMaximized || _isFullScreen) ? [] : null,
        child: _buildVirtualWindowFrame(context),
      );
    } else if (_kIsWindows) {
      return DragToResizeArea(
        enableResizeEdges: (_isMaximized || _isFullScreen)
            ? []
            : [
                ResizeEdge.topLeft,
                ResizeEdge.top,
                ResizeEdge.topRight,
              ],
        child: widget.child,
      );
    }

    return widget.child;
  }

  @override
  void onWindowFocus([int? windowId]) {
    setState(() {
      _isFocused = true;
    });
  }

  @override
  void onWindowBlur([int? windowId]) {
    setState(() {
      _isFocused = false;
    });
  }

  @override
  void onWindowMaximize([int? windowId]) {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize([int? windowId]) {
    setState(() {
      _isMaximized = false;
    });
  }

  @override
  void onWindowEnterFullScreen([int? windowId]) {
    setState(() {
      _isFullScreen = true;
    });
  }

  @override
  void onWindowLeaveFullScreen([int? windowId]) {
    setState(() {
      _isFullScreen = false;
    });
  }
}

// ignore: non_constant_identifier_names
TransitionBuilder VirtualWindowFrameInit() {
  return (_, Widget? child) {
    return VirtualWindowFrame(
      child: child!,
    );
  };
}
