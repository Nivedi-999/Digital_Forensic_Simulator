import 'dart:async';
import 'package:flutter/material.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration speed;
  final bool showFull;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.speed = const Duration(milliseconds: 35),
    this.showFull = false,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String displayedText = '';
  int index = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    if (widget.showFull) {
      displayedText = widget.text;
    } else {
      timer = Timer.periodic(widget.speed, (t) {
        if (index < widget.text.length) {
          setState(() {
            displayedText += widget.text[index];
            index++;
          });
        } else {
          t.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(displayedText, style: widget.style);
  }
}
