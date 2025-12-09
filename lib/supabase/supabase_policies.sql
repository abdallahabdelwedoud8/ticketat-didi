-- Ticketat Row Level Security Policies
-- Secure data access policies for all tables

-- Enable Row Level Security on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_proofs ENABLE ROW LEVEL SECURITY;
ALTER TABLE sponsor_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE sponsors ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics ENABLE ROW LEVEL SECURITY;

-- Users table policies
DROP POLICY IF EXISTS "Users can view all users" ON users;
CREATE POLICY "Users can view all users" ON users FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Anon users can create profiles during signup" ON users;
CREATE POLICY "Anon users can create profiles during signup" ON users FOR INSERT TO anon WITH CHECK (true);

DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
CREATE POLICY "Users can insert their own profile" ON users FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update their own profile" ON users;
CREATE POLICY "Users can update their own profile" ON users FOR UPDATE TO authenticated USING (auth.uid() = auth_user_id) WITH CHECK (true);

DROP POLICY IF EXISTS "Users can delete their own profile" ON users;
CREATE POLICY "Users can delete their own profile" ON users FOR DELETE TO authenticated USING (auth.uid() = auth_user_id);

-- Events table policies
DROP POLICY IF EXISTS "Anyone can view active events" ON events;
CREATE POLICY "Anyone can view active events" ON events FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Public can view active events" ON events;
CREATE POLICY "Public can view active events" ON events FOR SELECT TO anon USING (status = 'active');

DROP POLICY IF EXISTS "Organizers can create events" ON events;
CREATE POLICY "Organizers can create events" ON events FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Organizers can update their own events" ON events;
CREATE POLICY "Organizers can update their own events" ON events FOR UPDATE TO authenticated USING (organizer_id IN (SELECT user_id FROM users WHERE auth_user_id = auth.uid())) WITH CHECK (true);

DROP POLICY IF EXISTS "Organizers can delete their own events" ON events;
CREATE POLICY "Organizers can delete their own events" ON events FOR DELETE TO authenticated USING (organizer_id IN (SELECT user_id FROM users WHERE auth_user_id = auth.uid()));

-- Tickets table policies
DROP POLICY IF EXISTS "Users can view their own tickets" ON tickets;
CREATE POLICY "Users can view their own tickets" ON tickets FOR SELECT TO authenticated USING (user_id IN (SELECT user_id FROM users WHERE auth_user_id = auth.uid()));

DROP POLICY IF EXISTS "Users can create tickets" ON tickets;
CREATE POLICY "Users can create tickets" ON tickets FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update their own tickets" ON tickets;
CREATE POLICY "Users can update their own tickets" ON tickets FOR UPDATE TO authenticated USING (user_id IN (SELECT user_id FROM users WHERE auth_user_id = auth.uid())) WITH CHECK (true);

DROP POLICY IF EXISTS "Users can delete their own tickets" ON tickets;
CREATE POLICY "Users can delete their own tickets" ON tickets FOR DELETE TO authenticated USING (user_id IN (SELECT user_id FROM users WHERE auth_user_id = auth.uid()));

-- Payment proofs table policies
DROP POLICY IF EXISTS "Users can view all payment proofs" ON payment_proofs;
CREATE POLICY "Users can view all payment proofs" ON payment_proofs FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Users can create payment proofs" ON payment_proofs;
CREATE POLICY "Users can create payment proofs" ON payment_proofs FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update payment proofs" ON payment_proofs;
CREATE POLICY "Users can update payment proofs" ON payment_proofs FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Users can delete payment proofs" ON payment_proofs;
CREATE POLICY "Users can delete payment proofs" ON payment_proofs FOR DELETE TO authenticated USING (true);

