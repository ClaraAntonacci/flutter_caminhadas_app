import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MenuLateral extends StatelessWidget {
  final bool temaEscuro;
  final VoidCallback alternarTema;
  final VoidCallback abrirSplash;

  const MenuLateral({
    super.key,
    required this.temaEscuro,
    required this.alternarTema,
    required this.abrirSplash,
  });

  void _sair(BuildContext context) {
    Navigator.pop(context);

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No navegador, feche a aba para sair do aplicativo.',
          ),
        ),
      );
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                20,
                30,
                20,
                30,
              ),
              color: Colors.green.shade700,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.directions_walk,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Caminhadas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Splash'),
              onTap: () {
                Navigator.pop(context);
                abrirSplash();
              },
            ),

            ListTile(
              leading: Icon(
                temaEscuro
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              title: Text(
                temaEscuro
                    ? 'Tema claro'
                    : 'Tema escuro',
              ),
              onTap: () {
                alternarTema();
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () {
                _sair(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}