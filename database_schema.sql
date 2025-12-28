-- ============================================
-- StudioFlow - Esquema de Banco de Dados
-- Sistema de Agendamentos de Ensaios Musicais
-- ============================================

-- ============================================
-- EXTENSÕES
-- ============================================
-- Supabase já tem UUID instalado por padrão

-- ============================================
-- ENUMS
-- ============================================
CREATE TYPE user_role AS ENUM ('admin', 'studio', 'client');
CREATE TYPE client_type AS ENUM ('musico', 'banda');
CREATE TYPE booking_status AS ENUM ('pending', 'approved', 'cancelled', 'completed');
CREATE TYPE payment_method AS ENUM ('dinheiro', 'pix', 'cartao_debito', 'cartao_credito', 'transferencia');

-- ============================================
-- TABELA: users
-- Usuários do sistema (admin, studio, client)
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role user_role NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_at TIMESTAMP WITH TIME ZONE NULL
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_deleted_at ON users(deleted_at) WHERE deleted_at IS NULL;

-- ============================================
-- TABELA: studios
-- Estúdios musicais cadastrados pelo admin
-- ============================================
CREATE TABLE studios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    nome_estudio TEXT NOT NULL,
    cnpj TEXT UNIQUE NOT NULL,
    telefone TEXT NOT NULL,
    email TEXT NOT NULL,
    endereco_cep TEXT NOT NULL,
    endereco_rua TEXT NOT NULL,
    endereco_cidade TEXT NOT NULL,
    endereco_uf TEXT NOT NULL,
    endereco_bairro TEXT NOT NULL,
    responsavel_nome TEXT NOT NULL,
    responsavel_cpf TEXT NOT NULL,
    responsavel_telefone TEXT NOT NULL,
    latitude NUMERIC(10, 8) NOT NULL,
    longitude NUMERIC(11, 8) NOT NULL,
    ativo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_at TIMESTAMP WITH TIME ZONE NULL,
    CONSTRAINT fk_studio_user UNIQUE (user_id),
    CONSTRAINT check_latitude CHECK (latitude >= -90 AND latitude <= 90),
    CONSTRAINT check_longitude CHECK (longitude >= -180 AND longitude <= 180)
);

CREATE INDEX idx_studios_user_id ON studios(user_id);
CREATE INDEX idx_studios_cnpj ON studios(cnpj);
CREATE INDEX idx_studios_email ON studios(email);
CREATE INDEX idx_studios_location ON studios(latitude, longitude);
CREATE INDEX idx_studios_deleted_at ON studios(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_studios_cidade ON studios(endereco_cidade);

-- ============================================
-- TABELA: clients
-- Clientes (músicos ou bandas)
-- ============================================
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    email TEXT NOT NULL,
    telefone TEXT NOT NULL,
    cpf_cnpj TEXT NOT NULL,
    endereco_cep TEXT NOT NULL,
    endereco_rua TEXT NOT NULL,
    endereco_cidade TEXT NOT NULL,
    endereco_uf TEXT NOT NULL,
    endereco_bairro TEXT NOT NULL,
    tipo client_type NOT NULL,
    latitude NUMERIC(10, 8) NOT NULL,
    longitude NUMERIC(11, 8) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_at TIMESTAMP WITH TIME ZONE NULL,
    CONSTRAINT fk_client_user UNIQUE (user_id),
    CONSTRAINT check_client_latitude CHECK (latitude >= -90 AND latitude <= 90),
    CONSTRAINT check_client_longitude CHECK (longitude >= -180 AND longitude <= 180)
);

CREATE INDEX idx_clients_user_id ON clients(user_id);
CREATE INDEX idx_clients_email ON clients(email);
CREATE INDEX idx_clients_cpf_cnpj ON clients(cpf_cnpj);
CREATE INDEX idx_clients_location ON clients(latitude, longitude);
CREATE INDEX idx_clients_deleted_at ON clients(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_clients_tipo ON clients(tipo);

-- ============================================
-- TABELA: rooms
-- Salas dos estúdios
-- ============================================
CREATE TABLE rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
    nome_sala TEXT NOT NULL,
    descricao TEXT,
    valor_hora NUMERIC(10, 2) NOT NULL CHECK (valor_hora >= 0),
    ativo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    deleted_at TIMESTAMP WITH TIME ZONE NULL
);

