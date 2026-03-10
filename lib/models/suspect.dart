// lib/models/suspect.dart

class DigitalFootprint {
  final String ipActivity;
  final String deviceUsage;
  final String locationTrace;
  final String vpnCheck;

  const DigitalFootprint({
    required this.ipActivity,
    required this.deviceUsage,
    required this.locationTrace,
    required this.vpnCheck,
  });

  factory DigitalFootprint.fromJson(Map<String, dynamic> json) {
    return DigitalFootprint(
      ipActivity: json['ipActivity'] as String,
      deviceUsage: json['deviceUsage'] as String,
      locationTrace: json['locationTrace'] as String,
      vpnCheck: json['vpnCheck'] as String,
    );
  }
}

class Suspect {
  final String id;
  final String name;
  final String role;
  final String department;
  final String riskLevel; // 'high' | 'medium' | 'low'
  final bool isGuilty;
  final DigitalFootprint? digitalFootprint;
  final String? profileNotes;

  const Suspect({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
    required this.riskLevel,
    required this.isGuilty,
    this.digitalFootprint,
    this.profileNotes,
  });

  // Convenience getter for UI compatibility with old riskLevel string
  String get risk {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      default:
        return 'Low';
    }
  }

  factory Suspect.fromJson(Map<String, dynamic> json) {
    final footprintJson = json['digitalFootprint'] as Map<String, dynamic>?;
    return Suspect(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      department: json['department'] as String? ?? '',
      riskLevel: json['riskLevel'] as String,
      isGuilty: json['isGuilty'] as bool,
      digitalFootprint: footprintJson != null
          ? DigitalFootprint.fromJson(footprintJson)
          : null,
      profileNotes: json['profileNotes'] as String?,
    );
  }
}