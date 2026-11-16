import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { getSupabase, getUserId } from '../config.js';
import { TrashItem } from '../types.js';

export function registerBinTools(server: McpServer): string[] {
  // ─── 1. list_bin ───────────────────────────────────────────────────
  server.tool(
    'list_bin',
    'List soft-deleted items (tasks and/or mindmaps) in the trash / bin',
    {
      item_type: z
        .enum(['all', 'task', 'mindmap'])
        .optional()
        .default('all')
        .describe("Filter bin items by type: 'all' (default), 'task', or 'mindmap'"),
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
        const itemType = args.item_type || 'all';
        const items: TrashItem[] = [];

        // 1. Fetch soft-deleted tasks
        if (itemType === 'all' || itemType === 'task') {
          const { data: taskData, error: taskError } = await supabase
            .from('tasks')
            .select('id, title, deleted_at')
            .eq('user_id', userId)
            .not('deleted_at', 'is', null)
            .order('deleted_at', { ascending: false })
            .range(0, 49);

          if (taskError) {
            // Check if error is due to deleted_at column or try deleted_at_ms
            const { data: altTaskData, error: altTaskError } = await supabase
              .from('tasks')
              .select('id, title, deleted_at_ms')
              .eq('user_id', userId)
              .not('deleted_at_ms', 'is', null);

            if (altTaskError) throw taskError;
            if (altTaskData) {
              for (const t of altTaskData) {
                items.push({
                  id: t.id,
                  title: t.title || 'Untitled Task',
                  item_type: 'task',
                  deleted_at: t.deleted_at_ms ? new Date(t.deleted_at_ms).toISOString() : new Date().toISOString(),
                });
              }
            }
          } else if (taskData) {
            for (const t of taskData) {
              items.push({
                id: t.id,
                title: t.title || 'Untitled Task',
                item_type: 'task',
                deleted_at: t.deleted_at || new Date().toISOString(),
              });
            }

            // Also check for any tasks with deleted_at_ms if applicable
            try {
              const { data: msTasks } = await supabase
                .from('tasks')
                .select('id, title, deleted_at_ms')
                .eq('user_id', userId)
                .is('deleted_at', null)
                .not('deleted_at_ms', 'is', null);

              if (msTasks && msTasks.length > 0) {
                for (const t of msTasks) {
                  if (!items.some((existing) => existing.id === t.id)) {
                    items.push({
                      id: t.id,
                      title: t.title || 'Untitled Task',
                      item_type: 'task',
                      deleted_at: t.deleted_at_ms ? new Date(t.deleted_at_ms).toISOString() : new Date().toISOString(),
                    });
                  }
                }
              }
            } catch {
              // Ignore if deleted_at_ms column is not present
            }
          }
        }

        // 2. Fetch soft-deleted mindmaps
        if (itemType === 'all' || itemType === 'mindmap') {
          const { data: mindmapData, error: mindmapError } = await supabase
            .from('mindmaps')
            .select('id, title, deleted_at_ms')
            .eq('user_id', userId)
            .not('deleted_at_ms', 'is', null)
            .order('deleted_at_ms', { ascending: false })
            .range(0, 49);

          if (mindmapError) throw mindmapError;

          if (mindmapData) {
            for (const m of mindmapData) {
              items.push({
                id: m.id,
                title: m.title || 'Untitled Mindmap',
                item_type: 'mindmap',
                deleted_at: m.deleted_at_ms ? new Date(m.deleted_at_ms).toISOString() : new Date().toISOString(),
              });
            }
          }
        }

        if (items.length === 0) {
          return {
            content: [
              {
                type: 'text',
                text: `No deleted items found in bin (filter: ${itemType}).`,
              },
            ],
          };
        }

        // Sort combined list descending by deleted_at
        items.sort((a, b) => {
          const timeA = new Date(a.deleted_at).getTime() || 0;
          const timeB = new Date(b.deleted_at).getTime() || 0;
          return timeB - timeA;
        });

        const formattedList = items
          .map(
            (item) =>
              `• [${item.item_type.toUpperCase()}] ${item.title} (ID: ${item.id})\n  Type: ${item.item_type} | Deleted At: ${item.deleted_at}`
          )
          .join('\n\n');

        return {
          content: [
            {
              type: 'text',
              text: `Found ${items.length} deleted item(s) in bin (${itemType}):\n\n${formattedList}`,
            },
            {
              type: 'text',
              text: JSON.stringify({ count: items.length, item_type: itemType, items }, null, 2),
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
    'Restore a soft-deleted task or mindmap from the trash / bin back to active status',
    {
      item_type: z.enum(['task', 'mindmap']).describe("The type of item to restore: 'task' or 'mindmap'"),
      item_id: z.string().describe('The UUID of the item to restore'),
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

        if (args.item_type === 'task') {
          // For task: sets deleted_at: null, deleted_at_ms: null, updated_at: ISO
          let { error } = await supabase
            .from('tasks')
            .update({
              deleted_at: null,
              deleted_at_ms: null,
              updated_at: nowIso,
            })
            .eq('id', args.item_id)
            .eq('user_id', userId);

          if (error && error.message && error.message.includes('deleted_at_ms')) {
            const fallback = await supabase
              .from('tasks')
              .update({
                deleted_at: null,
                updated_at: nowIso,
              })
              .eq('id', args.item_id)
              .eq('user_id', userId);
            error = fallback.error;
          }

          if (error) throw error;

          return {
            content: [
              {
                type: 'text',
                text: `♻️ Restored task "${args.item_id}" from bin back to active tasks.`,
              },
              {
                type: 'text',
                text: JSON.stringify({ success: true, item_id: args.item_id, item_type: 'task' }, null, 2),
              },
            ],
          };
        } else if (args.item_type === 'mindmap') {
          // For mindmap: sets deleted_at_ms: null, updated_at_ms: Date.now(), updated_at: ISO
          const nowMs = Date.now();
          const { error } = await supabase
            .from('mindmaps')
            .update({
              deleted_at_ms: null,
              updated_at_ms: nowMs,
              updated_at: new Date(nowMs).toISOString(),
            })
            .eq('id', args.item_id)
            .eq('user_id', userId);

          if (error) throw error;

          return {
            content: [
              {
                type: 'text',
                text: `♻️ Restored mindmap "${args.item_id}" from bin back to active mindmaps.`,
              },
              {
                type: 'text',
                text: JSON.stringify({ success: true, item_id: args.item_id, item_type: 'mindmap' }, null, 2),
              },
            ],
          };
        } else {
          return {
            isError: true,
            content: [
              {
                type: 'text',
                text: `Unsupported item_type "${args.item_type}". Expected 'task' or 'mindmap'.`,
              },
            ],
          };
        }
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
    'Permanently delete soft-deleted items in the trash / bin from Supabase',
    {
      item_type: z
        .enum(['all', 'task', 'mindmap'])
        .optional()
        .default('all')
        .describe("Which items to permanently remove: 'all' (default), 'task', or 'mindmap'"),
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
        const itemType = args.item_type || 'all';
        const deletedSummaries: string[] = [];

        // 1. Permanently delete soft-deleted tasks
        if (itemType === 'all' || itemType === 'task') {
          const { error: taskError } = await supabase
            .from('tasks')
            .delete()
            .eq('user_id', userId)
            .not('deleted_at', 'is', null);

          if (taskError) throw taskError;

          try {
            await supabase
              .from('tasks')
              .delete()
              .eq('user_id', userId)
              .not('deleted_at_ms', 'is', null);
          } catch {
            // Ignore if deleted_at_ms column does not exist
          }

          deletedSummaries.push('tasks');
        }

        // 2. Permanently delete soft-deleted mindmaps
        if (itemType === 'all' || itemType === 'mindmap') {
          const { error: mindmapError } = await supabase
            .from('mindmaps')
            .delete()
            .eq('user_id', userId)
            .not('deleted_at_ms', 'is', null);

          if (mindmapError) throw mindmapError;

          deletedSummaries.push('mindmaps');
        }

        return {
          content: [
            {
              type: 'text',
              text: `🗑️ Permanently emptied bin for ${deletedSummaries.join(' and ')} (item_type: "${itemType}").`,
            },
            {
              type: 'text',
              text: JSON.stringify({ success: true, item_type: itemType, purged: deletedSummaries }, null, 2),
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
