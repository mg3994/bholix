import 'package:flutter/material.dart';
import 'package:kaisel/kaisel.dart';

import '../ui/menu_screen.dart';
import '../ui/game_screen.dart';
import '../ui/game_over_screen.dart';

// ── Sealed route hierarchy ────────────────────────────────────────────────────
//
// Dart 3 sealed class — compiler enforces exhaustiveness in every switch.
// KaiselRoute provides value equality via props; no manual == or hashCode.

sealed class AppRoute extends KaiselRoute {
  const AppRoute();
}

final class MenuRoute extends AppRoute {
  const MenuRoute();
}

final class PlayingRoute extends AppRoute {
  const PlayingRoute();
}

final class GameOverRoute extends AppRoute {
  const GameOverRoute({required this.finalScore});
  final int finalScore;

  @override
  List<Object?> get props => [finalScore];
}

// ── Router config — app-lifetime singleton ────────────────────────────────────
//
// KaiselRouterConfig collapses router + delegate + parser into one object.
// Pass to MaterialApp.router(routerConfig: appRouterConfig).
// Navigate with context.push / context.pushOrReplaceTop (typed, compile-safe).

final appRouterConfig = KaiselRouterConfig<AppRoute>(
  initial: const MenuRoute(),
  builder: (context, route) => switch (route) {
    MenuRoute() => const MenuScreen(),
    PlayingRoute() => const GameScreen(),
    GameOverRoute(:final finalScore) => GameOverScreen(finalScore: finalScore),
  },
);
