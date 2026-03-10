// lib/state/case_engine_provider.dart
// ═══════════════════════════════════════════════════════════════
//  CaseEngineProvider — InheritedWidget for reactive subtrees.
//  Also registers the engine in ActiveCase so screens outside
//  the subtree (pushed by AppShell bottom-nav) can still reach it.
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../logic/game_engine.dart';
import 'active_case.dart';

class CaseEngineProvider extends InheritedNotifier<CaseEngine> {
  CaseEngineProvider({
    super.key,
    required CaseEngine engine,
    required super.child,
  }) : super(notifier: engine) {
    // Register globally so routes pushed outside this subtree can find it
    ActiveCase.set(engine);
  }

  /// Reactive read — widget rebuilds when engine calls notifyListeners().
  /// Falls back to ActiveCase if there's no provider ancestor.
  static CaseEngine of(BuildContext context) {
    final provider =
    context.dependOnInheritedWidgetOfExactType<CaseEngineProvider>();
    if (provider != null) return provider.notifier!;
    // Fallback: screen was pushed outside the provider subtree
    return ActiveCase.engine;
  }

  /// One-shot read — no rebuild subscription.
  /// Falls back to ActiveCase if there's no provider ancestor.
  static CaseEngine read(BuildContext context) {
    final provider =
    context.getInheritedWidgetOfExactType<CaseEngineProvider>();
    if (provider != null) return provider.notifier!;
    return ActiveCase.engine;
  }
}