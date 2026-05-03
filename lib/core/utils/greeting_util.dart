/// Local greeting for home — no auth yet.
/// TODO: personalize when [User authentication] ships.
String greetingForNow(DateTime now) {
  final h = now.hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}
