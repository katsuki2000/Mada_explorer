import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../cubit/species_cubit.dart';
import '../cubit/species_state.dart';

class SpeciesListScreen extends StatefulWidget {
  const SpeciesListScreen({super.key});

  @override
  State<SpeciesListScreen> createState() => _SpeciesListScreenState();
}

class _SpeciesListScreenState extends State<SpeciesListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SpeciesCubit>().loadSpecies();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'En danger critique':
        return Colors.red.shade700;
      case 'En danger':
        return AppColors.laterite;
      case 'Vulnerable':
        return AppColors.sunset;
      default:
        return AppColors.forest;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faune endemique')),
      body: BlocBuilder<SpeciesCubit, SpeciesState>(
        builder: (context, state) {
          if (state is SpeciesLoading) return const Center(child: CircularProgressIndicator());
          if (state is SpeciesError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 56, color: Colors.black38),
                    const SizedBox(height: 12),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<SpeciesCubit>().loadSpecies(),
                      child: const Text('Reessayer'),
                    ),
                  ],
                ),
              ),
            );
          }
          final loaded = state as SpeciesLoaded;
          return RefreshIndicator(
            onRefresh: () => context.read<SpeciesCubit>().loadSpecies(),
            child: Column(
              children: [
                if (loaded.isOffline) const OfflineBanner(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: loaded.species.length,
                    itemBuilder: (context, index) {
                      final s = loaded.species[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              s.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: AppColors.forest.withValues(alpha: 0.15),
                                child: const Icon(Icons.pets, color: AppColors.forest),
                              ),
                            ),
                          ),
                          title: Text(s.commonName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(s.scientificName,
                                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(s.conservationStatus).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s.conservationStatus,
                              style: TextStyle(
                                  color: _statusColor(s.conservationStatus), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          isThreeLine: false,
                          onTap: () => showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            builder: (_) => Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.commonName, style: Theme.of(context).textTheme.titleLarge),
                                  Text(s.scientificName,
                                      style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
                                  const SizedBox(height: 12),
                                  Text(s.description, style: const TextStyle(height: 1.5)),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
