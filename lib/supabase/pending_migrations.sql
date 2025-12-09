-- Pending Migrations for Ticketat
-- Clean migration fixes (no auth.users dependencies)

-- This file is kept clean for future migrations
-- All base schema is already in supabase_tables.sql
-- All RLS policies are already in supabase_policies.sql

-- If you need to apply new migrations, add them here
-- Keep migrations simple and avoid:
-- 1. Service role policies (handled by Supabase automatically)
-- 2. Auth.users foreign keys in sample data
-- 3. Complex triggers or functions
