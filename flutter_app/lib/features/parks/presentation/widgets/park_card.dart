import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/park.dart';

class ParkCard extends StatelessWidget {
  final Park park;
  final VoidCallback onTap;
  const ParkCard({super.key, required this.park, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                park.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.forest.withValues(alpha: 0.15),
                  child:
                      const Icon(Icons.park, size: 48, color: AppColors.forest),
                ),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(park.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place,
                          size: 14, color: AppColors.laterite),
                      const SizedBox(width: 4),
                      Text(park.region,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 13)),
                      const Spacer(),
                      Text('${park.areaKm2} km²',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
