import 'dart:convert';
import 'package:http/http.dart' as http;

class CepService {
  static const String viaCepBaseUrl = 'https://viacep.com.br/ws';

  /// Busca endereço pelo CEP usando ViaCEP
  static Future<Map<String, String>?> buscarCep(String cep) async {
    try {
      // Remove formatação do CEP
      final cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (cepLimpo.length != 8) {
        return null;
      }

      final url = Uri.parse('$viaCepBaseUrl/$cepLimpo/json/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Verifica se o CEP foi encontrado (ViaCEP retorna erro quando não encontra)
        if (data.containsKey('erro')) {
          return null;
        }

        return {
          'cep': data['cep'] as String? ?? '',
          'logradouro': data['logradouro'] as String? ?? '',
          'complemento': data['complemento'] as String? ?? '',
          'bairro': data['bairro'] as String? ?? '',
          'localidade': data['localidade'] as String? ?? '',
          'uf': data['uf'] as String? ?? '',
          'ibge': data['ibge'] as String? ?? '',
          'gia': data['gia'] as String? ?? '',
          'ddd': data['ddd'] as String? ?? '',
          'siafi': data['siafi'] as String? ?? '',
        };
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
}

