import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/cep_service.dart';
import '../../../core/utils/responsive.dart';

class RegisterStudioPage extends StatefulWidget {
  const RegisterStudioPage({super.key});

  @override
  State<RegisterStudioPage> createState() => _RegisterStudioPageState();
}

class _RegisterStudioPageState extends State<RegisterStudioPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeEstudioController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ufController = TextEditingController();
  final _bairroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _responsavelNomeController = TextEditingController();
  final _responsavelCpfController = TextEditingController();
  final _responsavelTelefoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _telefoneFormatter = MaskTextInputFormatter(mask: '(##) #####-####');
  final _cepFormatter = MaskTextInputFormatter(mask: '#####-###');
  final _cpfFormatter = MaskTextInputFormatter(mask: '###.###.###-##');

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
    _nomeEstudioController.dispose();
    _cnpjController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _cepController.dispose();
    _ruaController.dispose();
    _cidadeController.dispose();
    _ufController.dispose();
    _bairroController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _responsavelNomeController.dispose();
    _responsavelCpfController.dispose();
    _responsavelTelefoneController.dispose();
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
      // Remove formatação do CNPJ e CPF
      final cnpjLimpo = _cnpjController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final cpfLimpo = _responsavelCpfController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      // Chamar Edge Function para registro
      final response = await authService.registerStudio(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nomeEstudio: _nomeEstudioController.text.trim(),
        cnpj: cnpjLimpo.isNotEmpty ? cnpjLimpo : null,
        telefone: _telefoneFormatter.getUnmaskedText(),
        enderecoCep: _cepFormatter.getUnmaskedText(),
        enderecoRua: _ruaController.text.trim(),
        enderecoCidade: _cidadeController.text.trim(),
        enderecoUf: _ufController.text.trim().toUpperCase(),
        enderecoBairro: _bairroController.text.trim(),
        enderecoNumero: _numeroController.text.trim().isNotEmpty
            ? _numeroController.text.trim()
            : null,
        enderecoComplemento: _complementoController.text.trim().isNotEmpty
            ? _complementoController.text.trim()
            : null,
        responsavelNome: _responsavelNomeController.text.trim(),
        responsavelCpf: cpfLimpo.isNotEmpty ? cpfLimpo : null,
        responsavelTelefone: _responsavelTelefoneController.text
                .trim()
                .isNotEmpty
            ? _responsavelTelefoneController.text.trim()
            : null,
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

          context.go('/studio');
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
              content: Text(
                  'Conta criada, mas erro ao fazer login. Tente fazer login manualmente.'),
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
      appBar: AppBar(title: const Text('Cadastro de Estúdio')),
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
                        'Cadastrar Estúdio',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Dados do Estúdio',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nomeEstudioController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Estúdio',
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nome do estúdio obrigatório';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cnpjController,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _CnpjFormatter(),
                        ],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'CNPJ',
                          prefixIcon: Icon(Icons.badge),
                          hintText: '00.000.000/0000-00',
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final cnpjLimpo = value.replaceAll(RegExp(r'[^0-9]'), '');
                            if (cnpjLimpo.length != 14) {
                              return 'CNPJ deve ter 14 dígitos';
                            }
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
                            return 'Email obrigatório';
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
                            return 'Telefone obrigatório';
                          }
                          return null;
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
                          Expanded(
                            flex: 2,
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
                      Text(
                        'Dados do Responsável',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _responsavelNomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Responsável',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nome do responsável obrigatório';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _responsavelCpfController,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _cpfFormatter,
                        ],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'CPF do Responsável',
                          prefixIcon: Icon(Icons.badge_outlined),
                          hintText: '000.000.000-00',
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final cpfLimpo = value.replaceAll(RegExp(r'[^0-9]'), '');
                            if (cpfLimpo.length != 11) {
                              return 'CPF deve ter 11 dígitos';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _responsavelTelefoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          MaskTextInputFormatter(mask: '(##) #####-####'),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Telefone do Responsável',
                          prefixIcon: Icon(Icons.phone),
                          hintText: 'Opcional',
                        ),
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
                            return 'Senha obrigatória';
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
                            return 'Confirmação de senha obrigatória';
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
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Cadastrar Estúdio',
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

/// Formatter para CNPJ
class _CnpjFormatter extends TextInputFormatter {
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

    // Limita a 14 dígitos para CNPJ
    final limitedDigits = digitsOnly.length > 14 ? digitsOnly.substring(0, 14) : digitsOnly;

    String formatted;

    if (limitedDigits.length <= 2) {
      formatted = limitedDigits;
    } else if (limitedDigits.length <= 5) {
      formatted = '${limitedDigits.substring(0, 2)}.${limitedDigits.substring(2)}';
    } else if (limitedDigits.length <= 8) {
      formatted = '${limitedDigits.substring(0, 2)}.${limitedDigits.substring(2, 5)}.${limitedDigits.substring(5)}';
    } else if (limitedDigits.length <= 12) {
      formatted = '${limitedDigits.substring(0, 2)}.${limitedDigits.substring(2, 5)}.${limitedDigits.substring(5, 8)}/${limitedDigits.substring(8)}';
    } else {
      // Para CNPJ completo (14 dígitos)
      formatted = '${limitedDigits.substring(0, 2)}.${limitedDigits.substring(2, 5)}.${limitedDigits.substring(5, 8)}/${limitedDigits.substring(8, 12)}-${limitedDigits.substring(12)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

