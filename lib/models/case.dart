import 'evidence.dart';
import 'suspect.dart';

enum CaseOutcome {
  perfect,
  partial,
  wrongAccusation,
  coldCase,
  framed,
}

class CaseFile {
  final String id;
  final String title;
  final String shortDescription;
  final String fullStory;

  final List<Evidence> evidences;
  final List<Suspect> suspects;

  const CaseFile({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.fullStory,
    required this.evidences,
    required this.suspects,
  });
}
