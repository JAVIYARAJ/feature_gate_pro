/// Represents the evaluated value of a feature flag.
class FlagValue {
  final dynamic _value;

  const FlagValue(this._value);

  bool get asBool => _value is bool ? _value : false;
  int get asInt => _value is int ? _value : 0;
  double get asDouble => _value is double ? _value : 0.0;
  String get asString => _value is String ? _value : '';
  List<dynamic> get asList => _value is List<dynamic> ? _value : [];
  Map<String, dynamic> get asJson => _value is Map<String, dynamic> ? _value : {};
  dynamic get asDynamic => _value;
  
  bool get isNull => _value == null;

  /// Serializes the value to a dynamic object safe for JSON
  dynamic toJson() => _value;

  /// Deserializes the value from a JSON dynamic object
  factory FlagValue.fromJson(dynamic json) => FlagValue(json);
}
