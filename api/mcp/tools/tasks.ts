import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { getSupabase, getUserId } from '../config.js';

/**
 * Resolves a date string ("today", "tomorrow", or "YYYY-MM-DD") and optional time string ("HH:mm")
 * with timezone offset (in minutes) into an ISO UTC string.
 */
function resolveDueDateTime(
  dateInput?: string,
  timeInput?: string,
  timezoneOffsetMinutes?: number
): { isoDate: string | null; hasTime: boolean } {
  if (!dateInput) return { isoDate: null, hasTime: false };

  const offsetMs = (timezoneOffsetMinutes ?? 0) * 60 * 1000;
  const now = new Date();
  const localNow = new Date(now.getTime() + offsetMs);

  let targetYear = localNow.getUTCFullYear();
  let targetMonth = localNow.getUTCMonth();
  let targetDay = localNow.getUTCDate();

  const trimmed = dateInput.trim().toLowerCase();
  if (trimmed === 'today') {
    // Keep localNow date
  } else if (trimmed === 'tomorrow') {
    const tmr = new Date(localNow.getTime() + 24 * 60 * 60 * 1000);
    targetYear = tmr.getUTCFullYear();
    targetMonth = tmr.getUTCMonth();
    targetDay = tmr.getUTCDate();
  } else {
    const parts = trimmed.split('-');
    if (parts.length === 3) {
      targetYear = parseInt(parts[0], 10);
      targetMonth = parseInt(parts[1], 10) - 1;
      targetDay = parseInt(parts[2], 10);
    }
  }

  let hours = 12;
  let minutes = 0;
  let hasTime = false;

  if (timeInput) {
    const timeParts = timeInput.trim().split(':');
    if (timeParts.length >= 2) {
      hours = parseInt(timeParts[0], 10);
      minutes = parseInt(timeParts[1], 10);
      hasTime = true;
    }
  }

  // Calculate UTC timestamp from local components
  const localDateMs = Date.UTC(targetYear, targetMonth, targetDay, hours, minutes, 0, 0);
  const utcDateMs = localDateMs - offsetMs;

  return {
    isoDate: new Date(utcDateMs).toISOString(),
    hasTime,
  };
}

/**
 * Formats a task due date into human readable text respecting local timezone offset.
 */
function formatTaskDue(isoDate: string | null, hasTime: boolean, timezoneOffsetMinutes?: number): string {
  if (!isoDate) return '';
  const d = new Date(isoDate);
  if (isNaN(d.getTime())) return '';

  const offsetMs = (timezoneOffsetMinutes ?? 0) * 60 * 1000;
  const localDate = new Date(d.getTime() + offsetMs);

  const datePart = localDate.toISOString().substring(0, 10);
  if (!hasTime) return ` (Due: ${datePart})`;

  const hh = String(localDate.getUTCHours()).padStart(2, '0');
  const mm = String(localDate.getUTCMinutes()).padStart(2, '0');
  const tzLabel = timezoneOffsetMinutes !== undefined ? ` ${hh}:${mm} local` : ` ${hh}:${mm} UTC`;
  return ` (Due: ${datePart}${tzLabel})`;
}

