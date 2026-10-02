import { createClient } from '@supabase/supabase-js';

// Configuration & Environment Variables
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://uewczwnrchvmvmccrdqf.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
const ZETA_USER_ID = process.env.ZETA_USER_ID || '';
const ZETA_MCP_KEY = process.env.ZETA_MCP_KEY || '';

// Fallback anon key for testing if service role is pending
const DEFAULT_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVld2N6d25yY2h2bXZtY2NyZHFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgzNTkyNTksImV4cCI6MjEwMzkzNTI1OX0.9vjUcxJ0Wy2JsBAZ-vjB0H8Sn3bnPpEIU28Dm9v0No8';

function getSupabase() {
  const key = SUPABASE_SERVICE_ROLE_KEY || DEFAULT_ANON_KEY;
  return createClient(SUPABASE_URL, key, {
    auth: { persistSession: false },
  });
}

// Spaced repetition interval helper
function getNextRevisionDate(stage: number): { nextDate: string | null; stageName: string } {
  const now = new Date();
  switch (stage) {
    case 1:
      now.setDate(now.getDate() + 5);
      return { nextDate: now.toISOString(), stageName: 'Stage 1 (1x - due in 5 days)' };
    case 2:
      now.setDate(now.getDate() + 10);
      return { nextDate: now.toISOString(), stageName: 'Stage 2 (2x - due in 10 days)' };
    case 3:
      now.setDate(now.getDate() + 20);
      return { nextDate: now.toISOString(), stageName: 'Stage 3 (3x - due in 20 days)' };
    case 4:
      now.setDate(now.getDate() + 40);
      return { nextDate: now.toISOString(), stageName: 'Stage 4 (4x - due in 40 days)' };
    case 5:
    default:
      return { nextDate: null, stageName: 'Stage 5 (Mastered 🏆)' };
  }
}

