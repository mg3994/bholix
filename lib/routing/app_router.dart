import 'package:kaisel/kaisel.dart';

import '../ui/menu_screen.dart';
import '../ui/game_screen.dart';
import '../ui/game_over_screen.dart';

// ── Sealed route hierarchy ────────────────────────────────────────────────────

sealed class AppRoute extends KaiselRoute {
  const AppRoute();
}

final class MenuRoute extends AppRoute {
  const MenuRoute();
}

final class PlayingRoute extends AppRoute {
  const PlayingRoute();
}

final class RunnerRoute extends AppRoute {
  const RunnerRoute();
}

final class GameOverRoute extends AppRoute {
  const GameOverRoute({required this.finalScore, required this.wavesReached});
  final int finalScore;
  final int wavesReached;

  @override
  List<Object?> get props => [finalScore, wavesReached];
}

// ── App-lifetime router config ─────────────────────────────────────────────────

final appRouterConfig = KaiselRouterConfig<AppRoute>(
  initial: const MenuRoute(),
  builder: (context, route) => switch (route) {
    MenuRoute() => const MenuScreen(),
    PlayingRoute() => const GameScreen(),
    RunnerRoute() => const GameScreen(), // Runs high-speed 3D flight mode
    GameOverRoute(:final finalScore, :final wavesReached) => GameOverScreen(
      finalScore: finalScore,
      wavesReached: wavesReached,
    ),
  },
);
