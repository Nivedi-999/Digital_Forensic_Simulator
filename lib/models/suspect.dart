class Suspect {
  final String id;
  final String name;
  final String role;
  final String description;
  final bool isActualCulprit;

  const Suspect({
    required this.id,
    required this.name,
    required this.role,
    required this.description,
    this.isActualCulprit = false,
  });
}
