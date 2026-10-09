
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
  final ImagePicker _imagePicker = ImagePicker();
  final CaminhadaStorageService _storage =
      CaminhadaStorageService();

  late Caminhada _caminhada;

  @override
  void initState() {
    super.initState();
    _caminhada = widget.caminhada;
  }

  Future<void> _salvarFoto(String fotoBase64) async {
    try {
      // Mantém o ID original e atualiza somente a foto.
      final atualizada = _caminhada.copyWith(
        fotoBase64: fotoBase64,
      );

      await _storage.atualizar(atualizada);

      if (!mounted) return;

      setState(() {
        _caminhada = atualizada;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto salva com sucesso!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar a foto: $e'),
        ),
      );
    }
  }

  Future<void> _tirarFoto() async {
    try {
      final imagem = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (imagem == null) return;

      final bytes = await imagem.readAsBytes();
      final fotoBase64 = base64Encode(bytes);

      await _salvarFoto(fotoBase64);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível tirar a foto: $e'),
        ),
      );
    }
  }

  Future<void> _escolherFoto() async {
    try {
      final imagem = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (imagem == null) return;

      final bytes = await imagem.readAsBytes();
      final fotoBase64 = base64Encode(bytes);

      await _salvarFoto(fotoBase64);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível escolher a foto: $e'),
        ),
      );
    }
  }

  String _formatarTempo(int minutos) {
    if (minutos < 60) {
      return '$minutos min';
    }

    final horas = minutos ~/ 60;
    final resto = minutos % 60;

    if (resto == 0) {
      return '${horas}h';
    }

    return '${horas}h ${resto}min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_caminhada.titulo),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFoto(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _caminhada.titulo,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInformacoes(),
                  const SizedBox(height: 24),
                  const Text(
                    'Trajeto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildMapa(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoto() {
    final foto = _caminhada.fotoBase64;

    if (foto == null || foto.isEmpty) {
      return Container(
        width: double.infinity,
        height: 230,
        color: Colors.grey.shade100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 55,
                color: Colors.green.shade700,
              ),
              const SizedBox(height: 10),
              const Text(
                'Nenhuma foto adicionada',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _tirarFoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Tirar foto'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _escolherFoto,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeria'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    try {
      final bytes = base64Decode(foto);

      return Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 260,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 60,
                  ),
                );
              },
            ),
          ),
          Positioned(
            right: 14,
            bottom: 14,
            child: Row(
              children: [
                FloatingActionButton.small(
                  heroTag: 'camera',
                  onPressed: _tirarFoto,
                  tooltip: 'Tirar outra foto',
                  child: const Icon(Icons.camera_alt),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'galeria',
                  onPressed: _escolherFoto,
                  tooltip: 'Trocar foto',
                  child: const Icon(Icons.photo_library),
                ),
              ],
            ),
          ),
        ],
      );
    } catch (e) {
      return Container(
        width: double.infinity,
        height: 230,
        color: Colors.grey.shade100,
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 60,
          ),
        ),
      );
    }
  }

  Widget _buildInformacoes() {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.route,
            titulo: 'Distância',
            valor:
                '${_caminhada.distanciaKm.toStringAsFixed(2)} km',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InfoCard(
            icon: Icons.local_fire_department,
            titulo: 'Calorias',
            valor:
                '${_caminhada.calorias.toStringAsFixed(0)} kcal',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InfoCard(
            icon: Icons.access_time,
            titulo: 'Tempo',
            valor: _formatarTempo(_caminhada.tempoMinutos),
          ),
        ),
      ],
    );
  }

  Widget _buildMapa() {
    final centro = _caminhada.rota.isNotEmpty
        ? _caminhada.rota.first
        : LatLng(
            _caminhada.origemLatitude,
            _caminhada.origemLongitude,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 330,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: centro,
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.caminhadas_app',
            ),
            if (_caminhada.rota.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _caminhada.rota,
                    strokeWidth: 5,
                    color: Colors.green.shade700,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(
                    _caminhada.origemLatitude,
                    _caminhada.origemLongitude,
                  ),
                  width: 45,
                  height: 45,
                  child: const Icon(
                    Icons.location_on,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
                Marker(
                  point: LatLng(
                    _caminhada.destinoLatitude,
                    _caminhada.destinoLongitude,
                  ),
                  width: 45,
                  height: 45,
                  child: const Icon(
                    Icons.location_on,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String valor;

  const _InfoCard({
    required this.icon,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.green.shade700,
          ),
          const SizedBox(height: 5),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            valor,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
