export interface Subtask {
  id: string;
  title: string;
  completed: boolean;
}

export interface Task {
  id: string;
  user_id: string;
  title: string;
  description?: string | null;
  completed: boolean;
  due_date?: string | null;
  has_time?: boolean;
  subtasks?: Subtask[];
  attachments?: any[];
  created_at?: string;
  updated_at?: string;
  deleted_at?: string | null;
}

export interface PomodoroSession {
  id: string;
  user_id: string;
  minutes: number;
  mode: 'focus' | 'short_break' | 'long_break';
  completed_at: string;
}

export interface MindMapNodeStyle {
  shape?: string;
  hasCheckbox?: boolean;
  isChecked?: boolean;
  tags?: string[];
  colorIndex?: number;
}

export interface MindMapNode {
  id: string;
  parentId: string | null;
  content: string;
  orderIndex: number;
  style?: MindMapNodeStyle;
}

export interface MindMapRecord {
  id: string;
  user_id: string;
  title: string;
  layout_type: string;
  nodes_json: MindMapNode[] | string;
  created_at_ms: number;
  updated_at_ms: number;
  deleted_at_ms?: number | null;
  updated_at: string;
}

export interface TrashItem {
  id: string;
  title: string;
  item_type: 'task';
  deleted_at: string;
}
