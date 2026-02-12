class GameProgress {
  static int xp = 0;           // total XP
  static int rankLevel = 1;    // 1 = Junior, 2 = Analyst, etc.
  static String rankName = 'Junior Analyst';

  static void addXp(int amount) {
    xp += amount;
    // Simple rank progression example (customize thresholds)
    if (xp >= 100 && rankLevel == 1) {
      rankLevel = 2;
      rankName = 'Analyst';
    } else if (xp >= 300 && rankLevel == 2) {
      rankLevel = 3;
      rankName = 'Senior Analyst';
    }
    // add more ranks as needed
  }

  static void reset() {
    xp = 0;
    rankLevel = 1;
    rankName = 'Junior Analyst';
  }
}