// MCP Tools Definition Schema
const MCP_TOOLS = [
  // ─── 1. TASKS & SUBTASKS ──────────────────────────────────────────────
  {
    name: 'list_tasks',
    description: 'Fetch active, upcoming, or completed tasks from Zeta with their subtasks checklists',
    inputSchema: {
      type: 'object',
      properties: {
        status: {
          type: 'string',
          enum: ['pending', 'completed', 'all'],
          description: 'Filter tasks by completion status (default is pending)',
        },
        due_date: {
          type: 'string',
          description: 'Optional filter by due date (YYYY-MM-DD)',
        },
      },
    },
  },
  {
    name: 'create_task',
    description: 'Create a new task in Zeta with optional subtasks, description, due date, and due time',
    inputSchema: {
      type: 'object',
      required: ['title'],
      properties: {
        title: {
          type: 'string',
          description: 'The title of the task',
        },
        description: {
          type: 'string',
          description: 'Optional task description or notes',
        },
        due_date: {
          type: 'string',
          description: 'Due date in YYYY-MM-DD format (e.g. 2026-10-03)',
        },
        due_time: {
          type: 'string',
          description: 'Due time in HH:mm 24-hour format (e.g. 17:30)',
        },
        subtasks: {
          type: 'array',
          items: { type: 'string' },
          description: 'List of subtask titles/items to include as a checklist',
        },
      },
    },
  },
  {
    name: 'complete_task',
    description: 'Mark an existing task as completed in Zeta by its task ID',
    inputSchema: {
      type: 'object',
      required: ['task_id'],
      properties: {
        task_id: {
          type: 'string',
          description: 'The UUID of the task to complete',
        },
      },
    },
  },
  {
    name: 'update_task',
    description: 'Update the title, description, or due date/time of an existing task in Zeta',
    inputSchema: {
      type: 'object',
      required: ['task_id'],
      properties: {
        task_id: {
          type: 'string',
          description: 'The UUID of the task to update',
        },
        title: {
          type: 'string',
          description: 'New title for the task',
        },
        description: {
          type: 'string',
          description: 'New description or notes',
        },
        due_date: {
          type: 'string',
          description: 'New due date in YYYY-MM-DD format',
        },
        due_time: {
          type: 'string',
          description: 'New due time in HH:mm format',
        },
      },
    },
  },
  {
    name: 'manage_subtask',
    description: 'Add, toggle completion, or remove a subtask in an existing task',
    inputSchema: {
      type: 'object',
      required: ['task_id', 'action'],
      properties: {
        task_id: {
          type: 'string',
          description: 'The UUID of the parent task',
        },
        action: {
          type: 'string',
          enum: ['add', 'complete', 'uncomplete', 'delete'],
          description: 'Action to perform on the subtask',
        },
        subtask_title: {
          type: 'string',
          description: 'The title of the subtask (required for add, or used to match when completing/deleting)',
        },
        subtask_id: {
          type: 'string',
          description: 'The UUID of the subtask (optional, if known)',
        },
      },
    },
  },
  {
    name: 'delete_task',
    description: 'Move a task to the trash / bin in Zeta',
    inputSchema: {
      type: 'object',
      required: ['task_id'],
      properties: {
        task_id: {
          type: 'string',
          description: 'The UUID of the task to delete',
        },
      },
    },
  },

  // ─── 2. REVISION SUBJECTS & TOPICS (SPACED REPETITION) ────────────────
  {
    name: 'list_subjects',
    description: 'List all study and revision subjects in Zeta with topic counts and mastery status',
    inputSchema: {
      type: 'object',
      properties: {},
    },
  },
  {
    name: 'create_subject',
    description: 'Create a new study subject in Zeta (e.g. Physics, Operating Systems, Spanish)',
    inputSchema: {
      type: 'object',
      required: ['name'],
      properties: {
        name: {
          type: 'string',
          description: 'Name of the subject',
        },
        color: {
          type: 'string',
          description: 'Hex color string (e.g. "#6750A4", "#1E88E5", "#43A047")',
        },
      },
    },
  },
  {
    name: 'list_topics',
    description: 'List study topics under subjects in Zeta, with their spaced repetition revision stage, next due date, or topics due for review',
    inputSchema: {
      type: 'object',
      properties: {
        subject_id: {
          type: 'string',
          description: 'Optional filter by subject UUID',
        },
        filter: {
          type: 'string',
          enum: ['due_today', 'all', 'mastered', 'in_progress'],
          description: 'Filter topics (due_today: due for revision today or overdue)',
        },
      },
    },
  },
  {
    name: 'create_topic',
    description: 'Add a new topic under a subject in Zeta to track study progress and spaced repetition revisions',
    inputSchema: {
      type: 'object',
      required: ['subject_id', 'title'],
      properties: {
        subject_id: {
          type: 'string',
          description: 'UUID of the subject this topic belongs to',
        },
        title: {
          type: 'string',
          description: 'Title of the topic',
        },
        description: {
          type: 'string',
          description: 'Notes or key concepts for this topic',
        },
      },
    },
  },
  {
    name: 'log_topic_revision',
    description: 'Log that you revised a topic today. Advances its spaced repetition stage (+5d, +10d, +20d, +40d) and schedules the next review',
    inputSchema: {
      type: 'object',
      required: ['topic_id'],
      properties: {
        topic_id: {
          type: 'string',
          description: 'UUID of the topic you just revised',
        },
      },
    },
  },

  // ─── 3. POMODORO FOCUS STATS & LOGGING ────────────────────────────────
  {
    name: 'get_pomodoro_summary',
    description: 'Get Pomodoro focus statistics from Zeta (today focus minutes, 7-day daily breakdown, weekly total, all-time minutes, and current streak)',
    inputSchema: {
      type: 'object',
      properties: {},
    },
  },
  {
    name: 'log_pomodoro_session',
    description: 'Manually log a completed focus or study session in Zeta',
    inputSchema: {
      type: 'object',
      required: ['minutes'],
      properties: {
        minutes: {
          type: 'number',
          description: 'Session duration in minutes (e.g. 25, 50)',
        },
        mode: {
          type: 'string',
          enum: ['focus', 'short_break', 'long_break'],
          description: 'Mode of the session (default is focus)',
        },
      },
    },
  },
];

