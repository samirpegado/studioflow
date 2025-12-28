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
  tipo?: 'musico' | 'banda';
}

interface RegisterResponse {
  success: boolean;
  message: string;
  notification: string;
  data?: {
    userId?: string;
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
    if (!body.email || !body.password || !body.nome || !body.telefone) {
      const response: RegisterResponse = {
        success: false,
        message: 'Campos obrigatórios não fornecidos',
        notification: 'Por favor, preencha todos os campos obrigatórios (nome, email, telefone e senha)',
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

    // Create user in public.users
    const { error: publicUserError } = await supabaseClient
      .from('users')
      .insert({
        id: userId,
        email: email,
        nome: body.nome.trim(),
        telefone: body.telefone.trim(),
        tipo: body.tipo || null,
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

    // Success response
    const response: RegisterResponse = {
      success: true,
      message: 'Usuário cadastrado com sucesso',
      notification: 'Cadastro realizado com sucesso! Você já pode fazer login.',
      data: {
        userId: userId,
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
