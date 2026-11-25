import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';

/// The logo mark blinking over a sliding bar, while the app gets ready
/// (Figma node 256:72).
///
/// The design loops over 6 seconds: three rounds of the bar sliding across
/// and back, and a blink in each. One round is played here, on repeat. With
/// animations turned off in the phone's settings it stands still.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final _round = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _round.stop();
    } else if (!_round.isAnimating) {
      _round.repeat();
    }
  }

  @override
  void dispose() {
    _round.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.canvas,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BlinkingMark(round: _round),
          const SizedBox(height: 40),
          SizedBox(
            width: 180,
            child: Column(
              children: [
                ExcludeSemantics(child: _SlidingBar(round: _round)),
                const SizedBox(height: 14),
                Text(
                  'Loading…',
                  textAlign: TextAlign.center,
                  style: AppText.nunito(
                    14,
                    FontWeight.w400,
                    AppColors.textPrimary,
                  ).copyWith(height: 20 / 14),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// The two fridges of the logo, drawn from their parts so the eyes can blink.
class _BlinkingMark extends StatelessWidget {
  const _BlinkingMark({required this.round});

  final Animation<double> round;

  /// How open the eyes are [seconds] into a round: they shut to 12% from
  /// 1.36 s to 1.43 s, and are open again at 1.52 s.
  static double _openness(double seconds) {
    const shut = 0.12;
    final t = seconds - 1.36;
    if (t < 0 || t >= 0.16) return 1;
    if (t < 0.07) return 1 - (1 - shut) * Curves.easeInOut.transform(t / 0.07);
    return shut + (1 - shut) * Curves.easeInOut.transform((t - 0.07) / 0.09);
  }

  Widget _part(
    double left,
    double top,
    double width,
    double height,
    Color color, {
    double radius = 0,
    BoxBorder? border,
  }) => Positioned(
    left: left,
    top: top,
    width: width,
    height: height,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: border,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );

  Widget _eye(double left) => Positioned(
    left: left,
    top: 16.22,
    child: AnimatedBuilder(
      animation: round,
      builder: (_, eye) => Transform.scale(
        scaleX: 1,
        scaleY: _openness(round.value * 2),
        child: eye,
      ),
      child: SvgPicture.asset(
        'assets/images/loading_eye.svg',
        width: 6.528,
        height: 6.528,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'FridgeFriend',
    child: SizedBox.square(
      dimension: 108.8,
      child: Padding(
        padding: const EdgeInsets.only(left: 11.74, top: 11.74),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox.square(
            dimension: 85.312,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _part(0, 15.04, 47.616, 70.272, Colors.black, radius: 15.872),
                _part(
                  38.53,
                  1.45,
                  45.344,
                  83.872,
                  AppColors.brandPrimary,
                  radius: 15.872,
                  border: Border.all(color: AppColors.surface, width: 2.901),
                ),
                _part(39.46, 33.06, 44.8, 3.2, AppColors.surface),
                _part(1.06, 33.06, 38.4, 3.2, AppColors.surfaceBlue),
                _eye(49.95),
                _eye(65.92),
                _part(
                  7.94,
                  45.25,
                  5.088,
                  15.872,
                  AppColors.surfaceBlue,
                  radius: 2.539,
                ),
                _part(
                  70.27,
                  45.25,
                  5.088,
                  15.872,
                  AppColors.surface,
                  radius: 2.539,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A short bar that slides across its track and back, brightening and
/// dimming twice on the way.
class _SlidingBar extends StatelessWidget {
  const _SlidingBar({required this.round});

  final Animation<double> round;

  static const _trackWidth = 160.0;
  static const _barWidth = 64.0;

  @override
  Widget build(BuildContext context) => Container(
    width: _trackWidth,
    height: 4,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.surfaceBlue,
      borderRadius: BorderRadius.circular(2),
    ),
    child: AnimatedBuilder(
      animation: round,
      builder: (_, bar) {
        // 0 → 1 across the first second, 1 → 0 back in the next.
        final there = round.value < 0.5
            ? Curves.easeInOut.transform(round.value * 2)
            : 1 - Curves.easeInOut.transform(round.value * 2 - 1);
        // 0.7 → 1 → 0.7 every second.
        final half = (round.value * 4) % 2;
        final glow = half < 1
            ? Curves.easeInOut.transform(half)
            : 1 - Curves.easeInOut.transform(half - 1);
        return Transform.translate(
          offset: Offset(there * (_trackWidth - _barWidth), 0),
          child: Opacity(opacity: 0.7 + 0.3 * glow, child: bar),
        );
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: _barWidth,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.brandPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    ),
  );
}
