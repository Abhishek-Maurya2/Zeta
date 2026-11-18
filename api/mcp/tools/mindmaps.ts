import { randomUUID } from 'node:crypto';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { getSupabase, getUserId } from '../config.js';
import { MindMapNode, MindMapNodeStyle } from '../types.js';

export function registerMindmapsTools(server: McpServer): string[] {
  // ─── 1. list_mindmaps ──────────────────────────────────────────────
  server.tool(
    'list_mindmaps',
    'Fetch all mindmaps from Zeta for the current user',
    {
      limit: z
        .number()
        .min(1)
        .max(100)
        .optional()
        .default(50)
        .describe('Maximum number of mindmaps to return (default: 50)'),
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
        const { data, error } = await supabase
          .from('mindmaps')
          .select('id, title, layout_type, nodes_json, created_at_ms, updated_at_ms')
          .eq('user_id', userId)
          .order('created_at_ms', { ascending: false })
          .range(0, limit - 1);

        if (error) throw error;
        if (!data || data.length === 0) {
          return {
            content: [{ type: 'text', text: 'No mindmaps found.' }],
          };
        }

        const mindmapList = data
          .map((m: any) => {
            const nodes = Array.isArray(m.nodes_json)
              ? m.nodes_json
              : (typeof m.nodes_json === 'string' ? JSON.parse(m.nodes_json || '[]') : []);
            const createdAt = m.created_at_ms ? new Date(m.created_at_ms).toISOString() : 'Unknown';
            return `• [${m.id}] ${m.title}\n  Layout: ${m.layout_type || 'horizontal'} | Nodes: ${nodes.length} | Created: ${createdAt}`;
          })
          .join('\n\n');

        return {
          content: [
            {
              type: 'text',
              text: `Found ${data.length} mindmap(s):\n\n${mindmapList}`,
            },
            {
              type: 'text',
              text: JSON.stringify({ count: data.length, mindmaps: data }, null, 2),
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
        const hierarchyText = rootLines.length > 0 ? rootLines.join('\n') : '(No nodes)';

        return {
          content: [
            {
              type: 'text',
              text: `🧠 Mindmap: "${data.title}"\nID: ${data.id}\nLayout: ${data.layout_type || 'horizontal'}\nCreated: ${createdAt}\nTotal Nodes: ${rawNodes.length}\n\nHierarchy:\n${hierarchyText}`,
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
    'Delete a mindmap permanently from Zeta',
    {
      mindmap_id: z.string().describe('The UUID of the mindmap to delete'),
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
              text: `🗑️ Mindmap deleted (ID: ${args.mindmap_id})`,
            },
            {
              type: 'text',
              text: JSON.stringify({ success: true, mindmap_id: args.mindmap_id }, null, 2),
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

  // ─── 6. update_mindmap_node ─────────────────────────────────────────
  server.tool(
    'update_mindmap_node',
    'Update the content, checkbox status, tags, or appearance of a specific node in a mindmap',
    {
      mindmap_id: z.string().describe('The UUID of the mindmap'),
      node_id: z.string().describe('The UUID of the node to update'),
      content: z.string().optional().describe('New text/content for the node'),
      is_checked: z.boolean().optional().describe('Toggle completed/checked status if the node has a checkbox'),
      has_checkbox: z.boolean().optional().describe('Enable or disable the checkbox for this node'),
      tags: z.array(z.string()).optional().describe('New list of tags for the node'),
      color_index: z.number().optional().describe('Color index (0 to 5) for branch styling'),
    },
    async (args) => {
      const supabase = getSupabase();
      const userId = getUserId();

      if (!userId) {
        return {
          isError: true,
          content: [{ type: 'text', text: 'Error: ZETA_USER_ID environment variable is not configured.' }],
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

        const nodeIndex = nodes.findIndex((n) => n.id === args.node_id);
        if (nodeIndex === -1) {
          return {
            isError: true,
            content: [{ type: 'text', text: `Node with ID "${args.node_id}" was not found in mindmap "${data.title}".` }],
          };
        }

        const targetNode = nodes[nodeIndex];
        if (args.content !== undefined) targetNode.content = args.content.trim();

        if (!targetNode.style) targetNode.style = {};
        if (args.has_checkbox !== undefined) targetNode.style.hasCheckbox = args.has_checkbox;
        if (args.is_checked !== undefined) {
          targetNode.style.isChecked = args.is_checked;
          if (args.has_checkbox === undefined && !targetNode.style.hasCheckbox) {
            targetNode.style.hasCheckbox = true;
          }
        }
        if (args.tags !== undefined) targetNode.style.tags = args.tags;
        if (args.color_index !== undefined) targetNode.style.colorIndex = args.color_index;

        nodes[nodeIndex] = targetNode;

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
              text: `✅ Updated node "${targetNode.content}" in mindmap "${data.title}".`,
            },
            {
              type: 'text',
              text: JSON.stringify({ success: true, node: targetNode, total_nodes: nodes.length }, null, 2),
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

  // ─── 7. delete_mindmap_node ─────────────────────────────────────────
  server.tool(
    'delete_mindmap_node',
    'Delete a node and all of its nested child descendants from a mindmap',
    {
      mindmap_id: z.string().describe('The UUID of the mindmap'),
      node_id: z.string().describe('The UUID of the node to delete'),
    },
    async (args) => {
      const supabase = getSupabase();
      const userId = getUserId();

      if (!userId) {
        return {
          isError: true,
          content: [{ type: 'text', text: 'Error: ZETA_USER_ID environment variable is not configured.' }],
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

        const targetNode = nodes.find((n) => n.id === args.node_id);
        if (!targetNode) {
          return {
            isError: true,
            content: [{ type: 'text', text: `Node with ID "${args.node_id}" was not found in mindmap "${data.title}".` }],
          };
        }

        if (targetNode.parentId === null) {
          return {
            isError: true,
            content: [{ type: 'text', text: `Cannot delete root node "${targetNode.content}". To remove the entire mindmap, use delete_mindmap.` }],
          };
        }

        // Recursively collect all descendant node IDs
        const toDeleteIds = new Set<string>([args.node_id]);
        let addedNew = true;
        while (addedNew) {
          addedNew = false;
          for (const node of nodes) {
            if (node.parentId && toDeleteIds.has(node.parentId) && !toDeleteIds.has(node.id)) {
              toDeleteIds.add(node.id);
              addedNew = true;
            }
          }
        }

        const remainingNodes = nodes.filter((n) => !toDeleteIds.has(n.id));

        const nowMs = Date.now();
        const { error: updateError } = await supabase
          .from('mindmaps')
          .update({
            nodes_json: remainingNodes,
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
              text: `🗑️ Deleted node "${targetNode.content}" and ${toDeleteIds.size - 1} descendant(s) from mindmap "${data.title}". Total remaining nodes: ${remainingNodes.length}.`,
            },
            {
              type: 'text',
              text: JSON.stringify({ success: true, deleted_count: toDeleteIds.size, deleted_ids: Array.from(toDeleteIds), remaining_nodes: remainingNodes.length }, null, 2),
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

  return [
    'list_mindmaps',
    'get_mindmap',
    'create_mindmap',
    'add_mindmap_node',
    'delete_mindmap',
    'update_mindmap_node',
    'delete_mindmap_node',
  ];
}
