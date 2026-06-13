import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/constants/confirm_dialog.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
// import 'dart:io';
// import 'package:image/image.dart' as img;

AppBar getAppBar(BuildContext context, bool isLoggedIn) {
  return AppBar(
    leading: Padding(
      padding: EdgeInsets.all(5),
      child: Image.asset(
        'assets/logo/malhar26.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    ),
    title: Text(
      "Malhar 26",
      style: GoogleFonts.montserrat(
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        fontSize: 24,
      ),
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    actions: [
      IconButton(
        color: AppColors.primary,
        tooltip: 'Refresh Page',
        onPressed: PageRefreshController.triggerRefresh,
        icon: Icon(Icons.restart_alt_sharp),
      ),
      if (isLoggedIn)
        IconButton(
          color: AppColors.primary,
          tooltip: 'Logout',
          onPressed:
              () => confirmDialog(
                context,
                'Confirm Logout',
                Text('Are you sure you want to Logout?'),
                onSubmit: () => Navigator.pop(context),
              ),
          icon: Icon(Icons.output, semanticLabel: 'Logout'),
        ),
    ],
  );
}

// Future<File> resizeImageSmoothly(File inputFile) async {
//   final inputBytes = await inputFile.readAsBytes();
//   final original = img.decodeImage(inputBytes);

//   if (original == null) throw Exception("Image decode failed");

//   // Use high-quality resize with Lanczos interpolation
//   final resizedAverage = img.copyResize(
//     original,
//     width: 512,
//     height: 512,
//     interpolation: img.Interpolation.average, // also try `cubic` or `lanczos3`
//   );

//   final resizedCubic = img.copyResize(
//     original,
//     width: 512,
//     height: 512,
//     interpolation: img.Interpolation.cubic, // also try `cubic` or `lanczos3`
//   );

//   final resizedLinear = img.copyResize(
//     original,
//     width: 512,
//     height: 512,
//     interpolation: img.Interpolation.linear, // also try `cubic` or `lanczos3`
//   );

//   final outputAverage = File('${inputFile.path}_resizedAverage.png');
//   final outputCubic = File('${inputFile.path}_resizeCubic.png');
//   final outputLinear = File('${inputFile.path}_resizedLinear.png');
//   await outputAverage.writeAsBytes(img.encodePng(resizedAverage));
//   await outputCubic.writeAsBytes(img.encodePng(resizedCubic));
//   await outputLinear.writeAsBytes(img.encodePng(resizedLinear));
//   return outputAverage;
// }
