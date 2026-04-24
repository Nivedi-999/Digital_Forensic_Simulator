// lib/screens/leaderboard_screen.dart
// ═══════════════════════════════════════════════════════════════
//  LEADERBOARD — real-time fastest solvers for a given case
//  Reads from: leaderboard/{caseId}/scores/{uid}
//  Ordered by: timeTakenSeconds ASC (fastest first)
// ═══════════════════════════════════════════════════════════════

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cyber_theme.dart';
import '../services/progress_service.dart';

class LeaderboardScreen extends StatelessWidget {
  final String caseId;
  const LeaderboardScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF040A0F),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────
            _LeaderboardTopBar(caseId: caseId),

            // ── Live stream from Firestore ─────────────────
            Expanded(
              child: StreamBuilder<List<LeaderboardEntry>>(
                stream: ProgressService.instance.leaderboardStream(caseId),
                builder: (context, snap) {
                  // Loading state
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: _CyberLoader(),
                    );
                  }

                  // Error state
                  if (snap.hasError) {
                    return Center(
                      child: _ErrorPane(error: snap.error.toString()),
                    );
                  }

                  final entries = snap.data ?? [];

                  // Empty state
                  if (entries.isEmpty) {
                    return const _EmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final entry  = entries[i];
                      final isMe   = entry.uid == myUid;
                      final rank   = i + 1;
                      return _LeaderboardRow(
                        entry: entry,
                        rank: rank,
                        isCurrentUser: isMe,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────────────────────

class _LeaderboardTopBar extends StatelessWidget {
  final String caseId;
  const _LeaderboardTopBar({required this.caseId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: CyberColors.neonCyan.withOpacity(0.12))),
      ),
      child: Row(children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CyberColors.neonCyan.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: CyberColors.neonCyan.withOpacity(0.25)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: CyberColors.neonCyan, size: 14),
          ),
        ),
        const SizedBox(width: 14),
        // FIX: wrap title column in Flexible so long caseIds don't overflow
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LEADERBOARD',
                  style: GoogleFonts.orbitron(
                      fontSize: 15,
                      color: CyberColors.neonCyan,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
              Text(
                'CASE #$caseId — FASTEST SOLVERS',
                style: GoogleFonts.shareTechMono(
                    fontSize: 8,
                    color: CyberColors.textMuted,
                    letterSpacing: 1.5),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        const Spacer(),
        // Live indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
              color: CyberColors.neonGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: CyberColors.neonGreen.withOpacity(0.3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _PulseDot(color: CyberColors.neonGreen),
            const SizedBox(width: 5),
            Text('LIVE',
                style: GoogleFonts.shareTechMono(
                    fontSize: 8,
                    color: CyberColors.neonGreen,
                    letterSpacing: 1.5)),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  LEADERBOARD ROW
// ─────────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isCurrentUser;

  const _LeaderboardRow({
    required this.entry,
    required this.rank,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final medal  = _medalFor(rank);
    final accent = isCurrentUser ? CyberColors.neonCyan : _rankColor(rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? CyberColors.neonCyan.withOpacity(0.06)
            : CyberColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentUser
              ? CyberColors.neonCyan.withOpacity(0.4)
              : rank <= 3
              ? accent.withOpacity(0.3)
              : CyberColors.borderSubtle,
          width: isCurrentUser ? 1.5 : 1,
        ),
        boxShadow: isCurrentUser
            ? [
          BoxShadow(
              color: CyberColors.neonCyan.withOpacity(0.08),
              blurRadius: 12)
        ]
            : null,
      ),
      child: Row(children: [
        // Rank / medal — fixed width, never shrinks
        SizedBox(
          width: 40,
          child: medal != null
              ? Text(medal,
              style: const TextStyle(fontSize: 22),
              textAlign: TextAlign.center)
              : Text('#$rank',
              style: GoogleFonts.orbitron(
                  fontSize: 12,
                  color: CyberColors.textMuted,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
        ),

        const SizedBox(width: 12),

        // Avatar circle — fixed size
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withOpacity(0.1),
            border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
          ),
          child: Center(
            child: Text(
              entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : '?',
              style: GoogleFonts.orbitron(
                  fontSize: 15,
                  color: accent,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // FIX: Name + stars in Expanded — long names were pushing time column off screen
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                // FIX: displayName in Flexible so it ellipsis before hitting the YOU badge
                Flexible(
                  child: Text(
                    entry.displayName,
                    style: GoogleFonts.orbitron(
                        fontSize: 12,
                        color: isCurrentUser
                            ? CyberColors.neonCyan
                            : CyberColors.textPrimary,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 6),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                          color: CyberColors.neonCyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                              color: CyberColors.neonCyan.withOpacity(0.4))),
                      child: Text('YOU',
                          style: GoogleFonts.shareTechMono(
                              fontSize: 7,
                              color: CyberColors.neonCyan,
                              letterSpacing: 1))),
                ],
              ]),
              const SizedBox(height: 3),
              // Star rating
              Row(children: List.generate(3, (i) {
                final filled = i < entry.score;
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled
                        ? CyberColors.neonAmber
                        : CyberColors.textMuted.withOpacity(0.3),
                    size: 13,
                  ),
                );
              })),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // FIX: time column constrained so it never overflows on narrow screens
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 90),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              entry.formattedTime,
              style: GoogleFonts.orbitron(
                  fontSize: 16,
                  color: accent,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  shadows: rank == 1
                      ? [Shadow(color: accent.withOpacity(0.6), blurRadius: 10)]
                      : null),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text('MM:SS',
                style: GoogleFonts.shareTechMono(
                    fontSize: 7, color: CyberColors.textMuted, letterSpacing: 1)),
          ]),
        ),
      ]),
    );
  }

  String? _medalFor(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return null;
    }
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1: return const Color(0xFFFFD700);   // gold
      case 2: return const Color(0xFFC0C0C0);   // silver
      case 3: return const Color(0xFFCD7F32);   // bronze
      default: return CyberColors.textMuted;
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CyberColors.neonCyan.withOpacity(0.06),
              border: Border.all(
                  color: CyberColors.neonCyan.withOpacity(0.25), width: 1.5),
            ),
            child: const Icon(Icons.emoji_events_outlined,
                color: CyberColors.neonCyan, size: 36),
          ),
          const SizedBox(height: 20),
          Text('NO SCORES YET',
              style: GoogleFonts.orbitron(
                  fontSize: 14,
                  color: CyberColors.neonCyan,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          Text('Be the first to solve this case.',
              style: GoogleFonts.shareTechMono(
                  fontSize: 11, color: CyberColors.textMuted)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ERROR PANE
// ─────────────────────────────────────────────────────────────

class _ErrorPane extends StatelessWidget {
  final String error;
  const _ErrorPane({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.wifi_off_rounded,
              color: CyberColors.neonRed.withOpacity(0.7), size: 40),
          const SizedBox(height: 14),
          Text('LEADERBOARD UNAVAILABLE',
              style: GoogleFonts.orbitron(
                  fontSize: 12,
                  color: CyberColors.neonRed,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Text('Check your connection and try again.',
              style: GoogleFonts.shareTechMono(
                  fontSize: 10, color: CyberColors.textMuted),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CYBER LOADER
// ─────────────────────────────────────────────────────────────

class _CyberLoader extends StatelessWidget {
  const _CyberLoader();

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: const AlwaysStoppedAnimation(CyberColors.neonCyan),
        ),
      ),
      const SizedBox(height: 14),
      Text('FETCHING SCORES...',
          style: GoogleFonts.shareTechMono(
              fontSize: 10, color: CyberColors.textMuted, letterSpacing: 1.5)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  PULSE DOT — animated breathing green dot for LIVE badge
// ─────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(_anim.value),
          boxShadow: [
            BoxShadow(
                color: widget.color.withOpacity(_anim.value * 0.8),
                blurRadius: 4,
                spreadRadius: 1),
          ],
        ),
      ),
    );
  }
}