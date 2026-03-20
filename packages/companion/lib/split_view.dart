import 'package:flutter/material.dart';

class SplitView extends StatefulWidget {
  final Widget left;
  final Widget right;
  final double initialLeftWidth;
  final double minWidth;
  final double maxWidth;

  const SplitView({
    super.key,
    required this.left,
    required this.right,
    this.initialLeftWidth = 300,
    this.minWidth = 150,
    this.maxWidth = 600,
  });

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  late double _splitPosition;

  @override
  void initState() {
    super.initState();
    _splitPosition = widget.initialLeftWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: _splitPosition, child: widget.left),
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _splitPosition += details.delta.dx;
                _splitPosition = _splitPosition.clamp(
                  widget.minWidth,
                  widget.maxWidth,
                );
              });
            },
            child: Container(
              width: 4,
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 4,
                  height: double.infinity,
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
          ),
        ),
        Expanded(child: widget.right),
      ],
    );
  }
}
