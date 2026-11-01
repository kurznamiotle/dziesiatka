/// The admin panel runs only in a browser. This stands in elsewhere, so the
/// code around it can still be compiled and tested.
void downloadTextFile(String fileName, String text) {
  throw UnsupportedError('Pobieranie działa tylko w przeglądarce.');
}

Future<String?> pickTextFile() {
  throw UnsupportedError('Wybór pliku działa tylko w przeglądarce.');
}
