import 'package:flutter/material.dart';
import 'package:kaisel/kaisel.dart';

// ── Sealed route hierarchy ────────────────────────────────────────────────────

sealed class AppRoute extends KaiselRoute {
  const AppRoute();
}

/// Default / home route.
final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  List<Object?> get props => [];
}

// ── App-lifetime router config ─────────────────────────────────────────────────

final appRouterConfig = KaiselRouterConfig<AppRoute>(
  initial: const HomeRoute(),
  builder: (context, route) => switch (route) {
    HomeRoute() => const Scaffold(body: Center(child: Text('Home'))),
  },
);
