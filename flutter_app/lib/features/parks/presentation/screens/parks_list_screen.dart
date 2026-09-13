import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../cubit/parks_cubit.dart';
import '../cubit/parks_state.dart';
import '../widgets/park_card.dart';
import 'park_detail_screen.dart';

class ParksListScreen extends StatefulWidget {
  const ParksListScreen({super.key});

  @override
  State<ParksListScreen> createState() => _ParksListScreenState();
}

class _ParksListScreenState extends State<ParksListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ParksCubit>().loadParks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parcs nationaux')),
      body: BlocBuilder<ParksCubit, ParksState>(
        builder: (context, state) {
          if (state is ParksLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ParksError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<ParksCubit>().loadParks(forceRefresh: true),
            );
          }
          final loaded = state as ParksLoaded;
          return RefreshIndicator(
            onRefresh: () => context.read<ParksCubit>().loadParks(forceRefresh: true),
            child: Column(
              children: [
                if (loaded.isOffline) const OfflineBanner(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: loaded.parks.length,
                    itemBuilder: (context, index) {
                      final park = loaded.parks[index];
                      return ParkCard(
                        park: park,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ParkDetailScreen(parkId: park.id)),
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.black38),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Reessayer')),
          ],
        ),
      ),
    );
  }
}
