-- Ticketat Database Schema
-- Complete database schema for the Ticketat event ticketing platform

-- Users table (links to auth.users)
CREATE TABLE IF NOT EXISTS users (
  user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone_number TEXT,
  username TEXT NOT NULL UNIQUE,
  email TEXT,
  role TEXT NOT NULL DEFAULT 'buyer' CHECK (role IN ('buyer', 'organizer', 'sponsor', 'security')),
  preferences TEXT[] DEFAULT ARRAY[]::TEXT[],
  joined_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  language TEXT NOT NULL DEFAULT 'fr',
  first_purchase_used BOOLEAN DEFAULT FALSE,
  birthday TIMESTAMPTZ,
  gender TEXT,
  neighborhood TEXT,
  has_premium_analytics BOOLEAN DEFAULT FALSE,
  premium_expiry_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT users_contact_check CHECK (email IS NOT NULL OR phone_number IS NOT NULL)
);

-- Events table
CREATE TABLE IF NOT EXISTS events (
  event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  venue TEXT NOT NULL,
  price NUMERIC(10, 2) NOT NULL DEFAULT 0,
  capacity INTEGER NOT NULL DEFAULT 100,
  sold_tickets INTEGER DEFAULT 0,
  organizer_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  image_url TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'past', 'cancelled')),
  is_sponsored BOOLEAN DEFAULT FALSE,
  sponsored_days INTEGER DEFAULT 0,
  payment_options JSONB DEFAULT '[]'::jsonb,
  google_maps_link TEXT,
  website_link TEXT,
  social_media_link TEXT,
  media_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tickets table
CREATE TABLE IF NOT EXISTS tickets (
  ticket_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  event_id UUID NOT NULL REFERENCES events(event_id) ON DELETE CASCADE,
  qr_data TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'valid' CHECK (status IN ('valid', 'used', 'expired')),
  purchase_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  price_paid NUMERIC(10, 2) NOT NULL,
  discount_applied NUMERIC(10, 2) DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Payment proofs table
CREATE TABLE IF NOT EXISTS payment_proofs (
  payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES tickets(ticket_id) ON DELETE CASCADE,
  method TEXT NOT NULL CHECK (method IN ('mobileMoney', 'card')),
  screenshot_url TEXT,
  sender_number TEXT,
  transaction_reference TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Sponsor applications table
CREATE TABLE IF NOT EXISTS sponsor_applications (
  application_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sponsor_id TEXT NOT NULL,
  event_id UUID NOT NULL REFERENCES events(event_id) ON DELETE CASCADE,
  brand_name TEXT NOT NULL,
  budget_offered NUMERIC(10, 2) NOT NULL,
  message TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  organizer_contact_info TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Event promotions table
CREATE TABLE IF NOT EXISTS event_promotions (
  promotion_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(event_id) ON DELETE CASCADE,
  days_promoted INTEGER NOT NULL,
  total_cost NUMERIC(10, 2) NOT NULL,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Security staff table
CREATE TABLE IF NOT EXISTS security_staff (
  staff_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(event_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  temp_password TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Sponsors table
CREATE TABLE IF NOT EXISTS sponsors (
  sponsor_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  company_name TEXT NOT NULL,
  category TEXT NOT NULL,
  budget_range TEXT NOT NULL,
  target_audience TEXT[] DEFAULT ARRAY[]::TEXT[],
  sponsored_events TEXT[] DEFAULT ARRAY[]::TEXT[],
  impressions INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Service providers table
CREATE TABLE IF NOT EXISTS service_providers (
  provider_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  company_name TEXT NOT NULL,
  service_type TEXT NOT NULL,
  rating NUMERIC(3, 2) DEFAULT 5.0 CHECK (rating >= 0 AND rating <= 5),
  contact_info TEXT NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Analytics table
CREATE TABLE IF NOT EXISTS analytics (
  analytics_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(event_id) ON DELETE CASCADE,
  total_sales INTEGER DEFAULT 0,
  revenue NUMERIC(10, 2) DEFAULT 0,
  attendance INTEGER DEFAULT 0,
  demographics JSONB DEFAULT '{}'::jsonb,
  avg_rating NUMERIC(3, 2) DEFAULT 0,
  sponsor_matches TEXT[] DEFAULT ARRAY[]::TEXT[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for better query performance
-- Use partial unique indexes for email and phone_number to allow multiple NULLs
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique ON users(email) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone_unique ON users(phone_number) WHERE phone_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_auth_user_id ON users(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_events_organizer_id ON events(organizer_id);
CREATE INDEX IF NOT EXISTS idx_events_date ON events(date);
CREATE INDEX IF NOT EXISTS idx_events_category ON events(category);
CREATE INDEX IF NOT EXISTS idx_events_is_sponsored ON events(is_sponsored) WHERE is_sponsored = TRUE;
CREATE INDEX IF NOT EXISTS idx_tickets_user_id ON tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_tickets_event_id ON tickets(event_id);
CREATE INDEX IF NOT EXISTS idx_tickets_qr_data ON tickets(qr_data);
CREATE INDEX IF NOT EXISTS idx_payment_proofs_ticket_id ON payment_proofs(ticket_id);
CREATE INDEX IF NOT EXISTS idx_sponsor_applications_event_id ON sponsor_applications(event_id);
CREATE INDEX IF NOT EXISTS idx_security_staff_event_id ON security_staff(event_id);
CREATE INDEX IF NOT EXISTS idx_sponsors_user_id ON sponsors(user_id);
CREATE INDEX IF NOT EXISTS idx_service_providers_user_id ON service_providers(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_event_id ON analytics(event_id);
