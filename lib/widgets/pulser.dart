/// Copyright 2023 Lukasz Majda (lukasz.majda@gmail.com)
///
///

import 'package:flutter/material.dart';

const _kOverdrawFactor = 1.4142135624;

typedef OnCreatedListener = void Function(AnimationController controller);

/// Pulsator widget that renders pulsating circles.
///
/// The widget can be configured to render a given number of pulsating circles
/// with a given [style].
///
/// The [count] property controls the number of circles rendered at a time.
///
/// The [duration] property controls the duration of a single pulse animation.
///
/// The [repeat] property controls the number of times the animation will
/// repeat. If 0, the animation will repeat forever.
///
/// The [startFromScratch] property controls if the animation should start from
/// the beginning.
///
/// The [autoStart] property controls if the animation should start
/// automatically when the widget is created.
///
/// The [fit] property controls how the pulse should be scaled to fit the
/// widget size. The [onCreated] callback is invoked when the animation
/// controller is created.
///
/// The [onCompleted] callback is invoked when the animation is completed.
///
/// The [child] property is the child of the widget that is rendered on top of
/// the pulses.
class Pulsator extends StatefulWidget {
  /// Make a new [Pulsator] instance.
  const Pulsator({
    required this.style,
    this.count = 3,
    this.duration = const Duration(seconds: 2),
    this.repeat = 0,
    this.startFromScratch = true,
    this.autoStart = true,
    this.fit = PulseFit.contain,
    this.onCreated,
    this.onCompleted,
    this.child,
    super.key,
  })  : assert(count > 0),
        assert(repeat >= 0);

  /// Pulse style configuration.
  final PulseStyle style;

  /// Number of pulses visible at a time. Default is 3.
  final int count;

  /// Duration of a single pulse animation. Default is 2 seconds.
  final Duration duration;

  /// Number of times pulses will repeat. If 0, pulses will repeat forever.
  /// Default is 0.
  final int repeat;

  /// Whether the animation should start from the beginning. Default is true.
  final bool startFromScratch;

  /// Whether the animation should start automatically when the widget is created.
  /// Default is true.
  final bool autoStart;

  /// How the pulse should be scaled to fit the widget size.
  /// Default is [PulseFit.contain].
  final PulseFit fit;

  /// Invoked when the animation controller is created.
  final OnCreatedListener? onCreated;

  /// Invoked when the animation is completed.
  final VoidCallback? onCompleted;

  /// The child of the widget that is rendered on top of the pulses.
  final Widget? child;

  @override
  State<Pulsator> createState() => _PulsatorViewState();
}

