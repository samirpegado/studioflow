import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/client_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/cep_service.dart';
import '../../../core/utils/responsive.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cpfCnpjController = TextEditingController();
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ufController = TextEditingController();
  final _bairroController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();

  final _telefoneFormatter = MaskTextInputFormatter(mask: '(##) #####-####');
  final _cepFormatter = MaskTextInputFormatter(mask: '#####-###');

  ClientType _tipo = ClientType.musico;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoadingCep = false;
  bool _isRegistering = false;
  String? _selectedUf;

  static const List<String> _estadosBrasileiros = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
    'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];

  @override
  void initState() {
    super.initState();
    // Listener para buscar CEP quando completo
    _cepController.addListener(_onCepChanged);
  }

  @override
  void dispose() {
    _cepController.removeListener(_onCepChanged);
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _cpfCnpjController.dispose();
    _cepController.dispose();
    _ruaController.dispose();
    _cidadeController.dispose();
    _ufController.dispose();
    _bairroController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onCepChanged() async {
    final cep = _cepFormatter.getUnmaskedText();

    // Busca CEP quando tiver 8 dígitos
    if (cep.length == 8) {
      await _buscarCep(cep);
    }
  }

  Future<void> _buscarCep(String cep) async {
    setState(() {
      _isLoadingCep = true;
    });

    try {
      final endereco = await CepService.buscarCep(cep);

      if (endereco != null && mounted) {
        // Preenche os campos com os dados retornados
        _ruaController.text = endereco['logradouro'] ?? '';
        _bairroController.text = endereco['bairro'] ?? '';
        _cidadeController.text = endereco['localidade'] ?? '';
        final uf = endereco['uf'] ?? '';
        _ufController.text = uf;
        _selectedUf = uf;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Endereço encontrado!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CEP não encontrado'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar CEP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCep = false;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isRegistering = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authService = AuthService();

    try {
      // Remove formatação do CPF/CNPJ
      final cpfCnpjLimpo = _cpfCnpjController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      // Chamar Edge Function para registro
      final response = await authService.registerClient(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nome: _nomeController.text.trim(),
        telefone: _telefoneFormatter.getUnmaskedText(),
        cpfCnpj: cpfCnpjLimpo,
        numero: _numeroController.text.trim(),
        complemento: _complementoController.text.trim(),
        enderecoCep: _cepFormatter.getUnmaskedText(),
        enderecoRua: _ruaController.text.trim(),
        enderecoCidade: _cidadeController.text.trim(),
        enderecoUf: _ufController.text.trim().toUpperCase(),
        enderecoBairro: _bairroController.text.trim(),
        tipo: _tipo.value,
        latitude: 0.0,
        longitude: 0.0,
      );

      if (!mounted) {
        setState(() {
          _isRegistering = false;
        });
        return;
      }

      if (response.success) {
        // Fazer login após registro bem-sucedido
        final loginSuccess = await authProvider.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (loginSuccess) {
          await authProvider.loadUser(authProvider.user!.id);
          if (!mounted) {
            setState(() {
              _isRegistering = false;
            });
            return;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.notification),
              backgroundColor: Colors.green,
            ),
          );
          
          setState(() {
            _isRegistering = false;
          });
          
          context.go('/client');
          return;
        } else {
          if (!mounted) {
            setState(() {
              _isRegistering = false;
            });
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Conta criada, mas erro ao fazer login. Tente fazer login manualmente.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (!mounted) {
          setState(() {
            _isRegistering = false;
          });
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.notification),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar conta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.getPadding(context)),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 600,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Criar Conta',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu email';
                      }
                      if (!value.contains('@')) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telefoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_telefoneFormatter],
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu telefone';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cpfCnpjController,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _CpfCnpjAutoFormatter(),
                    ],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'CPF ou CNPJ',
                      prefixIcon: Icon(Icons.badge),
                      hintText: '000.000.000-00 ou 00.000.000/0000-00',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu CPF ou CNPJ';
                      }
                      final cpfCnpjLimpo = value.replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );
                      if (cpfCnpjLimpo.length != 11 &&
                          cpfCnpjLimpo.length != 14) {
                        return 'CPF deve ter 11 dígitos ou CNPJ deve ter 14 dígitos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<ClientType>(
                    segments: const [
                      ButtonSegment(
                        value: ClientType.musico,
                        label: Text('Músico'),
                        icon: Icon(Icons.person),
                      ),
                      ButtonSegment(
                        value: ClientType.banda,
                        label: Text('Banda'),
                        icon: Icon(Icons.group),
                      ),
                    ],
                    selected: {_tipo},
                    onSelectionChanged: (Set<ClientType> newSelection) {
                      setState(() {
                        _tipo = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Endereço',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cepController,
                    inputFormatters: [_cepFormatter],
                    decoration: InputDecoration(
                      labelText: 'CEP',
                      prefixIcon: const Icon(Icons.location_on),
                      suffixIcon: _isLoadingCep
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                      hintText: '00000-000',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'CEP obrigatório';
                      }
                      final cepLimpo = _cepFormatter.getUnmaskedText();
                      if (cepLimpo.length != 8) {
                        return 'CEP inválido';
                      }
                      return null;
                    },
                  ),
                  if (_isLoadingCep)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Buscando endereço...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ruaController,
                    decoration: const InputDecoration(
                      labelText: 'Rua',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Rua obrigatória';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _numeroController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Número',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Número obrigatório';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _complementoController,
                          decoration: const InputDecoration(
                            labelText: 'Complemento',
                            hintText: 'Opcional',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bairroController,
                    decoration: const InputDecoration(
                      labelText: 'Bairro',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bairro obrigatório';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(flex: 2,
                        child: TextFormField(
                          controller: _cidadeController,
                          decoration: const InputDecoration(
                            labelText: 'Cidade',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Cidade obrigatória';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _selectedUf,
                          decoration: const InputDecoration(
                            labelText: 'UF',
                          ),
                          items: _estadosBrasileiros.map((uf) {
                            return DropdownMenuItem<String>(
                              value: uf,
                              child: Text(uf),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedUf = value;
                              _ufController.text = value ?? '';
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'UF obrigatória';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua senha';
                      }
                      if (value.length < 6) {
                        return 'Senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, confirme sua senha';
                      }
                      if (value != _passwordController.text) {
                        return 'Senhas não coincidem';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isRegistering ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: _isRegistering
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Cadastrar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Já tem conta? Faça login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Formatter que alterna automaticamente entre CPF e CNPJ baseado no tamanho
class _CpfCnpjAutoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Remove tudo que não é dígito
    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String formatted;

    // Se tem 11 dígitos ou menos, formata como CPF
    if (digitsOnly.length <= 11) {
      formatted = _formatCpf(digitsOnly);
    } else {
      // Se tem mais de 11 dígitos, formata como CNPJ
      formatted = _formatCnpj(digitsOnly);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatCpf(String digits) {
    // Limita a 11 dígitos para CPF
    final limitedDigits = digits.length > 11 ? digits.substring(0, 11) : digits;
    
    if (limitedDigits.length <= 3) {
      return limitedDigits;
    } else if (limitedDigits.length <= 6) {
      return '${limitedDigits.substring(0, 3)}.${limitedDigits.substring(3)}';
    } else if (limitedDigits.length <= 9) {
      return '${limitedDigits.substring(0, 3)}.${limitedDigits.substring(3, 6)}.${limitedDigits.substring(6)}';
    } else {
      // Para CPF completo (11 dígitos)
      return '${limitedDigits.substring(0, 3)}.${limitedDigits.substring(3, 6)}.${limitedDigits.substring(6, 9)}-${limitedDigits.substring(9)}';
    }
  }

  String _formatCnpj(String digits) {
    // Limita a 14 dígitos para CNPJ
    final limitedDigits = digits.length > 14 ? digits.substring(0, 14) : digits;
    
    if (limitedDigits.length <= 2) {
      return limitedDigits;
    } else if (limitedDigits.length <= 5) {
      return '${limitedDigits.substring(0, 2)}.${limitedDigits.substring(2)}';
    } else if (limitedDigits.length <= 8) {
      return '${limitedDigits.substring(0, 2)}.${limitedDigits.substring(2, 5)}.${limitedDigits.substring(5)}';
    } else if (limitedDigits.length <= 12) {
      return '${limitedDigits.substring(0, 2)}.${limitedDigits.substring(2, 5)}.${limitedDigits.substring(5, 8)}/${limitedDigits.substring(8)}';
    } else {
      // Para CNPJ completo (14 dígitos)
      return '${limitedDigits.substring(0, 2)}.${limitedDigits.substring(2, 5)}.${limitedDigits.substring(5, 8)}/${limitedDigits.substring(8, 12)}-${limitedDigits.substring(12)}';
    }
  }
}
