import 'mindmap_node.dart';

/// Manages undo and redo snapshots for a mindmap.
class MindMapHistory {
  final int maxHistory;
  final List<List<MindMapNode>> _undoStack = [];
  final List<List<MindMapNode>> _redoStack = [];

  MindMapHistory({this.maxHistory = 50});

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void push(List<MindMapNode> currentState) {
    _undoStack.add(List<MindMapNode>.unmodifiable(currentState));
    if (_undoStack.length > maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  List<MindMapNode>? undo(List<MindMapNode> currentState) {
    if (!canUndo) return null;
    final previousState = _undoStack.removeLast();
    _redoStack.add(List<MindMapNode>.unmodifiable(currentState));
    return previousState;
  }

  List<MindMapNode>? redo(List<MindMapNode> currentState) {
    if (!canRedo) return null;
    final nextState = _redoStack.removeLast();
    _undoStack.add(List<MindMapNode>.unmodifiable(currentState));
    return nextState;
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
