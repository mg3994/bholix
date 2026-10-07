import 'dart:async' show runZonedGuarded;

import 'dart:math';

import 'package:flutter/foundation.dart' show PlatformDispatcher;
import 'package:flutter/material.dart';

import 'core/errors/reporter_impl.dart' show BootstrapErrorReporter;

import 'package:flutter_scene/scene.dart';
// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math.dart' as vm;

void main() {
  const errors = BootstrapErrorReporter.active();

  FlutterError.onError = (details) {
    errors.report(details.exception, details.stack ?? StackTrace.current);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    errors.report(error, stackTrace);
    return true;
  };
  runZonedGuarded(() => runApp(const BootStrap(errors: errors)), errors.report);
}

class BootStrap extends StatefulWidget {
  final BootstrapErrorReporter errors;
  const BootStrap({super.key, required this.errors});

  @override
  State<BootStrap> createState() => _BootStrapState();
}

class _BootStrapState extends State<BootStrap> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold(body: FirstScene()));
  }
}

class FirstScene extends StatelessWidget {
  const FirstScene({super.key});

  @override
  Widget build(BuildContext context) {
    return SceneView.declarative(
      // The camera orbits the origin once per second.
      cameraBuilder: (elapsed) {
        final t = elapsed.inMicroseconds / 1e6;
        return PerspectiveCamera(
          position: vm.Vector3(sin(t) * 5, 2, cos(t) * 5),
          target: vm.Vector3(0, 0, 0),
        );
      },
      children: [
        SceneNode(
          components: [SpinComponent(1.5)],
          children: [
            SceneMesh(
              geometry: CuboidGeometry(vm.Vector3(1, 1, 1), debugColors: true),
              material: UnlitMaterial(),
            ),
          ],
        ),
      ],
    );
  }
}

class SpinComponent extends Component {
  SpinComponent(this.radiansPerSecond);

  final double radiansPerSecond;

  // Runs once when the node joins a live scene, before the first update.
  @override
  void onMount() {
    debugPrint('SpinComponent attached and driving its node');
  }

  // Runs every frame while mounted. deltaSeconds is the time since the
  // previous tick, so motion stays framerate independent.
  @override
  void update(double deltaSeconds) {
    node.localTransform.rotateY(radiansPerSecond * deltaSeconds);
    node.markTransformDirty();
  }

  // Runs when the node leaves the scene. Release any resources here.
  @override
  void onUnmount() {
    debugPrint('SpinComponent removed from the scene');
  }
}
