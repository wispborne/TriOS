// BSD 3-Clause License
//
// Copyright (c) 2024, Roberto Notario
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import 'dart:math';

import 'package:flutter/material.dart';

const kScrollRatioStart = 0.0;
const kScrollRatioEnd = 1.0;
const kMaxScreenRatioFade = 0.175;
const kMinScreenRatioFade = 0.05;
const kFadeColor = Colors.white;

class _GradientConfig {
  const _GradientConfig(this.stops, this.colors);

  final List<double> stops;
  final List<Color> colors;
}

class FadedScrollable extends StatefulWidget {
  const FadedScrollable({
    super.key,
    required this.child,
    this.scrollRatioStart = kScrollRatioStart,
    this.scrollRatioEnd = kScrollRatioEnd,
    this.minTopScreenRatioFade = kMinScreenRatioFade,
    this.maxTopScreenRatioFade = kMaxScreenRatioFade,
    this.minBottomScreenRatioFade = kMinScreenRatioFade,
    this.maxBottomScreenRatioFade = kMaxScreenRatioFade,
    this.proportionalFade = true,
  }) : assert(
         scrollRatioStart >= 0 && scrollRatioStart <= 1,
         'scrollRatioStart must be between 0 and 1',
       ),
       assert(
         scrollRatioEnd >= 0 && scrollRatioEnd <= 1,
         'scrollRatioEnd must be between 0 and 1',
       ),
       assert(
         minTopScreenRatioFade >= 0 && minTopScreenRatioFade <= 1,
         'minTopScreenRatioFade must be between 0 and 1',
       ),
       assert(
         maxTopScreenRatioFade >= 0 && maxTopScreenRatioFade <= 1,
         'maxTopScreenRatioFade must be between 0 and 1',
       ),
       assert(
         minBottomScreenRatioFade >= 0 && minBottomScreenRatioFade <= 1,
         'minBottomScreenRatioFade must be between 0 and 1',
       ),
       assert(
         maxBottomScreenRatioFade >= 0 && maxBottomScreenRatioFade <= 1,
         'maxBottomScreenRatioFade must be between 0 and 1',
       ),
       assert(
         minTopScreenRatioFade <= maxTopScreenRatioFade,
         'minTopScreenRatioFade must be less than or equal to maxTopScreenRatioFade',
       ),
       assert(
         minBottomScreenRatioFade <= maxBottomScreenRatioFade,
         'minBottomScreenRatioFade must be less than or equal to maxBottomScreenRatioFade',
       );

  /// The widget that will be faded at the top and bottom. Either this widget or some of its children should be scrollable.
  final Widget child;

  /// Scroll ratio greater than this will cause top fade to appear.
  ///
  /// Defaults to 0.0.
  final double scrollRatioStart;

  /// Scroll ratio lower than this will cause top fade to appear
  ///
  /// Defaults to 1.0.
  final double scrollRatioEnd;

  /// Minimum proportion of the screen that should be faded from the top of the screen.
  ///
  /// Defaults to 0.05.
  final double minTopScreenRatioFade;

  /// Maximum proportion of the screen that should be faded from the top of the screen. A value of 0 means no fade.
  ///
  /// Defaults to 0.175.
  final double maxTopScreenRatioFade;

  /// Minimum proportion of the screen that should be faded from the bottom of the screen. A value of 0 means no fade.
  ///
  /// Defaults to 0.05.
  final double minBottomScreenRatioFade;

  /// Maximum proportion of the screen that should be faded from the bottom of the screen. A value of 0 means no fade.
  ///
  /// Defaults to 0.175.
  final double maxBottomScreenRatioFade;

  /// Whether the fade amount should be proportional to the scroll ratio
  ///
  /// Defaults to true.
  final bool proportionalFade;

  @override
  State<FadedScrollable> createState() => _FadedScrollableState();
}

class _FadedScrollableState extends State<FadedScrollable> {
  double scrollRatio = 0;
  bool _isScrollable = false;

  _GradientConfig _getGradientConfig() {
    final double upperStop = widget.maxTopScreenRatioFade;
    final double lowerStop = 1 - widget.maxBottomScreenRatioFade;

    final bool shouldFadeTop =
        _isScrollable && scrollRatio > widget.scrollRatioStart;
    final bool shouldFadeBottom =
        _isScrollable && scrollRatio < widget.scrollRatioEnd;

    final List<double> stops = [];
    final List<Color> colors = [];

    if (shouldFadeTop) {
      stops.add(0);
      colors.add(kFadeColor);

      if (widget.proportionalFade) {
        stops.add(max(widget.minTopScreenRatioFade, upperStop * scrollRatio));
      } else {
        stops.add(upperStop);
      }

      colors.add(Colors.transparent);
    }

    if (shouldFadeBottom) {
      if (widget.proportionalFade) {
        stops.add(
          min(
            1 - widget.minBottomScreenRatioFade,
            lowerStop + (1 - lowerStop) * scrollRatio,
          ),
        );
      } else {
        stops.add(lowerStop);
      }

      colors.add(Colors.transparent);
      stops.add(1.0);
      colors.add(kFadeColor);
    }

    return _GradientConfig(stops, colors);
  }

  @override
  Widget build(BuildContext context) {
    _GradientConfig gradientConfig = _getGradientConfig();

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification ||
            notification is ScrollMetricsNotification) {
          final metrics = notification.metrics;
          final maxExtent = metrics.maxScrollExtent;

          final bool isScrollableNow = maxExtent > 0;
          final double ratio = isScrollableNow
              ? (metrics.pixels / maxExtent).clamp(0.0, 1.0)
              : 1.0;

          setState(() {
            _isScrollable = isScrollableNow;
            scrollRatio = ratio;
          });
        }

        return true;
      },
      child: gradientConfig.colors.isEmpty
          ? widget.child
          : ShaderMask(
              shaderCallback: (Rect rect) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientConfig.colors,
                  stops: gradientConfig.stops,
                ).createShader(rect);
              },
              blendMode: BlendMode.dstOut,
              child: widget.child,
            ),
    );
  }
}
