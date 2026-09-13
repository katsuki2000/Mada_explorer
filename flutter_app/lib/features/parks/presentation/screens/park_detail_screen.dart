import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../species/domain/entities/species.dart';
import '../../../species/domain/usecases/get_species_usecase.dart';
import '../../domain/entities/park.dart';
import '../../domain/usecases/get_park_by_id_usecase.dart';

class ParkDetailScreen extends StatefulWidget {
  final String parkId;
  const ParkDetailScreen({super.key, required this.parkId});

  @override
  State<ParkDetailScreen> createState() => _ParkDetailScreenState();
}

class _ParkDetailScreenState extends State<ParkDetailScreen> {
  late Future<Either<Failure, Park>> _parkFuture;
  late Future<Either<Failure, List<Species>>> _speciesFuture;

  @override
  void initState() {
    super.initState();
    _parkFuture = sl<GetParkByIdUseCase>()(GetParkByIdParams(widget.parkId));
    _speciesFuture = sl<GetSpeciesUseCase>()(const GetSpeciesParams());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Either<Failure, Park>>(
        future: _parkFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return snapshot.data!.fold(
            (failure) => Scaffold(
              appBar: AppBar(),
              body: Center(child: Text(failure.message)),
            ),
            (park) => _ParkDetailBody(park: park, speciesFuture: _speciesFuture),
          );
        },
      ),
    );
  }
}

class _ParkDetailBody extends StatelessWidget {
  final Park park;
  final Future<Either<Failure, List<Species>>> speciesFuture;
  const _ParkDetailBody({required this.park, required this.speciesFuture});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(park.name, style: const TextStyle(fontSize: 15)),
            background: Image.network(
              park.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppColors.forest),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _InfoChip(icon: Icons.place, label: park.region),
                    const SizedBox(width: 8),
                    _InfoChip(icon: Icons.straighten, label: '${park.areaKm2} km²'),
                    const SizedBox(width: 8),
                    _InfoChip(icon: Icons.calendar_today, label: '${park.createdYear}'),
                  ],
                ),
                const SizedBox(height: 20),
                Text(park.description, style: const TextStyle(fontSize: 15, height: 1.5)),
                const SizedBox(height: 24),
                Text('Especes observables', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                FutureBuilder<Either<Failure, List<Species>>>(
                  future: speciesFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    return snapshot.data!.fold(
                      (failure) => Text(failure.message),
                      (allSpecies) {
                        final relevant = allSpecies.where((s) => park.speciesIds.contains(s.id)).toList();
                        if (relevant.isEmpty) return const Text('Aucune donnee disponible.');
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: relevant
                              .map((s) => Chip(
                                    avatar: const Icon(Icons.pets, size: 16, color: AppColors.forest),
                                    label: Text(s.commonName),
                                    backgroundColor: AppColors.forest.withValues(alpha: 0.08),
                                  ))
                              .toList(),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppColors.baobab),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColors.cream,
    );
  }
}
