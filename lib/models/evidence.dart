class Evidence {
  final String id;
  final String title;
  final String description;
  final String reveal;
  final bool isKeyEvidence;

  const Evidence({
    required this.id,
    required this.title,
    required this.description,
    required this.reveal,
    this.isKeyEvidence = false,
  });
}
