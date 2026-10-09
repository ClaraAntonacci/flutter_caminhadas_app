
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/caminhada.dart';

class CaminhadaStorageService {
  static const String _chave = 'caminhadas';

  Future<List<Caminhada>> listar() async {
    final preferences = await SharedPreferences.getInstance();
    final dados = preferences.getString(_chave);

    if (dados == null || dados.isEmpty) {
      return [];
    }

    try {
      final lista = jsonDecode(dados) as List<dynamic>;

      return lista.map((item) {
        return Caminhada.fromMap(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList();
    } catch (e) {
      throw Exception('Não foi possível carregar as caminhadas: $e');
    }
  }

  Future<void> salvar(Caminhada caminhada) async {
    final caminhadas = await listar();

    caminhadas.add(caminhada);

    await _salvarLista(caminhadas);
  }

  Future<void> atualizar(Caminhada caminhada) async {
    final caminhadas = await listar();

    final indice = caminhadas.indexWhere(
      (item) => item.id == caminhada.id,
    );

    if (indice == -1) {
      throw Exception(
        'Caminhada não encontrada para atualização.',
      );
    }

    caminhadas[indice] = caminhada;

    await _salvarLista(caminhadas);

    // Confirma que os dados foram persistidos.
    final preferences = await SharedPreferences.getInstance();
    final dadosSalvos = preferences.getString(_chave);

    if (dadosSalvos == null) {
      throw Exception('Não foi possível confirmar o salvamento.');
    }

    final listaSalva = jsonDecode(dadosSalvos) as List<dynamic>;

    final itemSalvo = listaSalva.cast<Map>().firstWhere(
      (item) => item['id'].toString() == caminhada.id,
    );

    if (itemSalvo['fotoBase64'] != caminhada.fotoBase64) {
      throw Exception('A foto não foi salva corretamente.');
    }
  }

  Future<void> excluir(String id) async {
    final caminhadas = await listar();

    caminhadas.removeWhere((item) => item.id == id);

    await _salvarLista(caminhadas);
  }

  Future<void> limpar() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_chave);
  }

  Future<void> _salvarLista(List<Caminhada> caminhadas) async {
    final preferences = await SharedPreferences.getInstance();

    final dados = jsonEncode(
      caminhadas.map((item) => item.toMap()).toList(),
    );

    final sucesso = await preferences.setString(_chave, dados);

    if (!sucesso) {
      throw Exception('Não foi possível salvar as caminhadas.');
    }
  }
}
