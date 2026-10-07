import 'package:bloc_signals/bloc_signals.dart';

// ── Dart 3 record — immutable, structural equality, pattern-matchable ─────────

enum GamePhase { playing, gameOver }

typedef GameStateRecord = ({int score, int lives, GamePhase phase});

/// Default starting state — const-constructible via record literal.
const GameStateRecord kInitialGameState = (
  score: 0,
  lives: 3,
  phase: GamePhase.playing,
);

/// copyWith extension on the record type.
/// Records have no methods; extensions are the Dart-idiomatic solution.
extension GameStateRecordX on GameStateRecord {
  GameStateRecord copyWith({int? score, int? lives, GamePhase? phase}) => (
    score: score ?? this.score,
    lives: lives ?? this.lives,
    phase: phase ?? this.phase,
  );

  bool get isPlaying => phase == GamePhase.playing;
  bool get isGameOver => phase == GamePhase.gameOver;
}

// ── CubitSignal — synchronous, signal-speed, zero-microtask-delay ─────────────

/// Reactive game state container.
///
/// [CubitSignal] uses Signals v7 under the hood: [emit] propagates
/// synchronously in the same frame with no microtask delay.
/// Access the current value with [stateValue]; reactive listeners use
/// [BlocSignalBuilder] / [BlocSignalSelector] on the Flutter side.
final class GameCubit extends CubitSignal<GameStateRecord> {
  GameCubit() : super(initialState: kInitialGameState);

  void addScore(int points) =>
      emit(stateValue.copyWith(score: stateValue.score + points));

  void loseLife() {
    final newLives = stateValue.lives - 1;
    emit(
      stateValue.copyWith(
        lives: newLives,
        phase: newLives <= 0 ? GamePhase.gameOver : GamePhase.playing,
      ),
    );
  }

  void reset() => emit(kInitialGameState);
}
