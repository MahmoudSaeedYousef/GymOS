import 'package:flutter/material.dart';
import 'gym_colors_extension.dart';

class AppTheme {
  // Theme لجيم "ألفا" (أزرق)
  static final ThemeData alphaGymTheme = ThemeData.light().copyWith(
    extensions: <ThemeExtension<dynamic>>[
      const GymColorsExtension(
        brandPrimary: Colors.blueAccent,
        surfaceBackground: Colors.white,
        textHighlight: Colors.blue,
      ),
    ],
  );

  // Theme لجيم "تيتان" (أحمر)
  static final ThemeData titanGymTheme = ThemeData.dark().copyWith(
    extensions: <ThemeExtension<dynamic>>[
      const GymColorsExtension(
        brandPrimary: Colors.redAccent,
        surfaceBackground: Color(0xFF1E1E1E),
        textHighlight: Colors.red,
      ),
    ],
  );
}
