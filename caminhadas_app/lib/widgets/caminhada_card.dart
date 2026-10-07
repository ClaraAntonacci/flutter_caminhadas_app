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
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _imagem(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caminhada.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${caminhada.distanciaKm.toStringAsFixed(2)} km',
                    ),
                    Text(
                      '${caminhada.duracaoMin.toStringAsFixed(0)} min • '
                      '${caminhada.calorias.toStringAsFixed(0)} kcal',
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagem() {
    if (caminhada.fotoBase64 != null &&
        caminhada.fotoBase64!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          base64Decode(caminhada.fotoBase64!),
          width: 75,
          height: 75,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.directions_walk,
        size: 38,
        color: Colors.green,
      ),
    );
  }
}