CREATE INDEX idx_rooms_studio_id ON rooms(studio_id);
CREATE INDEX idx_rooms_deleted_at ON rooms(deleted_at) WHERE deleted_at IS NULL;

-- ============================================
-- TABELA: schedule_configs
-- Configuração de horários de funcionamento das salas
-- ============================================
CREATE TABLE schedule_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0 = Domingo, 6 = Sábado
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    CONSTRAINT check_time_range CHECK (end_time > start_time)
);

CREATE INDEX idx_schedule_configs_room_id ON schedule_configs(room_id);
CREATE INDEX idx_schedule_configs_day ON schedule_configs(day_of_week);

-- ============================================
-- TABELA: schedule_blocks
-- Bloqueios de horários (feriados, manutenção, etc)
-- ============================================
CREATE TABLE schedule_blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    start_datetime TIMESTAMP WITH TIME ZONE NOT NULL,
    end_datetime TIMESTAMP WITH TIME ZONE NOT NULL,
    motivo TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    CONSTRAINT check_block_range CHECK (end_datetime > start_datetime)
);

CREATE INDEX idx_schedule_blocks_room_id ON schedule_blocks(room_id);
CREATE INDEX idx_schedule_blocks_datetime ON schedule_blocks(start_datetime, end_datetime);

-- ============================================
-- TABELA: bookings
-- Agendamentos de ensaios
-- ============================================
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
    start_datetime TIMESTAMP WITH TIME ZONE NOT NULL,
    end_datetime TIMESTAMP WITH TIME ZONE NOT NULL,
    status booking_status DEFAULT 'pending',
    valor_hora NUMERIC(10, 2) NOT NULL, -- Valor no momento do agendamento
    valor_total NUMERIC(10, 2), -- Valor total calculado
    valor_recebido NUMERIC(10, 2), -- Valor efetivamente recebido (pode ser diferente)
    forma_pagamento payment_method,
    observacoes TEXT,
    cancelled_at TIMESTAMP WITH TIME ZONE NULL,
    cancelled_by UUID REFERENCES users(id) NULL, -- Quem cancelou
    motivo_cancelamento TEXT,
    completed_at TIMESTAMP WITH TIME ZONE NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    CONSTRAINT check_booking_range CHECK (end_datetime > start_datetime),
    CONSTRAINT check_valor_total CHECK (valor_total >= 0),
    CONSTRAINT check_valor_recebido CHECK (valor_recebido >= 0 OR valor_recebido IS NULL)
);

CREATE INDEX idx_bookings_client_id ON bookings(client_id);
CREATE INDEX idx_bookings_room_id ON bookings(room_id);
CREATE INDEX idx_bookings_studio_id ON bookings(studio_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_datetime ON bookings(start_datetime, end_datetime);
CREATE INDEX idx_bookings_created_at ON bookings(created_at);

-- ============================================
-- TABELA: reviews
-- Avaliações dos estúdios pelos clientes
-- ============================================
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comentario TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    CONSTRAINT fk_review_booking UNIQUE (booking_id) -- Uma avaliação por agendamento
);

CREATE INDEX idx_reviews_booking_id ON reviews(booking_id);
CREATE INDEX idx_reviews_client_id ON reviews(client_id);
CREATE INDEX idx_reviews_studio_id ON reviews(studio_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);

-- ============================================
-- TABELA: notifications
-- Notificações do sistema (integração com Brevo)
-- ============================================
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
    type TEXT NOT NULL, -- 'booking_approved', 'booking_cancelled', 'booking_reminder', etc
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    email_sent BOOLEAN DEFAULT FALSE,
    email_sent_at TIMESTAMP WITH TIME ZONE NULL,
    read_at TIMESTAMP WITH TIME ZONE NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_booking_id ON notifications(booking_id);
CREATE INDEX idx_notifications_read_at ON notifications(read_at) WHERE read_at IS NULL;
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- ============================================
-- TRIGGERS PARA UPDATED_AT
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_studios_updated_at BEFORE UPDATE ON studios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rooms_updated_at BEFORE UPDATE ON rooms
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_schedule_configs_updated_at BEFORE UPDATE ON schedule_configs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUNÇÕES ÚTEIS
-- ============================================

