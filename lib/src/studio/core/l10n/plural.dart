/// Arabic count phrases for 1, 2, 3 to 10 and 11 and over.
///
/// `one` and `two` are the whole phrase ("بوست", "بوستين"); `few` and `many`
/// get the number in front ("3 بوستات", "12 بوست"). Zero uses `many`'s noun
/// unless the caller handles it first.
String arCount(
  int n, {
  required String one,
  required String two,
  required String few,
  required String many,
}) {
  if (n == 1) return one;
  if (n == 2) return two;
  if (n >= 3 && n <= 10) return '$n $few';
  return '$n $many';
}
