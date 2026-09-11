import 'package:material_ui/material_ui.dart';

/// Material 3 expressive color variants mapped to Flutter's [DynamicSchemeVariant].
enum M3EColorVariant {
  monochrome,
  neutral,
  tonalSpot,
  vibrant,
  expressive,
  fidelity,
  content,
  rainbow,
  fruitSalad;

  DynamicSchemeVariant toDynamicSchemeVariant() {
    switch (this) {
      case M3EColorVariant.monochrome:
        return DynamicSchemeVariant.monochrome;
      case M3EColorVariant.neutral:
        return DynamicSchemeVariant.neutral;
      case M3EColorVariant.tonalSpot:
        return DynamicSchemeVariant.tonalSpot;
      case M3EColorVariant.vibrant:
        return DynamicSchemeVariant.vibrant;
      case M3EColorVariant.expressive:
        return DynamicSchemeVariant.expressive;
      case M3EColorVariant.fidelity:
        return DynamicSchemeVariant.fidelity;
      case M3EColorVariant.content:
        return DynamicSchemeVariant.content;
      case M3EColorVariant.rainbow:
        return DynamicSchemeVariant.rainbow;
      case M3EColorVariant.fruitSalad:
        return DynamicSchemeVariant.fruitSalad;
    }
  }
}