// Tool Execution Handlers
async function executeTool(name: string, args: Record<string, any>) {
  const supabase = getSupabase();
  const userId = ZETA_USER_ID;

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
    switch (name) {
      // ──────────────────────────────────────────────────────────────────
      // 1. TASKS & SUBTASKS
      // ──────────────────────────────────────────────────────────────────
      case 'list_tasks': {
        const status = args?.status || 'pending';
        let query = supabase
          .from('tasks')
          .select('id, title, description, completed, due_date, due_time, subtasks, created_at')
          .eq('user_id', userId)
          .is('deleted_at', null);

        if (status === 'pending') query = query.eq('completed', false);
        if (status === 'completed') query = query.eq('completed', true);
        if (args?.due_date) query = query.eq('due_date', args.due_date);

        const { data, error } = await query.order('due_date', { ascending: true, nullsFirst: false });

        if (error) throw error;
        if (!data || data.length === 0) {
          return {
            content: [{ type: 'text', text: `No ${status} tasks found in Zeta.` }],
          };
        }

        const taskList = data
          .map((t) => {
            const statusMark = t.completed ? '[x]' : '[ ]';
            const due = t.due_date ? ` (Due: ${t.due_date}${t.due_time ? ' ' + t.due_time : ''})` : '';
            const desc = t.description ? `\n    Notes: ${t.description}` : '';

            // Render subtasks checklist
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
              text: `📋 Found ${data.length} ${status} task(s):\n\n${taskList}`,
            },
          ],
        };
      }

      case 'create_task': {
        const title = args?.title;
        if (!title) throw new Error('Title is required to create a task');

        const now = new Date().toISOString();

        // Parse optional subtasks array
        const subtasks = Array.isArray(args?.subtasks)
          ? args.subtasks.map((s: string) => ({
              id: crypto.randomUUID(),
              title: String(s).trim(),
              completed: false,
            }))
          : [];

        const newTask = {
          id: crypto.randomUUID(),
          user_id: userId,
          title: title.trim(),
          description: args?.description ? String(args.description).trim() : null,
          completed: false,
          due_date: args?.due_date || null,
          due_time: args?.due_time || null,
          has_time: Boolean(args?.due_time),
          subtasks,
          attachments: [],
          created_at: now,
          updated_at: now,
          deleted_at: null,
        };

        const { data, error } = await supabase.from('tasks').insert(newTask).select().single();
        if (error) throw error;

        const subtaskSummary = subtasks.length > 0 ? `\nSubtasks: ${subtasks.map((s: any) => `\n  - ${s.title}`).join('')}` : '';

        return {
          content: [
            {
              type: 'text',
              text: `✅ Task created: "${data.title}"\nID: ${data.id}${
                data.due_date ? `\nDue: ${data.due_date} ${data.due_time || ''}` : ''
              }${subtaskSummary}`,
            },
          ],
        };
      }

      case 'complete_task': {
        const taskId = args?.task_id;
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
          ],
        };
      }

      case 'update_task': {
        const taskId = args?.task_id;
        if (!taskId) throw new Error('task_id is required');

        const updates: Record<string, any> = { updated_at: new Date().toISOString() };
        if (args.title !== undefined) updates.title = args.title;
        if (args.description !== undefined) updates.description = args.description;
        if (args.due_date !== undefined) updates.due_date = args.due_date;
        if (args.due_time !== undefined) {
          updates.due_time = args.due_time;
          updates.has_time = Boolean(args.due_time);
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
          ],
        };
      }

      case 'manage_subtask': {
        const taskId = args?.task_id;
        const action = args?.action;
        const subtaskTitle = args?.subtask_title?.trim();
        const subtaskId = args?.subtask_id;

        if (!taskId || !action) throw new Error('task_id and action are required');

        // Fetch current task
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
          currentSubtasks = currentSubtasks.map((st) => {
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
            (st) =>
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

        // Save updated subtasks to database
        const { error: updateErr } = await supabase
          .from('tasks')
          .update({ subtasks: currentSubtasks, updated_at: new Date().toISOString() })
          .eq('id', taskId)
          .eq('user_id', userId);

        if (updateErr) throw updateErr;

        return {
          content: [{ type: 'text', text: `✅ ${message}` }],
        };
      }

      case 'delete_task': {
        const taskId = args?.task_id;
        if (!taskId) throw new Error('task_id is required');

        const now = new Date().toISOString();
        const { error } = await supabase
          .from('tasks')
          .update({ deleted_at: now, updated_at: now })
          .eq('id', taskId)
          .eq('user_id', userId);

        if (error) throw error;
        return {
          content: [
            {
              type: 'text',
              text: `🗑️ Task ${taskId} moved to trash.`,
            },
          ],
        };
      }

      // ──────────────────────────────────────────────────────────────────
      // 2. REVISION SUBJECTS & TOPICS (SPACED REPETITION)
      // ──────────────────────────────────────────────────────────────────
      case 'list_subjects': {
        const { data: subjects, error: subjErr } = await supabase
          .from('revision_subjects')
          .select('id, name, color, icon, created_at')
          .eq('user_id', userId)
          .order('name');

        if (subjErr) throw subjErr;
        if (!subjects || subjects.length === 0) {
          return { content: [{ type: 'text', text: 'No revision subjects found in Zeta.' }] };
        }

        // Fetch topics count per subject
        const { data: topics } = await supabase
          .from('revision_topics')
          .select('id, subject_id, revision_stage')
          .eq('user_id', userId);

        const summary = subjects
          .map((s) => {
            const subjectTopics = (topics || []).filter((t) => t.subject_id === s.id);
            const masteredCount = subjectTopics.filter((t) => (t.revision_stage || 0) >= 4).length;
            return `📚 **${s.name}** [ID: ${s.id}]\n   Topics: ${subjectTopics.length} total (${masteredCount} mastered 🏆)`;
          })
          .join('\n\n');

        return {
          content: [{ type: 'text', text: `Found ${subjects.length} subject(s):\n\n${summary}` }],
        };
      }

      case 'create_subject': {
        const name = args?.name?.trim();
        if (!name) throw new Error('Subject name is required');

        const newSubject = {
          id: crypto.randomUUID(),
          user_id: userId,
          name,
          color: args?.color || '#6750A4',
          icon: 'menu_book',
          notes: {},
          attachments: [],
          created_at: new Date().toISOString(),
        };

        const { data, error } = await supabase.from('revision_subjects').insert(newSubject).select().single();
        if (error) throw error;

        return {
          content: [
            {
              type: 'text',
              text: `✅ Subject created: "${data.name}" (ID: ${data.id})`,
            },
          ],
        };
      }

      case 'list_topics':
      case 'list_revision_topics': {
        let query = supabase
          .from('revision_topics')
          .select('id, subject_id, title, description, revision_stage, last_revised_at, next_revision_date')
          .eq('user_id', userId);

        if (args?.subject_id) {
          query = query.eq('subject_id', args.subject_id);
        }

        const { data: topics, error } = await query.order('next_revision_date', { ascending: true, nullsFirst: false });
        if (error) throw error;

        if (!topics || topics.length === 0) {
          return { content: [{ type: 'text', text: 'No study topics found matching your criteria.' }] };
        }

        const now = new Date();
        const filter = args?.filter || 'all';

        const filtered = topics.filter((t) => {
          const stage = t.revision_stage || 0;
          if (filter === 'mastered') return stage >= 4;
          if (filter === 'in_progress') return stage > 0 && stage < 4;
          if (filter === 'due_today') {
            if (stage >= 4) return false; // Already mastered
            if (!t.next_revision_date) return true; // Never revised
            const nextDate = new Date(t.next_revision_date);
            return nextDate <= now; // Due now or overdue
          }
          return true;
        });

        if (filtered.length === 0) {
          return { content: [{ type: 'text', text: `No topics found under filter: "${filter}".` }] };
        }

        const topicLines = filtered.map((t) => {
          const stage = t.revision_stage || 0;
          const stageLabel = stage >= 4 ? '🏆 Mastered' : `Stage ${stage}/4`;
          const nextDue = t.next_revision_date ? `Due: ${t.next_revision_date.substring(0, 10)}` : 'Not scheduled';
          const lastRev = t.last_revised_at ? `Last revised: ${t.last_revised_at.substring(0, 10)}` : 'Never revised';
          return `• **${t.title}** (${stageLabel})\n    ${nextDue} | ${lastRev} [ID: ${t.id}]`;
        });

        return {
          content: [
            {
              type: 'text',
              text: `📖 Topics (${filtered.length}):\n\n${topicLines.join('\n\n')}`,
            },
          ],
        };
      }

      case 'create_topic':
      case 'create_revision_topic': {
        const { subject_id, title, description } = args;
        if (!subject_id || !title) throw new Error('subject_id and title are required');

        const now = new Date().toISOString();
        const newTopic = {
          id: crypto.randomUUID(),
          user_id: userId,
          subject_id,
          title: title.trim(),
          description: description || null,
          revision_stage: 0,
          last_revised_at: null,
          next_revision_date: now, // Ready for first revision immediately
          sort_order: 0,
          created_at: now,
        };

        const { data, error } = await supabase.from('revision_topics').insert(newTopic).select().single();
        if (error) throw error;

        return {
          content: [
            {
              type: 'text',
              text: `✅ Topic created: "${data.title}" under Subject ID ${subject_id}.\nReady for initial revision today!`,
            },
          ],
        };
      }

      case 'log_topic_revision': {
        const topicId = args?.topic_id;
        if (!topicId) throw new Error('topic_id is required');

        // Fetch current topic
        const { data: topic, error: fetchErr } = await supabase
          .from('revision_topics')
          .select('id, title, revision_stage')
          .eq('id', topicId)
          .eq('user_id', userId)
          .single();

        if (fetchErr || !topic) throw new Error('Topic not found');

        const currentStage = topic.revision_stage || 0;
        const newStage = Math.min(currentStage + 1, 5);
        const { nextDate, stageName } = getNextRevisionDate(newStage);

        const now = new Date().toISOString();
        const { error: updateErr } = await supabase
          .from('revision_topics')
          .update({
            revision_stage: newStage,
            last_revised_at: now,
            next_revision_date: nextDate,
          })
          .eq('id', topicId)
          .eq('user_id', userId);

        if (updateErr) throw updateErr;

        return {
          content: [
            {
              type: 'text',
              text: `🎉 Revision recorded for "${topic.title}"!\nAdvanced to: ${stageName}${
                nextDate ? `\nNext review due: ${nextDate.substring(0, 10)}` : '\nCongratulations on mastering this topic! 🏆'
              }`,
            },
          ],
        };
      }

      // ──────────────────────────────────────────────────────────────────
      // 3. POMODORO FOCUS STATS & LOGGING
      // ──────────────────────────────────────────────────────────────────
      case 'get_pomodoro_summary': {
        const { data: sessions, error } = await supabase
          .from('pomodoro_sessions')
          .select('id, minutes, mode, completed_at')
          .eq('user_id', userId)
          .order('completed_at', { ascending: false });

        if (error) throw error;

        const focusSessions = (sessions || []).filter((s) => s.mode === 'focus' || !s.mode);

        const now = new Date();
        const todayStr = now.toISOString().substring(0, 10);

        const yesterday = new Date(now);
        yesterday.setDate(yesterday.getDate() - 1);
        const yesterdayStr = yesterday.toISOString().substring(0, 10);

        const sevenDaysAgo = new Date(now);
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        let todayMinutes = 0;
        let todayCount = 0;
        let yesterdayMinutes = 0;
        let weekMinutes = 0;
        let totalMinutes = 0;

        const dailyMap: Record<string, { minutes: number; count: number }> = {};

        for (const s of focusSessions) {
          const dateStr = s.completed_at ? s.completed_at.substring(0, 10) : '';
          const mins = Number(s.minutes) || 0;

          totalMinutes += mins;

          if (dateStr === todayStr) {
            todayMinutes += mins;
            todayCount++;
          }
          if (dateStr === yesterdayStr) {
            yesterdayMinutes += mins;
          }
          if (s.completed_at && new Date(s.completed_at) >= sevenDaysAgo) {
            weekMinutes += mins;
          }

          if (dateStr) {
            if (!dailyMap[dateStr]) dailyMap[dateStr] = { minutes: 0, count: 0 };
            dailyMap[dateStr].minutes += mins;
            dailyMap[dateStr].count += 1;
          }
        }

        // Calculate consecutive streak days
        let streak = 0;
        let checkDate = new Date(now);
        // If no session today yet, check if there was a streak leading into yesterday
        if (!dailyMap[todayStr]) {
          checkDate.setDate(checkDate.getDate() - 1);
        }
        while (true) {
          const dStr = checkDate.toISOString().substring(0, 10);
          if (dailyMap[dStr] && dailyMap[dStr].minutes > 0) {
            streak++;
            checkDate.setDate(checkDate.getDate() - 1);
          } else {
            break;
          }
        }

        // Last 7 days breakdown lines
        const last7DaysLines: string[] = [];
        for (let i = 0; i < 7; i++) {
          const d = new Date(now);
          d.setDate(d.getDate() - i);
          const dKey = d.toISOString().substring(0, 10);
          const entry = dailyMap[dKey] || { minutes: 0, count: 0 };
          const label = i === 0 ? 'Today' : i === 1 ? 'Yesterday' : dKey;
          last7DaysLines.push(`  • ${label}: ${entry.minutes} mins (${entry.count} sessions)`);
        }

        return {
          content: [
            {
              type: 'text',
              text: `⏱️ **Zeta Pomodoro Focus Summary**\n
🔥 **Current Streak:** ${streak} day(s) in a row
🎯 **Today:** ${todayMinutes} mins (${todayCount} focus sessions)
⏮️ **Yesterday:** ${yesterdayMinutes} mins
📅 **Last 7 Days Total:** ${weekMinutes} mins (${Math.round((weekMinutes / 60) * 10) / 10} hours)
🏆 **All-Time Total:** ${totalMinutes} mins across ${focusSessions.length} sessions\n
**Daily Breakdown (Past 7 Days):**\n${last7DaysLines.join('\n')}`,
            },
          ],
        };
      }

      case 'log_pomodoro_session': {
        const minutes = Number(args?.minutes);
        if (!minutes || isNaN(minutes) || minutes <= 0) {
          throw new Error('Valid duration in minutes is required');
        }

        const mode = args?.mode || 'focus';
        const now = new Date().toISOString();

        const newSession = {
          id: crypto.randomUUID(),
          user_id: userId,
          minutes,
          mode,
          completed_at: now,
        };

        const { data, error } = await supabase.from('pomodoro_sessions').insert(newSession).select().single();
        if (error) throw error;

        return {
          content: [
            {
              type: 'text',
              text: `✅ Logged ${data.minutes} minute(s) of ${mode} in Zeta at ${now.substring(11, 16)} UTC!`,
            },
          ],
        };
      }

      default:
        return {
          isError: true,
          content: [{ type: 'text', text: `Unknown tool: ${name}` }],
        };
    }
  } catch (err: any) {
    return {
      isError: true,
      content: [{ type: 'text', text: `Database error: ${err.message || String(err)}` }],
    };
  }
}

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
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-zeta-key');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Authentication Check (Option A: Secret Token)
  if (ZETA_MCP_KEY) {
    const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
    const queryKey = url.searchParams.get('key');
    const authHeader = req.headers.authorization || '';
    const bearerKey = authHeader.replace(/^Bearer\s+/i, '');
    const customHeaderKey = req.headers['x-zeta-key'];

    const providedKey = queryKey || bearerKey || customHeaderKey;

    if (providedKey !== ZETA_MCP_KEY) {
      return res.status(401).json({
        jsonrpc: '2.0',
        error: {
          code: -32000,
          message: 'Unauthorized: Invalid or missing Zeta MCP secret key.',
        },
        id: null,
      });
    }
  }

  // GET Request: Health Check & Status
  if (req.method === 'GET') {
    return res.status(200).json({
      status: 'online',
      protocol: 'Model Context Protocol (MCP) Streamable HTTP',
      version: '2024-11-05',
      server: 'zeta-tasks-mcp',
      tools_count: MCP_TOOLS.length,
      tools: MCP_TOOLS.map((t) => t.name),
      configured_user: Boolean(ZETA_USER_ID),
      auth_enabled: Boolean(ZETA_MCP_KEY),
    });
  }

  // POST Request: Handle JSON-RPC 2.0 (MCP Protocol)
  if (req.method === 'POST') {
    try {
      const body = await getRequestBody(req);
      const { jsonrpc, id, method, params } = body;

      // 1. Handshake: initialize
      if (method === 'initialize') {
        return res.status(200).json({
          jsonrpc: '2.0',
          id,
          result: {
            protocolVersion: '2024-11-05',
            capabilities: {
              tools: { listChanged: false },
            },
            serverInfo: {
              name: 'zeta-tasks-mcp',
              version: '1.0.0',
            },
          },
        });
      }

      // 2. Notification: initialized
      if (method === 'notifications/initialized') {
        return res.status(200).json({ jsonrpc: '2.0', id: null, result: {} });
      }

      // 3. Ping
      if (method === 'ping') {
        return res.status(200).json({ jsonrpc: '2.0', id, result: {} });
      }

      // 4. Query Available Tools: tools/list
      if (method === 'tools/list') {
        return res.status(200).json({
          jsonrpc: '2.0',
          id,
          result: {
            tools: MCP_TOOLS,
          },
        });
      }

      // 5. Execute Tool: tools/call
      if (method === 'tools/call') {
        const toolName = params?.name;
        const toolArgs = params?.arguments || {};

        const result = await executeTool(toolName, toolArgs);

        return res.status(200).json({
          jsonrpc: '2.0',
          id,
          result,
        });
      }

      // Unknown Method
      return res.status(200).json({
        jsonrpc: '2.0',
        id,
        error: {
          code: -32601,
          message: `Method not found: ${method}`,
        },
      });
    } catch (err: any) {
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

  return res.status(405).json({ error: 'Method not allowed' });
}