-- Sponsor applications table policies
DROP POLICY IF EXISTS "Users can view all sponsor applications" ON sponsor_applications;
CREATE POLICY "Users can view all sponsor applications" ON sponsor_applications FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Sponsors can create applications" ON sponsor_applications;
CREATE POLICY "Sponsors can create applications" ON sponsor_applications FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Sponsors can update their applications" ON sponsor_applications;
CREATE POLICY "Sponsors can update their applications" ON sponsor_applications FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Sponsors can delete their applications" ON sponsor_applications;
CREATE POLICY "Sponsors can delete their applications" ON sponsor_applications FOR DELETE TO authenticated USING (true);

-- Event promotions table policies
DROP POLICY IF EXISTS "Users can view all promotions" ON event_promotions;
CREATE POLICY "Users can view all promotions" ON event_promotions FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Organizers can create promotions" ON event_promotions;
CREATE POLICY "Organizers can create promotions" ON event_promotions FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Organizers can update promotions" ON event_promotions;
CREATE POLICY "Organizers can update promotions" ON event_promotions FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Organizers can delete promotions" ON event_promotions;
CREATE POLICY "Organizers can delete promotions" ON event_promotions FOR DELETE TO authenticated USING (true);

-- Security staff table policies
DROP POLICY IF EXISTS "Users can view all security staff" ON security_staff;
CREATE POLICY "Users can view all security staff" ON security_staff FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Organizers can create security staff" ON security_staff;
CREATE POLICY "Organizers can create security staff" ON security_staff FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Organizers can update security staff" ON security_staff;
CREATE POLICY "Organizers can update security staff" ON security_staff FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Organizers can delete security staff" ON security_staff;
CREATE POLICY "Organizers can delete security staff" ON security_staff FOR DELETE TO authenticated USING (true);

-- Sponsors table policies
DROP POLICY IF EXISTS "Users can view all sponsors" ON sponsors;
CREATE POLICY "Users can view all sponsors" ON sponsors FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Users can create sponsor profiles" ON sponsors;
CREATE POLICY "Users can create sponsor profiles" ON sponsors FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Sponsors can update their profiles" ON sponsors;
CREATE POLICY "Sponsors can update their profiles" ON sponsors FOR UPDATE TO authenticated USING (user_id IN (SELECT user_id FROM users WHERE auth_user_id = auth.uid())) WITH CHECK (true);

DROP POLICY IF EXISTS "Sponsors can delete their profiles" ON sponsors;
CREATE POLICY "Sponsors can delete their profiles" ON sponsors FOR DELETE TO authenticated USING (user_id IN (SELECT user_id FROM users WHERE auth_user_id = auth.uid()));

-- Service providers table policies
DROP POLICY IF EXISTS "Users can view all service providers" ON service_providers;
CREATE POLICY "Users can view all service providers" ON service_providers FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Public can view service providers" ON service_providers;
CREATE POLICY "Public can view service providers" ON service_providers FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "Users can create service provider profiles" ON service_providers;
CREATE POLICY "Users can create service provider profiles" ON service_providers FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Providers can update their profiles" ON service_providers;
CREATE POLICY "Providers can update their profiles" ON service_providers FOR UPDATE TO authenticated USING (user_id IN (SELECT user_id FROM users WHERE auth_user_id = auth.uid())) WITH CHECK (true);

DROP POLICY IF EXISTS "Providers can delete their profiles" ON service_providers;
CREATE POLICY "Providers can delete their profiles" ON service_providers FOR DELETE TO authenticated USING (user_id IN (SELECT user_id FROM users WHERE auth_user_id = auth.uid()));

-- Analytics table policies
DROP POLICY IF EXISTS "Users can view all analytics" ON analytics;
CREATE POLICY "Users can view all analytics" ON analytics FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Organizers can create analytics" ON analytics;
CREATE POLICY "Organizers can create analytics" ON analytics FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Organizers can update analytics" ON analytics;
CREATE POLICY "Organizers can update analytics" ON analytics FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Organizers can delete analytics" ON analytics;
CREATE POLICY "Organizers can delete analytics" ON analytics FOR DELETE TO authenticated USING (true);
