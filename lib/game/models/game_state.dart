import 'package:bloc_signals/bloc_signals.dart';

// ── Phase enum ────────────────────────────────────────────────────────────────

enum GamePhase { playing, paused, gameOver }

// ── Dart 3 record ─────────────────────────────────────────────────────────────

typedef GameStateRecord = ({
  int score,
  int lives,
  int wave,
  int combo, // current kill chain count
  double comboTimer, // seconds until combo resets (counts down each frame)
  GamePhase phase,
  bool isInvincible,
  double invincibilityTimer, // seconds remaining
});

const GameStateRecord kInitialGameState = (
  score: 0,
  lives: 3,
  wave: 1,
  combo: 0,
  comboTimer: 0.0,
  phase: GamePhase.playing,
  isInvincible: false,
  invincibilityTimer: 0.0,
);

extension GameStateRecordX on GameStateRecord {
  GameStateRecord copyWith({
    int? score,
    int? lives,
    int? wave,
    int? combo,
    double? comboTimer,
    GamePhase? phase,
    bool? isInvincible,
    double? invincibilityTimer,
  }) => (
    score: score ?? this.score,
    lives: lives ?? this.lives,
    wave: wave ?? this.wave,
    combo: combo ?? this.combo,
    comboTimer: comboTimer ?? this.comboTimer,
    phase: phase ?? this.phase,
    isInvincible: isInvincible ?? this.isInvincible,
    invincibilityTimer: invincibilityTimer ?? this.invincibilityTimer,
  );

  bool get isPlaying => phase == GamePhase.playing;
  bool get isPaused => phase == GamePhase.paused;
  bool get isGameOver => phase == GamePhase.gameOver;

  /// Points awarded for a kill, multiplied by current combo tier.
  int scoreFor(int basePoints) {
    final multiplier = switch (combo) {
      0 || 1 => 1,
      2 => 2,
      3 => 3,
      _ => 5,
    };
    return basePoints * multiplier;
  }
}

// ── CubitSignal ───────────────────────────────────────────────────────────────

final class GameCubit extends CubitSignal<GameStateRecord> {
  GameCubit() : super(initialState: kInitialGameState);

  // ── score & combo ──────────────────────────────────────────────────────────

  void addScore(int basePoints) {
    final s = stateValue;
    // Combo window is 1.5 seconds
    final newCombo = s.comboTimer > 0 ? s.combo + 1 : 1;
    final points = s.scoreFor(basePoints) * (newCombo > 1 ? newCombo - 1 : 1);
    emit(s.copyWith(score: s.score + points, combo: newCombo, comboTimer: 1.5));
  }

  // ── lives ──────────────────────────────────────────────────────────────────

  void loseLife() {
    final s = stateValue;
    if (s.isInvincible) return; // ignore hit during invincibility
    final newLives = s.lives - 1;
    emit(
      s.copyWith(
        lives: newLives,
        phase: newLives <= 0 ? GamePhase.gameOver : GamePhase.playing,
        isInvincible: newLives > 0, // grant invincibility frames if still alive
        invincibilityTimer: newLives > 0 ? 2.0 : 0.0,
        combo: 0,
        comboTimer: 0.0,
      ),
    );
  }

  // ── wave ───────────────────────────────────────────────────────────────────

  void nextWave() {
    emit(stateValue.copyWith(wave: stateValue.wave + 1));
  }

  // ── pause / resume ─────────────────────────────────────────────────────────

  void togglePause() {
    final s = stateValue;
    if (s.isGameOver) return;
    emit(s.copyWith(phase: s.isPlaying ? GamePhase.paused : GamePhase.playing));
  }

  void resume() {
    if (stateValue.isPaused) {
      emit(stateValue.copyWith(phase: GamePhase.playing));
    }
  }

  // ── per-frame timers — called from Game.tick ───────────────────────────────

  void tickTimers(double dt) {
    final s = stateValue;
    if (!s.isPlaying) return;

    var newInvincible = s.isInvincible;
    var newInvTimer = s.invincibilityTimer;
    var newComboTimer = s.comboTimer;
    var newCombo = s.combo;

    if (s.isInvincible) {
      newInvTimer -= dt;
      if (newInvTimer <= 0) {
        newInvTimer = 0.0;
        newInvincible = false;
      }
    }

    if (s.comboTimer > 0) {
      newComboTimer -= dt;
      if (newComboTimer <= 0) {
        newComboTimer = 0.0;
        newCombo = 0;
      }
    }

    // Only emit if something actually changed (CubitSignal deduplicates on ==)
    if (newInvincible != s.isInvincible ||
        newInvTimer != s.invincibilityTimer ||
        newComboTimer != s.comboTimer ||
        newCombo != s.combo) {
      emit(
        s.copyWith(
          isInvincible: newInvincible,
          invincibilityTimer: newInvTimer,
          comboTimer: newComboTimer,
          combo: newCombo,
        ),
      );
    }
  }

  // ── reset ──────────────────────────────────────────────────────────────────

  void reset() => emit(kInitialGameState);
}