class _PulsatorViewState extends State<Pulsator>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late Animation<double> _animation;
  final int _counter = 0;
  double _scaleFactor = 1.0;
  late double? _minProgress;

  @override
  void initState() {
    super.initState();
    _buildAnimation();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant Pulsator oldWidget) {
    // Recalculate the scale factor.
    if (widget.fit == PulseFit.cover) {
      _scaleFactor = (widget.count > 1
              ? 1.0 /
                  widget.style.pulseCurve.transform(
                    (widget.count - 1) / widget.count,
                  )
              : 1.0) *
          _kOverdrawFactor;
    } else {
      _scaleFactor = 1.0;
    }

    // Rebuild the animation if necessary.
    if (widget.repeat != oldWidget.repeat ||
        widget.duration != oldWidget.duration ||
        widget.startFromScratch != oldWidget.startFromScratch ||
        widget.autoStart != oldWidget.autoStart ||
        widget.count != oldWidget.count) {
      _buildAnimation();
    }

    super.didUpdateWidget(oldWidget);
  }

  /// Build animation controller and animation based on widget configuration.
  void _buildAnimation() {
    // Calculate animation end value based on repeat count and pulse count.
    late final double animEnd;
    if (widget.repeat > 0) {
      animEnd = widget.repeat + 1.0 - 1.0 / widget.count;
    } else {
      animEnd = 1.0;
    }

    // Create animation controller and animation if not already created.
    // Otherwise, update only the animation duration.
    final firstBuild = _controller == null;
    final duration = (widget.duration.inMilliseconds * animEnd).toInt();
    if (_controller == null) {
      _controller = AnimationController(
        duration: Duration(milliseconds: duration),
        vsync: this,
      )..addStatusListener(_handleAnimationStatus);
    } else {
      _controller!.duration = Duration(milliseconds: duration);
    }

    _animation = Tween<double>(begin: 0.0, end: animEnd).animate(_controller!);
    _minProgress = widget.startFromScratch ? 0.0 : null;

    // Start animation if autoStart is true.
    if (widget.autoStart) {
      _controller!.reset();
      _controller!.forward();
    }

    // Invoke onCreated callback if it is a first build.
    if (firstBuild && widget.onCreated != null) {
      widget.onCreated!.call(_controller!);
    }
  }

  /// Handle animation status changes to reset the animation if necessary.
  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }

    if (widget.repeat > 0) {
      // Animation is completed so invoke the callback.
      widget.onCompleted?.call();
      return;
    }

    // It's another animation cycle, so don't clamp the progress.
    _minProgress = null;

    _controller!.reset();
    _controller!.forward();
  }

  @override
  Widget build(BuildContext context) {
    final pulse = AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final pulses = [
          for (var i = 0; i < widget.count; i++)
            _PulseCircle(
              style: widget.style,
              scale: _animation.value,
              offset: i / widget.count,
              progress: _counter + _animation.value,
              minProgress: _minProgress,
              maxProgress: widget.repeat > 0 ? widget.repeat.toDouble() : null,
              scaleFactor: _scaleFactor,
            ),
        ];
        // Pulses should be rendered in order from the biggest to the smallest.
        pulses.sort(_compareZIndex);

        return Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: pulses.map((e) => e).toList(growable: false),
        );
      },
    );

    // If there is no child, just return the pulse.
    if (widget.child == null) {
      return pulse;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        pulse,
        widget.child!,
      ],
    );
  }

  /// Compare two pulses by their z-index.
  static int _compareZIndex(_PulseCircle a, _PulseCircle b) {
    final ta = (a.progress - a.offset) % 1.0;
    final tb = (b.progress - b.offset) % 1.0;
    return tb.compareTo(ta);
  }
}

class _PulseCircle extends StatelessWidget {
  const _PulseCircle({
    required this.style,
    required this.scale,
    required this.offset,
    required this.progress,
    this.minProgress,
    this.maxProgress,
    this.scaleFactor = 1.0,
  })  : assert(scale >= 0.0),
        assert(offset >= 0.0),
        assert(progress >= 0.0),
        assert(scaleFactor > 0.0);

  /// Pulse style configuration.
  final PulseStyle style;

  /// Current animation scale value.
  final double scale;

  /// Offset of the pulse in the animation cycle.
  final double offset;

  /// Current animation progress value.
  final double progress;

  /// Minimum animation progress value to render the pulse.
  final double? minProgress;

  /// Maximum animation progress value to render the pulse.
  final double? maxProgress;

  /// Scale factor to apply to the pulse. Used when the pulse is rendered
  /// to fill the entire widget.
  final double scaleFactor;

  @override
  Widget build(BuildContext context) {
    // Calculate the current pulse progress, taking into account the offset.
    final progress = this.progress - offset;

    // If minProgress or maxProgress are set, check if the pulse should be
    // rendered.
    if ((minProgress != null && progress < minProgress!) ||
        (maxProgress != null && progress > maxProgress!)) {
      return const SizedBox.shrink();
    }

    // Make sure the progress is between 0.0 and 1.0.
    final t = progress % 1.0;
    final opacity =
        style.fadeOpacity ? 1.0 - style.opacityCurve.transform(t) : 1.0;
    final scale = style.startSize +
        style.pulseCurve.transform(t) * scaleFactor * (1.0 - style.startSize);

    return Transform.scale(
      scale: scale,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: style.gradientStyle == null
              ? style.color.withOpacity(opacity)
              : null,
          gradient: style.gradientStyle != null
              ? RadialGradient(
                  radius: style.gradientStyle!.radius,
                  stops: [style.gradientStyle!.start, style.gradientStyle!.end],
                  colors: style.gradientStyle!.reverseColors
                      ? [
                          style.color.withOpacity(opacity),
                          style.gradientStyle!.startColor != null
                              ? style.gradientStyle!.startColor!
                                  .withOpacity(opacity)
                              : style.color.withOpacity(0),
                        ]
                      : [
                          style.gradientStyle!.startColor != null
                              ? style.gradientStyle!.startColor!
                                  .withOpacity(opacity)
                              : style.color.withOpacity(0),
                          style.color.withOpacity(opacity),
                        ])
              : null,
          border: style.borderWidth != null && style.borderColor != null
              ? Border.all(
                  color: style.borderColor!.withOpacity(opacity),
                  width: style.borderWidth!,
                )
              : null,
        ),
      ),
    );
  }
}

