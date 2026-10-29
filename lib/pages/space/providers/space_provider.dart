import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/mindmap.dart';
import '../models/mindmap_node.dart';
import '../models/mindmap_history.dart';
import '../services/mindmap_repository.dart';

/// Provider for managing Space mindmap state, interactions, and persistence.
class SpaceProvider extends ChangeNotifier {
  final MindMapRepository _repository;
  final _uuid = const Uuid();

  List<MindMap> _mindMaps = [];
  MindMap? _activeMindMap;
  final MindMapHistory _history = MindMapHistory();

  String? _selectedNodeId;
  String? _editingNodeId;

  // Drag and drop state
  String? _draggedNodeId;
  String? _hoverTargetId;
  bool _isHoverReparent = false;
  bool _isHoverAbove = false;
  bool _isInvalidDrop = false;

  bool _isLoading = true;

  SpaceProvider({MindMapRepository? repository})
      : _repository = repository ?? MindMapRepository() {
    _init();
  }

  // Getters
  List<MindMap> get mindMaps => List.unmodifiable(_mindMaps);
  MindMap? get activeMindMap => _activeMindMap;
  String? get selectedNodeId => _selectedNodeId;
  String? get editingNodeId => _editingNodeId;
  bool get isLoading => _isLoading;

  String? get draggedNodeId => _draggedNodeId;
  String? get hoverTargetId => _hoverTargetId;
  bool get isHoverReparent => _isHoverReparent;
  bool get isHoverAbove => _isHoverAbove;
  bool get isInvalidDrop => _isInvalidDrop;

  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    _mindMaps = await _repository.loadMindMaps();
    final savedActiveId = _repository.getActiveMindMapId();
    if (savedActiveId != null && _mindMaps.any((m) => m.id == savedActiveId)) {
      _activeMindMap = _mindMaps.firstWhere((m) => m.id == savedActiveId);
    } else if (_mindMaps.isNotEmpty) {
      _activeMindMap = _mindMaps.first;
    }

