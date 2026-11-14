import { randomUUID } from 'node:crypto';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { getSupabase, getUserId } from '../config.js';
import { MindMapNode, MindMapNodeStyle } from '../types.js';

export function registerMindmapsTools(server: McpServer): string[] {
  // ─── 1. list_mindmaps ──────────────────────────────────────────────
  server.tool(
    'list_mindmaps',
    'Fetch mindmaps from Zeta with optional filtering by status (active, bin, or all)',
    {
      status: z
        .enum(['active', 'bin', 'all'])
        .optional()
        .describe("Filter mindmaps by status: 'active' (default), 'bin' (soft-deleted), or 'all'"),
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
        const status = args.status || 'active';
        let query = supabase
          .from('mindmaps')
          .select('id, title, layout_type, nodes_json, created_at_ms, deleted_at_ms')
          .eq('user_id', userId);

        if (status === 'active') {
          query = query.is('deleted_at_ms', null);
        } else if (status === 'bin') {
          query = query.not('deleted_at_ms', 'is', null);
        }

        const { data, error } = await query.order('created_at_ms', { ascending: false });

        if (error) throw error;
        if (!data || data.length === 0) {
          return {
            content: [{ type: 'text', text: `No mindmaps found for status "${status}".` }],
          };
        }

        const mindmapList = data
          .map((m: any) => {
            const nodes = Array.isArray(m.nodes_json)
              ? m.nodes_json
              : (typeof m.nodes_json === 'string' ? JSON.parse(m.nodes_json || '[]') : []);
            const createdAt = m.created_at_ms ? new Date(m.created_at_ms).toISOString() : 'Unknown';
            const statusTag = m.deleted_at_ms ? ' [BIN]' : '';
            return `• [${m.id}] ${m.title}${statusTag}\n  Layout: ${m.layout_type || 'horizontal'} | Nodes: ${nodes.length} | Created: ${createdAt}`;
          })
          .join('\n\n');

        return {
          content: [
            {
              type: 'text',
              text: `Found ${data.length} mindmap(s) (${status}):\n\n${mindmapList}`,
            },
            {
              type: 'text',
              text: JSON.stringify({ count: data.length, status, mindmaps: data }, null, 2),
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

  // ─── 2. get_mindmap ────────────────────────────────────────────────
  server.tool(
    'get_mindmap',
    'Fetch a mindmap by ID and view its complete hierarchical tree structure',
    {
      mindmap_id: z.string().describe('The UUID of the mindmap to retrieve'),
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
        const { data, error } = await supabase
          .from('mindmaps')
          .select('*')
          .eq('id', args.mindmap_id)
          .eq('user_id', userId)
          .single();

        if (error || !data) {
          return {
            isError: true,
            content: [{ type: 'text', text: `Mindmap not found with ID: ${args.mindmap_id}` }],
          };
        }

        const rawNodes: MindMapNode[] = Array.isArray(data.nodes_json)
          ? data.nodes_json
          : (typeof data.nodes_json === 'string' ? JSON.parse(data.nodes_json || '[]') : []);

        const nodeMap = new Map<string, MindMapNode>();
        const childrenMap = new Map<string | null, MindMapNode[]>();

        for (const node of rawNodes) {
          nodeMap.set(node.id, node);
          const pid = node.parentId ?? null;
          if (!childrenMap.has(pid)) {
            childrenMap.set(pid, []);
          }
          childrenMap.get(pid)!.push(node);
        }

        for (const list of childrenMap.values()) {
          list.sort((a, b) => (a.orderIndex ?? 0) - (b.orderIndex ?? 0));
        }

        function renderHierarchy(parentId: string | null, depth: number = 0): string[] {
          const children = childrenMap.get(parentId) || [];
          const lines: string[] = [];
          const indent = '  '.repeat(depth);
          for (const child of children) {
            const check = child.style?.hasCheckbox
              ? (child.style?.isChecked ? '[x] ' : '[ ] ')
              : '';
            const tags = child.style?.tags && child.style.tags.length > 0
              ? ` #${child.style.tags.join(' #')}`
              : '';
            lines.push(`${indent}- ${check}${child.content}${tags} (id: ${child.id})`);
            lines.push(...renderHierarchy(child.id, depth + 1));
          }
          return lines;
        }

        let rootLines = renderHierarchy(null, 0);
        // Fallback if root node had an unexpected parentId
        if (rootLines.length === 0 && rawNodes.length > 0) {
          const orphanedRoots = rawNodes.filter((n) => !n.parentId || !nodeMap.has(n.parentId));
          for (const r of orphanedRoots.length > 0 ? orphanedRoots : [rawNodes[0]]) {
            const check = r.style?.hasCheckbox ? (r.style?.isChecked ? '[x] ' : '[ ] ') : '';
            rootLines.push(`- ${check}${r.content} (id: ${r.id})`);
            rootLines.push(...renderHierarchy(r.id, 1));
          }
        }

        const createdAt = data.created_at_ms ? new Date(data.created_at_ms).toISOString() : 'Unknown';
        const isDeleted = data.deleted_at_ms ? ' [IN BIN]' : '';
        const hierarchyText = rootLines.length > 0 ? rootLines.join('\n') : '(No nodes)';

        return {
          content: [
            {
              type: 'text',
              text: `🧠 Mindmap: "${data.title}"${isDeleted}\nID: ${data.id}\nLayout: ${data.layout_type || 'horizontal'}\nCreated: ${createdAt}\nTotal Nodes: ${rawNodes.length}\n\nHierarchy:\n${hierarchyText}`,
            },
            {
              type: 'text',
              text: JSON.stringify(
                {
                  id: data.id,
                  title: data.title,
                  layout_type: data.layout_type,
                  created_at_ms: data.created_at_ms,
                  updated_at_ms: data.updated_at_ms,
                  total_nodes: rawNodes.length,
                  nodes: rawNodes,
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

  // ─── 3. create_mindmap ─────────────────────────────────────────────
  server.tool(
    'create_mindmap',
    'Create a new hierarchical mindmap in Zeta with a root topic, branches, and sub-branches',
    {
      title: z.string().describe('Title of the mindmap'),
      root_topic: z.string().describe('Central/root topic text'),
      branches: z
        .array(
          z.object({
            title: z.string().describe('Branch title/topic'),
            sub_branches: z.array(z.string()).optional().describe('Sub-branch items under this branch'),
          })
        )
        .optional()
        .describe('Branches extending from the root topic'),
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
        const mindmapId = randomUUID();
        const rootId = randomUUID();
        const nowMs = Date.now();
        const nowIso = new Date(nowMs).toISOString();

        const nodes: MindMapNode[] = [];

        // 1. Root node
        const rootNode: MindMapNode = {
          id: rootId,
          parentId: null,
          orderIndex: 0,
          content: args.root_topic.trim(),
          style: {
            shape: 'rounded',
            hasCheckbox: false,
            isChecked: false,
            tags: [],
          },
        };
        nodes.push(rootNode);

        // 2. Branch and sub-branch nodes
        if (args.branches && Array.isArray(args.branches)) {
          args.branches.forEach((branch, i) => {
            const branchId = randomUUID();
            const branchNode: MindMapNode = {
              id: branchId,
              parentId: rootId,
              orderIndex: i,
              content: branch.title.trim(),
              style: {
                colorIndex: (i + 1) % 6,
                shape: 'rounded',
                hasCheckbox: false,
                isChecked: false,
                tags: [],
              },
            };
            nodes.push(branchNode);

            if (branch.sub_branches && Array.isArray(branch.sub_branches)) {
              branch.sub_branches.forEach((subTitle, j) => {
                const subBranchId = randomUUID();
                const subNode: MindMapNode = {
                  id: subBranchId,
                  parentId: branchId,
                  orderIndex: j,
                  content: String(subTitle).trim(),
                  style: {
                    hasCheckbox: true,
                    isChecked: false,
                    shape: 'rounded',
                    tags: [],
                  },
                };
                nodes.push(subNode);
              });
            }
          });
        }

        const newMindmap = {
          id: mindmapId,
          user_id: userId,
          title: args.title.trim(),
          layout_type: 'horizontal',
          nodes_json: nodes,
          created_at_ms: nowMs,
          updated_at_ms: nowMs,
          deleted_at_ms: null,
          updated_at: nowIso,
        };

        const { data, error } = await supabase.from('mindmaps').insert(newMindmap).select().single();
        if (error) throw error;

        const branchCount = args.branches?.length || 0;
        return {
          content: [
            {
              type: 'text',
              text: `✅ Mindmap created: "${data.title}"\nID: ${data.id}\nRoot Topic: "${args.root_topic}"\nBranches: ${branchCount}\nTotal Nodes: ${nodes.length}`,
            },
            {
              type: 'text',
              text: JSON.stringify({ success: true, mindmap: data, total_nodes: nodes.length }, null, 2),
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

  // ─── 4. add_mindmap_node ───────────────────────────────────────────
  server.tool(
    'add_mindmap_node',
    'Add a new node to an existing mindmap under a specified parent node (or root)',
    {
      mindmap_id: z.string().describe('The UUID of the mindmap to update'),
      parent_node_id: z
        .string()
        .optional()
        .describe('The UUID of the parent node (defaults to root if omitted)'),
      content: z.string().describe('Text/content of the new node'),
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
        const { data, error } = await supabase
          .from('mindmaps')
          .select('*')
          .eq('id', args.mindmap_id)
          .eq('user_id', userId)
          .single();

        if (error || !data) {
          return {
            isError: true,
            content: [{ type: 'text', text: `Mindmap not found with ID: ${args.mindmap_id}` }],
          };
        }

        const nodes: MindMapNode[] = Array.isArray(data.nodes_json)
          ? data.nodes_json
          : (typeof data.nodes_json === 'string' ? JSON.parse(data.nodes_json || '[]') : []);

        // Resolve target parent node
        let parentNode: MindMapNode | undefined;
        if (args.parent_node_id) {
          parentNode = nodes.find((n) => n.id === args.parent_node_id);
          if (!parentNode) {
            return {
              isError: true,
              content: [
                {
                  type: 'text',
                  text: `Parent node with ID "${args.parent_node_id}" was not found in mindmap "${data.title}".`,
                },
              ],
            };
          }
        } else {
          // Defaults to root node (parentId === null)
          parentNode = nodes.find((n) => n.parentId === null) || nodes[0];
        }

        const targetParentId = parentNode ? parentNode.id : null;
        const siblingCount = nodes.filter((n) => n.parentId === targetParentId).length;

        // Determine node style based on depth:
        // - Under root => branch style
        // - Under branch or deeper => sub-branch style with checkbox
        let nodeStyle: MindMapNodeStyle;
        if (targetParentId === null) {
          nodeStyle = { shape: 'rounded', hasCheckbox: false, isChecked: false, tags: [] };
        } else if (!parentNode?.parentId) {
          nodeStyle = {
            colorIndex: (siblingCount + 1) % 6,
            shape: 'rounded',
            hasCheckbox: false,
            isChecked: false,
            tags: [],
          };
        } else {
          nodeStyle = {
            hasCheckbox: true,
            isChecked: false,
            shape: 'rounded',
            tags: [],
          };
        }

        const newNodeId = randomUUID();
        const newNode: MindMapNode = {
          id: newNodeId,
          parentId: targetParentId,
          orderIndex: siblingCount,
          content: args.content.trim(),
          style: nodeStyle,
        };

        nodes.push(newNode);

        const nowMs = Date.now();
        const { error: updateError } = await supabase
          .from('mindmaps')
          .update({
            nodes_json: nodes,
            updated_at_ms: nowMs,
            updated_at: new Date(nowMs).toISOString(),
          })
          .eq('id', args.mindmap_id)
          .eq('user_id', userId);

        if (updateError) throw updateError;

        return {
          content: [
            {
              type: 'text',
              text: `✅ Node added to mindmap "${data.title}":\nNode ID: ${newNodeId}\nParent: ${
                parentNode ? `"${parentNode.content}" (${parentNode.id})` : 'root'
              }\nContent: "${newNode.content}"\nTotal Nodes: ${nodes.length}`,
            },
            {
              type: 'text',
              text: JSON.stringify({ success: true, node: newNode, total_nodes: nodes.length }, null, 2),
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

  // ─── 5. delete_mindmap ─────────────────────────────────────────────
  server.tool(
    'delete_mindmap',
    'Soft-delete a mindmap to bin (default) or permanently delete it',
    {
      mindmap_id: z.string().describe('The UUID of the mindmap to delete'),
      permanent: z
        .boolean()
        .optional()
        .default(false)
        .describe('If true, permanently hard-deletes; if false (default), soft-deletes to bin'),
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
        if (args.permanent) {
          const { error } = await supabase
            .from('mindmaps')
            .delete()
            .eq('id', args.mindmap_id)
            .eq('user_id', userId);

          if (error) throw error;
          return {
            content: [
              {
                type: 'text',
                text: `🗑️ Mindmap permanently deleted (ID: ${args.mindmap_id})`,
              },
              {
                type: 'text',
                text: JSON.stringify({ success: true, mindmap_id: args.mindmap_id, permanent: true }, null, 2),
              },
            ],
          };
        } else {
          const nowMs = Date.now();
          const { error } = await supabase
            .from('mindmaps')
            .update({
              deleted_at_ms: nowMs,
              updated_at_ms: nowMs,
              updated_at: new Date(nowMs).toISOString(),
            })
            .eq('id', args.mindmap_id)
            .eq('user_id', userId);

          if (error) throw error;
          return {
            content: [
              {
                type: 'text',
                text: `🗑️ Mindmap moved to bin (ID: ${args.mindmap_id})`,
              },
              {
                type: 'text',
                text: JSON.stringify({ success: true, mindmap_id: args.mindmap_id, permanent: false }, null, 2),
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

  return [
    'list_mindmaps',
    'get_mindmap',
    'create_mindmap',
    'add_mindmap_node',
    'delete_mindmap',
  ];
}
