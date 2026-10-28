import 'package:flutter_timezone/flutter_timezone.dart';

/// Header carrying the device's IANA timezone (e.g. `America/New_York`).
///
/// The backend decides every calendar date (today's stats, default log dates,
/// challenge days) in this timezone, and rejects requests without it (422).
/// Read on every call so a timezone change while travelling applies immediately.
Future<Map<String, String>> timezoneHeader() async {
  final tz = await FlutterTimezone.getLocalTimezone();
  return {'X-Timezone': tz.identifier};
}

/// The user's local calendar date as `YYYY-MM-DD`.
String localIsoDate([DateTime? at]) {
  final d = (at ?? DateTime.now()).toLocal();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
