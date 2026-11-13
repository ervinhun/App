import 'package:flutter/painting.dart';

/// Colour tokens from the Figma design (Fridge Friend Designs), named after its
/// variables: `text/primary` is [textPrimary], `shadow/ink-8` is [shadowInk8].
abstract final class AppColors {
  static const canvas = Color(0xFFFBF8F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceBlue = Color(0xFFEBF5FA);

  static const textPrimary = Color(0xFF0D4F6B);
  static const textSecondary = Color(0xFF7BAFC4);

  static const brandPrimary = Color(0xFF1B6B8A);
  static const brandAccent = Color(0xFF2E8FAD);

  /// Expiry urgency: eat within a couple of days, within the week, or later.
  static const statusSoon = Color(0xFFC94B2E);
  static const statusUpcoming = Color(0xFFD4A017);
  static const statusFresh = Color(0xFF2A7A4F);

  /// Food card backgrounds.
  static const categoryMeat = Color(0xFFFAE8DC);
  static const categoryDairy = Color(0xFFE8F0FA);
  static const categoryProduce = Color(0xFFEAF5EC);
  static const categoryEggs = Color(0xFFE8F5F0);

  /// The ink colour ([textPrimary]) at 8%, 10%, 19% and 25% opacity.
  static const shadowInk8 = Color(0x140D4F6B);
  static const shadowInk10 = Color(0x1A0D4F6B);
  static const shadowInk19 = Color(0x300D4F6B);
  static const shadowInk25 = Color(0x400D4F6B);
}
