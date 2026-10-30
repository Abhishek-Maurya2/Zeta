import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../../database/database_provider.dart';
import '../../../database/daos/mindmap_dao.dart';
import '../../../services/preferences_service.dart';
import '../models/mindmap.dart';
import '../models/mindmap_node.dart';

/// Repository that manages local persistence of mindmaps using Drift SQLite.
class MindMapRepository {
  static const String _keyMindmaps = 'zeta_mindmaps_v1';
  static const String _keyActiveMapId = 'zeta_active_mindmap_id';
  static const _uuid = Uuid();

  MindmapDao get _dao => DatabaseProvider.instance.mindmapDao;

  /// Loads all user mindmaps from SQLite, migrating legacy preferences if needed,
  /// filtering out any old boilerplate/sample mindmaps, or starting with a clean blank map.
  Future<List<MindMap>> loadMindMaps() async {
    // 1. Fetch from local SQLite
    final localMaps = await _dao.getActiveMindMaps();

    // Purge any lingering boilerplate/sample mindmaps from prior runs
    final validMaps = <MindMap>[];
    for (final map in localMaps) {
      if (_isBoilerplateMap(map)) {
        await _dao.deleteMindMap(map.id);
      } else {
        validMaps.add(map);
      }
    }

    if (validMaps.isNotEmpty) {
      return validMaps;
    }

    // 2. Check for legacy SharedPreferences data (if migrating from old version)
    final prefs = PreferencesService.instance.prefs;
    final jsonStr = prefs.getString(_keyMindmaps);
    await prefs.remove(_keyMindmaps);

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        final legacyMaps = decoded
            .map((item) => MindMap.fromJson(item as Map<String, dynamic>))
            .where((m) => !_isBoilerplateMap(m))
            .toList();
        if (legacyMaps.isNotEmpty) {
          await _dao.upsertAllAndQueue(legacyMaps);
          return legacyMaps;
        }
      } catch (_) {}
    }

    // 3. Create a clean, blank starter mindmap with just a central topic
    final blankMap = createBlankMindMap();
    await _dao.upsertMindMapAndQueue(blankMap);
    await setActiveMindMapId(blankMap.id);
    return [blankMap];
  }

  /// Identifies whether a mindmap is the old sample/boilerplate seed data.
  bool _isBoilerplateMap(MindMap map) {
    if (map.title == 'Zeta Project Plan') return true;
    return map.nodes.any((n) =>
        n.content == 'Zeta Mindmap' ||
        n.content == 'N-ary Tree Engine' ||
        n.content == 'Single-Parent Invariant' ||
        n.content == 'Walker Auto-Layout' ||
        n.content == 'Visual Splines' ||
        n.content == 'Cubic Bézier Routing');
  }

  /// Saves the complete list of mindmaps to SQLite and queues sync.
  Future<void> saveMindMaps(List<MindMap> maps) async {
    await _dao.upsertAllAndQueue(maps);
  }

  /// Saves a single mindmap to SQLite and queues it for sync.
  Future<void> saveMindMap(MindMap map) async {
    await _dao.upsertMindMapAndQueue(map);
  }

  /// Deletes a mindmap from SQLite and queues the deletion.
  Future<void> deleteMindMap(String id) async {
    await _dao.deleteMindMapAndQueue(id);
  }

  /// Gets the ID of the last active mindmap.
  String? getActiveMindMapId() {
    return PreferencesService.instance.prefs.getString(_keyActiveMapId);
  }

  /// Sets the ID of the active mindmap.
  Future<void> setActiveMindMapId(String id) async {
    await PreferencesService.instance.prefs.setString(_keyActiveMapId, id);
  }

  /// Reactive stream of active mindmaps.
  Stream<List<MindMap>> watchMindMaps() {
    return _dao.watchActiveMindMaps();
  }

  /// Creates a clean, empty mindmap with just a single central root node.
  MindMap createBlankMindMap([String title = 'Untitled Mindmap']) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rootId = _uuid.v4();

    return MindMap(
      id: _uuid.v4(),
      title: title,
      createdAtMs: now,
      updatedAtMs: now,
      layoutType: 'horizontal',
      nodes: [
        MindMapNode(
          id: rootId,
          parentId: null,
          orderIndex: 0.0,
          content: 'Central Topic',
          style: const MindMapNodeStyle(shape: 'rounded', hasCheckbox: false),
        ),
      ],
    );
  }
}
