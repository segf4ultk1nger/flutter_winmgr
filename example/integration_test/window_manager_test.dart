import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_winmgr/window_manager_plus.dart';

Future<void> main(List<String> args) async {
  if (kDebugMode) {
    print(args);
  }
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await WindowManagerPlus.ensureInitialized(
      args.isEmpty ? 0 : int.parse(args[0]));
  await WindowManagerPlus.current.waitUntilReadyToShow(
    const WindowOptions(
      size: Size(640, 480),
      title: 'window_manager_test',
    ),
    () async {
      await WindowManagerPlus.current.show();
      await WindowManagerPlus.current.focus();
    },
  );

  testWidgets('getBounds', (tester) async {
    expect(
      await WindowManagerPlus.current.getBounds(),
      isA<Rect>().having((r) => r.size, 'size', const Size(640, 480)),
    );
  });

  testWidgets(
    'isAlwaysOnBottom',
    (tester) async {
      expect(await WindowManagerPlus.current.isAlwaysOnBottom(), isFalse);
    },
    skip: Platform.isMacOS || Platform.isWindows,
  );

  testWidgets('isAlwaysOnTop', (tester) async {
    expect(await WindowManagerPlus.current.isAlwaysOnTop(), isFalse);
  });

  testWidgets('isClosable', (tester) async {
    expect(await WindowManagerPlus.current.isClosable(), isTrue);
  });

  testWidgets('isFocused', (tester) async {
    expect(await WindowManagerPlus.current.isFocused(), isTrue);
  });

  testWidgets('isFullScreen', (tester) async {
    expect(await WindowManagerPlus.current.isFullScreen(), isFalse);
  });

  testWidgets(
    'hasShadow',
    (tester) async {
      expect(await WindowManagerPlus.current.hasShadow(), isTrue);
    },
    skip: Platform.isLinux,
  );

  testWidgets('isMaximizable', (tester) async {
    expect(await WindowManagerPlus.current.isMaximizable(), isTrue);
  });

  testWidgets('isMaximized', (tester) async {
    expect(await WindowManagerPlus.current.isMaximized(), isFalse);
  });

  testWidgets(
    'isMinimizable',
    (tester) async {
      expect(await WindowManagerPlus.current.isMinimizable(), isTrue);
    },
    skip: Platform.isMacOS,
  );

  testWidgets('isMinimized', (tester) async {
    expect(await WindowManagerPlus.current.isMinimized(), isFalse);
  });

  testWidgets(
    'isMovable',
    (tester) async {
      expect(await WindowManagerPlus.current.isMovable(), isTrue);
    },
    skip: Platform.isLinux || Platform.isWindows,
  );

  testWidgets('getOpacity', (tester) async {
    expect(await WindowManagerPlus.current.getOpacity(), 1.0);
  });

  testWidgets('getPosition', (tester) async {
    expect(await WindowManagerPlus.current.getPosition(), isA<Offset>());
  });

  testWidgets('isPreventClose', (tester) async {
    expect(await WindowManagerPlus.current.isPreventClose(), isFalse);
  });

  testWidgets('isResizable', (tester) async {
    expect(await WindowManagerPlus.current.isResizable(), isTrue);
  });

  testWidgets('getSize', (tester) async {
    expect(await WindowManagerPlus.current.getSize(), const Size(640, 480));
  });

  testWidgets(
    'isSkipTaskbar',
    (tester) async {
      expect(await WindowManagerPlus.current.isSkipTaskbar(), isFalse);
    },
    skip: Platform.isWindows,
  );

  testWidgets('getTitle', (tester) async {
    expect(await WindowManagerPlus.current.getTitle(), 'window_manager_test');
  });

  testWidgets('getTitleBarHeight', (tester) async {
    expect(await WindowManagerPlus.current.getTitleBarHeight(), isNonNegative);
  });

  testWidgets('isVisible', (tester) async {
    expect(await WindowManagerPlus.current.isVisible(), isTrue);
  });
}
