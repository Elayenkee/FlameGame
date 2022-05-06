import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flutter/widgets.dart' hide Image;

class MyTextBoxComponent<T extends TextRenderer> extends PositionComponent {
  static final Paint _imagePaint = BasicPalette.white.paint()
    ..filterQuality = FilterQuality.high;

  final String _text;
  final T _textRenderer;
  final TextBoxConfig _boxConfig;

  late List<String> _lines;
  double _maxLineWidth = 0.0;
  late double _lineHeight;
  late int _totalLines;

  double _lifeTime = 0.0;
  Image? _cache;
  int? _previousChar;

  String get text => _text;

  TextRenderer get renderer => _textRenderer;

  TextBoxConfig get boxConfig => _boxConfig;

  MyTextBoxComponent(
    String text, {
    T? textRenderer,
    TextBoxConfig? boxConfig,
    Vector2? position,
    Vector2? size,
    int? priority,
  })  : _text = text,
        _boxConfig = boxConfig ?? TextBoxConfig(),
        _textRenderer = textRenderer ?? TextRenderer.createDefault<T>(),
        super(position: position, size: size, priority: priority) {
    _lines = [];
    double? lineHeight;

    if(boxConfig != null && boxConfig.timePerChar > 0)
      maxTime = text.length * boxConfig.timePerChar;
    
    text.split(' ').forEach((word) {
      word.split("\n").forEach((word) { 
        final possibleLine = _lines.isEmpty ? word : '${_lines.last} $word';
        lineHeight ??= _textRenderer.measureTextHeight(possibleLine);

        final textWidth = _textRenderer.measureTextWidth(possibleLine);
        if (textWidth <= _boxConfig.maxWidth - _boxConfig.margins.horizontal) 
        {
          if (_lines.isNotEmpty) 
          {
            _lines.last = possibleLine;
          } 
          else 
          {
            _lines.add(possibleLine);
          }
          _updateMaxWidth(textWidth);
        } 
        else 
        {
          _lines.add(word);
          _updateMaxWidth(textWidth);
        }
      });
    });
    _totalLines = _lines.length;
    _lineHeight = lineHeight ?? 0.0;
  }

  void _updateMaxWidth(double w) {
    if (w > _maxLineWidth) {
      _maxLineWidth = w;
    }
  }

  double get totalCharTime => _text.length * _boxConfig.timePerChar;

  bool get finished => _lifeTime > totalCharTime + _boxConfig.dismissDelay;

  int get _actualTextLength {
    return _lines.map((e) => e.length).fold(0, (p, c) => p + c);
  }

  int get currentChar => _boxConfig.timePerChar == 0.0
      ? _actualTextLength
      : math.min(_lifeTime ~/ _boxConfig.timePerChar, _actualTextLength);

  int get currentLine {
    var totalCharCount = 0;
    final _currentChar = currentChar;
    for (var i = 0; i < _lines.length; i++) {
      totalCharCount += _lines[i].length;
      if (totalCharCount > _currentChar) {
        return i;
      }
    }
    return _lines.length - 1;
  }

  @override
  Vector2 get size => Vector2(width, height);

  double getLineWidth(String line, int charCount) {
    return _textRenderer.measureTextWidth(
      line.substring(0, math.min(charCount, line.length)),
    );
  }

  double? _cachedWidth;

  @override
  double get width {
    if (_cachedWidth != null) {
      return _cachedWidth!;
    }
    if (_boxConfig.growingBox) {
      var i = 0;
      var totalCharCount = 0;
      final _currentChar = currentChar;
      final _currentLine = currentLine;
      final textWidth = _lines.sublist(0, _currentLine + 1).map((line) {
        final charCount =
            (i < _currentLine) ? line.length : (_currentChar - totalCharCount);
        totalCharCount += line.length;
        i++;
        return getLineWidth(line, charCount);
      }).reduce(math.max);
      _cachedWidth = textWidth + _boxConfig.margins.horizontal;
    } else {
      _cachedWidth = _boxConfig.maxWidth + _boxConfig.margins.horizontal;
    }
    return _cachedWidth!;
  }

  @override
  double get height {
    if (_boxConfig.growingBox) {
      return _lineHeight * _lines.length + _boxConfig.margins.vertical;
    } else {
      return _lineHeight * _totalLines + _boxConfig.margins.vertical;
    }
  }

  @override
  void render(Canvas c) {
    if (_cache == null) {
      return;
    }
    super.render(c);
    c.drawImage(_cache!, Offset.zero, _imagePaint);
  }

  Future<Image> _redrawCache() {
    final recorder = PictureRecorder();
    final c = Canvas(recorder, size.toRect());
    _fullRender(c);
    return recorder.endRecording().toImage(width.toInt(), height.toInt());
  }

  /// Override this method to provide a custom background to the text box.
  void drawBackground(Canvas c) {}

  void _fullRender(Canvas c) {
    drawBackground(c);

    final _currentLine = currentLine;
    var charCount = 0;
    var dy = _boxConfig.margins.top;
    for (var line = 0; line < _currentLine; line++) {
      charCount += _lines[line].length;
      _drawLine(c, _lines[line], dy);
      dy += _lineHeight;
    }
    final max = math.min(currentChar - charCount, _lines[_currentLine].length);
    print(currentLine);
    _drawLine(c, _lines[_currentLine].substring(0, max), dy);
  }

  void _drawLine(Canvas c, String line, double dy) {
    _textRenderer.render(c, line, Vector2(_boxConfig.margins.left, dy));
  }

  void redrawLater() async {
    _cache = await _redrawCache();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTime += dt;
    if (_previousChar != currentChar) {
      _cachedWidth = null;
      redrawLater();
    }
    if(onEnd != null && maxTime > 0)
    {
      count += dt;
      if(count >= maxTime)
      {
        maxTime = count = 0;
        onEnd?.call();
        onEnd = null;
      }
    }
    _previousChar = currentChar;
  }

  double maxTime = 0;
  double count = 0;
  VoidCallback? onEnd;
}
