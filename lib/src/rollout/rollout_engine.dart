import '../core/user_context.dart';

/// A deterministic hashing engine for percentage rollouts.
class RolloutEngine {
  /// Evaluates whether a user falls into the rollout bucket for a given flag.
  static bool evaluate(String flagKey, int rolloutPercentage, UserContext? context) {
    if (rolloutPercentage <= 0) return false;
    if (rolloutPercentage >= 100) return true;
    if (context == null) return false; // Missing user context means they fail the rollout

    final combinedKey = '$flagKey-${context.id}';
    final hash = _fnv1a(combinedKey);
    final bucket = (hash.abs() % 100) + 1; // 1 to 100
    
    return bucket <= rolloutPercentage;
  }

  /// FNV-1a 32-bit string hashing algorithm.
  /// This ensures that the same user ID always hashes to the same bucket
  /// across different app sessions and platforms.
  static int _fnv1a(String text) {
    int hash = 0x811c9dc5;
    for (int i = 0; i < text.length; i++) {
      hash ^= text.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}
