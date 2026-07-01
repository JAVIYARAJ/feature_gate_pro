/// A lightweight semantic version comparator to avoid external dependencies.
class VersionComparator {
  /// Compares [v1] and [v2].
  /// Returns:
  /// -1 if v1 < v2
  ///  0 if v1 == v2
  ///  1 if v1 > v2
  static int compare(String v1, String v2) {
    final segments1 = _parseSegments(v1);
    final segments2 = _parseSegments(v2);

    final maxLength = segments1.length > segments2.length ? segments1.length : segments2.length;

    for (int i = 0; i < maxLength; i++) {
      final part1 = i < segments1.length ? segments1[i] : 0;
      final part2 = i < segments2.length ? segments2[i] : 0;

      if (part1 < part2) return -1;
      if (part1 > part2) return 1;
    }

    return 0;
  }

  /// Evaluates the comparison based on the [operator].
  static bool evaluate(String v1, String operator, String v2) {
    final result = compare(v1, v2);

    switch (operator) {
      case '==':
        return result == 0;
      case '!=':
        return result != 0;
      case '>':
        return result > 0;
      case '>=':
        return result >= 0;
      case '<':
        return result < 0;
      case '<=':
        return result <= 0;
      default:
        return false;
    }
  }

  static List<int> _parseSegments(String version) {
    // Remove 'v' prefix if exists (e.g. "v1.2.3" -> "1.2.3")
    var cleanVersion = version.toLowerCase().trim();
    if (cleanVersion.startsWith('v')) {
      cleanVersion = cleanVersion.substring(1);
    }

    // Split by '.' and parse to int
    return cleanVersion.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  }
}
