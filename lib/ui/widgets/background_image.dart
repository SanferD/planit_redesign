import 'dart:ui';
import 'package:flutter/material.dart';

class BackgroundImage extends StatelessWidget {
  final String imageFileName;
  final List<Widget> stackChildren;

  const BackgroundImage({
    super.key,
    this.stackChildren = const [],
    required this.imageFileName,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: Image.asset(
              'assets/images/$imageFileName',
            ),
          ),
          Stack(
            children: stackChildren,
          ),
        ],
      ),
    );
  }
}

class Blur extends StatelessWidget {
  final Widget child;
  final double blurValue = 2.2;
  final BlurMode blurMode;

  const Blur({
    super.key,
    required this.child,
    this.blurMode = BlurMode.none,
  });

  @override
  Widget build(BuildContext context) {
    switch (blurMode) {
      case BlurMode.none:
        return child;
      case BlurMode.me:
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
          child: child,
        );
      case BlurMode.notMe:
        print("!!!!!!! ${child.toString()}");
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
          child: child,
        );
    }
  }
}

enum BlurMode {
  none,
  me,
  notMe,
}
