import 'package:flutter/rendering.dart';
import 'package:kraken/element.dart';
import 'package:kraken/rendering.dart';
import 'package:kraken/css.dart';

// CSS Positioned Layout: https://drafts.csswg.org/css-position/

enum CSSPositionType {
  static,
  relative,
  absolute,
  fixed,
  sticky,
}

/// Sets vertical alignment of an inline, inline-block
enum VerticalAlign {
  /// Aligns the baseline of the element with the baseline of its parent.
  baseline,

  /// Aligns the top of the element and its descendants with the top of the entire line.
  top,

  /// Aligns the bottom of the element and its descendants with the bottom of the entire line.
  bottom,

  /// Aligns the middle of the element with the baseline plus half the x-height of the parent.
  /// @TODO not supported
  ///  middle,
}

CSSPositionType resolvePositionFromStyle(CSSStyleDeclaration style) {
  return resolveCSSPosition(style[POSITION]);
}

CSSPositionType resolveCSSPosition(String input) {
  switch (input) {
    case RELATIVE:
      return CSSPositionType.relative;
    case ABSOLUTE:
      return CSSPositionType.absolute;
    case FIXED:
      return CSSPositionType.fixed;
    case STICKY:
      return CSSPositionType.sticky;
  }
  return CSSPositionType.static;
}

void applyRelativeOffset(Offset relativeOffset, RenderBox renderBox, CSSStyleDeclaration style) {
  RenderLayoutParentData boxParentData = renderBox?.parentData;

  // Don't set offset if it was already set
  if (boxParentData.isOffsetSet) {
    return;
  }

  if (boxParentData != null) {
    Offset styleOffset;
    // Text node does not have relative offset
    if (renderBox is! RenderTextBox && style != null) {
      styleOffset = getRelativeOffset(style);
    }

    if (relativeOffset != null) {
      if (styleOffset != null) {
        boxParentData.offset = relativeOffset.translate(styleOffset.dx, styleOffset.dy);
      } else {
        boxParentData.offset = relativeOffset;
      }
    } else {
      boxParentData.offset = styleOffset;
    }
  }
}

Offset getRelativeOffset(CSSStyleDeclaration style) {
  CSSPositionType position = resolvePositionFromStyle(style);
  if (position == CSSPositionType.relative) {
    double dx;
    double dy;

    // @TODO support auto value
    if (style.contains(LEFT) && style[LEFT] != AUTO) {
      dx = CSSLength.toDisplayPortValue(style[LEFT]);
    } else if (style.contains(RIGHT) && style[RIGHT] != AUTO) {
      var _dx = CSSLength.toDisplayPortValue(style[RIGHT]);
      if (_dx != null) dx = -_dx;
    }

    if (style.contains(TOP) && style[TOP] != AUTO) {
      dy = CSSLength.toDisplayPortValue(style[TOP]);
    } else if (style.contains(BOTTOM) && style[BOTTOM] != AUTO) {
      var _dy = CSSLength.toDisplayPortValue(style[BOTTOM]);
      if (_dy != null) dy = -_dy;
    }

    if (dx != null || dy != null) {
      return Offset(dx ?? 0, dy ?? 0);
    }
  }
  return null;
}

BoxSizeType _getChildWidthSizeType(RenderBox child) {
  if (child is RenderTextBox) {
    return child.widthSizeType;
  } else if (child is RenderBoxModel) {
    return child.widthSizeType;
  }
  return null;
}

BoxSizeType _getChildHeightSizeType(RenderBox child) {
  if (child is RenderTextBox) {
    return child.heightSizeType;
  } else if (child is RenderBoxModel) {
    return child.heightSizeType;
  }
  return null;
}

void layoutPositionedChild(Element parentElement, RenderBox parent, RenderBox child) {
  RenderBoxModel parentRenderBoxModel = parentElement.renderBoxModel;
  final RenderLayoutParentData childParentData = child.parentData;

  // Default to no constraints. (0 - infinite)
  BoxConstraints childConstraints = const BoxConstraints();
  Size trySize = parentRenderBoxModel.contentConstraints.biggest;
  Size parentSize = trySize.isInfinite ? parentRenderBoxModel.contentConstraints.smallest : trySize;

  BoxSizeType widthType = _getChildWidthSizeType(child);
  BoxSizeType heightType = _getChildHeightSizeType(child);

  // If child has no width, calculate width by left and right.
  // Element with intrinsic size such as image will not stretch
  if (childParentData.width == 0.0 &&
      widthType != BoxSizeType.intrinsic &&
      childParentData.left != null &&
      childParentData.right != null) {
    childConstraints = childConstraints.tighten(width: parentSize.width - childParentData.left - childParentData.right);
  }
  // If child has not height, should be calculate height by top and bottom
  if (childParentData.height == 0.0 &&
      heightType != BoxSizeType.intrinsic &&
      childParentData.top != null &&
      childParentData.bottom != null) {
    childConstraints =
        childConstraints.tighten(height: parentSize.height - childParentData.top - childParentData.bottom);
  }
  child.layout(childConstraints, parentUsesSize: true);
}

// RenderPositionHolder may be affected by overflow: scroller offset.
// We need to reset these offset to keep positioned elements render at their original position.
Offset _getRenderPositionHolderScrollOffset(RenderPositionHolder holder, RenderObject root) {
  RenderBoxModel parent = holder.parent;
  while (parent != root) {
    if (parent.clipX || parent.clipY) {
      return Offset(parent.scrollLeft, parent.scrollTop);
    }
    parent = parent.parent;
  }
  return null;
}

