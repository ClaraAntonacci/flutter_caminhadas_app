import 'package:flutter/material.dart';

import '../models/caminhada.dart';
import '../services/caminhada_storage_service.dart';
import '../widgets/caminhada_card.dart';
import '../widgets/menu_lateral.dart';
import 'detalhes_caminhada_screen.dart';
import 'nova_caminhada_screen.dart';
import 'splash_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool temaEscuro;
  final VoidCallback alternarTema;

  const HomeScreen({
    super.key,
    required this.temaEscuro,
    required this.alternarTema,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CaminhadaStorageService _storage = CaminhadaStorageService();

  List<Caminhada> caminhadas = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarCaminhadas();
  }

  Future<void> _carregarCaminhadas() async {
    final dados = await _storage.listar();

    if (!mounted) return;

    setState(() {
      caminhadas = dados;
      carregando = false;
    });
  }

  Future<void> _novaCaminhada() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const NovaCaminhadaScreen(),
      ),
    );

    if (resultado == true) {
      await _carregarCaminhadas();
    }
  }

  void _abrirSplash() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SplashScreen(
          onFinished: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MenuLateral(
        temaEscuro: widget.temaEscuro,
        alternarTema: widget.alternarTema,
        abrirSplash: _abrirSplash,
      ),

      appBar: AppBar(
        title: const Text(
          'Caminhadas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),

      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : caminhadas.isEmpty
              ? _estadoVazio()
              : RefreshIndicator(
                  onRefresh: _carregarCaminhadas,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: caminhadas.length,
                    itemBuilder: (context, index) {
                      final caminhada = caminhadas[index];

                      return CaminhadaCard(
                        caminhada: caminhada,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetalhesCaminhadaScreen(
                                caminhada: caminhada,
                              ),
                            ),
                          );

                          await _carregarCaminhadas();
                        },
                      );
                    },
                  ),
                ),

      floatingActionButton: FloatingActionButton(
        onPressed: _novaCaminhada,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _estadoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_walk,
              size: 80,
              color: Colors.green.shade600,
            ),

            const SizedBox(height: 20),

            const Text(
              'Nenhuma caminhada cadastrada',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Toque no botão + para registrar sua primeira caminhada.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}