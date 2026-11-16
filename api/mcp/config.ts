import { createClient, SupabaseClient } from '@supabase/supabase-js';
import crypto from 'node:crypto';

// Configuration & Environment Variables
export const SUPABASE_URL = process.env.SUPABASE_URL || 'https://uewczwnrchvmvmccrdqf.supabase.co';
export const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
export const ZETA_USER_ID = process.env.ZETA_USER_ID || '';
export const ZETA_MCP_KEY = process.env.ZETA_MCP_KEY || '';

// Fallback anon key for local development only
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
  const userId = process.env.ZETA_USER_ID || ZETA_USER_ID;
  return userId ? userId.trim() : '';
}

export interface AuthValidationResult {
  authorized: boolean;
  statusCode: number;
  errorMessage?: string;
}

/**
 * Validates MCP request authentication strictly.
 * - HTTP 500 if ZETA_MCP_KEY is missing or empty in server environment.
 * - HTTP 401 if key/token is missing, malformed, or invalid.
 * - Accepts key via Authorization header ('Bearer <key>'), 'x-zeta-key' header, or URL query param '?key=<key>'.
 * - Constant-time comparison using crypto.timingSafeEqual to prevent timing attacks.
 */
export function validateAuth(req: {
  headers?: Record<string, string | string[] | undefined>;
  query?: Record<string, string | string[] | undefined>;
  url?: string;
}): AuthValidationResult {
  const serverKey = process.env.ZETA_MCP_KEY || ZETA_MCP_KEY;
  if (!serverKey || serverKey.trim() === '') {
    return {
      authorized: false,
      statusCode: 500,
      errorMessage: 'Server Misconfiguration: ZETA_MCP_KEY environment variable is not configured.',
    };
  }

  // 1. Check Authorization: Bearer <token>
  const authHeader = req.headers?.['authorization'] || req.headers?.['Authorization'];
  let rawAuth = Array.isArray(authHeader) ? authHeader[0] : authHeader;
  let clientToken: string | undefined;

  if (rawAuth && typeof rawAuth === 'string') {
    if (rawAuth.startsWith('Bearer ')) {
      clientToken = rawAuth.slice(7).trim();
    } else {
      clientToken = rawAuth.trim();
    }
  }

  // 2. Fallback to custom header x-zeta-key
  if (!clientToken) {
    const xKey = req.headers?.['x-zeta-key'];
    if (xKey && typeof xKey === 'string') {
      clientToken = xKey.trim();
    }
  }

  // 3. Fallback to query parameter ?key= or ?token=
  if (!clientToken) {
    const queryKey = req.query?.['key'] || req.query?.['token'];
    if (queryKey) {
      clientToken = (Array.isArray(queryKey) ? queryKey[0] : queryKey).trim();
    } else if (req.url && req.url.includes('?')) {
      try {
        const parsedUrl = new URL(req.url, 'http://localhost');
        const qKey = parsedUrl.searchParams.get('key') || parsedUrl.searchParams.get('token');
        if (qKey) clientToken = qKey.trim();
      } catch (_) {}
    }
  }

  if (!clientToken) {
    return {
      authorized: false,
      statusCode: 401,
      errorMessage: 'Unauthorized: Missing authentication. Provide Authorization header ("Bearer <key>") or query parameter ("?key=<key>").',
    };
  }

  const serverBuffer = Buffer.from(serverKey.trim(), 'utf8');
  const clientBuffer = Buffer.from(clientToken, 'utf8');

  if (serverBuffer.length !== clientBuffer.length || !crypto.timingSafeEqual(serverBuffer, clientBuffer)) {
    return {
      authorized: false,
      statusCode: 401,
      errorMessage: 'Unauthorized: Invalid Zeta MCP secret key.',
    };
  }

  return {
    authorized: true,
    statusCode: 200,
  };
}

// Alias for convenience / interoperability
export const validateMcpAuth = validateAuth;

export function validateConfig(): { valid: boolean; missing: string[]; warnings: string[] } {
  const missing: string[] = [];
  const warnings: string[] = [];

  if (!getUserId()) {
    missing.push('ZETA_USER_ID');
  }

  const serverKey = process.env.ZETA_MCP_KEY || ZETA_MCP_KEY;
  if (!serverKey || serverKey.trim() === '') {
    missing.push('ZETA_MCP_KEY');
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
