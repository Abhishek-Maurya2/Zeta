import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { registerTasksTools } from './tools/tasks.js';
import { registerPomodoroTools } from './tools/pomodoro.js';
import { registerMindmapsTools } from './tools/mindmaps.js';
import { registerBinTools } from './tools/bin.js';
import { registerResources } from './resources.js';

export function createServer(): { server: McpServer; tools: string[]; resources: string[] } {
  const server = new McpServer({
    name: 'zeta-tasks-mcp',
    version: '1.2.0',
  });

  const tools: string[] = [
    ...registerTasksTools(server),
    ...registerPomodoroTools(server),
    ...registerMindmapsTools(server),
    ...registerBinTools(server),
  ];

  const resources: string[] = registerResources(server);

  return { server, tools, resources };
}
