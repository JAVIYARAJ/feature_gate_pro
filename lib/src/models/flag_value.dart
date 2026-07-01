/// Represents the evaluated value of a feature flag.
class FlagValue {
  final dynamic _value;

  const FlagValue(this._value);

  /// Safely casts the underlying value to a boolean. Returns `false` if it is not a boolean.
  bool get asBool => _value is bool ? _value : false;
  
  /// Safely casts the underlying value to an integer. Returns `0` if it is not an integer.
  int get asInt => _value is int ? _value : 0;
  
  /// Safely casts the underlying value to a double. Returns `0.0` if it is not a double.
  double get asDouble => _value is double ? _value : 0.0;
  
  /// Safely casts the underlying value to a String. Returns `''` if it is not a String.
  String get asString => _value is String ? _value : '';
  
  /// Safely casts the underlying value to a List. Returns `[]` if it is not a List.
  List<dynamic> get asList => _value is List<dynamic> ? _value : [];
  
  /// Safely casts the underlying value to a Map (JSON object). Returns `{}` if it is not a Map.
  Map<String, dynamic> get asJson => _value is Map<String, dynamic> ? _value : {};
  
  /// Returns the raw underlying dynamic value.
  dynamic get asDynamic => _value;
  
  /// Returns `true` if the underlying value is exactly `null`.
  bool get isNull => _value == null;

  /// Serializes the value to a dynamic object safe for JSON
  dynamic toJson() => _value;

  /// Deserializes the value from a JSON dynamic object
  factory FlagValue.fromJson(dynamic json) => FlagValue(json);
}
