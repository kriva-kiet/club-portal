import 'package:flutter/material.dart';

/// Responsive utility helpers for KRIVA Web
class WebResponsive {
  WebResponsive._();

  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1100;
  static const double wideBreakpoint = 1440;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wideBreakpoint;

  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= wideBreakpoint) return 1500;
    if (width >= tabletBreakpoint) return 1300;
    return double.infinity;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= wideBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 40, vertical: 28);
    }
    if (width >= tabletBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 28, vertical: 24);
    }
    if (width >= mobileBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }
}
