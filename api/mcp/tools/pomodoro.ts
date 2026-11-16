import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { getSupabase, getUserId } from '../config.js';

export function registerPomodoroTools(server: McpServer): string[] {
  // get_pomodoro_summary
  server.tool(
    'get_pomodoro_summary',
    'Get Pomodoro focus statistics from Zeta (today focus minutes, 7-day daily breakdown, weekly total, all-time minutes, and current streak)',
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
              text: 'Error: ZETA_USER_ID environment variable is not configured in Vercel settings.',
            },
          ],
        };
      }

      try {
        const { data: sessions, error } = await supabase
          .from('pomodoro_sessions')
          .select('id, minutes, mode, completed_at')
          .eq('user_id', userId)
          .order('completed_at', { ascending: false })
          .range(0, 49);

        if (error) throw error;

        const focusSessions = (sessions || []).filter((s: any) => s.mode === 'focus' || !s.mode);

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
            {
              type: 'text',
              text: JSON.stringify(
                {
                  current_streak_days: streak,
                  today_minutes: todayMinutes,
                  today_sessions: todayCount,
                  yesterday_minutes: yesterdayMinutes,
                  last_7_days_minutes: weekMinutes,
                  total_minutes: totalMinutes,
                  total_sessions: focusSessions.length,
                  daily_breakdown: dailyMap,
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

  // log_pomodoro_session
  server.tool(
    'log_pomodoro_session',
    'Manually log a completed focus or study session in Zeta',
    {
      minutes: z.number().describe('Session duration in minutes (e.g. 25, 50)'),
      mode: z
        .enum(['focus', 'short_break', 'long_break'])
        .optional()
        .describe('Mode of the session (default is focus)'),
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
        const minutes = Number(args.minutes);
        if (!minutes || isNaN(minutes) || minutes <= 0) {
          throw new Error('Valid duration in minutes is required');
        }

        const mode = args.mode || 'focus';
        const now = new Date();
        const nowIso = now.toISOString();
        const nowMs = now.getTime();

        const newSession = {
          id: crypto.randomUUID(),
          user_id: userId,
          minutes,
          mode,
          completed_at: nowIso,
          completed_at_ms: nowMs,
        };

        const { data, error } = await supabase.from('pomodoro_sessions').insert(newSession).select().single();
        if (error) throw error;

        return {
          content: [
            {
              type: 'text',
              text: `✅ Logged ${data.minutes} minute(s) of ${mode} in Zeta at ${now.substring(11, 16)} UTC!`,
            },
            {
              type: 'text',
              text: JSON.stringify({ success: true, session: data }, null, 2),
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

  return ['get_pomodoro_summary', 'log_pomodoro_session'];
}
