import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../services/preferences_service.dart';
import '../models/mindmap.dart';
import '../models/mindmap_node.dart';

/// Repository that manages local persistence of mindmaps.
class MindMapRepository {
  static const String _keyMindmaps = 'zeta_mindmaps_v1';
  static const String _keyActiveMapId = 'zeta_active_mindmap_id';
  static const _uuid = Uuid();

  /// Loads all mindmaps from preferences, seeding default data if empty.
  Future<List<MindMap>> loadMindMaps() async {
    final prefs = PreferencesService.instance.prefs;
    final jsonStr = prefs.getString(_keyMindmaps);

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        final maps = decoded
            .map((item) => MindMap.fromJson(item as Map<String, dynamic>))
            .toList();
        if (maps.isNotEmpty) return maps;
      } catch (_) {}
    }

    // Seed default initial mindmap
    final defaultMap = createSeedMindMap();
    await saveMindMaps([defaultMap]);
    await setActiveMindMapId(defaultMap.id);
    return [defaultMap];
  }

  /// Saves the complete list of mindmaps.
  Future<void> saveMindMaps(List<MindMap> maps) async {
    final prefs = PreferencesService.instance.prefs;
    final encoded = jsonEncode(maps.map((m) => m.toJson()).toList());
    await prefs.setString(_keyMindmaps, encoded);
  }

  /// Gets the ID of the last active mindmap.
  String? getActiveMindMapId() {
    return PreferencesService.instance.prefs.getString(_keyActiveMapId);
  }

  /// Sets the ID of the active mindmap.
  Future<void> setActiveMindMapId(String id) async {
    await PreferencesService.instance.prefs.setString(_keyActiveMapId, id);
  }

  /// Creates a rich starter mindmap to showcase the canvas features.
  MindMap createSeedMindMap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rootId = _uuid.v4();

    final b1Id = _uuid.v4();
    final b1c1Id = _uuid.v4();
    final b1c2Id = _uuid.v4();

    final b2Id = _uuid.v4();
    final b2c1Id = _uuid.v4();
    final b2c2Id = _uuid.v4();
    final b2c3Id = _uuid.v4();

    final b3Id = _uuid.v4();
    final b3c1Id = _uuid.v4();
    final b3c2Id = _uuid.v4();

    final nodes = [
      MindMapNode(
        id: rootId,
        parentId: null,
        orderIndex: 0.0,
        content: 'Zeta Mindmap',
        style: const MindMapNodeStyle(shape: 'rounded', hasCheckbox: false),
      ),
      // Branch 1: Architecture
      MindMapNode(
        id: b1Id,
        parentId: rootId,
        orderIndex: 0.0,
        content: 'N-ary Tree Engine',
        style: const MindMapNodeStyle(hasCheckbox: true, isChecked: true),
      ),
      MindMapNode(
        id: b1c1Id,
        parentId: b1Id,
        orderIndex: 0.0,
        content: 'Single-Parent Invariant',
        style: const MindMapNodeStyle(hasCheckbox: true, isChecked: true),
      ),
      MindMapNode(
        id: b1c2Id,
        parentId: b1Id,
        orderIndex: 1.0,
        content: 'Walker Auto-Layout',
        style: const MindMapNodeStyle(hasCheckbox: true, isChecked: true),
      ),
      // Branch 2: Procedural Branching
      MindMapNode(
        id: b2Id,
        parentId: rootId,
        orderIndex: 1.0,
        content: 'Visual Splines',
        style: const MindMapNodeStyle(hasCheckbox: true, isChecked: false),
      ),
      MindMapNode(
        id: b2c1Id,
        parentId: b2Id,
        orderIndex: 0.0,
        content: 'Cubic Bézier Routing',
        style: const MindMapNodeStyle(hasCheckbox: true, isChecked: true),
      ),
      MindMapNode(
        id: b2c2Id,
        parentId: b2Id,
        orderIndex: 1.0,
        content: 'Tapering Line Strokes',
        style: const MindMapNodeStyle(hasCheckbox: true, isChecked: false),
      ),
      MindMapNode(
        id: b2c3Id,
        parentId: b2Id,
        orderIndex: 2.0,
        content: 'Branch Color Inheritance',
        style: const MindMapNodeStyle(hasCheckbox: true, isChecked: true),
      ),
      // Branch 3: Keyboard-First Interaction
      MindMapNode(
        id: b3Id,
        parentId: rootId,
        orderIndex: 2.0,
        content: 'Interaction Polish',
        style: const MindMapNodeStyle(hasCheckbox: true, isChecked: false),
      ),
      MindMapNode(
        id: b3c1Id,
        parentId: b3Id,
        orderIndex: 0.0,
        content: 'Tab for Child / Enter for Sibling',
        style: const MindMapNodeStyle(hasCheckbox: true, isChecked: true),
      ),
      MindMapNode(
        id: b3c2Id,
        parentId: b3Id,
        orderIndex: 1.0,
        content: 'Drag-and-Drop Reparenting',
        style: const MindMapNodeStyle(hasCheckbox: true, isChecked: false),
      ),
    ];

    return MindMap(
      id: _uuid.v4(),
      title: 'Zeta Project Plan',
      createdAtMs: now,
      updatedAtMs: now,
      layoutType: 'horizontal',
      nodes: nodes,
    );
  }
}