-- Função para calcular distância entre dois pontos (em km)
-- Usa a fórmula de Haversine para calcular distância entre coordenadas lat/long
CREATE OR REPLACE FUNCTION calculate_distance(
    lat1 NUMERIC,
    lon1 NUMERIC,
    lat2 NUMERIC,
    lon2 NUMERIC
) RETURNS NUMERIC AS $$
DECLARE
    earth_radius NUMERIC := 6371; -- Raio da Terra em km
    dlat NUMERIC;
    dlon NUMERIC;
    a NUMERIC;
    c NUMERIC;
BEGIN
    -- Converte graus para radianos
    dlat := radians(lat2 - lat1);
    dlon := radians(lon2 - lon1);
    
    -- Fórmula de Haversine
    a := sin(dlat/2) * sin(dlat/2) +
         cos(radians(lat1)) * cos(radians(lat2)) *
         sin(dlon/2) * sin(dlon/2);
    c := 2 * atan2(sqrt(a), sqrt(1-a));
    
    RETURN earth_radius * c;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Função para verificar se um horário está disponível
CREATE OR REPLACE FUNCTION is_time_slot_available(
    p_room_id UUID,
    p_start_datetime TIMESTAMP WITH TIME ZONE,
    p_end_datetime TIMESTAMP WITH TIME ZONE
) RETURNS BOOLEAN AS $$
DECLARE
    v_day_of_week INTEGER;
    v_start_time TIME;
    v_end_time TIME;
    v_conflicting_booking BOOLEAN;
    v_conflicting_block BOOLEAN;
BEGIN
    -- Extrai dia da semana e horário
    v_day_of_week := EXTRACT(DOW FROM p_start_datetime);
    v_start_time := p_start_datetime::TIME;
    v_end_time := p_end_datetime::TIME;
    
    -- Verifica se está dentro do horário de funcionamento
    IF NOT EXISTS (
        SELECT 1 FROM schedule_configs
        WHERE room_id = p_room_id
        AND day_of_week = v_day_of_week
        AND is_available = TRUE
        AND start_time <= v_start_time
        AND end_time >= v_end_time
    ) THEN
        RETURN FALSE;
    END IF;
    
    -- Verifica conflitos com bloqueios
    SELECT EXISTS (
        SELECT 1 FROM schedule_blocks
        WHERE room_id = p_room_id
        AND (
            (start_datetime <= p_start_datetime AND end_datetime > p_start_datetime)
            OR (start_datetime < p_end_datetime AND end_datetime >= p_end_datetime)
            OR (start_datetime >= p_start_datetime AND end_datetime <= p_end_datetime)
        )
    ) INTO v_conflicting_block;
    
    IF v_conflicting_block THEN
        RETURN FALSE;
    END IF;
    
    -- Verifica conflitos com agendamentos aprovados
    SELECT EXISTS (
        SELECT 1 FROM bookings
        WHERE room_id = p_room_id
        AND status IN ('approved', 'completed')
        AND (
            (start_datetime <= p_start_datetime AND end_datetime > p_start_datetime)
            OR (start_datetime < p_end_datetime AND end_datetime >= p_end_datetime)
            OR (start_datetime >= p_start_datetime AND end_datetime <= p_end_datetime)
        )
    ) INTO v_conflicting_booking;
    
    RETURN NOT v_conflicting_booking;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- VIEWS ÚTEIS
-- ============================================

-- View para relatórios diários
CREATE OR REPLACE VIEW v_daily_reports AS
SELECT 
    s.id AS studio_id,
    s.nome_estudio,
    DATE(b.start_datetime) AS data,
    COUNT(*) FILTER (WHERE b.status = 'completed') AS total_ensaios,
    COUNT(DISTINCT b.client_id) AS total_clientes,
    COALESCE(SUM(b.valor_recebido), 0) AS receita_total,
    COALESCE(AVG(r.rating), 0) AS media_avaliacoes
FROM studios s
LEFT JOIN bookings b ON b.studio_id = s.id
LEFT JOIN reviews r ON r.booking_id = b.id AND b.status = 'completed'
WHERE b.status = 'completed'
GROUP BY s.id, s.nome_estudio, DATE(b.start_datetime);

-- View para relatórios mensais
CREATE OR REPLACE VIEW v_monthly_reports AS
SELECT 
    s.id AS studio_id,
    s.nome_estudio,
    DATE_TRUNC('month', b.start_datetime) AS mes,
    COUNT(*) FILTER (WHERE b.status = 'completed') AS total_ensaios,
    COUNT(DISTINCT b.client_id) AS total_clientes,
    COALESCE(SUM(b.valor_recebido), 0) AS receita_total,
    COALESCE(AVG(r.rating), 0) AS media_avaliacoes
