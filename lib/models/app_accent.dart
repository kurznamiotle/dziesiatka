/// The accent color of the app. Every one but [indigo] comes with
/// Dziesiątka+. The colors themselves are in `lib/views/app_theme.dart`.
enum AppAccent {
  indigo('Indygo'),
  teal('Morski'),
  rose('Malinowy'),
  amber('Bursztynowy'),
  forest('Leśny');

  const AppAccent(this.label);

  static const standard = AppAccent.indigo;

  final String label;

  bool get needsPlus => this != standard;
}
