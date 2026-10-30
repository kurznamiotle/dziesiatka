import 'dart:ui' as ui;

import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/share_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/category_artwork.dart';
import 'package:dziesiatka/views/category_badge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const _shareTitle = 'Dziesiątka - Ciekawostka na dziś';
const _fileName = 'dziesiatka-story.png';

// Laid out at a third of the final 1080 x 1920 px, so the image looks the same
// however large the preview is on a given screen.
const _imageSize = Size(360, 640);
const _imagePixelRatio = 3.0;
const _previewMaxWidth = 260.0;

// Stories cover about 250 px at the top and 340 px at the bottom of the image
// with their own controls. The card keeps equal margins to stay centered.
const _bottomSafeZone = 114.0;
const _cardVerticalMargin = 136.0;

/// Previews a fact as a branded image and shares that image.
class ShareCardSheet extends StatefulWidget {
  const ShareCardSheet({
    super.key,
    required this.fact,
    this.shareService = const ShareService(),
  });

  static Future<void> show(BuildContext context, Fact fact) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      // useSafeArea leaves the bottom inset to the sheet's content.
      builder: (_) => SafeArea(top: false, child: ShareCardSheet(fact: fact)),
    );
  }

  final Fact fact;
  final ShareService shareService;

  @override
  State<ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<ShareCardSheet> {
  final _imageKey = GlobalKey();
  final _buttonKey = GlobalKey();
  bool _isWorking = false;
  String? _message;
  bool _isError = false;

  Future<Uint8List> _captureImage() async {
    final boundary =
        _imageKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: _imagePixelRatio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Rect _buttonRect() {
    final button = _buttonKey.currentContext!.findRenderObject()! as RenderBox;
    return button.localToGlobal(Offset.zero) & button.size;
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String failureMessage,
    String? successMessage,
  }) async {
    setState(() {
      _isWorking = true;
      _message = null;
    });

    var failed = false;
    try {
      await action();
    } catch (_) {
      failed = true;
    }

    if (!mounted) return;
    setState(() {
      _isWorking = false;
      _isError = failed;
      _message = failed ? failureMessage : successMessage;
    });
  }

  Future<void> _share() {
    return _run(() async {
      await widget.shareService.shareImage(
        await _captureImage(),
        fileName: _fileName,
        title: _shareTitle,
        origin: _buttonRect(),
      );
    }, failureMessage: 'Nie udało się udostępnić grafiki.');
  }

  Future<void> _save() {
    return _run(
      () async => widget.shareService.saveImage(
        await _captureImage(),
        fileName: _fileName,
      ),
      failureMessage: 'Nie udało się zapisać grafiki.',
      successMessage: kIsWeb ? 'Pobrano grafikę.' : 'Zapisano w galerii.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final message = _message;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _previewMaxWidth),
            child: AspectRatio(
              aspectRatio: _imageSize.aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FittedBox(
                  child: RepaintBoundary(
                    key: _imageKey,
                    child: SizedBox.fromSize(
                      size: _imageSize,
                      // The shared image does not follow the app's theme.
                      child: Theme(
                        data: AppTheme.light,
                        child: _ShareImage(fact: widget.fact),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (message != null) ...[
            Text(
              message,
              style: TextStyle(
                color: _isError ? colors.error : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            key: _buttonKey,
            onPressed: _isWorking ? null : _share,
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Udostępnij grafikę'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isWorking ? null : _save,
            icon: const Icon(Icons.download_rounded),
            label: const Text(kIsWeb ? 'Pobierz obrazek' : 'Zapisz w galerii'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareImage extends StatelessWidget {
  const _ShareImage({required this.fact});

  final Fact fact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final surfaces = theme.extension<AppSurfaces>()!;
    // The image keeps its layout whatever text size the device uses.
    return MediaQuery.withNoTextScaling(
      child: CategoryArtwork(
        category: fact.category,
        iconSize: 300,
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: _cardVerticalMargin,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: surfaces.card,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CategoryBadge(category: fact.category),
                        const SizedBox(height: 16),
                        Text(
                          fact.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          fact.shortText,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              // Lines up with the card's text, clear of the category icon.
              left: 48,
              bottom: _bottomSafeZone,
              child: Text(
                'Dziesiątka',
                style: textTheme.titleSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
