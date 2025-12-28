import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface RegisterRequest {
  email: string;
  password: string;
  nome_estudio: string;
  cnpj?: string;
  telefone: string;
  endereco_cep: string;
  endereco_rua: string;
  endereco_cidade: string;
  endereco_uf: string;
  endereco_bairro: string;
  endereco_numero?: string;
  endereco_complemento?: string;
  responsavel_nome?: string;
  responsavel_cpf?: string;
  responsavel_telefone?: string;
}

interface AwesomeApiResponse {
  cep: string;
  address_type: string;
  address_name: string;
  address: string;
  state: string;
  district: string;
  lat: string;
  lng: string;
  city: string;
  city_ibge: string;
  ddd: string;
}

interface AsaasCustomerResponse {
  id: string;
  dateCreated: string;
  name: string;
  email: string;
  [key: string]: any;
}

interface AsaasSubscriptionResponse {
  id: string;
  customer: string;
  billingType: string;
  value: number;
  nextDueDate: string;
  cycle: string;
  status: string;
  subscriptionUrl?: string;
  [key: string]: any;
}

interface RegisterResponse {
  success: boolean;
  message: string;
  notification: string;
  data?: {
    userId?: string;
    studioId?: string;
  };
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Get Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );

    // Parse request body
    const body: RegisterRequest = await req.json();

    // Validate required fields
    if (!body.email || !body.password || !body.nome_estudio || !body.telefone || !body.responsavel_nome) {
      const response: RegisterResponse = {
        success: false,
        message: 'Campos obrigatórios não fornecidos',
        notification: 'Por favor, preencha todos os campos obrigatórios',
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    // Normalize email
    const email = body.email.toLowerCase().trim();

    // Check if email already exists in public.users
    const { data: existingUser, error: userCheckError } = await supabaseClient
      .from('users')
      .select('id, email')
      .eq('email', email)
      .is('deleted_at', null)
      .maybeSingle();

    if (userCheckError) {
      console.error('Error checking user:', userCheckError);
      const response: RegisterResponse = {
        success: false,
        message: 'Erro ao verificar usuário existente',
        notification: 'Erro ao processar cadastro. Tente novamente.',
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      });
    }

    if (existingUser) {
      const response: RegisterResponse = {
        success: false,
        message: 'Email já cadastrado',
        notification: 'Este email já está cadastrado. Use outro email ou faça login.',
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 409,
      });
    }

       // Create user in auth.users
    const { data: authUser, error: authError } = await supabaseClient.auth.admin.createUser({
      email: email,
      password: body.password,
      email_confirm: true, // Auto-confirm email
    });

    if (authError || !authUser.user) {
      console.error('Error creating auth user:', authError);
      const response: RegisterResponse = {
        success: false,
        message: authError?.message || 'Erro ao criar usuário',
        notification: 'Erro ao criar conta. Tente novamente.',
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      });
    }

    const userId = authUser.user.id;

    // Buscar dados do CEP na AwesomeAPI
    let latitude = 0.0;
    let longitude = 0.0;
    let enderecoRua = body.endereco_rua.trim();
    let enderecoCidade = body.endereco_cidade.trim();
    let enderecoUf = body.endereco_uf.trim().toUpperCase();
    let enderecoBairro = body.endereco_bairro.trim();

    const awesomeApiToken = Deno.env.get('AWESOME_API');
    const cepLimpo = body.endereco_cep.replace(/\D/g, ''); // Remove formatação

    if (awesomeApiToken && cepLimpo.length === 8) {
      try {
        const awesomeApiUrl = `https://cep.awesomeapi.com.br/json/${cepLimpo}?token=${awesomeApiToken}`;
        const cepResponse = await fetch(awesomeApiUrl);

        if (cepResponse.ok) {
          const cepData: AwesomeApiResponse = await cepResponse.json();
          
          // Usa os dados da API se disponíveis, senão mantém os enviados
          if (cepData.address) {
            enderecoRua = cepData.address.trim();
          }
          if (cepData.city) {
            enderecoCidade = cepData.city.trim();
          }
          if (cepData.state) {
            enderecoUf = cepData.state.trim().toUpperCase();
          }
          if (cepData.district) {
            enderecoBairro = cepData.district.trim();
          }
          if (cepData.lat && cepData.lng) {
            latitude = parseFloat(cepData.lat);
            longitude = parseFloat(cepData.lng);
          }
        }
      } catch (error) {
        console.error('Erro ao buscar CEP na AwesomeAPI:', error);
        // Continua com os dados enviados se a API falhar
      }
    }

    // Create user in public.users
    const { error: publicUserError } = await supabaseClient
      .from('users')
      .insert({
        id: userId,
        email: email,
        role: 'studio',
      });

    if (publicUserError) {
      console.error('Error creating public user:', publicUserError);
      // Try to clean up auth user if public user creation fails
      await supabaseClient.auth.admin.deleteUser(userId);
      
      const response: RegisterResponse = {
        success: false,
        message: 'Erro ao criar registro do usuário',
        notification: 'Erro ao processar cadastro. Tente novamente.',
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      });
    }

    // Integração com Asaas - Criar customer e assinatura
    const asaasUrl = Deno.env.get('ASAAS_URL');
    const asaasApiKey = Deno.env.get('ASAAS_API_KEY');
    let customerId: string | null = null;
    let subscriptionLink: string | null = null;
    let subscriptionId: string | null = null;

    if (asaasUrl && asaasApiKey) {
      try {
        // Criar customer no Asaas
        const customerData = {
          name: body.nome_estudio.trim(),
          email: email,
          phone: body.telefone.replace(/\D/g, ''), // Remove formatação
          cpfCnpj: body.cnpj ? body.cnpj.replace(/\D/g, '') : (body.responsavel_cpf ? body.responsavel_cpf.replace(/\D/g, '') : null),
          postalCode: cepLimpo,
          address: enderecoRua,
          addressNumber: body.endereco_numero ? body.endereco_numero.trim() : null,
          complement: body.endereco_complemento ? body.endereco_complemento.trim() : null,
          province: enderecoBairro,
          city: enderecoCidade,
          state: enderecoUf,
        };

        const customerResponse = await fetch(`${asaasUrl}/customers`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'access_token': asaasApiKey,
          },
          body: JSON.stringify(customerData),
        });

        if (customerResponse.ok) {
          const customerResult: AsaasCustomerResponse = await customerResponse.json();
          customerId = customerResult.id;
        } else {
          console.error('Error creating Asaas customer:', await customerResponse.text());
        }

        // Criar assinatura recorrente no Asaas
        if (customerId) {
          const subscriptionData = {
            customer: customerId,
            billingType: 'PIX', // Pode ser alterado para 'CREDIT_CARD', 'BOLETO', etc.
            value: 59.9,
            nextDueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 7 dias a partir de hoje
            cycle: 'MONTHLY',
            description: `Assinatura mensal - ${body.nome_estudio.trim()}`,
          };

          const subscriptionResponse = await fetch(`${asaasUrl}/subscriptions`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'access_token': asaasApiKey,
            },
            body: JSON.stringify(subscriptionData),
          });

          if (subscriptionResponse.ok) {
            const subscriptionResult: AsaasSubscriptionResponse = await subscriptionResponse.json();
            subscriptionId = subscriptionResult.id;
            subscriptionLink = subscriptionResult.subscriptionUrl || null;
          } else {
            console.error('Error creating Asaas subscription:', await subscriptionResponse.text());
          }
        }
      } catch (error) {
        console.error('Erro ao integrar com Asaas:', error);
        // Continua mesmo se o Asaas falhar
      }
    }

    // Calcular data de assinatura (7 dias após criação)
    const dataAssinatura = new Date();
    dataAssinatura.setDate(dataAssinatura.getDate() + 7);
    const dataAssinaturaStr = dataAssinatura.toISOString().split('T')[0];

    // Create studio in public.studios
    const studioInsertData: any = {
      user_id: userId,
      nome_estudio: body.nome_estudio.trim(),
      email: email,
      telefone: body.telefone.trim(),
      cnpj: body.cnpj ? body.cnpj.trim() : null,
      endereco_cep: body.endereco_cep.trim(),
      endereco_rua: enderecoRua,
      endereco_cidade: enderecoCidade,
      endereco_uf: enderecoUf,
      endereco_bairro: enderecoBairro,
      endereco_numero: body.endereco_numero ? body.endereco_numero.trim() : null,
      endereco_complemento: body.endereco_complemento ? body.endereco_complemento.trim() : null,
      responsavel_nome: body.responsavel_nome ? body.responsavel_nome.trim() : null,
      responsavel_cpf: body.responsavel_cpf ? body.responsavel_cpf.trim() : null,
      responsavel_telefone: body.responsavel_telefone ? body.responsavel_telefone.trim() : null,
      latitude: latitude,
      longitude: longitude,
      customer_id: customerId,
      data_assinatura: dataAssinaturaStr,
      status_assinatura: 'trial',
      link_assinatura: subscriptionLink,
    };

    const { data: studioData, error: studioError } = await supabaseClient
      .from('studios')
      .insert(studioInsertData)
      .select('id')
      .single();

    if (studioError) {
      console.error('Error creating studio:', studioError);
      // Try to clean up if studio creation fails
      await supabaseClient.from('users').delete().eq('id', userId);
      await supabaseClient.auth.admin.deleteUser(userId);
      
      const response: RegisterResponse = {
        success: false,
        message: 'Erro ao criar registro do estúdio',
        notification: 'Erro ao processar cadastro. Tente novamente.',
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      });
    }

    // Success response
    const response: RegisterResponse = {
      success: true,
      message: 'Estúdio cadastrado com sucesso',
      notification: 'Cadastro realizado com sucesso! Você já pode fazer login.',
      data: {
        userId: userId,
        studioId: studioData.id,
      },
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 201,
    });
  } catch (error) {
    console.error('Unexpected error:', error);
    const response: RegisterResponse = {
      success: false,
      message: error instanceof Error ? error.message : 'Erro desconhecido',
      notification: 'Erro inesperado ao processar cadastro. Tente novamente.',
    };
    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});

