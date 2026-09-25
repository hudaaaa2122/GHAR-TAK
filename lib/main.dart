import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants/figma_assets.dart';
import 'core/location/delivery_location.dart';
import 'core/location/delivery_location_provider.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_fonts.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'router/app_router.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Bundled Manrope assets — do not depend on network font fetch.
    GoogleFonts.config.allowRuntimeFetching = false;

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('PlatformError: $error\n$stack');
      return true; // handled — do not kill the app
    };
    ErrorWidget.builder = (details) => Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Something went wrong.\n${details.exceptionAsString()}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ),
    );

    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {}

    await _precacheSplash();
    runApp(const ProviderScope(child: GherTakApp()));
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}

Future<void> _precacheSplash() async {
  final image = const AssetImage(FigmaAssets.splash);
  final stream = image.resolve(const ImageConfiguration());
  final done = Completer<void>();
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (ImageInfo _, bool __) {
      if (!done.isCompleted) done.complete();
      stream.removeListener(listener);
    },
    onError: (Object _, StackTrace? __) {
      if (!done.isCompleted) done.complete();
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  await done.future.timeout(
    const Duration(milliseconds: 1500),
    onTimeout: () {},
  );
}

class GherTakApp extends ConsumerStatefulWidget {
  const GherTakApp({super.key});

  @override
  ConsumerState<GherTakApp> createState() => _GherTakAppState();
}

class _GherTakAppState extends ConsumerState<GherTakApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AppPermissions.requestStartupPermissions();
      ref.invalidate(deliveryLocationProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Gher Tak',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Keep AppColors text tokens in sync with Material brightness.
        AppColors.bindBrightness(Theme.of(context).brightness);
        // Match website mobile density — browsers don't apply Android
        // accessibility textScale the same way Material does.
        final mq = MediaQuery.of(context);
        final clamped = mq.textScaler.clamp(
          minScaleFactor: 0.90,
          maxScaleFactor: 1.0,
        );
        return MediaQuery(
          data: mq.copyWith(textScaler: clamped),
          child: DefaultTextStyle(
            style: AppFonts.style(
              color: AppColors.textPrimary,
              fontSize: AppFonts.body,
              fontWeight: FontWeight.w500,
            ),
            child: IconTheme(
              data: IconThemeData(color: AppColors.textSecondary),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
