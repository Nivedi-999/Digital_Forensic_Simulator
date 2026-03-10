// lib/services/tutorial_service.dart

enum TutorialStep {
  none,
  welcomeToHub,
  exploreFeeds,
  viewEvidence,
  markEvidence,
  decryptionHint,
  flagSuspect,
  completed,
}

class AriaMessage {
  final String text;
  final TutorialStep step;

  const AriaMessage({required this.text, required this.step});
}

class TutorialService {
  static final TutorialService _instance = TutorialService._internal();
  factory TutorialService() => _instance;
  TutorialService._internal();

  TutorialStep _currentStep = TutorialStep.welcomeToHub;
  bool _isActive = true; // Only active during GhostTrace (tutorial case)
  bool _messageShown = false;

  TutorialStep get currentStep => _currentStep;
  bool get isActive => _isActive;
  bool get messageShown => _messageShown;

  void setMessageShown(bool val) => _messageShown = val;

  void advance(TutorialStep step) {
    // Only move forward, never backward
    if (step.index > _currentStep.index) {
      _currentStep = step;
      _messageShown = false;
    }
  }

  void reset() {
    _currentStep = TutorialStep.welcomeToHub;
    _isActive = true;
    _messageShown = false;
  }

  void complete() {
    _currentStep = TutorialStep.completed;
    _isActive = false;
  }

  AriaMessage? getMessageForStep(TutorialStep step) {
    switch (step) {
      case TutorialStep.welcomeToHub:
        return const AriaMessage(
          text: "...Signal acquired.\nI am ARIA. I will be your eyes in the dark.\nThe truth is buried here — start digging.",
          step: TutorialStep.welcomeToHub,
        );
      case TutorialStep.exploreFeeds:
        return const AriaMessage(
          text: "The feed panels above hold fragments of the breach.\nChat logs. Files. Metadata. IP traces.\nEach hides something. Tap one.",
          step: TutorialStep.exploreFeeds,
        );
      case TutorialStep.viewEvidence:
        return const AriaMessage(
          text: "You've found a thread.\nRead carefully — not everything is what it seems.\nWhen something is suspicious... mark it.",
          step: TutorialStep.viewEvidence,
        );
      case TutorialStep.markEvidence:
        return const AriaMessage(
          text: "Evidence collected.\nGood instinct.\nKeep building your chain — you'll need at least 3 solid links to close this case.",
          step: TutorialStep.markEvidence,
        );
      case TutorialStep.decryptionHint:
        return const AriaMessage(
          text: "There's an encrypted string hiding in plain sight.\nCaesar knew how to hide things... but so do I.\nFind the 'Unlock Hidden Clue' button.",
          step: TutorialStep.decryptionHint,
        );
      case TutorialStep.flagSuspect:
        return const AriaMessage(
          text: "A trace is forming.\nYou're on to something — keep pulling the thread.\nRemember- at least 3 solid evidences.\nDon't stop now.",
          step: TutorialStep.flagSuspect,
        );
      default:
        return null;
    }
  }

  /// Call this when user opens the Investigation Hub
  void onHubOpened() {
    if (_currentStep == TutorialStep.welcomeToHub) {
      _messageShown = false;
    }
  }

  /// Call this when user taps any evidence feed button
  void onFeedTapped() {
    if (_currentStep == TutorialStep.welcomeToHub ||
        _currentStep == TutorialStep.exploreFeeds) {
      advance(TutorialStep.viewEvidence);
    }
  }

  /// Call this when user marks evidence as relevant
  void onEvidenceMarked() {
    advance(TutorialStep.markEvidence);
  }

  /// Call this after marking first evidence - nudge toward decryption
  void onReadyForDecryption() {
    if (_currentStep == TutorialStep.markEvidence) {
      advance(TutorialStep.decryptionHint);
    }
  }

  /// Call this when user has enough evidence to flag
  void onReadyToFlag(int evidenceCount) {
    if (evidenceCount >= 2 && _currentStep.index < TutorialStep.flagSuspect.index) {
      advance(TutorialStep.flagSuspect);
    }
  }
}