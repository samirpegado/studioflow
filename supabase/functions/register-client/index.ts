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
  cpf_cnpj: string;
  endereco_cep: string;
  endereco_rua: string;
  endereco_cidade: string;
  endereco_uf: string;
  endereco_bairro: string;
  tipo: 'musico' | 'banda';
  latitude?: number;
  longitude?: number;
}

interface RegisterResponse {
  success: boolean;
  message: string;
  notification: string;
  data?: {
    userId?: string;
    clientId?: string;
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
    if (!body.email || !body.password || !body.nome || !body.cpf_cnpj) {
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

    // Check if CPF/CNPJ already exists in public.clients
    const { data: existingClient, error: clientCheckError } = await supabaseClient
      .from('clients')
      .select('id, cpf_cnpj')
      .eq('cpf_cnpj', body.cpf_cnpj)
      .is('deleted_at', null)
      .maybeSingle();

    if (clientCheckError) {
      console.error('Error checking client:', clientCheckError);
      const response: RegisterResponse = {
        success: false,
        message: 'Erro ao verificar CPF/CNPJ existente',
        notification: 'Erro ao processar cadastro. Tente novamente.',
      };
      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      });
    }

    if (existingClient) {
      const response: RegisterResponse = {
        success: false,
        message: 'CPF/CNPJ já cadastrado',
        notification: 'Este CPF/CNPJ já está cadastrado no sistema.',
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

    // Create user in public.users
    const { error: publicUserError } = await supabaseClient
      .from('users')
      .insert({
        id: userId,
        email: email,
        role: 'client',
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

    // Create client in public.clients
    const { data: clientData, error: clientError } = await supabaseClient
      .from('clients')
      .insert({
        user_id: userId,
        nome: body.nome.trim(),
        email: email,
        telefone: body.telefone.trim(),
        cpf_cnpj: body.cpf_cnpj.trim(),
        endereco_cep: body.endereco_cep.trim(),
        endereco_rua: body.endereco_rua.trim(),
        endereco_cidade: body.endereco_cidade.trim(),
        endereco_uf: body.endereco_uf.trim().toUpperCase(),
        endereco_bairro: body.endereco_bairro.trim(),
        tipo: body.tipo,
        latitude: body.latitude ?? 0.0,
        longitude: body.longitude ?? 0.0,
      })
      .select('id')
      .single();

    if (clientError) {
      console.error('Error creating client:', clientError);
      // Try to clean up if client creation fails
      await supabaseClient.from('users').delete().eq('id', userId);
      await supabaseClient.auth.admin.deleteUser(userId);
      
      const response: RegisterResponse = {
        success: false,
        message: 'Erro ao criar registro do cliente',
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
      message: 'Usuário cadastrado com sucesso',
      notification: 'Cadastro realizado com sucesso! Você já pode fazer login.',
      data: {
        userId: userId,
        clientId: clientData.id,
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

