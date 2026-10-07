class Caminhada {
  final String id;
  final String titulo;
  final double origemLatitude;
  final double origemLongitude;
  final double destinoLatitude;
  final double destinoLongitude;
  final List<Map<String, double>> rota;
  final double distanciaKm;
  final double duracaoMin;
  final double calorias;
  final String? fotoBase64;

  const Caminhada({
    required this.id,
    required this.titulo,
    required this.origemLatitude,
    required this.origemLongitude,
    required this.destinoLatitude,
    required this.destinoLongitude,
    required this.rota,
    required this.distanciaKm,
    required this.duracaoMin,
    required this.calorias,
    this.fotoBase64,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'origemLatitude': origemLatitude,
      'origemLongitude': origemLongitude,
      'destinoLatitude': destinoLatitude,
      'destinoLongitude': destinoLongitude,
      'rota': rota,
      'distanciaKm': distanciaKm,
      'duracaoMin': duracaoMin,
      'calorias': calorias,
      'fotoBase64': fotoBase64,
    };
  }

  factory Caminhada.fromMap(Map<String, dynamic> map) {
    final rotaBruta = (map['rota'] as List<dynamic>? ?? []);

    return Caminhada(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      origemLatitude: (map['origemLatitude'] as num).toDouble(),
      origemLongitude: (map['origemLongitude'] as num).toDouble(),
      destinoLatitude: (map['destinoLatitude'] as num).toDouble(),
      destinoLongitude: (map['destinoLongitude'] as num).toDouble(),
      rota: rotaBruta.map<Map<String, double>>((item) {
        final ponto = Map<String, dynamic>.from(item as Map);
        return {
          'latitude': (ponto['latitude'] as num).toDouble(),
          'longitude': (ponto['longitude'] as num).toDouble(),
        };
      }).toList(),
      distanciaKm: (map['distanciaKm'] as num).toDouble(),
      duracaoMin: (map['duracaoMin'] as num).toDouble(),
      calorias: (map['calorias'] as num).toDouble(),
      fotoBase64: map['fotoBase64'] as String?,
    );
  }
}
