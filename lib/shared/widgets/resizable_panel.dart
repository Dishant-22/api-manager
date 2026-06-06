import 'package:flutter/material.dart';

/// A horizontal split panel with a draggable divider.
class ResizableHorizontalPanel extends StatefulWidget {
  final Widget left;
  final Widget right;
  final double initialWidth;
  final double minWidth;
  final double maxWidth;
  final bool leftVisible;

  const ResizableHorizontalPanel({
    super.key,
    required this.left,
    required this.right,
    this.initialWidth = 260,
    this.minWidth = 160,
    this.maxWidth = 480,
    this.leftVisible = true,
  });

  @override
  State<ResizableHorizontalPanel> createState() =>
      _ResizableHorizontalPanelState();
}

class _ResizableHorizontalPanelState extends State<ResizableHorizontalPanel> {
  late double _width;

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.leftVisible) {
      return widget.right;
    }

    return Row(
      children: [
        SizedBox(width: _width, child: widget.left),
        _DividerHandle(
          onDrag: (dx) {
            setState(() {
              _width = (_width + dx).clamp(widget.minWidth, widget.maxWidth);
            });
          },
        ),
        Expanded(child: widget.right),
      ],
    );
  }
}

/// A vertical split panel with a draggable divider.
class ResizableVerticalPanel extends StatefulWidget {
  final Widget top;
  final Widget bottom;
  final double initialTopFraction;
  final double minTopFraction;
  final double maxTopFraction;

  const ResizableVerticalPanel({
    super.key,
    required this.top,
    required this.bottom,
    this.initialTopFraction = 0.5,
    this.minTopFraction = 0.2,
    this.maxTopFraction = 0.8,
  });

  @override
  State<ResizableVerticalPanel> createState() => _ResizableVerticalPanelState();
}

class _ResizableVerticalPanelState extends State<ResizableVerticalPanel> {
  late double _topFraction;

  @override
  void initState() {
    super.initState();
    _topFraction = widget.initialTopFraction;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final topHeight =
            (_topFraction * totalHeight).clamp(80.0, totalHeight - 80.0);

        return Column(
          children: [
            SizedBox(height: topHeight, child: widget.top),
            _HorizontalDividerHandle(
              onDrag: (dy) {
                setState(() {
                  _topFraction = ((topHeight + dy) / totalHeight).clamp(
                    widget.minTopFraction,
                    widget.maxTopFraction,
                  );
                });
              },
            ),
            Expanded(child: widget.bottom),
          ],
        );
      },
    );
  }
}

class _DividerHandle extends StatelessWidget {
  final ValueChanged<double> onDrag;

  const _DividerHandle({required this.onDrag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Container(
          width: 5,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 1,
              color: theme.dividerColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalDividerHandle extends StatelessWidget {
  final ValueChanged<double> onDrag;

  const _HorizontalDividerHandle({required this.onDrag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onVerticalDragUpdate: (details) => onDrag(details.delta.dy),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeRow,
        child: Container(
          height: 5,
          color: Colors.transparent,
          child: Center(
            child: Container(
              height: 1,
              color: theme.dividerColor,
            ),
          ),
        ),
      ),
    );
  }
}
