import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = state.user;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.forest,
                  child: Icon(Icons.person, size: 42, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(user.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(user.email, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 32),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.baobab),
                  title: Text('A propos'),
                  subtitle:
                      Text('Mada Explorer - parcs et faune de Madagascar'),
                ),
                const Divider(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.read<AuthCubit>().logout(),
                    icon: const Icon(Icons.logout, color: AppColors.laterite),
                    label: const Text('Se deconnecter',
                        style: TextStyle(color: AppColors.laterite)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.laterite),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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
