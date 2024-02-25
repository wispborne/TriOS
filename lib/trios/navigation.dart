import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// GoRoute GoRouteDefaultTransition({
//   required String path,
//   required Widget Function(BuildContext, GoRouterState) builder,
// }) {
//   return GoRoute(
//     path: path,
//     pageBuilder: (context, state) => CustomTransitionPage<void>(
//       key: state.pageKey,
//       transitionDuration: const Duration(milliseconds: 300),
//       child: builder(context, state),
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         return NoTransitionPage(
//           opacity: CurveTween(curve: Curves.easeIn).animate(animation),
//           child: child,
//         );
//       },
//     ),
//   );
// }