void setPositionedChildOffset(RenderBoxModel parent, RenderBoxModel child, Size parentSize, EdgeInsets borderEdge) {
  final RenderLayoutParentData childParentData = child.parentData;
  // Calc x,y by parentData.
  double x, y;

  double childMarginTop = 0;
  double childMarginBottom = 0;
  double childMarginLeft = 0;
  double childMarginRight = 0;

    Element childEl = parent.elementManager.getEventTargetByTargetId<Element>(child.targetId);
    RenderBoxModel childRenderBoxModel = childEl.renderBoxModel;
    childMarginTop = childRenderBoxModel.marginTop;
    childMarginBottom = childRenderBoxModel.marginBottom;
    childMarginLeft = childRenderBoxModel.marginLeft;
    childMarginRight = childRenderBoxModel.marginRight;

  // Offset to global coordinate system of base.
  if (childParentData.position == CSSPositionType.absolute || childParentData.position == CSSPositionType.fixed) {
    RenderObject root = parent.elementManager.getRootRenderObject();
    Offset positionHolderScrollOffset = _getRenderPositionHolderScrollOffset(childRenderBoxModel.renderPositionHolder, parent) ?? Offset.zero;

    // If [renderPositionHolder] is not laid out, then base offset must be [Offset.zero].
    Offset baseOffset = _isLaidOut(childRenderBoxModel.renderPositionHolder, ancestor: root) ?
        (childRenderBoxModel.renderPositionHolder.localToGlobal(positionHolderScrollOffset, ancestor: root) -
          parent.localToGlobal(Offset(parent.scrollLeft, parent.scrollTop), ancestor: root))
      : Offset.zero;

    // Positioned element is positioned relative to the edge of
    // padding box of containing block, so it needs to add border insets
    // when caculating offset
    // https://www.w3.org/TR/CSS2/visudet.html#containing-block-details
    double borderLeft = borderEdge != null ? borderEdge.left : 0;
    double borderRight = borderEdge != null ? borderEdge.right : 0;
    double borderTop = borderEdge != null ? borderEdge.top : 0;
    double borderBottom = borderEdge != null ? borderEdge.bottom : 0;

    double top = childParentData.top != null ?
      childParentData.top + borderTop + childMarginTop : baseOffset.dy + childMarginTop;
    if (childParentData.top == null && childParentData.bottom != null) {
      top = parentSize.height - child.size.height - borderBottom - childMarginBottom -
        ((childParentData.bottom) ?? 0);
    }

    double left = childParentData.left != null ?
      childParentData.left + borderLeft + childMarginLeft : baseOffset.dx + childMarginLeft;
    if (childParentData.left == null && childParentData.right != null) {
      left = parentSize.width - child.size.width - borderRight - childMarginRight -
        ((childParentData.right) ?? 0);
    }

    x = left;
    y = top;
  }

  Offset offset = setAutoMarginPositionedElementOffset(x, y, child, parentSize);
  childParentData.offset = offset;
}

// Margin auto has special rules for positioned element
// which will override the default position rule
// https://www.w3.org/TR/CSS21/visudet.html#abs-non-replaced-width
Offset setAutoMarginPositionedElementOffset(double x, double y, RenderBox child, Size parentSize) {
  if (child is RenderBoxModel) {
    CSSStyleDeclaration childStyle = child.style;
    String marginLeft = childStyle[MARGIN_LEFT];
    String marginRight = childStyle[MARGIN_RIGHT];
    String marginTop = childStyle[MARGIN_TOP];
    String marginBottom = childStyle[MARGIN_BOTTOM];
    String width = childStyle[WIDTH];
    String height = childStyle[HEIGHT];
    String left = childStyle[LEFT];
    String right = childStyle[RIGHT];
    String top = childStyle[TOP];
    String bottom = childStyle[BOTTOM];

    // 'left' + 'margin-left' + 'border-left-width' + 'padding-left' + 'width' + 'padding-right'
    // + 'border-right-width' + 'margin-right' + 'right' = width of containing block
    if ((left.isNotEmpty && left != AUTO) &&
        (right.isNotEmpty && right != AUTO) &&
        (width.isNotEmpty && width != AUTO)) {
      if (marginLeft == AUTO) {
        double leftValue = CSSLength.toDisplayPortValue(left) ?? 0.0;
        double rightValue = CSSLength.toDisplayPortValue(right) ?? 0.0;
        double remainingSpace = parentSize.width - child.size.width - leftValue - rightValue;

        if (marginRight == AUTO) {
          x = leftValue + remainingSpace / 2;
        } else {
          x = leftValue + remainingSpace;
        }
      }
    }

    if ((top.isNotEmpty && top != AUTO) &&
        (bottom.isNotEmpty && bottom != AUTO) &&
        (height.isNotEmpty && height != AUTO)) {
      if (marginTop == AUTO) {
        double topValue = CSSLength.toDisplayPortValue(top) ?? 0.0;
        double bottomValue = CSSLength.toDisplayPortValue(bottom) ?? 0.0;
        double remainingSpace = parentSize.height - child.size.height - topValue - bottomValue;

        if (marginBottom == AUTO) {
          y = topValue + remainingSpace / 2;
        } else {
          y = topValue + remainingSpace;
        }
      }
    }
  }
  return Offset(x ?? 0, y ?? 0);
}

VerticalAlign getVerticalAlign(CSSStyleDeclaration style) {
  String verticalAlign = style[VERTICAL_ALIGN];

  switch (verticalAlign) {
    case 'top':
      return VerticalAlign.top;
    case 'bottom':
      return VerticalAlign.bottom;
  }
  return VerticalAlign.baseline;
}

/// Check whether renderBox's parents is laied out.
bool _isLaidOut(RenderBox renderer, { RenderObject ancestor }) {
  while (renderer != ancestor) {
    if (!renderer.hasSize) {
      return false;
    }

    if (renderer.parent is RenderBox) {
      renderer = renderer.parent;
    }
  }
  return true;
}
