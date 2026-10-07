import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ResultadoRota {
  final List<LatLng> pontos;
  final double distanciaKm;
  final double duracaoMin;

  const ResultadoRota({
    required this.pontos,
    required this.distanciaKm,
    required this.duracaoMin,
  });
}

class RotaService {
  Future<ResultadoRota> calcularRota({
    required LatLng origem,
    required LatLng destino,
  }) async {
    final url = Uri.parse(
      'https://routing.openstreetmap.de/routed-foot/route/v1/driving/'
      '${origem.longitude},${origem.latitude};'
      '${destino.longitude},${destino.latitude}'
      '?overview=full&geometries=geojson',
    );

    final resposta = await http.get(url);

    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível calcular a rota.');
    }

    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;
    final rotas = dados['routes'] as List<dynamic>?;

    if (rotas == null || rotas.isEmpty) {
      throw Exception('Nenhuma rota encontrada.');
    }

    final rota = rotas.first as Map<String, dynamic>;
    final geometria = rota['geometry'] as Map<String, dynamic>;
    final coordenadas = geometria['coordinates'] as List<dynamic>;

    final pontos = coordenadas.map<LatLng>((coordenada) {
      final ponto = coordenada as List<dynamic>;
      return LatLng(
        (ponto[1] as num).toDouble(),
        (ponto[0] as num).toDouble(),
      );
    }).toList();

    return ResultadoRota(
      pontos: pontos,
      distanciaKm: ((rota['distance'] as num).toDouble()) / 1000,
      duracaoMin: ((rota['duration'] as num).toDouble()) / 60,
    );
  }
}
