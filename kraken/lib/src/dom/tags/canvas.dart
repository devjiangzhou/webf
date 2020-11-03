/*
 * Copyright (C) 2019-present Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */
import 'package:flutter/rendering.dart';
import 'package:kraken/dom.dart';
import 'package:kraken/rendering.dart';
import 'package:kraken/painting.dart';
import 'package:kraken/css.dart';

const String CANVAS = 'CANVAS';

const Map<String, dynamic> _defaultStyle = {
  DISPLAY: INLINE_BLOCK,
  WIDTH: ELEMENT_DEFAULT_WIDTH,
  HEIGHT: ELEMENT_DEFAULT_HEIGHT,
};

class RenderCanvasPaint extends RenderCustomPaint {
  @override
  bool get isRepaintBoundary => true;

  RenderCanvasPaint({ CustomPainter painter, Size preferredSize }) : super(
    painter: painter,
    foregroundPainter: null, // Ignore foreground painter
    preferredSize: preferredSize,
  );
}

class CanvasElement extends Element {
  CanvasElement(int targetId, ElementManager elementManager)
      : super(
          targetId,
          elementManager,
          defaultStyle: _defaultStyle,
          isIntrinsicBox: true,
          repaintSelf: true,
          tagName: CANVAS,
        );

  @override
  void willAttachRenderer() {
    super.willAttachRenderer();
    renderCustomPaint = RenderCanvasPaint(
      painter: painter,
      preferredSize: size,
    );

    addChild(renderCustomPaint);
    style.addStyleChangeListener(_propertyChangedListener);
  }


  @override
  void didDetachRenderer() {
    super.didDetachRenderer();
    style.removeStyleChangeListener(_propertyChangedListener);
    renderCustomPaint = null;
  }

  /// The painter that paints before the children.
  final CanvasPainter painter = CanvasPainter();

  /// The size that this [CustomPaint] should aim for, given the layout
  /// constraints, if there is no child.
  ///
  /// If there's a child, this is ignored, and the size of the child is used
  /// instead.
  Size get size => Size(width, height);

  RenderCustomPaint renderCustomPaint;

  // RenderingContext? getContext(DOMString contextId, optional any options = null);
  CanvasRenderingContext getContext(String contextId, {dynamic options}) {
    switch (contextId) {
      case '2d':
        if (painter.context == null) {
          painter.context = CanvasRenderingContext2D();
        }
        return painter.context;
      default:
        throw FlutterError('CanvasRenderingContext $contextId not supported!');
    }
  }

  /// Element attribute width
  double _width = CSSLength.toDisplayPortValue(ELEMENT_DEFAULT_WIDTH);
  double get width => _width;
  set width(double value) {
    if (value == null) {
      return;
    }

    if (value != _width) {
      _width = value;
      if (renderCustomPaint != null) {
        renderCustomPaint.preferredSize = size;
      }
    }
  }

  /// Element attribute height
  double _height = CSSLength.toDisplayPortValue(ELEMENT_DEFAULT_HEIGHT);
  double get height => _height;
  set height(double value) {
    if (value == null) {
      return;
    }

    if (value != _height) {
      _height = value;
      if (renderCustomPaint != null) {
        renderCustomPaint.preferredSize = size;
      }
    }
  }

  void _propertyChangedListener(String key, String original, String present, bool inAnimation) {
    switch (key) {
      case 'width':
        // Trigger width setter to invoke rerender.
        width = CSSLength.toDisplayPortValue(present);
        break;
      case 'height':
        // Trigger height setter to invoke rerender.
        height = CSSLength.toDisplayPortValue(present);
        break;
    }
  }

  void _applyContext2DMethod(List args) {
    // [String method, [...args]]
    if (args == null) return;
    if (args.length < 1) return;
    String method = args[0];
    switch (method) {
      case 'fillRect':
        double x = CSSLength.toDouble(args[1]) ?? 0.0;
        double y = CSSLength.toDouble(args[2]) ?? 0.0;
        double w = CSSLength.toDouble(args[3]) ?? 0.0;
        double h = CSSLength.toDouble(args[4]) ?? 0.0;
        painter.context.fillRect(x, y, w, h);
        break;

      case 'clearRect':
        double x = CSSLength.toDouble(args[1]) ?? 0.0;
        double y = CSSLength.toDouble(args[2]) ?? 0.0;
        double w = CSSLength.toDouble(args[3]) ?? 0.0;
        double h = CSSLength.toDouble(args[4]) ?? 0.0;
        painter.context.clearRect(x, y, w, h);
        break;

      case 'strokeRect':
        double x = CSSLength.toDouble(args[1]) ?? 0.0;
        double y = CSSLength.toDouble(args[2]) ?? 0.0;
        double w = CSSLength.toDouble(args[3]) ?? 0.0;
        double h = CSSLength.toDouble(args[4]) ?? 0.0;
        painter.context.strokeRect(x, y, w, h);
        break;

      case 'fillText':
        String text = args[1];
        double x = CSSLength.toDouble(args[2]) ?? 0.0;
        double y = CSSLength.toDouble(args[3]) ?? 0.0;
        if (args.length == 5) {
          // optional maxWidth
          double maxWidth = CSSLength.toDouble(args[4]) ?? 0.0;
          painter.context.fillText(text, x, y, maxWidth: maxWidth);
        } else {
          painter.context.fillText(text, x, y);
        }
        break;

      case 'strokeText':
        String text = args[1];
        double x = CSSLength.toDouble(args[2]) ?? 0.0;
        double y = CSSLength.toDouble(args[3]) ?? 0.0;
        if (args.length == 5) {
          // optional maxWidth
          double maxWidth = CSSLength.toDouble(args[4]) ?? 0.0;
          painter.context.strokeText(text, x, y, maxWidth: maxWidth);
        } else {
          painter.context.strokeText(text, x, y);
        }
        break;
    }

    if (renderCustomPaint != null) {
      renderCustomPaint.markNeedsPaint();
    }
  }

  void _updateContext2DProperty(List args) {
    // [String method, [...args]]
    if (args == null) return;
    if (args.length < 1) return;
    String property = args[0];
    switch (property) {
      case 'fillStyle':
        painter.context.fillStyle = CSSColor.parseColor(args[1]);
        break;
      case 'strokeStyle':
        painter.context.strokeStyle = CSSColor.parseColor(args[1]);
        break;
      case 'font':
        painter.context.font = args[1];
        break;
    }
  }

  @override
  method(String name, List args) {
    if (name == 'getContext') {
      return getContext(args[0]);
    } else if (name == 'applyContext2DMethod') {
      return _applyContext2DMethod(args);
    } else if (name == 'updateContext2DProperty') {
      return _updateContext2DProperty(args);
    } else {
      return super.method(name, args);
    }
  }
}