FROM studios s
LEFT JOIN bookings b ON b.studio_id = s.id
LEFT JOIN reviews r ON r.booking_id = b.id AND b.status = 'completed'
WHERE b.status = 'completed'
GROUP BY s.id, s.nome_estudio, DATE_TRUNC('month', b.start_datetime);

-- View para relatórios anuais
CREATE OR REPLACE VIEW v_yearly_reports AS
SELECT 
    s.id AS studio_id,
    s.nome_estudio,
    DATE_TRUNC('year', b.start_datetime) AS ano,
    COUNT(*) FILTER (WHERE b.status = 'completed') AS total_ensaios,
    COUNT(DISTINCT b.client_id) AS total_clientes,
    COALESCE(SUM(b.valor_recebido), 0) AS receita_total,
    COALESCE(AVG(r.rating), 0) AS media_avaliacoes
FROM studios s
LEFT JOIN bookings b ON b.studio_id = s.id
LEFT JOIN reviews r ON r.booking_id = b.id AND b.status = 'completed'
WHERE b.status = 'completed'
GROUP BY s.id, s.nome_estudio, DATE_TRUNC('year', b.start_datetime);

-- View para estúdios com avaliações
CREATE OR REPLACE VIEW v_studios_with_ratings AS
SELECT 
    s.*,
    COALESCE(AVG(r.rating), 0) AS media_avaliacoes,
    COUNT(r.id) AS total_avaliacoes
FROM studios s
LEFT JOIN reviews r ON r.studio_id = s.id
WHERE s.deleted_at IS NULL
GROUP BY s.id;

-- ============================================
-- POLÍTICAS RLS (Row Level Security)
-- Para uso com Supabase
-- ============================================

-- Habilitar RLS em todas as tabelas
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE studios ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedule_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedule_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Políticas básicas (ajustar conforme necessidade de segurança)
-- Admin pode ver tudo
CREATE POLICY "Admin can view all" ON studios FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- Studio pode ver apenas seus próprios dados
CREATE POLICY "Studio can view own data" ON studios FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'studio' AND user_id = auth.uid())
);

-- Client pode ver todos os estúdios (para busca)
CREATE POLICY "Client can view studios" ON studios FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'client')
);

-- Client pode ver apenas seus próprios dados
CREATE POLICY "Client can view own data" ON clients FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'client' AND user_id = auth.uid())
);

-- Studio pode ver apenas suas salas
CREATE POLICY "Studio can view own rooms" ON rooms FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM studios s
        JOIN users u ON s.user_id = u.id
        WHERE s.id = rooms.studio_id AND u.id = auth.uid() AND u.role = 'studio'
    )
);

-- Client pode ver todas as salas (para busca)
CREATE POLICY "Client can view rooms" ON rooms FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'client')
);

-- Client pode ver apenas seus próprios agendamentos
CREATE POLICY "Client can view own bookings" ON bookings FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM clients c
        JOIN users u ON c.user_id = u.id
        WHERE c.id = bookings.client_id AND u.id = auth.uid() AND u.role = 'client'
    )
);

-- Studio pode ver agendamentos de suas salas
CREATE POLICY "Studio can view own studio bookings" ON bookings FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM studios s
        JOIN users u ON s.user_id = u.id
        WHERE s.id = bookings.studio_id AND u.id = auth.uid() AND u.role = 'studio'
    )
);

-- ============================================
-- COMENTÁRIOS NAS TABELAS
-- ============================================
COMMENT ON TABLE users IS 'Usuários do sistema (admin, studio, client)';
COMMENT ON TABLE studios IS 'Estúdios musicais cadastrados pelo admin';
COMMENT ON TABLE clients IS 'Clientes (músicos ou bandas) que se cadastram livremente';
COMMENT ON TABLE rooms IS 'Salas dos estúdios para ensaios/gravações';
COMMENT ON TABLE schedule_configs IS 'Configuração de horários de funcionamento das salas';
COMMENT ON TABLE schedule_blocks IS 'Bloqueios de horários (feriados, manutenção, etc)';
COMMENT ON TABLE bookings IS 'Agendamentos de ensaios';
COMMENT ON TABLE reviews IS 'Avaliações dos estúdios pelos clientes';
COMMENT ON TABLE notifications IS 'Notificações do sistema para integração com Brevo';