export function registerTasksTools(server: McpServer): string[] {
  // ─── 1. list_tasks ──────────────────────────────────────────────────────────
  server.tool(
    'list_tasks',
    'Fetch active, upcoming, or completed tasks from Zeta with checklists, timezone filtering, and machine-readable JSON',
    {
      status: z
        .enum(['pending', 'completed', 'all'])
        .optional()
        .describe('Filter tasks by completion status (default is pending)'),
      due_date: z
        .string()
        .optional()
        .describe('Filter by due date: "today", "tomorrow", or "YYYY-MM-DD"'),
      timezone_offset_minutes: z
        .number()
        .optional()
        .describe('User timezone offset from UTC in minutes (e.g. +330 for IST, -300 for EST, 0 for UTC)'),
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
              text: 'Error: ZETA_USER_ID environment variable is not configured in Vercel settings.',
            },
          ],
        };
      }

      try {
        const status = args.status || 'pending';
        let query = supabase
          .from('tasks')
          .select('id, title, description, completed, due_date, has_time, subtasks, created_at')
          .eq('user_id', userId)
          .is('deleted_at', null);

        if (status === 'pending') query = query.eq('completed', false);
        if (status === 'completed') query = query.eq('completed', true);

        const { data, error } = await query
          .order('due_date', { ascending: true, nullsFirst: false })
          .range(0, 49);

        if (error) throw error;
        if (!data || data.length === 0) {
          return {
            content: [
              { type: 'text', text: `No ${status} tasks found in Zeta.` },
              { type: 'text', text: JSON.stringify({ count: 0, status, tasks: [] }, null, 2) },
            ],
          };
        }

        // Apply due_date filtering if requested
        let filteredData = data;
        if (args.due_date) {
          const resolved = resolveDueDateTime(args.due_date, undefined, args.timezone_offset_minutes);
          if (resolved.isoDate) {
            const targetDay = new Date(
              new Date(resolved.isoDate).getTime() + (args.timezone_offset_minutes ?? 0) * 60 * 1000
            )
              .toISOString()
              .substring(0, 10);

            filteredData = data.filter((t: any) => {
              if (!t.due_date) return false;
              const taskDay = new Date(
                new Date(t.due_date).getTime() + (args.timezone_offset_minutes ?? 0) * 60 * 1000
              )
                .toISOString()
                .substring(0, 10);
              return taskDay === targetDay;
            });
          }
        }

        const taskList = filteredData
          .map((t: any) => {
            const statusMark = t.completed ? '[x]' : '[ ]';
            const due = formatTaskDue(t.due_date, t.has_time, args.timezone_offset_minutes);
            const desc = t.description ? `\n    Notes: ${t.description}` : '';

            let subtasksText = '';
            if (Array.isArray(t.subtasks) && t.subtasks.length > 0) {
              const items = t.subtasks.map((st: any) => `    ${st.completed ? '✓' : '○'} ${st.title} [id: ${st.id}]`);
              subtasksText = '\n' + items.join('\n');
            }

            return `${statusMark} ${t.title}${due} [ID: ${t.id}]${desc}${subtasksText}`;
          })
          .join('\n\n');

        return {
          content: [
            {
              type: 'text',
              text: `📋 Found ${filteredData.length} ${status} task(s):\n\n${taskList}`,
            },
            {
              type: 'text',
              text: JSON.stringify(
                {
                  count: filteredData.length,
                  status,
                  tasks: filteredData,
                },
                null,
                2
              ),
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

  // ─── 2. create_task ─────────────────────────────────────────────────────────
  server.tool(
    'create_task',
    'Create a new task in Zeta with optional subtasks, description, due date/time, and timezone offset',
    {
      title: z.string().describe('The title of the task'),
      description: z.string().optional().describe('Optional task description or notes'),
      due_date: z
        .string()
        .optional()
        .describe('Due date: "today", "tomorrow", or "YYYY-MM-DD" (e.g. 2026-11-14)'),
      due_time: z.string().optional().describe('Due time in HH:mm 24-hour format (e.g. 17:30)'),
      timezone_offset_minutes: z
        .number()
        .optional()
        .describe('User timezone offset in minutes from UTC (e.g. +330 for IST, -300 for EST)'),
      subtasks: z
        .array(z.string())
        .optional()
        .describe('List of subtask titles/items to include as a checklist'),
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
              text: 'Error: ZETA_USER_ID environment variable is not configured in Vercel settings.',
            },
          ],
        };
      }

      try {
        const title = args.title?.trim();
        if (!title) throw new Error('Title is required to create a task');

        const now = new Date().toISOString();
        const subtasks = Array.isArray(args.subtasks)
          ? args.subtasks.map((s: string) => ({
              id: crypto.randomUUID(),
              title: String(s).trim(),
              completed: false,
            }))
          : [];

        const { isoDate, hasTime } = resolveDueDateTime(
          args.due_date,
          args.due_time,
          args.timezone_offset_minutes
        );

        const newTask = {
          id: crypto.randomUUID(),
          user_id: userId,
          title,
          description: args.description ? String(args.description).trim() : null,
          completed: false,
          due_date: isoDate,
          has_time: hasTime,
          subtasks,
          attachments: [],
          created_at: now,
          updated_at: now,
          deleted_at: null,
        };

        const { data, error } = await supabase.from('tasks').insert(newTask).select().single();
        if (error) throw error;

        const subtaskSummary =
          subtasks.length > 0 ? `\nSubtasks: ${subtasks.map((s: any) => `\n  - ${s.title}`).join('')}` : '';

        return {
          content: [
            {
              type: 'text',
              text: `✅ Task created: "${data.title}"\nID: ${data.id}${
                data.due_date ? formatTaskDue(data.due_date, data.has_time, args.timezone_offset_minutes) : ''
              }${subtaskSummary}`,
            },
            {
              type: 'text',
              text: JSON.stringify({ success: true, task: data }, null, 2),
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

  // ─── 3. batch_create_tasks ──────────────────────────────────────────────────
  server.tool(
    'batch_create_tasks',
    'Batch create multiple tasks in Zeta with optional subtasks, descriptions, due dates, and timezone offset',
    {
      timezone_offset_minutes: z
        .number()
        .optional()
        .describe('Timezone offset from UTC in minutes (e.g. +330 for IST, -300 for EST) applied to all relative dates'),
      tasks: z
        .array(
          z.object({
            title: z.string().describe('The title of the task'),
            description: z.string().optional().describe('Optional task description or notes'),
            due_date: z.string().optional().describe('Due date: "today", "tomorrow", or "YYYY-MM-DD"'),
            due_time: z.string().optional().describe('Due time in HH:mm 24-hour format (e.g. 17:30)'),
            subtasks: z
              .array(z.string())
              .optional()
              .describe('List of subtask titles/items to include as a checklist'),
          })
        )
        .describe('List of tasks to create'),
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
              text: 'Error: ZETA_USER_ID environment variable is not configured in Vercel settings.',
            },
          ],
        };
      }

      try {
        if (!args.tasks || args.tasks.length === 0) {
          return {
            content: [{ type: 'text', text: 'No tasks provided to batch create.' }],
          };
        }

        const now = new Date().toISOString();
        const newTasks = args.tasks.map((taskItem) => {
          const title = taskItem.title ? taskItem.title.trim() : '';
          if (!title) throw new Error('Task title cannot be empty');

          const subtasks = Array.isArray(taskItem.subtasks)
            ? taskItem.subtasks.map((s: string) => ({
                id: crypto.randomUUID(),
                title: String(s).trim(),
                completed: false,
              }))
            : [];

          const { isoDate, hasTime } = resolveDueDateTime(
            taskItem.due_date,
            taskItem.due_time,
            args.timezone_offset_minutes
          );

          return {
            id: crypto.randomUUID(),
            user_id: userId,
            title,
            description: taskItem.description ? String(taskItem.description).trim() : null,
            completed: false,
            due_date: isoDate,
            has_time: hasTime,
            subtasks,
            attachments: [],
            created_at: now,
            updated_at: now,
            deleted_at: null,
          };
        });

        const { data, error } = await supabase.from('tasks').insert(newTasks).select();
        if (error) throw error;

        const summary = (data || [])
          .map(
            (t: any) =>
              `• "${t.title}" (ID: ${t.id}${formatTaskDue(t.due_date, t.has_time, args.timezone_offset_minutes)})`
          )
          .join('\n');

        return {
          content: [
            {
              type: 'text',
              text: `✅ Batch created ${data.length} task(s):\n\n${summary}`,
            },
            {
              type: 'text',
              text: JSON.stringify({ success: true, count: data.length, tasks: data }, null, 2),
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

  // ─── 4. complete_task ───────────────────────────────────────────────────────
  server.tool(
    'complete_task',
    'Mark an existing task as completed in Zeta by its task ID',
    {
      task_id: z.string().describe('The UUID of the task to complete'),
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
              text: 'Error: ZETA_USER_ID environment variable is not configured in Vercel settings.',
            },
          ],
        };
      }

      try {
        const taskId = args.task_id;
        if (!taskId) throw new Error('task_id is required');

        const now = new Date().toISOString();
        const { data, error } = await supabase
          .from('tasks')
          .update({ completed: true, updated_at: now })
          .eq('id', taskId)
          .eq('user_id', userId)
          .select()
          .single();

        if (error) throw error;
        return {
          content: [
            {
              type: 'text',
              text: `✅ Task completed: "${data.title}" (ID: ${data.id})`,
            },
            {
              type: 'text',
              text: JSON.stringify({ success: true, task: data }, null, 2),
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

  // ─── 5. update_task ─────────────────────────────────────────────────────────
  server.tool(
    'update_task',
    'Update the title, description, subtasks, or due date/time of an existing task in Zeta',
    {
      task_id: z.string().describe('The UUID of the task to update'),
      title: z.string().optional().describe('New title for the task'),
      description: z.string().optional().describe('New description or notes'),
      due_date: z.string().optional().describe('New due date: "today", "tomorrow", or "YYYY-MM-DD"'),
      due_time: z.string().optional().describe('New due time in HH:mm format'),
      timezone_offset_minutes: z.number().optional().describe('Timezone offset in minutes from UTC'),
      subtasks: z
        .array(z.string())
        .optional()
        .describe('Replacement list of subtask titles/items for this task'),
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
              text: 'Error: ZETA_USER_ID environment variable is not configured in Vercel settings.',
            },
          ],
        };
      }

      try {
        const taskId = args.task_id;
        if (!taskId) throw new Error('task_id is required');

        const updates: Record<string, any> = { updated_at: new Date().toISOString() };
        if (args.title !== undefined) updates.title = args.title.trim();
        if (args.description !== undefined) updates.description = args.description.trim();

        if (args.due_date !== undefined) {
          const { isoDate, hasTime } = resolveDueDateTime(
            args.due_date,
            args.due_time,
            args.timezone_offset_minutes
          );
          updates.due_date = isoDate;
          updates.has_time = hasTime;
        }

        if (Array.isArray(args.subtasks)) {
          updates.subtasks = args.subtasks.map((s: string) => ({
            id: crypto.randomUUID(),
            title: String(s).trim(),
            completed: false,
          }));
        }

        const { data, error } = await supabase
          .from('tasks')
          .update(updates)
          .eq('id', taskId)
          .eq('user_id', userId)
          .select()
          .single();

        if (error) throw error;
        return {
          content: [
            {
              type: 'text',
              text: `✅ Task updated: "${data.title}"`,
            },
            {
              type: 'text',
              text: JSON.stringify({ success: true, task: data }, null, 2),
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

  // ─── 6. manage_subtask ──────────────────────────────────────────────────────
  server.tool(
    'manage_subtask',
    'Add, toggle completion, or remove a subtask in an existing task',
    {
      task_id: z.string().describe('The UUID of the parent task'),
      action: z
        .enum(['add', 'complete', 'uncomplete', 'delete'])
        .describe('Action to perform on the subtask'),
      subtask_title: z
        .string()
        .optional()
        .describe('The title of the subtask (required for add, or used to match when completing/deleting)'),
      subtask_id: z.string().optional().describe('The UUID of the subtask (optional, if known)'),
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
              text: 'Error: ZETA_USER_ID environment variable is not configured in Vercel settings.',
            },
          ],
        };
      }

      try {
        const taskId = args.task_id;
        const action = args.action;
        const subtaskTitle = args.subtask_title?.trim();
        const subtaskId = args.subtask_id;

        if (!taskId || !action) throw new Error('task_id and action are required');

        const { data: task, error: fetchErr } = await supabase
          .from('tasks')
          .select('id, title, subtasks')
          .eq('id', taskId)
          .eq('user_id', userId)
          .single();

        if (fetchErr || !task) throw new Error('Task not found');

        let currentSubtasks: any[] = Array.isArray(task.subtasks) ? [...task.subtasks] : [];
        let message = '';

        if (action === 'add') {
          if (!subtaskTitle) throw new Error('subtask_title is required to add a subtask');
          const newSubtask = {
            id: crypto.randomUUID(),
            title: subtaskTitle,
            completed: false,
          };
          currentSubtasks.push(newSubtask);
          message = `Added subtask "${subtaskTitle}" to task "${task.title}".`;
        } else if (action === 'complete' || action === 'uncomplete') {
          const isDone = action === 'complete';
          let found = false;
          currentSubtasks = currentSubtasks.map((st: any) => {
            if (
              (subtaskId && st.id === subtaskId) ||
              (subtaskTitle && st.title.toLowerCase().includes(subtaskTitle.toLowerCase()))
            ) {
              found = true;
              return { ...st, completed: isDone };
            }
            return st;
          });
          if (!found) throw new Error(`Subtask matching "${subtaskId || subtaskTitle}" not found`);
          message = `Marked subtask as ${isDone ? 'completed ✓' : 'pending ○'} in task "${task.title}".`;
        } else if (action === 'delete') {
          const initialLen = currentSubtasks.length;
          currentSubtasks = currentSubtasks.filter(
            (st: any) =>
              !(
                (subtaskId && st.id === subtaskId) ||
                (subtaskTitle && st.title.toLowerCase().includes(subtaskTitle.toLowerCase()))
              )
          );
          if (currentSubtasks.length === initialLen) {
            throw new Error(`Subtask matching "${subtaskId || subtaskTitle}" not found`);
          }
          message = `Deleted subtask from task "${task.title}".`;
        }

        const { data: updated, error: updateErr } = await supabase
          .from('tasks')
          .update({ subtasks: currentSubtasks, updated_at: new Date().toISOString() })
          .eq('id', taskId)
          .eq('user_id', userId)
          .select()
          .single();

        if (updateErr) throw updateErr;

        return {
          content: [
            { type: 'text', text: `✅ ${message}` },
            { type: 'text', text: JSON.stringify({ success: true, task: updated }, null, 2) },
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

  // ─── 7. delete_task ─────────────────────────────────────────────────────────
  server.tool(
    'delete_task',
    'Move a task to the trash / bin in Zeta, or optionally permanently hard-delete it',
    {
      task_id: z.string().describe('The UUID of the task to delete'),
      permanent: z
        .boolean()
        .optional()
        .describe('If true, permanently hard-deletes the task instead of moving to trash'),
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
              text: 'Error: ZETA_USER_ID environment variable is not configured in Vercel settings.',
            },
          ],
        };
      }

      try {
        const taskId = args.task_id;
        if (!taskId) throw new Error('task_id is required');

        if (args.permanent) {
          const { error } = await supabase.from('tasks').delete().eq('id', taskId).eq('user_id', userId);
          if (error) throw error;
          return {
            content: [
              { type: 'text', text: `🗑️ Task ${taskId} permanently deleted.` },
              { type: 'text', text: JSON.stringify({ success: true, task_id: taskId, permanent: true }, null, 2) },
            ],
          };
        } else {
          const now = new Date().toISOString();
          const { error } = await supabase
            .from('tasks')
            .update({ deleted_at: now, updated_at: now })
            .eq('id', taskId)
            .eq('user_id', userId);

          if (error) throw error;
          return {
            content: [
              { type: 'text', text: `🗑️ Task ${taskId} moved to trash.` },
              { type: 'text', text: JSON.stringify({ success: true, task_id: taskId, permanent: false }, null, 2) },
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

  return [
    'list_tasks',
    'create_task',
    'batch_create_tasks',
    'complete_task',
    'update_task',
    'manage_subtask',
    'delete_task',
  ];
}
