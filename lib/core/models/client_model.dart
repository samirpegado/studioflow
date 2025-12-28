enum ClientType { musico, banda }

extension ClientTypeExtension on ClientType {
  String get value {
    switch (this) {
      case ClientType.musico:
        return 'musico';
      case ClientType.banda:
        return 'banda';
    }
  }
  
  String get label {
    switch (this) {
      case ClientType.musico:
        return 'Músico';
      case ClientType.banda:
        return 'Banda';
    }
  }
  
  static ClientType fromString(String value) {
    switch (value) {
      case 'musico':
        return ClientType.musico;
      case 'banda':
        return ClientType.banda;
      default:
        return ClientType.musico;
    }
  }
}

class ClientModel {
  final String id;
  final String userId;
  final String nome;
  final String email;
  final String telefone;
  final String cpfCnpj;
  final String enderecoCep;
  final String enderecoRua;
  final String enderecoCidade;
  final String enderecoUf;
  final String enderecoBairro;
  final ClientType tipo;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  ClientModel({
    required this.id,
    required this.userId,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.cpfCnpj,
    required this.enderecoCep,
    required this.enderecoRua,
    required this.enderecoCidade,
    required this.enderecoUf,
    required this.enderecoBairro,
    required this.tipo,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      telefone: json['telefone'] as String,
      cpfCnpj: json['cpf_cnpj'] as String,
      enderecoCep: json['endereco_cep'] as String,
      enderecoRua: json['endereco_rua'] as String,
      enderecoCidade: json['endereco_cidade'] as String,
      enderecoUf: json['endereco_uf'] as String,
      enderecoBairro: json['endereco_bairro'] as String,
      tipo: ClientTypeExtension.fromString(json['tipo'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'cpf_cnpj': cpfCnpj,
      'endereco_cep': enderecoCep,
      'endereco_rua': enderecoRua,
      'endereco_cidade': enderecoCidade,
      'endereco_uf': enderecoUf,
      'endereco_bairro': enderecoBairro,
      'tipo': tipo.value,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
  
  String get enderecoCompleto {
    return '$enderecoRua, $enderecoBairro, $enderecoCidade - $enderecoUf, $enderecoCep';
  }
}

