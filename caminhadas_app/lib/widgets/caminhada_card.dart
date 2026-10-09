import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/caminhada.dart';

class CaminhadaCard extends StatelessWidget {
  final Caminhada caminhada;
  final VoidCallback onTap;

  const CaminhadaCard({
    super.key,
    required this.caminhada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildFoto(),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      caminhada.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Icon(
                          Icons.route,
                          size: 17,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${caminhada.distanciaKm.toStringAsFixed(2)} km',
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 17,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${caminhada.calorias.toStringAsFixed(0)} kcal',
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 17,
                          color: Colors.blueGrey.shade600,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatarTempo(
                            caminhada.tempoMinutos,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoto() {
    if (caminhada.fotoBase64 == null ||
        caminhada.fotoBase64!.isEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.image_outlined,
          size: 42,
          color: Colors.green.shade700,
        ),
      );
    }

    try {
      final bytes = base64Decode(
        caminhada.fotoBase64!,
      );

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    } catch (e) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.broken_image_outlined,
          size: 42,
          color: Colors.green.shade700,
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
}