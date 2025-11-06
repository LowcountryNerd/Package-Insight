-- Fix RLS Policies for Index Tables
-- Run this in your Supabase SQL Editor

-- Enable RLS on all index tables (if not already enabled)
ALTER TABLE ani_watchlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE vai_safe_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cii_ranges ENABLE ROW LEVEL SECURITY;
ALTER TABLE osi_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE rsi_rules ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow authenticated users to read indexes" ON ani_watchlist;
DROP POLICY IF EXISTS "Allow authenticated users to insert indexes" ON ani_watchlist;
DROP POLICY IF EXISTS "Allow authenticated users to delete indexes" ON ani_watchlist;

DROP POLICY IF EXISTS "Allow authenticated users to read indexes" ON vai_safe_accounts;
DROP POLICY IF EXISTS "Allow authenticated users to insert indexes" ON vai_safe_accounts;
DROP POLICY IF EXISTS "Allow authenticated users to delete indexes" ON vai_safe_accounts;

DROP POLICY IF EXISTS "Allow authenticated users to read indexes" ON cii_ranges;
DROP POLICY IF EXISTS "Allow authenticated users to insert indexes" ON cii_ranges;
DROP POLICY IF EXISTS "Allow authenticated users to delete indexes" ON cii_ranges;

DROP POLICY IF EXISTS "Allow authenticated users to read indexes" ON osi_rules;
DROP POLICY IF EXISTS "Allow authenticated users to insert indexes" ON osi_rules;
DROP POLICY IF EXISTS "Allow authenticated users to delete indexes" ON osi_rules;

DROP POLICY IF EXISTS "Allow authenticated users to read indexes" ON rsi_rules;
DROP POLICY IF EXISTS "Allow authenticated users to insert indexes" ON rsi_rules;
DROP POLICY IF EXISTS "Allow authenticated users to delete indexes" ON rsi_rules;

-- ANI Watchlist Policies
CREATE POLICY "Allow authenticated users to read indexes" ON ani_watchlist
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to insert indexes" ON ani_watchlist
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to delete indexes" ON ani_watchlist
  FOR DELETE USING (auth.role() = 'authenticated');

-- VAI Safe Accounts Policies
CREATE POLICY "Allow authenticated users to read indexes" ON vai_safe_accounts
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to insert indexes" ON vai_safe_accounts
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to delete indexes" ON vai_safe_accounts
  FOR DELETE USING (auth.role() = 'authenticated');

-- CII Ranges Policies
CREATE POLICY "Allow authenticated users to read indexes" ON cii_ranges
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to insert indexes" ON cii_ranges
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to delete indexes" ON cii_ranges
  FOR DELETE USING (auth.role() = 'authenticated');

-- OSI Rules Policies
CREATE POLICY "Allow authenticated users to read indexes" ON osi_rules
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to insert indexes" ON osi_rules
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to delete indexes" ON osi_rules
  FOR DELETE USING (auth.role() = 'authenticated');

-- RSI Rules Policies
CREATE POLICY "Allow authenticated users to read indexes" ON rsi_rules
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to insert indexes" ON rsi_rules
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to delete indexes" ON rsi_rules
  FOR DELETE USING (auth.role() = 'authenticated');

