import 'package:flutter/material.dart';

class RouteProvider extends ChangeNotifier {
  String _activeRoute = '/dashboard'; // Default to dashboard

  String get activeRoute => _activeRoute;

  void setActiveRoute(String route) {
    if (_activeRoute != route) {
      _activeRoute = route;
      notifyListeners();
    }
  }
}