DateTime parseDate(dynamic value) => DateTime.parse(value as String);

DateTime? parseOptionalDate(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.parse(value as String);
}

double readDouble(Map<String, dynamic> map, String key) =>
    (map[key] as num).toDouble();

int readInt(Map<String, dynamic> map, String key) => (map[key] as num).toInt();

String? blankToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

double? tryParseDecimal(String? value) {
  final normalized = (value ?? '').trim().replaceAll(',', '.');
  return double.tryParse(normalized);
}

double parseDecimal(String value) =>
    double.parse(value.trim().replaceAll(',', '.'));
