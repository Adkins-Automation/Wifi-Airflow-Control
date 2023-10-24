import 'package:flutter/material.dart';

class DamperSlider extends StatefulWidget {
  final int initialValue;
  final Function(int) onEnd;

  DamperSlider({required this.initialValue, required this.onEnd});

  @override
  DamperSliderState createState() => DamperSliderState();
}

class DamperSliderState extends State<DamperSlider> {
  double? _intermediateSliderValue;

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _intermediateSliderValue ?? widget.initialValue.toDouble(),
      onChanged: (double changingValue) {
        _intermediateSliderValue = changingValue;
        setState(() {});
      },
      onChangeEnd: (double endValue) {
        widget.onEnd(endValue.toInt());
        _intermediateSliderValue = null;
        setState(() {});
      },
      min: 0,
      max: 100,
      activeColor: Colors.green,
      inactiveColor: Colors.blue,
    );
  }
}
