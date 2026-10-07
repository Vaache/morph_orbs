/// What the orb is showing. Continuous states loop; terminal states play a
/// short settle and then hold still.
enum MorphOrbState {
  idle,
  thinking,
  processing,
  generating,
  success,
  error,
  stopped;

  bool get isTerminal => this == success || this == error || this == stopped;

  bool get isContinuous => !isTerminal;

  String get defaultSemanticsLabel => switch (this) {
    MorphOrbState.idle => 'Idle',
    MorphOrbState.thinking => 'Thinking',
    MorphOrbState.processing => 'Processing',
    MorphOrbState.generating => 'Generating',
    MorphOrbState.success => 'Done',
    MorphOrbState.error => 'Failed',
    MorphOrbState.stopped => 'Stopped',
  };
}
