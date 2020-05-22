import 'package:flutter/material.dart';

class UnicornOutlineButton extends StatefulWidget {
  final GradientPainter _painter;
  final GradientPainter _tappedPainter;
  final Widget _child;
  final VoidCallback _callback;
  final double _radius;
  bool tapped = false;
  bool getTapped(){
    return tapped;
  }
  UnicornOutlineButton({
    @required double strokeWidth,
    @required double radius,
    @required Gradient gradient,
    @required Gradient tappedGradient,
    @required Widget child,
    @required VoidCallback onPressed,
  })  : this._painter = GradientPainter(strokeWidth: strokeWidth, radius: radius, gradient: gradient),
        this._tappedPainter = GradientPainter(strokeWidth: strokeWidth, radius: radius, gradient: tappedGradient),
        this._child = child,
        this._callback = onPressed,
        this._radius = radius;

  @override
  _UnicornOutlineButtonState createState() => _UnicornOutlineButtonState();
}

class _UnicornOutlineButtonState extends State<UnicornOutlineButton> {
  bool _tapped = false;
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _tapped ? widget._tappedPainter : widget._painter,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget._callback,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget._radius),
          onTap: (){
            _tapped = !_tapped;
            widget.tapped = _tapped;
            setState(() {});
          },
          child: Container(
            padding: EdgeInsets.all(10.0),
            constraints: BoxConstraints(minWidth: 88, minHeight: 48),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                widget._child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GradientPainter extends CustomPainter {
  final Paint _paint = Paint();
  final double radius;
  final double strokeWidth;
  final Gradient gradient;

  GradientPainter({@required double strokeWidth, @required double radius, @required Gradient gradient})
      : this.strokeWidth = strokeWidth,
        this.radius = radius,
        this.gradient = gradient;

  @override
  void paint(Canvas canvas, Size size) {
    // create outer rectangle equals size
    Rect outerRect = Offset.zero & size;
    var outerRRect = RRect.fromRectAndRadius(outerRect, Radius.circular(radius));

    // create inner rectangle smaller by strokeWidth
    Rect innerRect = Rect.fromLTWH(strokeWidth, strokeWidth, size.width - strokeWidth * 2, size.height - strokeWidth * 2);
    var innerRRect = RRect.fromRectAndRadius(innerRect, Radius.circular(radius - strokeWidth));

    // apply gradient shader
    _paint.shader = gradient.createShader(outerRect);

    // create difference between outer and inner paths and draw it
    Path path1 = Path()..addRRect(outerRRect);
    Path path2 = Path()..addRRect(innerRRect);
    var path = Path.combine(PathOperation.difference, path1, path2);
    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => oldDelegate != this;
}