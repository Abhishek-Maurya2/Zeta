import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { getSupabase, getUserId } from '../config.js';
import { TrashItem } from '../types.js';

export function registerBinTools(server: McpServer): string[] {
  // ─── 1. list_bin ───────────────────────────────────────────────────
  server.tool(
    'list_bin',
    'List soft-deleted tasks in the trash / bin',
    {
      limit: z
        .number()
        .min(1)
        .max(100)
        .optional()
        .default(50)
        .describe('Maximum number of bin tasks to return (default: 50)'),
    },
    async (args) => {
      const supabase = getSupabase();
      const userId = getUserId();

      if (!userId) {
        return {
          isError: true,
          content: [
            {
              type: 'text',
              text: 'Error: ZETA_USER_ID environment variable is not configured.',
            },
          ],
        };
      }

      try {
        const limit = args.limit || 50;
        const { data: taskData, error: taskError } = await supabase
          .from('tasks')
          .select('id, title, deleted_at')
          .eq('user_id', userId)
          .not('deleted_at', 'is', null)
          .order('deleted_at', { ascending: false })
          .range(0, limit - 1);

        if (taskError) throw taskError;

        if (!taskData || taskData.length === 0) {
          return {
            content: [
              {
                type: 'text',
                text: 'No deleted tasks found in bin.',
              },
            ],
          };
        }

        const items: TrashItem[] = taskData.map((t) => ({
          id: t.id,
          title: t.title || 'Untitled Task',
          item_type: 'task',
          deleted_at: t.deleted_at || new Date().toISOString(),
        }));

        const formattedList = items
          .map(
            (item) =>
              `• ${item.title} (ID: ${item.id})\n  Deleted At: ${item.deleted_at}`
          )
          .join('\n\n');

        return {
          content: [
            {
              type: 'text',
              text: `Found ${items.length} deleted task(s) in bin:\n\n${formattedList}`,
            },
            {
              type: 'text',
              text: JSON.stringify({ count: items.length, tasks: items }, null, 2),
            },
          ],
        };
      } catch (err: any) {
        return {
          isError: true,
          content: [{ type: 'text', text: `Database error: ${err.message || String(err)}` }],
        };
      }
    }
  );

  // ─── 2. restore_item ───────────────────────────────────────────────
  server.tool(
    'restore_item',
    'Restore a soft-deleted task from the trash / bin back to active tasks',
    {
      task_id: z.string().describe('The UUID of the task to restore'),
    },
    async (args) => {
      const supabase = getSupabase();
      const userId = getUserId();

      if (!userId) {
        return {
          isError: true,
          content: [
            {
              type: 'text',
              text: 'Error: ZETA_USER_ID environment variable is not configured.',
            },
          ],
        };
      }

      try {
        const nowIso = new Date().toISOString();
        const { data, error } = await supabase
          .from('tasks')
          .update({
            deleted_at: null,
            updated_at: nowIso,
          })
          .eq('id', args.task_id)
          .eq('user_id', userId)
          .select()
          .single();

        if (error || !data) {
          return {
            isError: true,
            content: [{ type: 'text', text: `Task with ID "${args.task_id}" not found or not in bin.` }],
          };
        }

        return {
          content: [
            {
              type: 'text',
              text: `♻️ Restored task "${data.title || args.task_id}" from bin back to active tasks.`,
            },
            {
              type: 'text',
              text: JSON.stringify({ success: true, task_id: args.task_id, task: data }, null, 2),
            },
          ],
        };
      } catch (err: any) {
        return {
          isError: true,
          content: [{ type: 'text', text: `Database error: ${err.message || String(err)}` }],
        };
      }
    }
  );

  // ─── 3. empty_bin ──────────────────────────────────────────────────
  server.tool(
    'empty_bin',
    'Permanently delete all soft-deleted tasks in the trash / bin from Supabase',
    {},
    async () => {
      const supabase = getSupabase();
      const userId = getUserId();

      if (!userId) {
        return {
          isError: true,
          content: [
            {
              type: 'text',
              text: 'Error: ZETA_USER_ID environment variable is not configured.',
            },
          ],
        };
      }

      try {
        const { error: taskError } = await supabase
          .from('tasks')
          .delete()
          .eq('user_id', userId)
          .not('deleted_at', 'is', null);

        if (taskError) throw taskError;

        return {
          content: [
            {
              type: 'text',
              text: '🗑️ Permanently emptied bin of all soft-deleted tasks.',
            },
            {
              type: 'text',
              text: JSON.stringify({ success: true, purged: ['tasks'] }, null, 2),
            },
          ],
        };
      } catch (err: any) {
        return {
          isError: true,
          content: [{ type: 'text', text: `Database error: ${err.message || String(err)}` }],
        };
      }
    }
  );

  return ['list_bin', 'restore_item', 'empty_bin'];
}
