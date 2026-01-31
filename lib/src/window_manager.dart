import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_winmgr/src/resize_edge.dart';
import 'package:flutter_winmgr/src/title_bar_style.dart';
import 'package:flutter_winmgr/src/utils/calc_window_position.dart';
import 'package:flutter_winmgr/src/window_listener.dart';
import 'package:flutter_winmgr/src/window_options.dart';

const kWindowEventInitialized = 'initialized';
const kWindowEventClose = 'close';
const kWindowEventFocus = 'focus';
const kWindowEventBlur = 'blur';
const kWindowEventMaximize = 'maximize';
const kWindowEventUnmaximize = 'unmaximize';
const kWindowEventMinimize = 'minimize';
const kWindowEventRestore = 'restore';
const kWindowEventResize = 'resize';
const kWindowEventResized = 'resized';
const kWindowEventMove = 'move';
const kWindowEventMoved = 'moved';
const kWindowEventEnterFullScreen = 'enter-full-screen';
const kWindowEventLeaveFullScreen = 'leave-full-screen';
const kEventFromWindow = 'event-from-window';

const kWindowEventDocked = 'docked';
const kWindowEventUndocked = 'undocked';

enum DockSide { left, right }

/// WindowManagerPlus
class WindowManagerPlus {
  WindowManagerPlus._(int id)
      : _id = id,
        _channel = MethodChannel('window_manager_plus_$id') {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  WindowManagerPlus._fromWindowId(int id)
      : _id = id,
        _channel = _current!._channel {}

  final MethodChannel _channel;
  static const MethodChannel _staticChannel =
      MethodChannel('window_manager_plus_static');

  int _id;

  int get id => _id;

  static WindowManagerPlus? _current;

  /// The current instance of [WindowManagerPlus].
  /// [ensureInitialized] must be called before accessing this.
  static WindowManagerPlus get current => _current!;

  final ObserverList<WindowListener> _listeners =
      ObserverList<WindowListener>();

  static final ObserverList<WindowListener> _globalListeners =
      ObserverList<WindowListener>();

  static final Map<int, Completer> _completers = {};

  Future<dynamic> _methodCallHandler(MethodCall call) async {
    if (call.method != 'onEvent') throw UnimplementedError();

    String eventName = call.arguments['eventName'];
    int? windowId = call.arguments['windowId'];

    if (windowId != null) {
      if (eventName == kWindowEventInitialized) {
        if (_completers[windowId] != null &&
            !_completers[windowId]!.isCompleted) {
          _completers[windowId]?.complete();
        }
        _completers.remove(windowId);
      } else if (eventName == kWindowEventClose) {
        if (_completers[windowId] != null &&
            !_completers[windowId]!.isCompleted) {
          _completers[windowId]?.complete();
        }
        _completers.remove(windowId);
      }

      for (final WindowListener listener in globalListeners) {
        if (!_globalListeners.contains(listener)) {
          break;
        }

        listener.onWindowEvent(eventName, windowId);
        Map<String, Function> funcMap = {
          kWindowEventClose: listener.onWindowClose,
          kWindowEventFocus: listener.onWindowFocus,
          kWindowEventBlur: listener.onWindowBlur,
          kWindowEventMaximize: listener.onWindowMaximize,
          kWindowEventUnmaximize: listener.onWindowUnmaximize,
          kWindowEventMinimize: listener.onWindowMinimize,
          kWindowEventRestore: listener.onWindowRestore,
          kWindowEventResize: listener.onWindowResize,
          kWindowEventResized: listener.onWindowResized,
          kWindowEventMove: listener.onWindowMove,
          kWindowEventMoved: listener.onWindowMoved,
          kWindowEventEnterFullScreen: listener.onWindowEnterFullScreen,
          kWindowEventLeaveFullScreen: listener.onWindowLeaveFullScreen,
          kWindowEventDocked: listener.onWindowDocked,
          kWindowEventUndocked: listener.onWindowUndocked,
        };
        funcMap[eventName]?.call(windowId);
      }

      if (_current != null && _id != _current!.id) {
        for (final WindowListener listener in listeners) {
          if (!_listeners.contains(listener)) {
            break;
          }

          if (eventName == kEventFromWindow) {
            String method = call.arguments['method'];
            int fromWindowId = call.arguments['fromWindowId'];
            dynamic eventArguments = call.arguments['arguments'];
            try {
              return await listener.onEventFromWindow(
                  method, fromWindowId, eventArguments);
            } catch (_) {}
          }

          listener.onWindowEvent(eventName);
          Map<String, Function> funcMap = {
            kWindowEventClose: listener.onWindowClose,
            kWindowEventFocus: listener.onWindowFocus,
            kWindowEventBlur: listener.onWindowBlur,
            kWindowEventMaximize: listener.onWindowMaximize,
            kWindowEventUnmaximize: listener.onWindowUnmaximize,
            kWindowEventMinimize: listener.onWindowMinimize,
            kWindowEventRestore: listener.onWindowRestore,
            kWindowEventResize: listener.onWindowResize,
            kWindowEventResized: listener.onWindowResized,
            kWindowEventMove: listener.onWindowMove,
            kWindowEventMoved: listener.onWindowMoved,
            kWindowEventEnterFullScreen: listener.onWindowEnterFullScreen,
            kWindowEventLeaveFullScreen: listener.onWindowLeaveFullScreen,
            kWindowEventDocked: listener.onWindowDocked,
            kWindowEventUndocked: listener.onWindowUndocked,
          };
          funcMap[eventName]?.call();
        }
      }
    } else if (_current != null && _id == _current!.id) {
      for (final WindowListener listener in listeners) {
        if (!_listeners.contains(listener)) {
          break;
        }

        if (eventName == kEventFromWindow) {
          String method = call.arguments['method'];
          int fromWindowId = call.arguments['fromWindowId'];
          dynamic eventArguments = call.arguments['arguments'];
          try {
            return await listener.onEventFromWindow(
                method, fromWindowId, eventArguments);
          } catch (_) {}
        }

        listener.onWindowEvent(eventName);
        Map<String, Function> funcMap = {
          kWindowEventClose: listener.onWindowClose,
          kWindowEventFocus: listener.onWindowFocus,
          kWindowEventBlur: listener.onWindowBlur,
          kWindowEventMaximize: listener.onWindowMaximize,
          kWindowEventUnmaximize: listener.onWindowUnmaximize,
          kWindowEventMinimize: listener.onWindowMinimize,
          kWindowEventRestore: listener.onWindowRestore,
          kWindowEventResize: listener.onWindowResize,
          kWindowEventResized: listener.onWindowResized,
          kWindowEventMove: listener.onWindowMove,
          kWindowEventMoved: listener.onWindowMoved,
          kWindowEventEnterFullScreen: listener.onWindowEnterFullScreen,
          kWindowEventLeaveFullScreen: listener.onWindowLeaveFullScreen,
          kWindowEventDocked: listener.onWindowDocked,
          kWindowEventUndocked: listener.onWindowUndocked,
        };
        funcMap[eventName]?.call();
      }
    }
  }

  /// Get the window listeners.
  List<WindowListener> get listeners {
    final List<WindowListener> localListeners =
        List<WindowListener>.from(_listeners);
    return localListeners;
  }

  /// Whether the window has listeners.
  bool get hasListeners {
    return _listeners.isNotEmpty;
  }

  /// Add a listener to the window.
  void addListener(WindowListener listener) {
    _listeners.add(listener);
  }

  /// Remove a listener from the window.
  void removeListener(WindowListener listener) {
    _listeners.remove(listener);
  }

  /// Get the global window listeners.
  static List<WindowListener> get globalListeners {
    final List<WindowListener> localListeners =
        List<WindowListener>.from(_globalListeners);
    return localListeners;
  }

  /// Whether the window has global listeners.
  static bool get hasGlobalListeners {
    return _globalListeners.isNotEmpty;
  }

  /// Add a global listener to the window.
  static void addGlobalListener(WindowListener listener) {
    _globalListeners.add(listener);
  }

  /// Remove a global listener from the window.
  static void removeGlobalListener(WindowListener listener) {
    _globalListeners.remove(listener);
  }

  /// Get the device pixel ratio.
  double getDevicePixelRatio() {
    // Subsequent version, remove this deprecated member.
    // ignore: deprecated_member_use
    return window.devicePixelRatio;
  }

  /// Create a new window.
  static Future<WindowManagerPlus?> createWindow([List<String>? args]) async {
    final Map<String, dynamic> arguments = {
      'args': args,
    };
    int? windowId =
        await _staticChannel.invokeMethod('createWindow', arguments);
    if (windowId == null) {
      return null;
    }
    _completers[windowId] = Completer();
    await _completers[windowId]?.future;
    return WindowManagerPlus._fromWindowId(windowId);
  }

  /// Get all window manager ids.
  static Future<List<int>> getAllWindowManagerIds() async {
    return (await _staticChannel
                .invokeMethod<List<dynamic>>('getAllWindowManagerIds'))
            ?.cast<int>() ??
        [];
  }

  /// Get the window manager from the window id.
  static WindowManagerPlus fromWindowId(int windowId) {
    return WindowManagerPlus._fromWindowId(windowId);
  }

  /// Ensure the window manager for this [windowId] is initialized.
  /// Must be called before accessing the [WindowManagerPlus.current].
  static Future<void> ensureInitialized(int windowId) async {
    if (_current != null) {
      return;
    }
    final Map<String, dynamic> arguments = {
      'windowId': windowId,
    };
    // temp method channel to ensure initialized
    final MethodChannel _channel = const MethodChannel('window_manager_plus');
    await _channel.invokeMethod('ensureInitialized', arguments);
    _current = WindowManagerPlus._(windowId);
  }

  Future<T?> _invokeMethod<T>(String method,
      [Map<String, dynamic>? arguments]) {
    final Map<String, dynamic> args = _current?._id == _id
        ? {}
        : {
            'windowId': _id,
          };
    if (arguments != null) {
      args.addAll(arguments);
    }
    return _channel.invokeMethod<T>(method, args.isEmpty ? null : args);
  }

  /// You can call this to remove the window frame (title bar, outline border, etc), which is basically everything except the Flutter view, also can call setTitleBarStyle(TitleBarStyle.normal) or setTitleBarStyle(TitleBarStyle.hidden) to restore it.
  Future<void> setAsFrameless() async {
    await _invokeMethod('setAsFrameless');
  }

  /// Wait until ready to show.
  Future<void> waitUntilReadyToShow([
    WindowOptions? options,
    VoidCallback? callback,
  ]) async {
    await _invokeMethod('waitUntilReadyToShow');

    if (options?.titleBarStyle != null) {
      await setTitleBarStyle(
        options!.titleBarStyle!,
        windowButtonVisibility: options.windowButtonVisibility ?? true,
      );
    }

    if (await isFullScreen()) await setFullScreen(false);
    if (await isMaximized()) await unmaximize();
    if (await isMinimized()) await restore();

    if (options?.size != null) await setSize(options!.size!);
    if (options?.center == true) await setAlignment(Alignment.center);
    if (options?.minimumSize != null) {
      await setMinimumSize(options!.minimumSize!);
    }
    if (options?.maximumSize != null) {
      await setMaximumSize(options!.maximumSize!);
    }
    if (options?.alwaysOnTop != null) {
      await setAlwaysOnTop(options!.alwaysOnTop!);
    }
    if (options?.fullScreen != null) await setFullScreen(options!.fullScreen!);
    if (options?.backgroundColor != null) {
      await setBackgroundColor(options!.backgroundColor!);
    }
    if (options?.skipTaskbar != null) {
      await setSkipTaskbar(options!.skipTaskbar!);
    }
    if (options?.title != null) await setTitle(options!.title!);

    if (callback != null) {
      callback();
    }
  }

  /// Force closing the window.
  Future<void> destroy() async {
    await _invokeMethod('destroy');
  }

  /// Try to close the window.
  Future<void> close() async {
    await _invokeMethod('close');
  }

  /// Check if is intercepting the native close signal.
  Future<bool> isPreventClose() async {
    return await _invokeMethod('isPreventClose');
  }

  /// Set if intercept the native close signal. May useful when combine with the onclose event listener.
  /// This will also prevent the manually triggered close event.
  Future<void> setPreventClose(bool isPreventClose) async {
    final Map<String, dynamic> arguments = {
      'isPreventClose': isPreventClose,
    };
    await _invokeMethod('setPreventClose', arguments);
  }

  /// Focuses on the window.
  Future<void> focus() async {
    await _invokeMethod('focus');
  }

  /// Removes focus from the window.
  ///
  /// **Supported Platforms**:
  /// - Windows
  /// - macOS
  Future<void> blur() async {
    await _invokeMethod('blur');
  }

  /// Returns `bool` - Whether window is focused.
  ///
  /// **Supported Platforms**:
  /// - Windows
  /// - macOS
  Future<bool> isFocused() async {
    return await _invokeMethod('isFocused');
  }

  /// Shows and gives focus to the window.
  Future<void> show({bool inactive = false}) async {
    bool isMinimized = await this.isMinimized();
    if (isMinimized) {
      await restore();
    }
    final Map<String, dynamic> arguments = {
      'inactive': inactive,
    };
    await _invokeMethod('show', arguments);
  }

  /// Hides the window.
  Future<void> hide() async {
    await _invokeMethod('hide');
  }

  /// Returns `bool` - Whether the window is visible to the user.
  Future<bool> isVisible() async {
    return await _invokeMethod('isVisible');
  }

  /// Returns `bool` - Whether the window is maximized.
  Future<bool> isMaximized() async {
    return await _invokeMethod('isMaximized');
  }

  /// Maximizes the window. `vertically` simulates aero snap, only works on Windows
  Future<void> maximize({bool vertically = false}) async {
    final Map<String, dynamic> arguments = {
      'vertically': vertically,
    };
    await _invokeMethod('maximize', arguments);
  }

  /// Unmaximizes the window.
  Future<void> unmaximize() async {
    await _invokeMethod('unmaximize');
  }

  /// Returns `bool` - Whether the window is minimized.
  Future<bool> isMinimized() async {
    return await _invokeMethod('isMinimized');
  }

  /// Minimizes the window. On some platforms the minimized window will be shown in the Dock.
  Future<void> minimize() async {
    await _invokeMethod('minimize');
  }

  /// Restores the window from minimized state to its previous state.
  Future<void> restore() async {
    await _invokeMethod('restore');
  }

  /// Returns `bool` - Whether the window is in fullscreen mode.
  Future<bool> isFullScreen() async {
    return await _invokeMethod('isFullScreen');
  }

  /// Sets whether the window should be in fullscreen mode.
  Future<void> setFullScreen(bool isFullScreen) async {
    final Map<String, dynamic> arguments = {
      'isFullScreen': isFullScreen,
    };
    await _invokeMethod('setFullScreen', arguments);
    // (Windows) Force refresh the app so it 's back to the correct size
    // (see GitHub issue #311)
    if (Platform.isWindows) {
      final size = await getSize();
      setSize(size + const Offset(1, 1));
      setSize(size);
    }
  }

  /// Returns `bool` - Whether the window is dockable or not.
  ///
  /// **Supported Platforms**:
  /// - Windows
  Future<bool> isDockable() async {
    return await _invokeMethod('isDockable');
  }

  /// Returns `bool` - Whether the window is docked.
  ///
  /// **Supported Platforms**:
  /// - Windows
  Future<DockSide?> isDocked() async {
    int? docked = await _invokeMethod('isDocked');
    if (docked == 0) return null;
    if (docked == 1) return DockSide.left;
    if (docked == 2) return DockSide.right;
    return null;
  }

  /// Docks the window. only works on Windows
  ///
  /// **Supported Platforms**:
  /// - Windows
  Future<void> dock({required DockSide side, required int width}) async {
    final Map<String, dynamic> arguments = {
      'left': side == DockSide.left,
      'right': side == DockSide.right,
      'width': width,
    };
    await _invokeMethod('dock', arguments);
  }

  /// Undocks the window. only works on Windows
  ///
  /// **Supported Platforms**:
  /// - Windows
  Future<bool> undock() async {
    return await _invokeMethod('undock');
  }

  /// This will make a window maintain an aspect ratio.
  Future<void> setAspectRatio(double aspectRatio) async {
    final Map<String, dynamic> arguments = {
      'aspectRatio': aspectRatio,
    };
    await _invokeMethod('setAspectRatio', arguments);
  }

  /// Sets the background color of the window.
  Future<void> setBackgroundColor(Color backgroundColor) async {
    final Map<String, dynamic> arguments = {
      'backgroundColorA': backgroundColor.alpha,
      'backgroundColorR': backgroundColor.red,
      'backgroundColorG': backgroundColor.green,
      'backgroundColorB': backgroundColor.blue,
    };
    await _invokeMethod('setBackgroundColor', arguments);
  }

  /// Move the window to a position aligned with the screen.
  Future<void> setAlignment(
    Alignment alignment, {
    bool animate = false,
  }) async {
    Size windowSize = await getSize();
    Offset position = await calcWindowPosition(windowSize, alignment);
    await setPosition(position, animate: animate);
  }

  /// Moves window to the center of the screen.
  Future<void> center({
    bool animate = false,
  }) async {
    Size windowSize = await getSize();
    Offset position = await calcWindowPosition(windowSize, Alignment.center);
    await setPosition(position, animate: animate);
  }

  /// Returns `Rect` - The bounds of the window as Object.
  Future<Rect> getBounds() async {
    final Map<String, dynamic> arguments = {
      'devicePixelRatio': getDevicePixelRatio(),
    };
    final Map<dynamic, dynamic> resultData = await _invokeMethod(
      'getBounds',
      arguments,
    );

    return Rect.fromLTWH(
      resultData['x'],
      resultData['y'],
      resultData['width'],
      resultData['height'],
    );
  }

  /// Resizes and moves the window to the supplied bounds.
  Future<void> setBounds(
    Rect? bounds, {
    Offset? position,
    Size? size,
    bool animate = false,
  }) async {
    final Map<String, dynamic> arguments = {
      'devicePixelRatio': getDevicePixelRatio(),
      'x': bounds?.topLeft.dx ?? position?.dx,
      'y': bounds?.topLeft.dy ?? position?.dy,
      'width': bounds?.size.width ?? size?.width,
      'height': bounds?.size.height ?? size?.height,
      'animate': animate,
    }..removeWhere((key, value) => value == null);
    await _invokeMethod('setBounds', arguments);
  }

  /// Returns `Size` - Contains the window's width and height.
  Future<Size> getSize() async {
    Rect bounds = await getBounds();
    return bounds.size;
  }

  /// Resizes the window to `width` and `height`.
  Future<void> setSize(Size size, {bool animate = false}) async {
    await setBounds(
      null,
      size: size,
      animate: animate,
    );
  }

  /// Returns `Offset` - Contains the window's current position.
  Future<Offset> getPosition() async {
    Rect bounds = await getBounds();
    return bounds.topLeft;
  }

  /// Moves window to position.
  Future<void> setPosition(Offset position, {bool animate = false}) async {
    await setBounds(
      null,
      position: position,
      animate: animate,
    );
  }

  /// Sets the minimum size of window to `width` and `height`.
  Future<void> setMinimumSize(Size size) async {
    final Map<String, dynamic> arguments = {
      'devicePixelRatio': getDevicePixelRatio(),
      'width': size.width,
      'height': size.height,
    };
    await _invokeMethod('setMinimumSize', arguments);
  }

  /// Sets the maximum size of window to `width` and `height`.
  Future<void> setMaximumSize(Size size) async {
    final Map<String, dynamic> arguments = {
      'devicePixelRatio': getDevicePixelRatio(),
      'width': size.width,
      'height': size.height,
    };
    await _invokeMethod('setMaximumSize', arguments);
  }

  /// Returns `bool` - Whether the window can be manually resized by the user.
  Future<bool> isResizable() async {
    return await _invokeMethod('isResizable');
  }

  /// Sets whether the window can be manually resized by the user.
  Future<void> setResizable(bool isResizable) async {
    final Map<String, dynamic> arguments = {
      'isResizable': isResizable,
    };
    await _invokeMethod('setResizable', arguments);
  }

  /// Returns `bool` - Whether the window can be moved by user.
  ///
  /// **Supported Platforms**:
  /// - macOS
  Future<bool> isMovable() async {
    return await _invokeMethod('isMovable');
  }

  /// Sets whether the window can be moved by user.
  ///
  /// **Supported Platforms**:
  /// - macOS
  Future<void> setMovable(bool isMovable) async {
    final Map<String, dynamic> arguments = {
      'isMovable': isMovable,
    };
    await _invokeMethod('setMovable', arguments);
  }

  /// Returns `bool` - Whether the window can be manually minimized by the user.
  ///
  /// **Supported Platforms**:
  /// - Windows
  /// - macOS
  Future<bool> isMinimizable() async {
    return await _invokeMethod('isMinimizable');
  }

  /// Sets whether the window can be manually minimized by user.
  ///
  /// **Supported Platforms**:
  /// - Windows
  /// - macOS
  Future<void> setMinimizable(bool isMinimizable) async {
    final Map<String, dynamic> arguments = {
      'isMinimizable': isMinimizable,
    };
    await _invokeMethod('setMinimizable', arguments);
  }

  /// Returns `bool` - Whether the window can be manually closed by user.
  ///
  /// **Supported Platforms**:
  /// - Windows
  Future<bool> isClosable() async {
    return await _invokeMethod('isClosable');
  }

  /// Returns `bool` - Whether the window can be manually maximized by the user.
  ///
  /// **Supported Platforms**:
  /// - Windows
  /// - macOS
  Future<bool> isMaximizable() async {
    return await _invokeMethod('isMaximizable');
  }

  /// Sets whether the window can be manually maximized by the user.
  Future<void> setMaximizable(bool isMaximizable) async {
    final Map<String, dynamic> arguments = {
      'isMaximizable': isMaximizable,
    };
    await _invokeMethod('setMaximizable', arguments);
  }

  /// Sets whether the window can be manually closed by user.
  ///
  /// **Supported Platforms**:
  /// - Windows
  /// - macOS
  Future<void> setClosable(bool isClosable) async {
    final Map<String, dynamic> arguments = {
      'isClosable': isClosable,
    };
    await _invokeMethod('setClosable', arguments);
  }

  /// Returns `bool` - Whether the window is always on top of other windows.
  Future<bool> isAlwaysOnTop() async {
    return await _invokeMethod('isAlwaysOnTop');
  }

  /// Sets whether the window should show always on top of other windows.
  Future<void> setAlwaysOnTop(bool isAlwaysOnTop) async {
    final Map<String, dynamic> arguments = {
      'isAlwaysOnTop': isAlwaysOnTop,
    };
    await _invokeMethod('setAlwaysOnTop', arguments);
  }

  /// Returns `bool` - Whether the window is always below other windows.
  Future<bool> isAlwaysOnBottom() async {
    return await _invokeMethod('isAlwaysOnBottom');
  }

  /// Sets whether the window should show always below other windows.
  ///
  /// **Supported Platforms**:
  /// - Windows
  Future<void> setAlwaysOnBottom(bool isAlwaysOnBottom) async {
    final Map<String, dynamic> arguments = {
      'isAlwaysOnBottom': isAlwaysOnBottom,
    };
    await _invokeMethod('setAlwaysOnBottom', arguments);
  }

  /// Returns `String` - The title of the native window.
  Future<String> getTitle() async {
    return await _invokeMethod('getTitle');
  }

  /// Changes the title of native window to title.
  Future<void> setTitle(String title) async {
    final Map<String, dynamic> arguments = {
      'title': title,
    };
    await _invokeMethod('setTitle', arguments);
  }

  /// Changes the title bar style of native window.
  Future<void> setTitleBarStyle(
    TitleBarStyle titleBarStyle, {
    bool windowButtonVisibility = true,
  }) async {
    final Map<String, dynamic> arguments = {
      'titleBarStyle': titleBarStyle.name,
      'windowButtonVisibility': windowButtonVisibility,
    };
    await _invokeMethod('setTitleBarStyle', arguments);
  }

  /// Returns `int` - The title bar height of the native window.
  Future<int> getTitleBarHeight() async {
    return await _invokeMethod('getTitleBarHeight');
  }

  /// Returns `bool` - Whether skipping taskbar is enabled.
  Future<bool> isSkipTaskbar() async {
    return await _invokeMethod('isSkipTaskbar');
  }

  /// Makes the window not show in the taskbar / dock.
  Future<void> setSkipTaskbar(bool isSkipTaskbar) async {
    final Map<String, dynamic> arguments = {
      'isSkipTaskbar': isSkipTaskbar,
    };
    await _invokeMethod('setSkipTaskbar', arguments);
  }

  /// Sets progress value in progress bar. Valid range is `[0, 1.0]`.
  ///
  /// **Supported Platforms**:
  /// - Windows
  /// - macOS
  Future<void> setProgressBar(double progress) async {
    final Map<String, dynamic> arguments = {
      'progress': progress,
    };
    await _invokeMethod('setProgressBar', arguments);
  }

  /// Sets window/taskbar icon.
  ///
  /// **Supported Platforms**:
  /// - Windows
  Future<void> setIcon(String iconPath) async {
    final Map<String, dynamic> arguments = {
      'iconPath': path.joinAll([
        path.dirname(Platform.resolvedExecutable),
        'data/flutter_assets',
        iconPath,
      ]),
    };

    await _invokeMethod('setIcon', arguments);
  }

  /// Returns `bool` - Whether the window is visible on all workspaces.
  ///
  /// **Supported Platforms**:
  /// - macOS
  Future<bool> isVisibleOnAllWorkspaces() async {
    return await _invokeMethod('isVisibleOnAllWorkspaces');
  }

  /// Sets whether the window should be visible on all workspaces.
  ///
  /// Note: If you need to support dragging a window on top of a fullscreen
  /// window on another screen, you need to modify MainFlutterWindow
  /// to inherit from NSPanel
  ///
  /// ```swift
  /// class MainFlutterWindow: NSPanel {
  ///     // ...
  /// }
  /// ```
  ///
  /// **Supported Platforms**:
  /// - macOS
  Future<void> setVisibleOnAllWorkspaces(
    bool visible, {
    bool? visibleOnFullScreen,
  }) async {
    final Map<String, dynamic> arguments = {
      'visible': visible,
      'visibleOnFullScreen': visibleOnFullScreen ?? false,
    };
    await _invokeMethod('setVisibleOnAllWorkspaces', arguments);
  }

  /// Set/unset label on taskbar(dock) app icon
  ///
  /// Note that it's required to request access at your AppDelegate.swift like this:
  /// `UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge])`
  ///
  /// **Supported Platforms**:
  /// - macOS
  Future<void> setBadgeLabel([String? label]) async {
    final Map<String, dynamic> arguments = {
      'label': label ?? '',
    };
    await _invokeMethod('setBadgeLabel', arguments);
  }

  /// Returns `bool` - Whether the window has a shadow. On Windows, always returns true unless window is frameless.
  ///
  /// **Supported Platforms**:
  /// - Windows
  /// - macOS
  Future<bool> hasShadow() async {
    return await _invokeMethod('hasShadow');
  }

  /// Sets whether the window should have a shadow. On Windows, doesn't do anything unless window is frameless.
  ///
  /// **Supported Platforms**:
  /// - Windows
  /// - macOS
  Future<void> setHasShadow(bool hasShadow) async {
    final Map<String, dynamic> arguments = {
      'hasShadow': hasShadow,
    };
    await _invokeMethod('setHasShadow', arguments);
  }

  /// Returns `double` - between 0.0 (fully transparent) and 1.0 (fully opaque).
  Future<double> getOpacity() async {
    return await _invokeMethod('getOpacity');
  }

  /// Sets the opacity of the window.
  Future<void> setOpacity(double opacity) async {
    final Map<String, dynamic> arguments = {
      'opacity': opacity,
    };
    await _invokeMethod('setOpacity', arguments);
  }

  /// Sets the brightness of the window.
  Future<void> setBrightness(Brightness brightness) async {
    final Map<String, dynamic> arguments = {
      'brightness': brightness.name,
    };
    await _invokeMethod('setBrightness', arguments);
  }

  /// Makes the window ignore all mouse events.
  ///
  /// All mouse events happened in this window will be passed to the window below this window, but if this window has focus, it will still receive keyboard events.
  Future<void> setIgnoreMouseEvents(bool ignore, {bool forward = false}) async {
    final Map<String, dynamic> arguments = {
      'ignore': ignore,
      'forward': forward,
    };
    await _invokeMethod('setIgnoreMouseEvents', arguments);
  }

  Future<void> popUpWindowMenu() async {
    final Map<String, dynamic> arguments = {};
    await _invokeMethod('popUpWindowMenu', arguments);
  }

  /// Starts a window drag based on the specified mouse-down event.
  /// On Windows, this is disabled during full screen mode.
  Future<void> startDragging() async {
    if (Platform.isWindows && await isFullScreen()) return;
    await _invokeMethod('startDragging');
  }

  /// Starts a window resize based on the specified mouse-down & mouse-move event.
  /// On Windows, this is disabled during full screen mode.
  ///
  /// **Supported Platforms**:
  /// - Windows
  Future<void> startResizing(ResizeEdge resizeEdge) async {
    if (Platform.isWindows && await isFullScreen()) return;
    await _invokeMethod<bool>(
      'startResizing',
      {
        'resizeEdge': resizeEdge.name,
        'top': resizeEdge == ResizeEdge.top ||
            resizeEdge == ResizeEdge.topLeft ||
            resizeEdge == ResizeEdge.topRight,
        'bottom': resizeEdge == ResizeEdge.bottom ||
            resizeEdge == ResizeEdge.bottomLeft ||
            resizeEdge == ResizeEdge.bottomRight,
        'right': resizeEdge == ResizeEdge.right ||
            resizeEdge == ResizeEdge.topRight ||
            resizeEdge == ResizeEdge.bottomRight,
        'left': resizeEdge == ResizeEdge.left ||
            resizeEdge == ResizeEdge.topLeft ||
            resizeEdge == ResizeEdge.bottomLeft,
      },
    );
  }

  // /// Grabs the keyboard.
  // /// @platforms linux
  // Future<bool> grabKeyboard() async {
  //   return await _invokeMethod('grabKeyboard');
  // }
  //
  // /// Ungrabs the keyboard.
  // /// @platforms linux
  // Future<bool> ungrabKeyboard() async {
  //   return await _invokeMethod('ungrabKeyboard');
  // }

  /// Invokes a method on the window with id [targetWindowId].
  /// It could return a Future that resolves to the return value of the invoked method, otherwise `null`.
  /// Use [WindowListener.onEventFromWindow] to listen for the event.
  Future<dynamic> invokeMethodToWindow(int targetWindowId, String method,
      [dynamic args]) async {
    final Map<String, dynamic> arguments = {
      'targetWindowId': targetWindowId,
      'args': {
        'fromWindowId': _id,
        'eventName': kEventFromWindow,
        'method': method,
        'arguments': args,
      },
    };
    return await _invokeMethod('invokeMethodToWindow', arguments);
  }

  @override
  String toString() {
    return 'WindowManagerPlus{id: $_id}';
  }
}
