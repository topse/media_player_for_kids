import 'dart:typed_data';

import 'package:dart_couch/dart_couch.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:watch_it/watch_it.dart';

import '../models/datatypes.dart';

final Logger _log = Logger('MediaBaseIcon');

/// A widget that displays the cover image for a [MediaBase], falling back to a
/// type-appropriate icon when no cover is available.
///
/// Cover resolution is handled internally via
/// [MediaBase.resolveCoverImageAttachmentId]. Pass [allDocuments] whenever
/// folder cover resolution needs to follow references into child documents
/// (not required for [MediaItem]).
///
/// Set [showTypeBadge] to overlay a small coloured circular badge in the
/// top-right corner so the type (folder / item) is always visible even when
/// a cover image fills the widget.
class MediaBaseIcon extends StatefulWidget {
  final MediaBase media;

  /// All documents keyed by ID — required for folder cover resolution.
  /// Defaults to an empty map, which is sufficient for [MediaItem].
  final Map<String, MediaBase> allDocuments;

  final double iconSize;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// When true, overlays a small circular type-badge (folder = blue,
  /// item = orange) in the top-right corner.
  final bool showTypeBadge;

  /// When non-null, overlays this number centred over the icon or image.
  /// The number is always legible regardless of the underlying colours.
  final int? overlayNumber;

  /// When true, draws a golden glowing border around the icon to signal that
  /// this item (or a descendant) is marked as "new".
  final bool isNew;

  /// When true, overlays the glowing star marker used by the player grid.
  /// This is independent from [isNew] so callers can choose star-only,
  /// border-only, or both.
  final bool showNewStar;

  const MediaBaseIcon({
    super.key,
    required this.media,
    this.allDocuments = const {},
    this.iconSize = 48,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showTypeBadge = false,
    this.overlayNumber,
    this.isNew = false,
    this.showNewStar = false,
  });

  @override
  State<MediaBaseIcon> createState() => _MediaBaseIconState();
}

class _MediaBaseIconState extends State<MediaBaseIcon> {
  Uint8List? _imageData;
  bool _isLoading = false;

  /// The reference that was used to load the current [_imageData].
  CoverImageReference? _currentRef;

  @override
  void initState() {
    super.initState();
    _resolveAndLoad();
  }

  @override
  void didUpdateWidget(MediaBaseIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newRef = widget.media.resolveCoverImageAttachmentId(
      widget.allDocuments,
    );
    if (newRef?.documentId != _currentRef?.documentId ||
        newRef?.attachmentId != _currentRef?.attachmentId) {
      _resolveAndLoad();
    }
  }

  Future<void> _resolveAndLoad() async {
    _log.info(
      'Resolving and loading cover image for ${widget.media.name} (${widget.media.id})',
    );
    final ref = widget.media.resolveCoverImageAttachmentId(widget.allDocuments);
    _currentRef = ref;

    if (ref == null) {
      if (mounted)
        setState(() {
          _imageData = null;
          _isLoading = false;
        });
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    final data = await di<DartCouchDb>().getAttachment(
      ref.documentId,
      ref.attachmentId,
    );

    // Ignore stale responses if a newer load was triggered in the meantime.
    if (mounted &&
        _currentRef?.documentId == ref.documentId &&
        _currentRef?.attachmentId == ref.attachmentId) {
      setState(() {
        _imageData = data;
        _isLoading = false;
      });
    }
  }

  bool get _isFolder => widget.media is MediaFolder;

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_imageData != null) {
      Widget image = Image.memory(
        _imageData!,
        width: double.infinity,
        height: double.infinity,
        fit: widget.fit,
      );
      if (widget.borderRadius != null) {
        image = ClipRRect(borderRadius: widget.borderRadius!, child: image);
      }
      return image;
    }
    return Center(
      child: Icon(
        _isFolder ? Icons.folder : Icons.audiotrack,
        size: widget.iconSize,
      ),
    );
  }

  Widget _buildNumberOverlay() {
    return Positioned(
      bottom: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${widget.overlayNumber}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: [
              Shadow(blurRadius: 2, color: Colors.black),
              Shadow(blurRadius: 4, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: (_isFolder ? Colors.blue : Colors.orange).withValues(
            alpha: 0.9,
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isFolder ? Icons.folder : Icons.audiotrack,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildNewStarOverlay() {
    return Positioned(
      left: 4,
      top: 4,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.amberAccent.withValues(alpha: 0.9),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.55),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.star,
              size: 28,
              color: Colors.amber.withValues(alpha: 0.85),
            ),
            const Icon(Icons.star, size: 22, color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child = _buildContent();
    if (widget.showTypeBadge || widget.overlayNumber != null) {
      child = Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (widget.overlayNumber != null) _buildNumberOverlay(),
          if (widget.showTypeBadge) _buildBadge(),
          if (widget.showNewStar) _buildNewStarOverlay(),
        ],
      );
    } else if (widget.showNewStar) {
      child = Stack(
        fit: StackFit.expand,
        children: [child, _buildNewStarOverlay()],
      );
    }
    if (widget.isNew) {
      final radius = widget.borderRadius ?? BorderRadius.circular(4);
      child = Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: const Color(0xFFFFD700), width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0xCCFFD700),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Color(0x55FFD700),
              blurRadius: 22,
              spreadRadius: 4,
            ),
          ],
        ),
        child: child,
      );
    }
    return child;
  }
}
