class EvidenceItem {
  final String label;
  final int count;

  EvidenceItem({required this.label, required this.count});
}

class EvidencePreview {
  final String message;
  final String ip;
  final String time;

  EvidencePreview({
    required this.message,
    required this.ip,
    required this.time,
  });
}

class Suspect {
  final String name;
  final String risk;
  final String riskLevel; // high, medium, low

  Suspect({
    required this.name,
    required this.risk,
    required this.riskLevel,
  });
}

class TimelineEvent {
  final String time;
  final String title;
  final String description;

  TimelineEvent({
    required this.time,
    required this.title,
    required this.description,
  });
}

class DecryptionPuzzle {
  final String cipherText;
  final String hint;
  final String solution;
  final String unlockedFilename;

  DecryptionPuzzle({
    required this.cipherText,
    required this.hint,
    required this.solution,
    required this.unlockedFilename,
  });
}

class CaseData {
  final String caseId;
  final String status;
  final String duration;
  final List<EvidenceItem> evidenceFeed;
  final EvidencePreview preview;
  final List<Suspect> suspects;
  final List<TimelineEvent> timeline;
  final DecryptionPuzzle attachmentPuzzle;

  CaseData({
    required this.caseId,
    required this.status,
    required this.duration,
    required this.evidenceFeed,
    required this.preview,
    required this.suspects,
    required this.timeline,
    required this.attachmentPuzzle,
  });
}

// ------------------- CASE DATA -------------------

final ghostTraceCase = CaseData(
  caseId: "2047",
  status: "Active",
  duration: "1h 32m",
  evidenceFeed: [
    EvidenceItem(label: "Chat Logs", count: 12),
    EvidenceItem(label: "Files", count: 6),
    EvidenceItem(label: "Metadata", count: 4),
    EvidenceItem(label: "IP Traces", count: 3),
  ],
  preview: EvidencePreview(
    message:
    "@ghost → admin\nfor the next phase, transfer the funds to the offshore account we discussed.",
    ip: "202.56.23.101",
    time: "22 Jan 2024 • 10:45 AM",
  ),
  suspects: [
    Suspect(name: "Dhruv A", risk: "High", riskLevel: "high"),
    Suspect(name: "Ankita E", risk: "Medium", riskLevel: "medium"),
    Suspect(name: "Manav R", risk: "Medium", riskLevel: "medium"),
    Suspect(name: "Ayon K", risk: "Low", riskLevel: "low"),
  ],
  timeline: [
    TimelineEvent(
      time: "10:45 AM",
      title: "Suspicious IP Activity",
      description: "Login detected from 202.56.23.101",
    ),
    TimelineEvent(
      time: "09:32 AM",
      title: "New Device Login",
      description: "Access from unknown workstation",
    ),
    TimelineEvent(
      time: "08:15 AM",
      title: "Deleted Files",
      description: "Files removed on system 4D-32",
    ),
  ],
  attachmentPuzzle: DecryptionPuzzle(
    cipherText: "Dwwdfkphqw",
    hint: "Caesar shift by -3. Decode to unlock the filename.",
    solution: "Attachment",
    unlockedFilename: "ghosttrace_briefing.pdf",
  ),
);

class GameProgress {
  static bool isBriefingUnlocked = false;

  static void unlockBriefing() {
    isBriefingUnlocked = true;
  }

  static void reset() {
    isBriefingUnlocked = false;
  }
}