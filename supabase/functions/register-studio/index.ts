import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface RegisterRequest {
  email: string;
  password: string;
  nome: string;
  telefone: string;
  cpf_cnpj?: string;
  nome_legal?: string;
  endereco_cep?: string;
  endereco_rua?: string;
  endereco_cidade?: string;
  endereco_uf?: string;
  endereco_bairro?: string;
  endereco_numero?: string;
  endereco_complemento?: string;
  img_url?: string;
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
    if (!body.email || !body.password || !body.nome || !body.telefone || !body.cpf_cnpj || !body.nome_legal || 
        !body.endereco_cep || !body.endereco_rua || !body.endereco_cidade || !body.endereco_uf || 
        !body.endereco_bairro || !body.endereco_numero) {
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

    // Buscar dados do CEP na AwesomeAPI (se endereco_cep fornecido)
    let latitude: number | null = null;
    let longitude: number | null = null;
    let enderecoRua = body.endereco_rua || null;
    let enderecoCidade = body.endereco_cidade || null;
    let enderecoUf = body.endereco_uf ? body.endereco_uf.trim().toUpperCase() : null;
    let enderecoBairro = body.endereco_bairro || null;
    const cepLimpo = body.endereco_cep ? body.endereco_cep.replace(/\D/g, '') : null;

    if (body.endereco_cep && cepLimpo && cepLimpo.length === 8) {
      const awesomeApiToken = Deno.env.get('AWESOME_API');
      if (awesomeApiToken) {
        try {
          const awesomeApiUrl = `https://cep.awesomeapi.com.br/json/${cepLimpo}?token=${awesomeApiToken}`;
          const cepResponse = await fetch(awesomeApiUrl);

          if (cepResponse.ok) {
            const cepData: AwesomeApiResponse = await cepResponse.json();
            
            // Usa os dados da API se disponíveis
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
        }
      }
    }

    // Calculate data_assinatura (7 days from today)
    const dataAssinatura = new Date();
    dataAssinatura.setDate(dataAssinatura.getDate() + 7);
    const dataAssinaturaStr = dataAssinatura.toISOString().split('T')[0];

    // Create studio in public.studios
    const studioInsertData: any = {
      id: userId,
      nome: body.nome.trim(),
      email: email,
      telefone: body.telefone.trim(),
      img_url: body.img_url ? body.img_url.trim() : null,
      customer_id: null,
      data_assinatura: dataAssinaturaStr,
      status_assinatura: 'trial',
      cpf_cnpj: body.cpf_cnpj.trim(),
      nome_legal: body.nome_legal.trim(),
    };

    const { data: studioData, error: studioError } = await supabaseClient
      .from('studios')
      .insert(studioInsertData)
      .select('id')
      .single();

    if (studioError) {
      console.error('Error creating studio:', studioError);
      // Try to clean up if studio creation fails
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

    // Create endereco in public.enderecos
    const enderecoInsertData: any = {
      id: userId,
      cep: body.endereco_cep.replace(/\D/g, ''),
      endereco: enderecoRua,
      numero: body.endereco_numero.trim(),
      cidade: enderecoCidade,
      estado: enderecoUf,
      complemento: body.endereco_complemento ? body.endereco_complemento.trim() : null,
      lat: latitude,
      long: longitude,
    };

    const { error: enderecoError } = await supabaseClient
      .from('enderecos')
      .insert(enderecoInsertData);

    if (enderecoError) {
      console.error('Error creating endereco:', enderecoError);
      // Try to clean up if endereco creation fails
      await supabaseClient.from('studios').delete().eq('id', userId);
      await supabaseClient.auth.admin.deleteUser(userId);
      
      const response: RegisterResponse = {
        success: false,
        message: 'Erro ao criar endereço',
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

