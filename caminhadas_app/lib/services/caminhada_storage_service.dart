import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/caminhada.dart';

class CaminhadaStorageService {
  static const String _chave = 'caminhadas';

  Future<List<Caminhada>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    final dados = prefs.getStringList(_chave) ?? [];

    return dados.map((item) {
      return Caminhada.fromMap(
        jsonDecode(item) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<void> salvar(Caminhada caminhada) async {
    final prefs = await SharedPreferences.getInstance();
    final caminhadas = await listar();

    caminhadas.removeWhere((item) => item.id == caminhada.id);
    caminhadas.insert(0, caminhada);

    await prefs.setStringList(
      _chave,
      caminhadas.map((item) => jsonEncode(item.toMap())).toList(),
    );
  }

  Future<void> excluir(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final caminhadas = await listar();
    caminhadas.removeWhere((item) => item.id == id);

    await prefs.setStringList(
      _chave,
      caminhadas.map((item) => jsonEncode(item.toMap())).toList(),
    );
  }
}
