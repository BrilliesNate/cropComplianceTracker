import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileView;
  final Widget tabletView;
  final Widget desktopView;

  const ResponsiveLayout({
    Key? key,
    required this.mobileView,
    required this.tabletView,
    required this.desktopView,
  }) : super(key: key);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
          MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1100) {
          return desktopView;
        } else if (constraints.maxWidth >= 650) {
          return tabletView;
        } else {
          return mobileView;
        }
      },
    );
  }
}