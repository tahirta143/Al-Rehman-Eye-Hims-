import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

/// A wrapper that applies a "Fade Through" transition to its child when it changes.
/// Ideal for switching between views (e.g., loading state to content).
class CustomPageTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const CustomPageTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: duration,
      transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
        return FadeThroughTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// A wrapper that applies a "Fade Scale" transition to its child when it appears.
/// Ideal for elements that pop up or enter the scene.
class FadeScaleTransitionWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool show;

  const FadeScaleTransitionWrapper({
    super.key,
    required this.child,
    this.show = true,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<FadeScaleTransitionWrapper> createState() => _FadeScaleTransitionWrapperState();
}

class _FadeScaleTransitionWrapperState extends State<FadeScaleTransitionWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: widget.show ? 1.0 : 0.0,
      duration: widget.duration,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(FadeScaleTransitionWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show != oldWidget.show) {
      if (widget.show) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeScaleTransition(
      animation: _controller,
      child: widget.child,
    );
  }
}

/// A wrapper for OpenContainer (Container Transform) to animate from a closed
/// state (e.g., a card) to an open state (e.g., a details page).
class CustomOpenContainer extends StatelessWidget {
  final Widget closedChild;
  final Widget openChild;
  final Color? closedColor;
  final double closedElevation;
  final ShapeBorder closedShape;

  const CustomOpenContainer({
    super.key,
    required this.closedChild,
    required this.openChild,
    this.closedColor,
    this.closedElevation = 0.0,
    this.closedShape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
  });

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      closedElevation: closedElevation,
      closedShape: closedShape,
      closedColor: closedColor ?? Theme.of(context).cardColor,
      transitionType: ContainerTransitionType.fade,
      openBuilder: (context, action) => openChild,
      closedBuilder: (context, action) => closedChild,
    );
  }
}
