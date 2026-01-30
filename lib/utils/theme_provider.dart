import 'package:flutter/material.dart';
import 'package:camp_x/utils/theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = CampXTheme.darkTheme;
  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData.brightness == Brightness.dark;

  void toggleTheme() {
    if (_themeData.brightness == Brightness.dark) {
      _themeData = CampXTheme.lightTheme;
    } else {
      _themeData = CampXTheme.darkTheme;
    }
    notifyListeners();
  }
}
