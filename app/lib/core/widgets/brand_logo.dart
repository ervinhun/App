import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';

/// The logo mark and the FridgeFriend wordmark, as in the screen headers.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox.square(
        dimension: 34,
        child: Padding(
          padding: const EdgeInsets.only(left: 3.67, top: 3.67),
          child: Align(
            alignment: Alignment.topLeft,
            child: SvgPicture.asset(
              'assets/images/logo_mark.svg',
              width: 26.66,
              height: 27.12,
            ),
          ),
        ),
      ),
      const SizedBox(width: 7),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Fridge', style: AppText.brand(Colors.black)),
            TextSpan(
              text: 'Friend',
              style: AppText.brand(AppColors.brandPrimary),
            ),
          ],
        ),
      ),
    ],
  );
}
