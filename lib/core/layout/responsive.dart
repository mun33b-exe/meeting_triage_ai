import 'package:flutter/widgets.dart';

/// Breakpoint helpers and a `constrainedContainer` helper that centres
/// content horizontally with a max-width cap — the primary layout primitive
/// used on both screens.
abstract final class Responsive {
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 960.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobileBreakpoint && w < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  /// Centres [child] horizontally and constrains its width to [maxWidth].
  /// [padding] is applied inside the constraint so that it counts against the
  /// available content width on narrow screens.
  static Widget constrainedContainer({
    required Widget child,
    double maxWidth = 720.0,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 20.0),
  }) {
    return Align(
      // topCenter: only constrains horizontally; lets the child dictate height.
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
