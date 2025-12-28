class StudioModel {
  final String id;
  final String userId;
  final String nomeEstudio;
  final String cnpj;
  final String telefone;
  final String email;
  final String enderecoCep;
  final String enderecoRua;
  final String enderecoCidade;
  final String enderecoUf;
  final String enderecoBairro;
  final String responsavelNome;
  final String responsavelCpf;
  final String responsavelTelefone;
  final double latitude;
  final double longitude;
  final bool ativo;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  
  // Campos calculados
  final double? mediaAvaliacoes;
  final int? totalAvaliacoes;

  StudioModel({
    required this.id,
    required this.userId,
    required this.nomeEstudio,
    required this.cnpj,
    required this.telefone,
    required this.email,
    required this.enderecoCep,
    required this.enderecoRua,
    required this.enderecoCidade,
    required this.enderecoUf,
    required this.enderecoBairro,
    required this.responsavelNome,
    required this.responsavelCpf,
    required this.responsavelTelefone,
    required this.latitude,
    required this.longitude,
    required this.ativo,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.mediaAvaliacoes,
    this.totalAvaliacoes,
  });

  factory StudioModel.fromJson(Map<String, dynamic> json) {
    return StudioModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      nomeEstudio: json['nome_estudio'] as String,
      cnpj: json['cnpj'] as String,
      telefone: json['telefone'] as String,
      email: json['email'] as String,
      enderecoCep: json['endereco_cep'] as String,
      enderecoRua: json['endereco_rua'] as String,
      enderecoCidade: json['endereco_cidade'] as String,
      enderecoUf: json['endereco_uf'] as String,
      enderecoBairro: json['endereco_bairro'] as String,
      responsavelNome: json['responsavel_nome'] as String,
      responsavelCpf: json['responsavel_cpf'] as String,
      responsavelTelefone: json['responsavel_telefone'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      ativo: json['ativo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at'] as String) 
          : null,
      mediaAvaliacoes: json['media_avaliacoes'] != null 
          ? (json['media_avaliacoes'] as num).toDouble() 
          : null,
      totalAvaliacoes: json['total_avaliacoes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nome_estudio': nomeEstudio,
      'cnpj': cnpj,
      'telefone': telefone,
      'email': email,
      'endereco_cep': enderecoCep,
      'endereco_rua': enderecoRua,
      'endereco_cidade': enderecoCidade,
      'endereco_uf': enderecoUf,
      'endereco_bairro': enderecoBairro,
      'responsavel_nome': responsavelNome,
      'responsavel_cpf': responsavelCpf,
      'responsavel_telefone': responsavelTelefone,
      'latitude': latitude,
      'longitude': longitude,
      'ativo': ativo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
  
  String get enderecoCompleto {
    return '$enderecoRua, $enderecoBairro, $enderecoCidade - $enderecoUf, $enderecoCep';
  }
}

