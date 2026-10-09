import 'package:latlong2/latlong.dart';

class Caminhada {
  final String id;
  final String titulo;

  final double distanciaKm;
  final double calorias;
  final int tempoMinutos;

  final double origemLatitude;
  final double origemLongitude;

  final double destinoLatitude;
  final double destinoLongitude;

  final List<LatLng> rota;

  // Foto armazenada como Base64.
  final String? fotoBase64;

  Caminhada({
    String? id,
    required this.titulo,
    required this.distanciaKm,
    required this.calorias,
    required this.tempoMinutos,
    required this.origemLatitude,
    required this.origemLongitude,
    required this.destinoLatitude,
    required this.destinoLongitude,
    required this.rota,
    this.fotoBase64,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Caminhada copyWith({
    String? titulo,
    double? distanciaKm,
    double? calorias,
    int? tempoMinutos,
    double? origemLatitude,
    double? origemLongitude,
    double? destinoLatitude,
    double? destinoLongitude,
    List<LatLng>? rota,
    String? fotoBase64,
  }) {
    return Caminhada(
      id: id,
      titulo: titulo ?? this.titulo,
      distanciaKm: distanciaKm ?? this.distanciaKm,
      calorias: calorias ?? this.calorias,
      tempoMinutos: tempoMinutos ?? this.tempoMinutos,
      origemLatitude: origemLatitude ?? this.origemLatitude,
      origemLongitude: origemLongitude ?? this.origemLongitude,
      destinoLatitude: destinoLatitude ?? this.destinoLatitude,
      destinoLongitude: destinoLongitude ?? this.destinoLongitude,
      rota: rota ?? this.rota,
      fotoBase64: fotoBase64 ?? this.fotoBase64,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'distanciaKm': distanciaKm,
      'calorias': calorias,
      'tempoMinutos': tempoMinutos,
      'origemLatitude': origemLatitude,
      'origemLongitude': origemLongitude,
      'destinoLatitude': destinoLatitude,
      'destinoLongitude': destinoLongitude,
      'rota': rota
          .map(
            (ponto) => {
              'latitude': ponto.latitude,
              'longitude': ponto.longitude,
            },
          )
          .toList(),
      'fotoBase64': fotoBase64,
    };
  }

  factory Caminhada.fromMap(Map<String, dynamic> map) {
    final listaRota = map['rota'] as List<dynamic>? ?? [];

    final pontos = listaRota.map((item) {
      final ponto = Map<String, dynamic>.from(item as Map);

      return LatLng(
        (ponto['latitude'] as num).toDouble(),
        (ponto['longitude'] as num).toDouble(),
      );
    }).toList();

    return Caminhada(
      id: map['id']?.toString(),
      titulo: map['titulo']?.toString() ?? 'Caminhada',
      distanciaKm:
          (map['distanciaKm'] as num?)?.toDouble() ?? 0,
      calorias:
          (map['calorias'] as num?)?.toDouble() ?? 0,
      tempoMinutos:
          (map['tempoMinutos'] as num?)?.toInt() ?? 0,
      origemLatitude:
          (map['origemLatitude'] as num?)?.toDouble() ?? 0,
      origemLongitude:
          (map['origemLongitude'] as num?)?.toDouble() ?? 0,
      destinoLatitude:
          (map['destinoLatitude'] as num?)?.toDouble() ?? 0,
      destinoLongitude:
          (map['destinoLongitude'] as num?)?.toDouble() ?? 0,
      rota: pontos,
      fotoBase64: map['fotoBase64']?.toString(),
    );
  }
}