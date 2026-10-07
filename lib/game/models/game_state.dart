enum GamePhase { playing, gameOver }

class GameState {
  final int score;
  final int lives;
  final GamePhase phase;

  const GameState({
    this.score = 0,
    this.lives = 3,
    this.phase = GamePhase.playing,
  });

  GameState copyWith({int? score, int? lives, GamePhase? phase}) => GameState(
        score: score ?? this.score,
        lives: lives ?? this.lives,
        phase: phase ?? this.phase,
      );
}
