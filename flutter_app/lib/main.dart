import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/design_tokens.dart';
import 'core/router/app_router.dart';
import 'core/l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/coach_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/log_provider.dart';
import 'providers/photo_analysis_provider.dart';
import 'providers/predict_provider.dart';
import 'providers/session_provider.dart';
import 'services/api/api_http.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: MirrorColors.bg,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  final language = await loadAppLanguage();
  runApp(ProviderScope(
    overrides: [initialAppLanguageProvider.overrideWithValue(language)],
    child: const MirrorApp(),
  ));
}

class MirrorApp extends ConsumerStatefulWidget {
  const MirrorApp({super.key});

  @override
  ConsumerState<MirrorApp> createState() => _MirrorAppState();
}

class _MirrorAppState extends ConsumerState<MirrorApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<SessionEndReason>? _sessionEnded;

  @override
  void initState() {
    super.initState();
    // The one place that reacts to a session ending — an expired/invalid token (any 401,
    // detected in ApiHttp) or an explicit sign-out. Screens never handle 401 themselves.
    _sessionEnded = SessionEvents.stream.listen(_onSessionEnded);
  }

  @override
  void dispose() {
    _sessionEnded?.cancel();
    super.dispose();
  }

  void _onSessionEnded(SessionEndReason reason) {
    appRouter.go(MirrorRoute.auth);
    // Reset per-user state after the navigation frame, so the screen being left
    // doesn't refetch with no token before it is disposed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(authProvider);
      ref.invalidate(sessionsProvider);
      ref.invalidate(sessionDetailProvider);
      ref.invalidate(inputDraftProvider);
      ref.invalidate(todayStatsProvider);
      ref.invalidate(predictMetricsProvider);
      ref.invalidate(coachSuggestionsProvider);
      ref.invalidate(targetParamsNotifierProvider);
      ref.invalidate(challengeProgressProvider);
      ref.invalidate(latestBodyAnalysisProvider);
    });
    // The messenger sits below MaterialApp's Localizations, so its context has S.
    final messengerContext = _messengerKey.currentContext;
    if (reason == SessionEndReason.expired && messengerContext != null) {
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(S.of(messengerContext).sessionExpired)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    return MaterialApp.router(
      title: '3D Mirror',
      debugShowCheckedModeBanner: false,
      theme: MirrorTheme.light,
      routerConfig: appRouter,
      scaffoldMessengerKey: _messengerKey,
      // null = follow the device; resolveAppLocale maps it to zh/en, falling back to zh.
      locale: language.locale,
      supportedLocales: kSupportedLocales,
      localeListResolutionCallback: (preferred, _) => resolveAppLocale(preferred),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
