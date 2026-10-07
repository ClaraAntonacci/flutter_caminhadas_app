import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../models/caminhada.dart';
import '../services/caminhada_storage_service.dart';

class DetalhesCaminhadaScreen extends StatefulWidget {
  final Caminhada caminhada;

  const DetalhesCaminhadaScreen({
    super.key,
    required this.caminhada,
  });

  @override
  State<DetalhesCaminhadaScreen> createState() =>
      _DetalhesCaminhadaScreenState();
}

class _DetalhesCaminhadaScreenState
    extends State<DetalhesCaminhadaScreen> {
  final ImagePicker _picker = ImagePicker();
  final CaminhadaStorageService _storage = CaminhadaStorageService();

  String? fotoBase64;

  @override
  void initState() {
    super.initState();
    fotoBase64 = widget.caminhada.fotoBase64;
  }

  Future<void> _tirarFoto() async {
    try {
      final arquivo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1200,
      );

      if (arquivo == null) return;

      final bytes = await arquivo.readAsBytes();
      final base64 = base64Encode(bytes);

      final atualizada = Caminhada(
        id: widget.caminhada.id,
        titulo: widget.caminhada.titulo,
        origemLatitude: widget.caminhada.origemLatitude,
        origemLongitude: widget.caminhada.origemLongitude,
        destinoLatitude: widget.caminhada.destinoLatitude,
        destinoLongitude: widget.caminhada.destinoLongitude,
        rota: widget.caminhada.rota,
        distanciaKm: widget.caminhada.distanciaKm,
        duracaoMin: widget.caminhada.duracaoMin,
        calorias: widget.caminhada.calorias,
        fotoBase64: base64,
      );

      await _storage.salvar(atualizada);

      if (!mounted) return;

      setState(() {
        fotoBase64 = base64;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto salva com sucesso.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir a câmera.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rota = widget.caminhada.rota
        .map(
          (ponto) => LatLng(
            ponto['latitude']!,
            ponto['longitude']!,
          ),
        )
        .toList();

    final origem = LatLng(
      widget.caminhada.origemLatitude,
      widget.caminhada.origemLongitude,
    );

    final destino = LatLng(
      widget.caminhada.destinoLatitude,
      widget.caminhada.destinoLongitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da caminhada'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 360,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: destino,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.caminhadas_app',
                ),
                if (rota.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: rota,
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
                    Marker(
                      point: destino,
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
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.caminhada.titulo,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _infoCard(
                  Icons.straighten,
                  'Distância',
                  '${widget.caminhada.distanciaKm.toStringAsFixed(2)} km',
                ),
                _infoCard(
                  Icons.timer_outlined,
                  'Tempo de caminhada',
                  '${widget.caminhada.duracaoMin.toStringAsFixed(0)} minutos',
                ),
                _infoCard(
                  Icons.local_fire_department_outlined,
                  'Gasto calórico estimado',
                  '${widget.caminhada.calorias.toStringAsFixed(0)} kcal',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Foto da caminhada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (fotoBase64 == null || fotoBase64!.isEmpty)
                  InkWell(
                    onTap: _tirarFoto,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 60,
                            color: Colors.green,
                          ),
                          SizedBox(height: 10),
                          Text('Tirar foto'),
                        ],
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      base64Decode(fotoBase64!),
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String titulo, String valor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(titulo),
        subtitle: Text(
          valor,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
