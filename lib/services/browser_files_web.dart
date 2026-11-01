import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

void downloadTextFile(String fileName, String text) {
  final blob = web.Blob(
    [text.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..click();
  web.URL.revokeObjectURL(url);
}

/// Returns the chosen file's text, or null if the user cancelled.
Future<String?> pickTextFile() {
  final result = Completer<String?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.json,.txt';

  input.onchange = ((web.Event _) {
    final file = input.files?.item(0);
    if (file == null) {
      result.complete(null);
      return;
    }
    file.text().toDart.then(
      (text) => result.complete(text.toDart),
      onError: result.completeError,
    );
  }).toJS;
  input.oncancel = ((web.Event _) => result.complete(null)).toJS;

  input.click();
  return result.future;
}
