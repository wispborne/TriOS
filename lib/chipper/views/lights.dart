import 'dart:math';

import 'package:flutter/material.dart';

// thank you based chatgpt

class ChristmasLights extends StatefulWidget {
  const ChristmasLights({super.key});

  @override
  ChristmasLightsState createState() => ChristmasLightsState();
}

class ChristmasLightsState extends State<ChristmasLights> with TickerProviderStateMixin {
  final List<Light> _lights = [];
  final int numberOfLights = 100;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < numberOfLights; i++) {
      _lights.add(Light(null, vsync: this, onEnd: _restartLight));
    }
  }

  void _restartLight(Light light) {
    setState(() {
      _lights.remove(light);
      _lights.add(Light(MediaQuery.of(context).size, vsync: this, onEnd: _restartLight));
    });
  }

  @override
  Widget build(BuildContext context) {
    for (int i = 0; i < numberOfLights; i++) {
      _lights.add(Light(MediaQuery.of(context).size, vsync: this, onEnd: _restartLight));
    }
    return CustomPaint(
      painter: LightPainter(_lights),
      child: Container(),
    );
  }

  @override
  void dispose() {
    for (var light in _lights) {
      // light.controller.dispose();
    }
    super.dispose();
  }
}

class Light {
  late Offset position;
  late Color color;
  late double size;
  late double intensity;
  // late AnimationController controller;
  // late Animation<double> animation;
  TickerProvider vsync;
  Function(Light) onEnd;

  Light(Size? canvasSize, {required this.vsync, required this.onEnd}) {
    var random = Random();
    position = Offset(random.nextDouble() * (canvasSize?.width ?? 1), random.nextDouble() * (canvasSize?.height ?? 1));
    color = (random.nextBool() ? Colors.red : Colors.green);
    size = random.nextDouble() * 3 + 2; // Random size between 2.0 and 5.0
    intensity = (random.nextDouble() * 0.1) + 0.3; // Random intensity between 0.1 and 0.6

    // controller = AnimationController(
    //   duration: Duration(milliseconds: canvasSize == null ? 1 : random.nextInt(10000) + 5000),
    //   vsync: vsync,
    // );

    // animation = Tween(begin: 0.0, end: 1.0).animate(controller)
    //   ..addStatusListener((status) {
    //     if (status == AnimationStatus.completed) {
    //       controller.reverse();
    //     } else if (status == AnimationStatus.dismissed) {
    //       onEnd(this);
    //     }
    //   });
    //
    // controller.forward();
  }
}

class LightPainter extends CustomPainter {
  final List<Light> lights;

  LightPainter(this.lights);

  @override
  void paint(Canvas canvas, Size size) {
    for (var light in lights) {
      final paint = Paint()
        ..color = light.color.withOpacity(light.intensity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(light.position, light.size, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
