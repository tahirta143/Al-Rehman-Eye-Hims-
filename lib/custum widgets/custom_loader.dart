import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CustomLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final List<Color>? colors;

  const CustomLoader({
    super.key,
    this.size = 50.0,
    this.color,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? Theme.of(context).colorScheme.primary;

    return Center(
      child: LoadingAnimationWidget.inkDrop(
        color: primaryColor,
        size: size,
      ),
    );
  }
}
