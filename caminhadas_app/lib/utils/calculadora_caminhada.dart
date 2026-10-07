class CalculadoraCaminhada {
  // Peso padrão usado apenas para gerar a estimativa solicitada no desafio.
  // Pode ser alterado facilmente pelo aluno.
  static const double pesoKg = 60;
  static const double velocidadeKmH = 5;

  static double calorias(double distanciaKm) {
    // Estimativa simples de aproximadamente 0,7 kcal por kg por km.
    return 0.7 * pesoKg * distanciaKm;
  }

  static double tempoMinutos(double distanciaKm) {
    return (distanciaKm / velocidadeKmH) * 60;
  }
}
