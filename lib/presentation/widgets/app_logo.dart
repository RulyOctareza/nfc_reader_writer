import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nfc_reader_writer/core/constants/app_assets.dart';

/// Logo aplikasi NFC Reader & Writer.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 88,
    this.semanticLabel = 'Logo NFC Reader & Writer',
  });

  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    image: true,
    child: SvgPicture.asset(
      AppAssets.appLogo,
      width: size,
      height: size,
    ),
  );
}
