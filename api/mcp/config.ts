import { createClient, SupabaseClient } from '@supabase/supabase-js';

// Configuration & Environment Variables
export const SUPABASE_URL = process.env.SUPABASE_URL || 'https://uewczwnrchvmvmccrdqf.supabase.co';
export const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
export const ZETA_USER_ID = process.env.ZETA_USER_ID || '';
export const ZETA_MCP_KEY = process.env.ZETA_MCP_KEY || '';

// Fallback anon key for local testing/development only
export const DEFAULT_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVld2N6d25yY2h2bXZtY2NyZHFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgzNTkyNTksImV4cCI6MjEwMzkzNTI1OX0.9vjUcxJ0Wy2JsBAZ-vjB0H8Sn3bnPpEIU28Dm9v0No8';

let supabaseClient: SupabaseClient | null = null;

export function getSupabase(): SupabaseClient {
  if (supabaseClient) return supabaseClient;

  const key = SUPABASE_SERVICE_ROLE_KEY || DEFAULT_ANON_KEY;
  if (!SUPABASE_SERVICE_ROLE_KEY) {
    console.warn(
      '[Zeta MCP] Warning: SUPABASE_SERVICE_ROLE_KEY is not configured. Falling back to anon key. Database RLS policies may restrict operations.'
    );
  }

  supabaseClient = createClient(SUPABASE_URL, key, {
    auth: { persistSession: false },
  });
  return supabaseClient;
}

export function getUserId(): string {
  return process.env.ZETA_USER_ID || ZETA_USER_ID || '';
}

export function validateConfig(): { valid: boolean; missing: string[]; warnings: string[] } {
  const missing: string[] = [];
  const warnings: string[] = [];

  if (!getUserId()) {
    missing.push('ZETA_USER_ID');
  }

  if (!SUPABASE_SERVICE_ROLE_KEY) {
    warnings.push('SUPABASE_SERVICE_ROLE_KEY not configured (using fallback anon key)');
  }

  return {
    valid: missing.length === 0,
    missing,
    warnings,
  };
}
