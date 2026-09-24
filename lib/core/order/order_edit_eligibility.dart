/// Mirrors website `orderEditEligibility.ts` — edit allowed only for
/// pending/processing orders with ≥4 hours before slot start.
const orderEditCutoffHours = 4;

/// Parse delivery_time like:
/// - "Fri, Jul 24 · 8:00–11:00 AM"
/// - "Thu 24 Sep · Morning - 8.00 AM - 11.00 AM"
DateTime? parseDeliverySlotStart(
  String? deliveryTime, {
  String? referenceDate,
}) {
  if (deliveryTime == null || deliveryTime.trim().isEmpty) return null;
  final raw = deliveryTime.trim();
  final timeMatch = RegExp(
    r'(\d{1,2}[.:]\d{2})\s*([AaPp][Mm])?\s*[-–—]\s*(\d{1,2}[.:]\d{2})\s*([AaPp][Mm])',
  ).firstMatch(raw);
  if (timeMatch == null) return null;

  final startClock = timeMatch.group(1)!.replaceAll('.', ':');
  final endMeridiem = timeMatch.group(4)!.toUpperCase();
  final startMeridiem = (timeMatch.group(2) ?? endMeridiem).toUpperCase();

  final datePart = raw.split('·').first.trim().replaceAll(RegExp(r',\s*$'), '');
  final ref = referenceDate != null
      ? DateTime.tryParse(referenceDate) ?? DateTime.now()
      : DateTime.now();
  final year = ref.year;

  final parts = startClock.split(':');
  var hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  if (startMeridiem == 'PM' && hours < 12) hours += 12;
  if (startMeridiem == 'AM' && hours == 12) hours = 0;

  final parsed = _parseLooseDate(datePart, fallbackYear: year);
  if (parsed == null) return null;

  var result = DateTime(parsed.year, parsed.month, parsed.day, hours, minutes);
  if (result.isBefore(DateTime.now().subtract(const Duration(days: 180))) &&
      !RegExp(r'\d{4}').hasMatch(datePart)) {
    result = DateTime(year + 1, parsed.month, parsed.day, hours, minutes);
  }
  return result;
}

DateTime? _parseLooseDate(String input, {required int fallbackYear}) {
  const months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  // "Fri, Jul 24" / "Jul 24, 2026"
  final monthFirst = RegExp(
    r'(?:[A-Za-z]{3},\s*)?([A-Za-z]{3})\s+(\d{1,2})(?:,?\s*(\d{4}))?',
  ).firstMatch(input);
  if (monthFirst != null) {
    final month = months[monthFirst.group(1)!.toLowerCase()];
    final day = int.tryParse(monthFirst.group(2)!);
    final year =
        int.tryParse(monthFirst.group(3) ?? '') ?? fallbackYear;
    if (month != null && day != null) return DateTime(year, month, day);
  }

  // "Thu 24 Sep" / "24 Sep 2026" (Flutter checkout format)
  final dayFirst = RegExp(
    r'(?:[A-Za-z]{3}\s+)?(\d{1,2})\s+([A-Za-z]{3})(?:\s+(\d{4}))?',
  ).firstMatch(input);
  if (dayFirst != null) {
    final day = int.tryParse(dayFirst.group(1)!);
    final month = months[dayFirst.group(2)!.toLowerCase()];
    final year = int.tryParse(dayFirst.group(3) ?? '') ?? fallbackYear;
    if (month != null && day != null) return DateTime(year, month, day);
  }

  final withYear =
      RegExp(r'\d{4}').hasMatch(input) ? input : '$input, $fallbackYear';
  return DateTime.tryParse(withYear);
}

DateTime? getOrderEditCutoffAt({
  required String? deliveryTime,
  String? createdAt,
}) {
  final slot = parseDeliverySlotStart(deliveryTime, referenceDate: createdAt);
  if (slot == null) return null;
  return slot.subtract(const Duration(hours: orderEditCutoffHours));
}

bool _isEditableStatus(String? status) {
  final key = (status ?? '').toLowerCase().replaceAll('_', '-');
  return key.contains('pending') || key.contains('processing') || key.isEmpty;
}

bool canEditOrder({
  required String? status,
  required String? deliveryTime,
  String? createdAt,
  DateTime? now,
}) {
  if (!_isEditableStatus(status)) return false;

  final cutoff = getOrderEditCutoffAt(
    deliveryTime: deliveryTime,
    createdAt: createdAt,
  );
  final clock = now ?? DateTime.now();

  // Prefer website rule when slot is parseable.
  if (cutoff != null) {
    return !clock.isAfter(cutoff);
  }

  // Fallback: pending/processing without a parseable slot stay editable
  // for 48h after creation (covers alternate API time formats).
  final created = createdAt != null ? DateTime.tryParse(createdAt) : null;
  if (created == null) return true;
  return clock.isBefore(created.add(const Duration(hours: 48)));
}
