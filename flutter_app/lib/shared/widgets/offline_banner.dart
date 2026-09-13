import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Small persistent banner shown at the top of a screen when data being
/// displayed comes from the local cache because there is no connectivity.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.sunset,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 16, color: Colors.black87),
          SizedBox(width: 8),
          Text(
            'Mode hors ligne - donnees en cache',
            style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
