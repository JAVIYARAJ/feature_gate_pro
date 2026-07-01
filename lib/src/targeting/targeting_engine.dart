import '../core/user_context.dart';
import 'version_comparator.dart';

/// Evaluates audience-based targeting rules against a UserContext.
class TargetingEngine {
  /// Evaluates an array of rules using strict AND logic.
  /// If the rule list is empty or null, it returns true (no targeting applied).
  static bool evaluate(List<dynamic>? rules, UserContext? context) {
    if (rules == null || rules.isEmpty) return true;
    
    // If there are targeting rules but no user context, they fail targeting.
    if (context == null) return false;

    for (final rule in rules) {
      if (rule is! Map<String, dynamic>) return false; // Malformed rule

      final attribute = rule['attribute']?.toString();
      final operator = rule['operator']?.toString();
      final targetValue = rule['value'];

      if (attribute == null || operator == null || targetValue == null) {
        return false; // Malformed rule
      }

      final contextValue = _extractContextValue(attribute, context);

      final passed = _evaluateRule(contextValue, operator, targetValue);
      if (!passed) return false; // AND logic: any failure fails all
    }

    return true;
  }

  static dynamic _extractContextValue(String attribute, UserContext context) {
    switch (attribute) {
      case 'id':
        return context.id;
      case 'email':
        return context.email;
      case 'country':
        return context.country;
      case 'language':
        return context.language;
      case 'platform':
        return context.platform;
      case 'appVersion':
        return context.appVersion;
      default:
        // Handle custom attributes (e.g. "custom.isPremium" or just "isPremium")
        String customKey = attribute;
        if (attribute.startsWith('custom.')) {
          customKey = attribute.substring(7);
        }
        return context.customAttributes[customKey];
    }
  }

  static bool _evaluateRule(dynamic contextValue, String operator, dynamic targetValue) {
    if (operator == 'in' || operator == 'not_in') {
      if (targetValue is! List) return false;
      
      final isInList = targetValue.contains(contextValue);
      return operator == 'in' ? isInList : !isInList;
    }

    if (contextValue == null) {
      if (operator == '==') return targetValue == null;
      if (operator == '!=') return targetValue != null;
      return false; // Missing value fails >=, <=, >, <
    }

    if (operator == '==') return contextValue == targetValue;
    if (operator == '!=') return contextValue != targetValue;

    // Numerical / String comparisons
    if (contextValue is num && targetValue is num) {
      switch (operator) {
        case '>': return contextValue > targetValue;
        case '<': return contextValue < targetValue;
        case '>=': return contextValue >= targetValue;
        case '<=': return contextValue <= targetValue;
      }
    }

    // Semantic Version comparisons
    if (contextValue is String && targetValue is String) {
      return VersionComparator.evaluate(contextValue, operator, targetValue);
    }

    return false;
  }
}