/// How the pulse should be scaled to fit the widget size.
enum PulseFit {
  /// The pulse will be scaled to fit the widget size.
  contain,

  /// The pulse will be scaled to fill the widget size.
  cover,
}

/// The style of the pulse gradient.
///
/// [radius] is the radius of the gradient, as a fraction pulse radius.
///
/// [start] is the start point of the gradient, as a fraction of the pulse
/// radius.
///
/// [end] is the end point of the gradient, as a fraction of the pulse radius.
///
/// [startColor] is the start color of the gradient. If null, the pulse color
/// will be used with the opacity set to 0.0.
///
/// [reverseColors] is if the gradient colors should be reversed. If true, the
/// gradient will start from [end] and end at [start].
class PulseGradientStyle {
  /// Make a new [PulseGradientStyle] instance.
  const PulseGradientStyle({
    this.radius = 0.5,
    this.start = 0.0,
    this.end = 1.0,
    this.startColor,
    this.reverseColors = false,
  })  : assert(radius >= 0.0 && radius <= 1.0),
        assert(start >= 0.0 && start <= 1.0),
        assert(end >= 0.0 && end <= 1.0);

  /// The radius of the gradient, as a fraction pulse radius. Default is 0.5.
  final double radius;

  /// The start point of the gradient, as a fraction of the pulse radius.
  /// Default is 0.0.
  final double start;

  /// The end point of the gradient, as a fraction of the pulse radius. Default
  /// is 1.0.
  final double end;

  /// The start color of the gradient. If null, the pulse color will be used
  /// with the opacity set to 0.0.
  final Color? startColor;

  /// Whether the gradient colors should be reversed. If true, the gradient will
  /// start from [end] and end at [start]. Default is false.
  final bool reverseColors;
}

/// The style of the pulse.
///
/// [color] is the main color of the pulse.
///
/// [borderColor] is the border color of the pulse.
///
/// [borderWidth] is the border width of the pulse. If 0, no border will be
/// rendered.
///
/// [gradientStyle] is the gradient style of the pulse. If null, no gradient
/// will be rendered.
///
/// [pulseCurve] is the pulse scale animation curve (default is linear).
///
/// [opacityCurve] is the pulse opacity animation curve (default is linear).
///
/// [fadeOpacity] is if the opacity should be animated from 1.0 to 0.0. Default
///
/// [startSize] is the size of the pulse when it begins, as a fraction of the
/// pulse radius. Default is 0.0.
class PulseStyle {
  /// Make a new [PulseStyle] instance.
  const PulseStyle({
    this.color = Colors.red,
    this.borderColor,
    this.borderWidth,
    this.gradientStyle,
    this.pulseCurve = Curves.linear,
    this.opacityCurve = Curves.linear,
    this.fadeOpacity = true,
    this.startSize = 0.0,
  }) : assert(startSize >= 0.0 && startSize <= 1.0);

  /// Main pulse color.
  final Color color;

  /// Pulse border color. If `null`, no border will be rendered.
  final Color? borderColor;

  /// Pulse border width. If `null`, no border will be rendered.
  final double? borderWidth;

  /// If set, the pulse will be rendered as a gradient.
  final PulseGradientStyle? gradientStyle;

  /// Pulse scale animation curve (default is linear).
  final Curve pulseCurve;

  /// Pulse opacity animation curve (default is linear).
  final Curve opacityCurve;

  /// Whether the opacity should be animated from 1.0 to 0.0. Default is true.
  final bool fadeOpacity;

  /// The size of the pulse when it begins, as a fraction of the pulse radius.
  /// Default is 0.0.
  final double startSize;
}
