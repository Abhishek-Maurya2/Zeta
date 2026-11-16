import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { createServer } from './mcp/index.js';
import { validateAuth, getUserId, validateConfig } from './mcp/config.js';

// Helper to parse JSON body from raw request stream if needed
async function getRequestBody(req: any): Promise<any> {
  if (req.body && typeof req.body === 'object') {
    return req.body;
  }
  if (typeof req.body === 'string') {
    try {
      return JSON.parse(req.body);
    } catch {
      return {};
    }
  }

  return new Promise((resolve) => {
    let body = '';
    req.on('data', (chunk: any) => {
      body += chunk;
    });
    req.on('end', () => {
      try {
        resolve(JSON.parse(body || '{}'));
      } catch {
        resolve({});
      }
    });
    req.on('error', () => resolve({}));
  });
}

// Vercel Serverless Function Entry Point
export default async function handler(req: any, res: any) {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Strict Authentication Gate (Bearer token only, constant-time validation)
  const auth = validateAuth(req);
  if (!auth.authorized) {
    return res.status(auth.statusCode).json({
      jsonrpc: '2.0',
      error: {
        code: auth.statusCode === 500 ? -32603 : -32000,
        message: auth.errorMessage,
      },
      id: null,
    });
  }

  // GET Request: Health Check & Status (Strictly Authenticated)
  if (req.method === 'GET') {
    const accept = req.headers?.accept || '';
    if (!accept.includes('text/event-stream')) {
      const { tools, resources } = createServer();
      const configHealth = validateConfig();
      return res.status(200).json({
        status: 'online',
        protocol: 'Model Context Protocol (MCP) Streamable HTTP',
        version: '2024-11-05',
        server: 'zeta-tasks-mcp',
        tools_count: tools.length,
        tools: tools,
        resources_count: resources.length,
        resources: resources,
        configured_user: Boolean(getUserId()),
        auth_enabled: true,
        config_health: configHealth,
      });
    }
  }

  // Ensure Accept header includes application/json and text/event-stream for Streamable HTTP compliance
  if (req.headers) {
    const accept = req.headers['accept'] || '';
    if (!accept.includes('application/json') || !accept.includes('text/event-stream')) {
      req.headers['accept'] = accept
        ? `${accept}, application/json, text/event-stream`
        : 'application/json, text/event-stream';
    }
  }

  try {
    const body = req.method === 'POST' ? await getRequestBody(req) : undefined;
    const { server } = createServer();
    const transport = new StreamableHTTPServerTransport({
      sessionIdGenerator: undefined,
      enableJsonResponse: true,
    });

    await server.connect(transport);
    await transport.handleRequest(req, res, body);
  } catch (err: any) {
    if (!res.headersSent) {
      return res.status(500).json({
        jsonrpc: '2.0',
        error: {
          code: -32603,
          message: `Internal error: ${err.message || String(err)}`,
        },
        id: null,
      });
    }
  }
}
