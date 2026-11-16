import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { getSupabase, getUserId } from './config.js';

export function registerResources(server: McpServer): string[] {
  const registered: string[] = [];

  // 1. zeta://tasks/today
  server.registerResource(
    'today_tasks',
    'zeta://tasks/today',
    {
      title: "Today's Tasks",
      description: 'Active and upcoming tasks scheduled for today or currently pending in Zeta (bounded to top 50)',
      mimeType: 'application/json',
    },
    async (uri) => {
      const supabase = getSupabase();
      const userId = getUserId();

      if (!userId) {
        return {
          contents: [
            {
              uri: uri.href,
              mimeType: 'application/json',
              text: JSON.stringify({ error: 'ZETA_USER_ID not configured' }),
            },
          ],
        };
      }

      const todayStr = new Date().toISOString().substring(0, 10);
      const { data: tasks, error } = await supabase
        .from('tasks')
        .select('id, title, description, completed, due_date, has_time, subtasks, created_at')
        .eq('user_id', userId)
        .is('deleted_at', null)
        .eq('completed', false)
        .order('due_date', { ascending: true, nullsFirst: false })
        .range(0, 49);

      if (error) {
        return {
          contents: [
            {
              uri: uri.href,
              mimeType: 'application/json',
              text: JSON.stringify({ error: error.message }),
            },
          ],
        };
      }

      // Filter tasks due today or undated pending
      const todayTasks = (tasks || []).filter((t: any) => {
        if (!t.due_date) return true; // Include undated pending tasks
        return t.due_date.startsWith(todayStr);
      });

      return {
        contents: [
          {
            uri: uri.href,
            mimeType: 'application/json',
            text: JSON.stringify(
              {
                date: todayStr,
                total_pending: (tasks || []).length,
                today_count: todayTasks.length,
                tasks: todayTasks,
              },
              null,
              2
            ),
          },
        ],
      };
    }
  );
  registered.push('zeta://tasks/today');

  // 2. zeta://tasks/summary
  server.registerResource(
    'tasks_summary',
    'zeta://tasks/summary',
    {
      title: 'Task Metrics & Summary',
      description: 'Overall task breakdown (total active, pending, completed) in Zeta (bounded to 50 items)',
      mimeType: 'application/json',
    },
    async (uri) => {
      const supabase = getSupabase();
      const userId = getUserId();

      if (!userId) {
        return {
          contents: [
            {
              uri: uri.href,
              mimeType: 'application/json',
              text: JSON.stringify({ error: 'ZETA_USER_ID not configured' }),
            },
          ],
        };
      }

      const { data, error } = await supabase
        .from('tasks')
        .select('id, completed, due_date')
        .eq('user_id', userId)
        .is('deleted_at', null)
        .range(0, 49);

      if (error) {
        return {
          contents: [
            {
              uri: uri.href,
              mimeType: 'application/json',
              text: JSON.stringify({ error: error.message }),
            },
          ],
        };
      }

      const total = data ? data.length : 0;
      const completed = data ? data.filter((t: any) => t.completed).length : 0;
      const pending = total - completed;
      const completionRate = total > 0 ? Math.round((completed / total) * 100) : 0;

      return {
        contents: [
          {
            uri: uri.href,
            mimeType: 'application/json',
            text: JSON.stringify(
              {
                sample_count: total,
                total_tasks: total,
                pending_tasks: pending,
                completed_tasks: completed,
                completion_rate_percentage: completionRate,
              },
              null,
              2
            ),
          },
        ],
      };
    }
  );
  registered.push('zeta://tasks/summary');

  // 3. zeta://pomodoro/summary
  server.registerResource(
    'pomodoro_summary',
    'zeta://pomodoro/summary',
    {
      title: 'Pomodoro Focus Statistics',
      description: "Current focus metrics, streaks, and today's completed pomodoro sessions (bounded to top 50)",
      mimeType: 'application/json',
    },
    async (uri) => {
      const supabase = getSupabase();
      const userId = getUserId();

      if (!userId) {
        return {
          contents: [
            {
              uri: uri.href,
              mimeType: 'application/json',
              text: JSON.stringify({ error: 'ZETA_USER_ID not configured' }),
            },
          ],
        };
      }

      const { data: sessions, error } = await supabase
        .from('pomodoro_sessions')
        .select('id, minutes, mode, completed_at, created_at')
        .eq('user_id', userId)
        .order('completed_at', { ascending: false })
        .range(0, 49);

      if (error) {
        return {
          contents: [
            {
              uri: uri.href,
              mimeType: 'application/json',
              text: JSON.stringify({ error: error.message }),
            },
          ],
        };
      }

      const todayStr = new Date().toISOString().substring(0, 10);
      const allSessions = (sessions || []).filter((s: any) => s.mode === 'focus' || !s.mode);
      const todaySessions = allSessions.filter((s: any) => {
        const d = (s.completed_at || s.created_at || '').substring(0, 10);
        return d === todayStr;
      });

      const todayMinutes = todaySessions.reduce((sum: number, s: any) => sum + (Number(s.minutes) || 0), 0);
      const totalMinutes = allSessions.reduce((sum: number, s: any) => sum + (Number(s.minutes) || 0), 0);

      return {
        contents: [
          {
            uri: uri.href,
            mimeType: 'application/json',
            text: JSON.stringify(
              {
                today_focus_minutes: todayMinutes,
                today_sessions_count: todaySessions.length,
                total_focus_minutes: totalMinutes,
                total_sessions_count: allSessions.length,
                recent_sessions: todaySessions.slice(0, 5),
              },
              null,
              2
            ),
          },
        ],
      };
    }
  );
  registered.push('zeta://pomodoro/summary');

  // 4. zeta://mindmaps/index
  server.registerResource(
    'mindmaps_index',
    'zeta://mindmaps/index',
    {
      title: 'Mindmaps Index',
      description: 'Index of active mindmaps in Zeta Space with node counts and root topics (bounded to top 50)',
      mimeType: 'application/json',
    },
    async (uri) => {
      const supabase = getSupabase();
      const userId = getUserId();

      if (!userId) {
        return {
          contents: [
            {
              uri: uri.href,
              mimeType: 'application/json',
              text: JSON.stringify({ error: 'ZETA_USER_ID not configured' }),
            },
          ],
        };
      }

      const { data: rows, error } = await supabase
        .from('mindmaps')
        .select('id, title, layout_type, nodes_json, created_at_ms, updated_at_ms')
        .eq('user_id', userId)
        .is('deleted_at_ms', null)
        .order('updated_at_ms', { ascending: false })
        .range(0, 49);

      if (error) {
        return {
          contents: [
            {
              uri: uri.href,
              mimeType: 'application/json',
              text: JSON.stringify({ error: error.message }),
            },
          ],
        };
      }

      const mindmaps = (rows || []).map((row: any) => {
        const nodes = Array.isArray(row.nodes_json) ? row.nodes_json : [];
        const rootNode = nodes.find((n: any) => !n.parentId || n.isRoot) || nodes[0];
        return {
          id: row.id,
          title: row.title,
          layout_type: row.layout_type,
          node_count: nodes.length,
          root_topic: rootNode ? rootNode.content : null,
          updated_at: new Date(row.updated_at_ms || Date.now()).toISOString(),
        };
      });

      return {
        contents: [
          {
            uri: uri.href,
            mimeType: 'application/json',
            text: JSON.stringify(
              {
                total_mindmaps: mindmaps.length,
                mindmaps,
              },
              null,
              2
            ),
          },
        ],
      };
    }
  );
  registered.push('zeta://mindmaps/index');

  return registered;
}
