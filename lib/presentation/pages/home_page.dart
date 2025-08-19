import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/injection_container.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_bloc.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_event.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_state.dart';
import 'package:fusion_box/presentation/pages/pokemon_selection_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => instance<GameSetupBloc>()..add(CheckGamePath()),
      child: BlocListener<GameSetupBloc, GameSetupState>(
        listener: (context, state) {
          if (state is GamePathSet) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Game path configured successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        child: BlocBuilder<GameSetupBloc, GameSetupState>(
          builder: (context, state) {
            if (state is GameSetupLoading) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Checking game configuration...'),
                    ],
                  ),
                ),
              );
            }

            return const PokemonSelectionPage();
          },
        ),
      ),
    );
  }
}
