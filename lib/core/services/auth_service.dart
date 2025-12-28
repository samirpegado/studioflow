import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SupabaseClient get client => Supabase.instance.client;

  /// Registra um novo cliente usando a Edge Function
  Future<RegisterResponse> registerClient({
    required String email,
    required String password,
    required String nome,
    required String telefone,
    required String cpfCnpj,
    required String enderecoCep,
    required String enderecoRua,
    required String enderecoCidade,
    required String enderecoUf,
    required String enderecoBairro,
    required String tipo,
    String? numero,
    String? complemento,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await client.functions.invoke(
        'register-client',
        body: {
          'email': email,
          'password': password,
          'nome': nome,
          'telefone': telefone,
          'cpf_cnpj': cpfCnpj,
          'endereco_cep': enderecoCep,
          'endereco_rua': enderecoRua,
          'endereco_cidade': enderecoCidade,
          'endereco_uf': enderecoUf,
          'endereco_bairro': enderecoBairro,
          'numero': numero,
          'complemento': complemento,
          'tipo': tipo,
          'latitude': latitude ?? 0.0,
          'longitude': longitude ?? 0.0,
        },
      );

      if (response.status == 201 || response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        return RegisterResponse.fromJson(data);
      } else {
        final data = response.data as Map<String, dynamic>?;
        return RegisterResponse(
          success: false,
          message: data?['message'] ?? 'Erro ao criar conta',
          notification: data?['notification'] ?? 'Erro ao processar cadastro',
        );
      }
    } catch (e) {
      return RegisterResponse(
        success: false,
        message: e.toString(),
        notification: 'Erro ao conectar com o servidor. Verifique sua conexão.',
      );
    }
  }

  /// Registra um novo estúdio usando a Edge Function
  Future<RegisterResponse> registerStudio({
    required String email,
    required String password,
    required String nomeEstudio,
    String? cnpj,
    required String telefone,
    required String enderecoCep,
    required String enderecoRua,
    required String enderecoCidade,
    required String enderecoUf,
    required String enderecoBairro,
    String? enderecoNumero,
    String? enderecoComplemento,
    required String responsavelNome,
    String? responsavelCpf,
    String? responsavelTelefone,
  }) async {
    try {
      final response = await client.functions.invoke(
        'register-studio',
        body: {
          'email': email,
          'password': password,
          'nome_estudio': nomeEstudio,
          'cnpj': cnpj,
          'telefone': telefone,
          'endereco_cep': enderecoCep,
          'endereco_rua': enderecoRua,
          'endereco_cidade': enderecoCidade,
          'endereco_uf': enderecoUf,
          'endereco_bairro': enderecoBairro,
          'endereco_numero': enderecoNumero,
          'endereco_complemento': enderecoComplemento,
          'responsavel_nome': responsavelNome,
          'responsavel_cpf': responsavelCpf,
          'responsavel_telefone': responsavelTelefone,
        },
      );

      if (response.status == 201 || response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        return RegisterResponse.fromJson(data);
      } else {
        final data = response.data as Map<String, dynamic>?;
        return RegisterResponse(
          success: false,
          message: data?['message'] ?? 'Erro ao criar conta',
          notification: data?['notification'] ?? 'Erro ao processar cadastro',
        );
      }
    } catch (e) {
      return RegisterResponse(
        success: false,
        message: e.toString(),
        notification: 'Erro ao conectar com o servidor. Verifique sua conexão.',
      );
    }
  }
}

class RegisterResponse {
  final bool success;
  final String message;
  final String notification;
  final RegisterData? data;

  RegisterResponse({
    required this.success,
    required this.message,
    required this.notification,
    this.data,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      notification: json['notification'] as String? ?? '',
      data: json['data'] != null
          ? RegisterData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class RegisterData {
  final String? userId;
  final String? clientId;

  RegisterData({
    this.userId,
    this.clientId,
  });

  factory RegisterData.fromJson(Map<String, dynamic> json) {
    return RegisterData(
      userId: json['userId'] as String?,
      clientId: json['clientId'] as String?,
    );
  }
}

