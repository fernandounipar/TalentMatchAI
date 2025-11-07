class Usuario {
  final String id;
  final String nome;
  final String email;
  final String role; // 'admin', 'recrutador', 'gestor'
  final String companyId;
  final String? avatar;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.role,
    required this.companyId,
    this.avatar,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'recrutador',
      companyId: json['companyId']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'role': role,
      'companyId': companyId,
      'avatar': avatar,
    };
  }
}

class Empresa {
  final String id;
  final String nome;
  final String tipo; // 'CPF' | 'CNPJ'
  final String documento;
  final String? logo;
  final String? corPrimaria;

  Empresa({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.documento,
    this.logo,
    this.corPrimaria,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'CNPJ',
      documento: json['documento']?.toString() ?? '',
      logo: json['logo']?.toString(),
      corPrimaria: json['corPrimaria']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo,
      'documento': documento,
      'logo': logo,
      'corPrimaria': corPrimaria,
    };
  }
}
