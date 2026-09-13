import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/parks/presentation/cubit/parks_cubit.dart';
import 'features/species/presentation/cubit/species_cubit.dart';

import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/parks/presentation/screens/parks_list_screen.dart';
import 'features/species/presentation/screens/species_list_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';

import 'core/di/injection_container.dart' as di;

class MadaExplorerApp extends StatelessWidget {
  const MadaExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => di.sl<AuthCubit>()..restoreSession()),
        BlocProvider<ParksCubit>(create: (_) => di.sl<ParksCubit>()),
        BlocProvider<SpeciesCubit>(create: (_) => di.sl<SpeciesCubit>()),
      ],
      child: MaterialApp(
        title: 'Mada Explorer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _RootRouter(),
      ),
    );
  }
}

/// Decides which screen to show first based on the restored session:
/// authenticated -> the tabbed home; otherwise -> the login screen.
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) return const HomeShell();
        if (state is AuthUnauthenticated || state is AuthError) return const LoginScreen();
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

/// Bottom-navigation shell hosting the three data-driven screens required
/// by the assignment: Parks, Species, Profile.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    ParksListScreen(),
    SpeciesListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.park_outlined), selectedIcon: Icon(Icons.park), label: 'Parcs'),
          NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Faune'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
