import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/caminhada.dart';
import '../services/caminhada_storage_service.dart';
import '../services/rota_service.dart';
import '../utils/calculadora_caminhada.dart';

class NovaCaminhadaScreen extends StatefulWidget {
  const NovaCaminhadaScreen({super.key});

  @override
  State<NovaCaminhadaScreen> createState() => _NovaCaminhadaScreenState();
}

class _NovaCaminhadaScreenState extends State<NovaCaminhadaScreen> {
  static const LatLng origem = LatLng(-22.7130000, -46.8180000);

  final MapController _mapController = MapController();
  final RotaService _rotaService = RotaService();
  final CaminhadaStorageService _storage = CaminhadaStorageService();

  LatLng? destino;
  List<LatLng> pontosRota = [];
  double? distanciaKm;
  double? duracaoMin;
  bool calculando = false;

  Future<void> _selecionarDestino(LatLng ponto) async {
    setState(() {
      destino = ponto;
      pontosRota = [];
      distanciaKm = null;
      duracaoMin = null;
      calculando = true;
    });

    try {
      final resultado = await _rotaService.calcularRota(
        origem: origem,
        destino: ponto,
      );

      if (!mounted) return;

      setState(() {
        pontosRota = resultado.pontos;
        distanciaKm = resultado.distanciaKm;
        duracaoMin = resultado.duracaoMin;
        calculando = false;
      });

      if (pontosRota.isNotEmpty) {
        _ajustarMapa();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        calculando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível calcular a rota.'),
        ),
      );
    }
  }

  void _ajustarMapa() {
    if (destino == null) return;

    final menorLat = math.min(origem.latitude, destino!.latitude);
    final maiorLat = math.max(origem.latitude, destino!.latitude);
    final menorLng = math.min(origem.longitude, destino!.longitude);
    final maiorLng = math.max(origem.longitude, destino!.longitude);

    final centro = LatLng(
      (menorLat + maiorLat) / 2,
      (menorLng + maiorLng) / 2,
    );

    final maiorDiferenca = math.max(
      maiorLat - menorLat,
      maiorLng - menorLng,
    );

    double zoom = 17;
    if (maiorDiferenca > 0.03) {
      zoom = 12;
    } else if (maiorDiferenca > 0.015) {
      zoom = 13;
    } else if (maiorDiferenca > 0.008) {
      zoom = 14;
    } else if (maiorDiferenca > 0.004) {
      zoom = 15;
    } else if (maiorDiferenca > 0.002) {
      zoom = 16;
    }

    _mapController.move(centro, zoom);
  }

  Future<void> _salvar() async {
    if (destino == null || pontosRota.isEmpty || distanciaKm == null) {
      return;
    }

    final controller = TextEditingController();

    final titulo = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Salvar caminhada'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Título da caminhada',
              hintText: 'Ex.: Caminhada da manhã',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final texto = controller.text.trim();
                if (texto.isEmpty) return;
                Navigator.pop(context, texto);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (titulo == null || titulo.trim().isEmpty) return;

    final caminhada = Caminhada(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: titulo.trim(),
      origemLatitude: origem.latitude,
      origemLongitude: origem.longitude,
      destinoLatitude: destino!.latitude,
      destinoLongitude: destino!.longitude,
      rota: pontosRota
          .map((ponto) => {
                'latitude': ponto.latitude,
                'longitude': ponto.longitude,
              })
          .toList(),
      distanciaKm: distanciaKm!,
      duracaoMin: duracaoMin ??
          CalculadoraCaminhada.tempoMinutos(distanciaKm!),
      calorias: CalculadoraCaminhada.calorias(distanciaKm!),
    );

    await _storage.salvar(caminhada);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final calorias = distanciaKm == null
        ? null
        : CalculadoraCaminhada.calorias(distanciaKm!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova caminhada'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: origem,
              initialZoom: 17,
              onTap: (_, ponto) => _selecionarDestino(ponto),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.caminhadas_app',
              ),
              if (pontosRota.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: pontosRota,
                      strokeWidth: 6,
                      color: Colors.blue,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: origem,
                    width: 55,
                    height: 55,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 50,
                    ),
                  ),
                  if (destino != null)
                    Marker(
                      point: destino!,
                      width: 55,
                      height: 55,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  destino == null
                      ? 'Clique no destino da sua caminhada'
                      : 'Destino: ${destino!.latitude.toStringAsFixed(5)}, '
                          '${destino!.longitude.toStringAsFixed(5)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
          if (calculando)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(),
                      ),
                      SizedBox(width: 12),
                      Text('Calculando rota...'),
                    ],
                  ),
                ),
              ),
            ),
          if (destino != null && pontosRota.isNotEmpty && !calculando)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.route, color: Colors.green),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Dados da caminhada',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _info(
                            Icons.straighten,
                            '${distanciaKm!.toStringAsFixed(2)} km',
                          ),
                          _info(
                            Icons.timer_outlined,
                            '${(duracaoMin ?? 0).toStringAsFixed(0)} min',
                          ),
                          _info(
                            Icons.local_fire_department_outlined,
                            '${(calorias ?? 0).toStringAsFixed(0)} kcal',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _salvar,
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String texto) {
    return Column(
      children: [
        Icon(icon, size: 22),
        const SizedBox(height: 4),
        Text(texto),
      ],
    );
  }
}
