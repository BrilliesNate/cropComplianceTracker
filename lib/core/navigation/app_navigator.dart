import 'package:flutter/widgets.dart';

/// The app's root navigator, so code outside the widget tree (the session
/// watcher, push-notification taps) can navigate.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
