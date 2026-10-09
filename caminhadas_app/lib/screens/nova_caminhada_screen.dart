import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../models/caminhada.dart';
import '../services/caminhada_storage_service.dart';

class NovaCaminhadaScreen extends StatefulWidget {
  const NovaCaminhadaScreen({super.key});

  @override
  State<NovaCaminhadaScreen> createState() =>
      _NovaCaminhadaScreenState();
}

class _NovaCaminhadaScreenState
    extends State<NovaCaminhadaScreen> {
  final MapController _mapController = MapController();

  final CaminhadaStorageService _storage =
      CaminhadaStorageService();

  final ImagePicker _imagePicker = ImagePicker();

  LatLng? _origem;
  LatLng? _destino;

  List<LatLng> _rota = [];

  double _distanciaKm = 0;
  double _calorias = 0;
  int _tempoMinutos = 0;

  bool _carregandoLocalizacao = true;
  bool _calculandoRota = false;

  String? _erro;

  @override
  void initState() {
    super.initState();
    _obterLocalizacao();
  }

  Future<void> _obterLocalizacao() async {
    try {
      final servicoAtivo =
          await Geolocator.isLocationServiceEnabled();

      if (!servicoAtivo) {
        throw Exception('Serviço de localização desativado.');
      }

      LocationPermission permissao =
          await Geolocator.checkPermission();

      if (permissao == LocationPermission.denied) {
        permissao =
            await Geolocator.requestPermission();
      }

      if (permissao == LocationPermission.denied ||
          permissao ==
              LocationPermission.deniedForever) {
        throw Exception('Permissão de localização negada.');
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final local = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _origem = local;
        _carregandoLocalizacao = false;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;

      // Ponto padrão para testes
      const localPadrao = LatLng(
        -23.5505,
        -46.6333,
      );

      setState(() {
        _origem = localPadrao;
        _carregandoLocalizacao = false;
        _erro =
            'Não foi possível obter sua localização. '
            'Foi utilizado um ponto padrão para o teste.';
      });
    }
  }

  Future<void> _selecionarDestino(
    LatLng destino,
  ) async {
    if (_origem == null) return;

    setState(() {
      _destino = destino;
      _rota = [];
      _distanciaKm = 0;
      _calorias = 0;
      _tempoMinutos = 0;
      _calculandoRota = true;
      _erro = null;
    });

    try {
      final resultado = await _calcularRota(
        _origem!,
        destino,
      );

      if (!mounted) return;

      setState(() {
        _rota = resultado.rota;
        _distanciaKm = resultado.distanciaKm;
        _tempoMinutos = resultado.tempoMinutos;

        // Estimativa simples.
        _calorias = _distanciaKm * 50;

        _calculandoRota = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _calculandoRota = false;
        _erro =
            'Não foi possível calcular a rota.';
      });
    }
  }

  Future<_ResultadoRota> _calcularRota(
    LatLng origem,
    LatLng destino,
  ) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/foot/'
      '${origem.longitude},${origem.latitude};'
      '${destino.longitude},${destino.latitude}'
      '?overview=full&geometries=geojson',
    );

    final resposta = await http.get(url);

    if (resposta.statusCode != 200) {
      throw Exception(
        'Erro na API de rotas: ${resposta.statusCode}',
      );
    }

    final dados =
        jsonDecode(resposta.body)
            as Map<String, dynamic>;

    final rotas =
        dados['routes'] as List<dynamic>?;

    if (rotas == null || rotas.isEmpty) {
      throw Exception('Nenhuma rota encontrada.');
    }

    final primeiraRota =
        rotas.first as Map<String, dynamic>;

    final distanciaMetros =
        (primeiraRota['distance'] as num)
            .toDouble();

    final duracaoSegundos =
        (primeiraRota['duration'] as num)
            .toDouble();

    final geometria =
        primeiraRota['geometry']
            as Map<String, dynamic>;

    final coordenadas =
        geometria['coordinates']
            as List<dynamic>;

    final pontos =
        coordenadas.map((coordenada) {
      final lista =
          coordenada as List<dynamic>;

      return LatLng(
        (lista[1] as num).toDouble(),
        (lista[0] as num).toDouble(),
      );
    }).toList();

    return _ResultadoRota(
      rota: pontos,
      distanciaKm: distanciaMetros / 1000,
      tempoMinutos:
          (duracaoSegundos / 60).ceil(),
    );
  }

  Future<void> _abrirModalSalvar() async {
    if (_destino == null || _rota.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione um destino e aguarde a rota ser calculada.',
          ),
        ),
      );
      return;
    }

    final tituloController =
        TextEditingController();

    String? fotoBase64;

    final resultado =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Salvar caminhada',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tituloController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Título da caminhada',
                        border:
                            OutlineInputBorder(),
                        prefixIcon:
                            Icon(Icons.title),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (fotoBase64 != null)
                      _buildPreviewDialog(
                        fotoBase64!,
                      ),

                    const SizedBox(height: 10),

                    OutlinedButton.icon(
                      onPressed: () async {
                        final imagem =
                            await _imagePicker
                                .pickImage(
                          source:
                              ImageSource.gallery,
                          imageQuality: 80,
                        );

                        if (imagem == null) {
                          return;
                        }

                        final bytes =
                            await imagem.readAsBytes();

                        setDialogState(() {
                          fotoBase64 =
                              base64Encode(bytes);
                        });
                      },
                      icon: const Icon(
                        Icons.photo_library_outlined,
                      ),
                      label: Text(
                        fotoBase64 == null
                            ? 'Escolher foto'
                            : 'Trocar foto',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text(
                    'Cancelar',
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final titulo =
                        tituloController.text.trim();

                    if (titulo.isEmpty) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Digite um título.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      {
                        'titulo': titulo,
                        'fotoBase64':
                            fotoBase64,
                      },
                    );
                  },
                  icon: const Icon(
                    Icons.save,
                  ),
                  label: const Text(
                    'Salvar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    tituloController.dispose();

    if (resultado == null) return;

    final titulo =
        resultado['titulo'] as String;

    final foto =
        resultado['fotoBase64'] as String?;

    final caminhada = Caminhada(
      titulo: titulo,
      distanciaKm: _distanciaKm,
      calorias: _calorias,
      tempoMinutos: _tempoMinutos,
      origemLatitude: _origem!.latitude,
      origemLongitude: _origem!.longitude,
      destinoLatitude: _destino!.latitude,
      destinoLongitude: _destino!.longitude,
      rota: _rota,
      fotoBase64: foto,
    );

    await _storage.salvar(caminhada);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Caminhada salva com sucesso!',
        ),
      ),
    );

    Navigator.pop(context, true);
  }

  Widget _buildPreviewDialog(
    String fotoBase64,
  ) {
    try {
      final bytes =
          base64Decode(fotoBase64);

      return ClipRRect(
        borderRadius:
            BorderRadius.circular(10),
        child: Image.memory(
          bytes,
          height: 130,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } catch (e) {
      return const SizedBox();
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
    if (_carregandoLocalizacao) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Nova caminhada',
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Obtendo sua localização...',
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nova caminhada',
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _origem!,
              initialZoom: 15,
              onTap: (
                tapPosition,
                ponto,
              ) {
                _selecionarDestino(ponto);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/'
                    '{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.example.caminhadas_app',
              ),

              if (_rota.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _rota,
                      strokeWidth: 5,
                      color:
                          Colors.green.shade700,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: _origem!,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on,
                      size: 45,
                      color: Colors.blue,
                    ),
                  ),

                  if (_destino != null)
                    Marker(
                      point: _destino!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        size: 45,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding:
                    const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nova caminhada',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _destino == null
                          ? 'Toque no mapa para escolher o destino.'
                          : _calculandoRota
                              ? 'Calculando rota...'
                              : 'Rota calculada. Você pode salvar a caminhada.',
                    ),

                    if (_erro != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _erro!,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          if (_destino != null &&
              !_calculandoRota &&
              _rota.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                elevation: 5,
                child: Padding(
                  padding:
                      const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceAround,
                        children: [
                          _InfoItem(
                            icon: Icons.route,
                            titulo: 'Distância',
                            valor:
                                '${_distanciaKm.toStringAsFixed(2)} km',
                          ),
                          _InfoItem(
                            icon: Icons
                                .local_fire_department,
                            titulo: 'Calorias',
                            valor:
                                '${_calorias.toStringAsFixed(0)} kcal',
                          ),
                          _InfoItem(
                            icon: Icons.access_time,
                            titulo: 'Tempo',
                            valor:
                                _formatarTempo(
                              _tempoMinutos,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child:
                            FilledButton.icon(
                          onPressed:
                              _abrirModalSalvar,
                          icon: const Icon(
                            Icons.save,
                          ),
                          label: const Text(
                            'Salvar caminhada',
                          ),
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
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String valor;

  const _InfoItem({
    required this.icon,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.green.shade700,
          size: 23,
        ),
        const SizedBox(height: 4),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ResultadoRota {
  final List<LatLng> rota;
  final double distanciaKm;
  final int tempoMinutos;

  _ResultadoRota({
    required this.rota,
    required this.distanciaKm,
    required this.tempoMinutos,
  });
}