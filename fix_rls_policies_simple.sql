-- SIMPLE FIX: Disable RLS or allow all authenticated users
-- Run this in Supabase SQL Editor

-- Option 1: Disable RLS (if these tables should be accessible to all authenticated users)
ALTER TABLE ani_watchlist DISABLE ROW LEVEL SECURITY;
ALTER TABLE vai_safe_accounts DISABLE ROW LEVEL SECURITY;
ALTER TABLE cii_ranges DISABLE ROW LEVEL SECURITY;
ALTER TABLE osi_rules DISABLE ROW LEVEL SECURITY;
ALTER TABLE rsi_rules DISABLE ROW LEVEL SECURITY;

-- OR Option 2: Enable RLS with permissive policies (uncomment if you prefer this)
/*
ALTER TABLE ani_watchlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE vai_safe_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cii_ranges ENABLE ROW LEVEL SECURITY;
ALTER TABLE osi_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE rsi_rules ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Allow all authenticated" ON ani_watchlist;
DROP POLICY IF EXISTS "Allow all authenticated" ON vai_safe_accounts;
DROP POLICY IF EXISTS "Allow all authenticated" ON cii_ranges;
DROP POLICY IF EXISTS "Allow all authenticated" ON osi_rules;
DROP POLICY IF EXISTS "Allow all authenticated" ON rsi_rules;

-- Create permissive policies
CREATE POLICY "Allow all authenticated" ON ani_watchlist FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow all authenticated" ON vai_safe_accounts FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow all authenticated" ON cii_ranges FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow all authenticated" ON osi_rules FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow all authenticated" ON rsi_rules FOR ALL USING (auth.role() = 'authenticated');
*/

