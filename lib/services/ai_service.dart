import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/expense.dart';
import '../models/trip.dart';

class AIService {
  static const String _apiKey = '';

  static Future<String> getTravelAnalysis({
    required Trip trip,
    required List<Expense> expenses,
  }) async {
    if (_apiKey.startsWith('AQ.')) {
      return "⚠️ Erro: A chave de API parece inválida. No Google AI Studio, ela deve começar com 'AIza'.";
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash', 
        apiKey: _apiKey,
      );
      
      double totalSpent = expenses.fold(0, (sum, e) => sum + e.value);
      String categories = expenses.map((e) => "${e.category}: R\$${e.value.toStringAsFixed(2)}").join(", ");

      final prompt = """
      Analise financeiramente esta viagem:
      Destino: ${trip.destination}
      Orçamento: R\$ ${trip.budget}
      Gasto real: R\$ $totalSpent
      Itens gastos: $categories

      Dê uma dica curta de 2 frases sobre como economizar ou onde gastar o que sobrou.
      Seja direto e amigável.
      """;

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? "A IA não retornou uma resposta.";
    } catch (e) {
      print("Erro Gemini: $e");
      return "IA temporariamente indisponível. Verifique sua chave e conexão.";
    }
  }

  static Future<List<String>> getRoteiroSuggestions(String destination) async {
    if (_apiKey.startsWith('AQ.')) return ["Visitar pontos turísticos", "Provar culinária local", "Passeio pelo centro"];

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      final prompt = "Liste 3 atrações turísticas em $destination. Retorne apenas os nomes separados por vírgula.";
      
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? "";
      if (text.isEmpty) return ["Museu local", "Parque central", "Restaurante típico"];
      
      return text.split(',').map((s) => s.trim()).toList();
    } catch (e) {
      return ["Pontos históricos", "Culinária regional", "Caminhada guiada"];
    }
  }

  static Future<List<String>> getChecklistSuggestions(String destination, String weather) async {
    if (_apiKey.startsWith('AQ.')) return ["Documentos", "Carregador", "Roupas extras"];

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      final prompt = "Viagem para $destination com clima $weather. Sugira 3 itens indispensáveis. Apenas nomes separados por vírgula.";
      
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? "";
      if (text.isEmpty) return ["Protetor solar", "Capa de chuva", "Remédios básicos"];

      return text.split(',').map((s) => s.trim()).toList();
    } catch (e) {
      return ["Documentos de viagem", "Kit higiene", "Calçados confortáveis"];
    }
  }
}