    _selectedNodeId = _activeMindMap?.rootNode?.id;
    _history.clear();
    _isLoading = false;
    notifyListeners();
  }

  void selectMindMap(String id) {
    if (_activeMindMap?.id == id) return;
    final match = _mindMaps.firstWhere((m) => m.id == id, orElse: () => _mindMaps.first);
    _activeMindMap = match;
    _selectedNodeId = match.rootNode?.id;
    _editingNodeId = null;
    _draggedNodeId = null;
    _history.clear();
    _repository.setActiveMindMapId(id);
    notifyListeners();
  }

  Future<void> createMindMap(String title) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rootId = _uuid.v4();
    final newMap = MindMap(
      id: _uuid.v4(),
      title: title.trim().isEmpty ? 'Untitled Mindmap' : title.trim(),
      createdAtMs: now,
      updatedAtMs: now,
      layoutType: 'horizontal',
      nodes: [
        MindMapNode(
          id: rootId,
          parentId: null,
          orderIndex: 0.0,
          content: title.trim().isEmpty ? 'Central Topic' : title.trim(),
          style: const MindMapNodeStyle(shape: 'rounded', hasCheckbox: false),
        ),
      ],
    );

    _mindMaps.add(newMap);
    _activeMindMap = newMap;
    _selectedNodeId = rootId;
    _editingNodeId = null;
    _history.clear();

    await _repository.saveMindMaps(_mindMaps);
    await _repository.setActiveMindMapId(newMap.id);
    notifyListeners();
  }

  Future<void> renameActiveMindMap(String newTitle) async {
    if (_activeMindMap == null || newTitle.trim().isEmpty) return;
    _activeMindMap = _activeMindMap!.copyWith(
      title: newTitle.trim(),
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    _updateActiveInList();
    await _repository.saveMindMaps(_mindMaps);
    notifyListeners();
  }

  Future<void> deleteActiveMindMap() async {
    if (_activeMindMap == null || _mindMaps.length <= 1) return;
    final currentId = _activeMindMap!.id;
    _mindMaps.removeWhere((m) => m.id == currentId);
    _activeMindMap = _mindMaps.first;
    _selectedNodeId = _activeMindMap?.rootNode?.id;
    _editingNodeId = null;
    _history.clear();
    await _repository.saveMindMaps(_mindMaps);
    await _repository.setActiveMindMapId(_activeMindMap!.id);
    notifyListeners();
  }

  void changeLayoutType(String layoutType) {
    if (_activeMindMap == null || _activeMindMap!.layoutType == layoutType) return;
    _activeMindMap = _activeMindMap!.copyWith(layoutType: layoutType);
    _updateActiveInList();
    _repository.saveMindMaps(_mindMaps);
    notifyListeners();
  }

  void selectNode(String? id) {
    if (_selectedNodeId == id) return;
    _selectedNodeId = id;
    if (_editingNodeId != null && _editingNodeId != id) {
      _editingNodeId = null;
    }
    notifyListeners();
  }

  void startEditingNode(String id) {
    _selectedNodeId = id;
    _editingNodeId = id;
    notifyListeners();
  }

  void stopEditingNode() {
    if (_editingNodeId == null) return;
    _editingNodeId = null;
    notifyListeners();
  }

  // ── Node Mutations & CRUD ──────────────────────────────────────────────────

  void addChildNode({String? parentId, String content = 'New Topic'}) {
    if (_activeMindMap == null) return;
    final effectiveParentId = parentId ?? _selectedNodeId ?? _activeMindMap!.rootNode?.id;
    if (effectiveParentId == null) return;

    _pushHistory();

    final siblings = _activeMindMap!.childrenOf(effectiveParentId);
    double maxOrder = -1.0;
    for (final s in siblings) {
      if (s.orderIndex > maxOrder) maxOrder = s.orderIndex;
    }

    final newId = _uuid.v4();
    final newNode = MindMapNode(
      id: newId,
      parentId: effectiveParentId,
      orderIndex: maxOrder + 1.0,
      content: content,
      style: const MindMapNodeStyle(hasCheckbox: true),
    );

    // Uncollapse parent so child is visible
    final updatedNodes = _activeMindMap!.nodes.map((n) {
      if (n.id == effectiveParentId && n.isCollapsed) {
        return n.copyWith(isCollapsed: false);
      }
      return n;
    }).toList()..add(newNode);

    _activeMindMap = _activeMindMap!.copyWith(
      nodes: updatedNodes,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    _updateActiveInList();

    _selectedNodeId = newId;
    _editingNodeId = newId;

    _repository.saveMindMaps(_mindMaps);
    notifyListeners();
  }

  void addSiblingNode({String? siblingOfId, String content = 'New Topic'}) {
    if (_activeMindMap == null) return;
    final targetId = siblingOfId ?? _selectedNodeId ?? _activeMindMap!.rootNode?.id;
    if (targetId == null) return;

    final targetNode = _activeMindMap!.nodes.firstWhere((n) => n.id == targetId);

    // Root cannot have siblings, add child instead
    if (targetNode.isRoot) {
      addChildNode(parentId: targetNode.id, content: content);
      return;
    }

    _pushHistory();

    final siblings = _activeMindMap!.childrenOf(targetNode.parentId);
    final targetIndex = siblings.indexWhere((s) => s.id == targetNode.id);
    double newOrder = targetNode.orderIndex + 1.0;

    if (targetIndex >= 0 && targetIndex < siblings.length - 1) {
      final nextSibling = siblings[targetIndex + 1];
      newOrder = (targetNode.orderIndex + nextSibling.orderIndex) / 2.0;
    }

    final newId = _uuid.v4();
    final newNode = MindMapNode(
      id: newId,
      parentId: targetNode.parentId,
      orderIndex: newOrder,
      content: content,
      style: const MindMapNodeStyle(hasCheckbox: true),
    );

    final updatedNodes = List<MindMapNode>.from(_activeMindMap!.nodes)..add(newNode);

    _activeMindMap = _activeMindMap!.copyWith(
      nodes: updatedNodes,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    _updateActiveInList();

    _selectedNodeId = newId;
    _editingNodeId = newId;

    _repository.saveMindMaps(_mindMaps);
    notifyListeners();
  }

  void updateNodeContent(String id, String content) {
    if (_activeMindMap == null) return;
    final index = _activeMindMap!.nodes.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final current = _activeMindMap!.nodes[index];
    if (current.content == content) {
      _editingNodeId = null;
      notifyListeners();
      return;
    }

    _pushHistory();

    final updatedNodes = List<MindMapNode>.from(_activeMindMap!.nodes);
    updatedNodes[index] = current.copyWith(content: content);

    _activeMindMap = _activeMindMap!.copyWith(
      nodes: updatedNodes,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    _updateActiveInList();
    _editingNodeId = null;

    _repository.saveMindMaps(_mindMaps);
    notifyListeners();
  }

  void toggleNodeCollapsed(String id) {
    if (_activeMindMap == null) return;
    final index = _activeMindMap!.nodes.indexWhere((n) => n.id == id);
    if (index == -1) return;

    _pushHistory();

    final current = _activeMindMap!.nodes[index];
    final updatedNodes = List<MindMapNode>.from(_activeMindMap!.nodes);
    updatedNodes[index] = current.copyWith(isCollapsed: !current.isCollapsed);

    _activeMindMap = _activeMindMap!.copyWith(nodes: updatedNodes);
    _updateActiveInList();
    _repository.saveMindMaps(_mindMaps);
    notifyListeners();
  }

  void toggleNodeChecked(String id) {
    if (_activeMindMap == null) return;
    final index = _activeMindMap!.nodes.indexWhere((n) => n.id == id);
    if (index == -1) return;

    _pushHistory();

    final current = _activeMindMap!.nodes[index];
    final updatedNodes = List<MindMapNode>.from(_activeMindMap!.nodes);
    updatedNodes[index] = current.copyWith(
      style: current.style.copyWith(isChecked: !current.style.isChecked),
    );

    _activeMindMap = _activeMindMap!.copyWith(nodes: updatedNodes);
    _updateActiveInList();
    _repository.saveMindMaps(_mindMaps);
    notifyListeners();
  }

  void deleteNode(String id) {
    if (_activeMindMap == null) return;
    final node = _activeMindMap!.nodes.firstWhere((n) => n.id == id, orElse: () => _activeMindMap!.nodes.first);
    if (node.isRoot) {
      // Root cannot be deleted
      return;
    }

    _pushHistory();

    final toDeleteIds = {id};
    final descendants = _activeMindMap!.descendantsOf(id);
    for (final d in descendants) {
      toDeleteIds.add(d.id);
    }

    final updatedNodes = _activeMindMap!.nodes.where((n) => !toDeleteIds.contains(n.id)).toList();

    _activeMindMap = _activeMindMap!.copyWith(
      nodes: updatedNodes,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    _updateActiveInList();

    if (_selectedNodeId != null && toDeleteIds.contains(_selectedNodeId)) {
      _selectedNodeId = node.parentId ?? _activeMindMap!.rootNode?.id;
    }
    _editingNodeId = null;

    _repository.saveMindMaps(_mindMaps);
    notifyListeners();
  }

  // ── Drag & Drop Reparenting & Reordering ────────────────────────────────────

  void startDragNode(String id) {
    _draggedNodeId = id;
    _hoverTargetId = null;
    _isHoverReparent = false;
    _isHoverAbove = false;
    _isInvalidDrop = false;
    notifyListeners();
  }

  void updateDragHover({
    required String targetId,
    required bool isReparent,
    required bool isAbove,
  }) {
    if (_draggedNodeId == null || _activeMindMap == null) return;

    final isDisallowed = _draggedNodeId == targetId ||
        _activeMindMap!.isDescendant(targetId, _draggedNodeId!);

    if (_hoverTargetId != targetId ||
        _isHoverReparent != isReparent ||
        _isHoverAbove != isAbove ||
        _isInvalidDrop != isDisallowed) {
      _hoverTargetId = targetId;
      _isHoverReparent = isReparent;
      _isHoverAbove = isAbove;
      _isInvalidDrop = isDisallowed;
      notifyListeners();
    }
  }

  void endDragNode() {
    if (_draggedNodeId != null && _hoverTargetId != null && !_isInvalidDrop && _activeMindMap != null) {
      if (_isHoverReparent) {
        reparentNode(_draggedNodeId!, _hoverTargetId!);
      } else {
        reorderSibling(_draggedNodeId!, _hoverTargetId!, _isHoverAbove);
      }
    }

    _draggedNodeId = null;
    _hoverTargetId = null;
    _isHoverReparent = false;
    _isHoverAbove = false;
    _isInvalidDrop = false;
    notifyListeners();
  }

  void reparentNode(String draggedId, String newParentId) {
    if (_activeMindMap == null || draggedId == newParentId) return;
    if (_activeMindMap!.isDescendant(newParentId, draggedId)) return;

    _pushHistory();

    final siblings = _activeMindMap!.childrenOf(newParentId);
    double maxOrder = -1.0;
    for (final s in siblings) {
      if (s.id != draggedId && s.orderIndex > maxOrder) {
        maxOrder = s.orderIndex;
      }
    }

    final updatedNodes = _activeMindMap!.nodes.map((n) {
      if (n.id == draggedId) {
        return n.copyWith(parentId: newParentId, orderIndex: maxOrder + 1.0);
      }
      if (n.id == newParentId && n.isCollapsed) {
        return n.copyWith(isCollapsed: false);
      }
      return n;
    }).toList();

    _activeMindMap = _activeMindMap!.copyWith(
      nodes: updatedNodes,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    _updateActiveInList();
    _repository.saveMindMaps(_mindMaps);
    notifyListeners();
  }

  void reorderSibling(String draggedId, String targetSiblingId, bool insertAbove) {
    if (_activeMindMap == null || draggedId == targetSiblingId) return;
    if (_activeMindMap!.isDescendant(targetSiblingId, draggedId)) return;

    final targetNode = _activeMindMap!.nodes.firstWhere((n) => n.id == targetSiblingId);
    if (targetNode.isRoot) return; // Cannot be sibling to root

    _pushHistory();

    final parentId = targetNode.parentId;
    final siblings = _activeMindMap!.childrenOf(parentId).where((s) => s.id != draggedId).toList();
    final targetIdx = siblings.indexWhere((s) => s.id == targetSiblingId);

    double newOrder;
    if (targetIdx == -1) {
      newOrder = targetNode.orderIndex;
    } else if (insertAbove) {
      final prevOrder = targetIdx > 0 ? siblings[targetIdx - 1].orderIndex : targetNode.orderIndex - 2.0;
      newOrder = (prevOrder + targetNode.orderIndex) / 2.0;
    } else {
      final nextOrder = targetIdx < siblings.length - 1 ? siblings[targetIdx + 1].orderIndex : targetNode.orderIndex + 2.0;
      newOrder = (targetNode.orderIndex + nextOrder) / 2.0;
    }

    final updatedNodes = _activeMindMap!.nodes.map((n) {
      if (n.id == draggedId) {
        return n.copyWith(parentId: parentId, orderIndex: newOrder);
      }
      return n;
    }).toList();

    _activeMindMap = _activeMindMap!.copyWith(
      nodes: updatedNodes,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    _updateActiveInList();
    _repository.saveMindMaps(_mindMaps);
    notifyListeners();
  }

  // ── History & Undo/Redo ────────────────────────────────────────────────────

  void _pushHistory() {
    if (_activeMindMap == null) return;
    _history.push(_activeMindMap!.nodes);
  }

  void undo() {
    if (_activeMindMap == null || !_history.canUndo) return;
    final prevNodes = _history.undo(_activeMindMap!.nodes);
    if (prevNodes != null) {
      _activeMindMap = _activeMindMap!.copyWith(nodes: prevNodes);
      _updateActiveInList();
      _repository.saveMindMaps(_mindMaps);
      notifyListeners();
    }
  }

  void redo() {
    if (_activeMindMap == null || !_history.canRedo) return;
    final nextNodes = _history.redo(_activeMindMap!.nodes);
    if (nextNodes != null) {
      _activeMindMap = _activeMindMap!.copyWith(nodes: nextNodes);
      _updateActiveInList();
      _repository.saveMindMaps(_mindMaps);
      notifyListeners();
    }
  }

  void _updateActiveInList() {
    if (_activeMindMap == null) return;
    final index = _mindMaps.indexWhere((m) => m.id == _activeMindMap!.id);
    if (index >= 0) {
      _mindMaps[index] = _activeMindMap!;
    }
  }
}
