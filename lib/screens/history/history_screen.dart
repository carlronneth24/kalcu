import 'package:flutter/material.dart';
import '../../models/history_entry.dart';
import '../../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const orange = Color(0xFFEC8116);

  late List<MapEntry<dynamic, HistoryEntry>> _entries;
  bool _isSelectionMode = false;
  final Set<dynamic> _selectedKeys = {};

  @override
  void initState() {
    super.initState();
    _entries = HistoryService.getAllEntriesWithKeys();
  }

  void _refresh() {
    setState(() {
      _entries = HistoryService.getAllEntriesWithKeys();
    });
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedKeys.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedKeys.clear();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedKeys.length == _entries.length) {
        _selectedKeys.clear();
      } else {
        _selectedKeys
          ..clear()
          ..addAll(_entries.map((e) => e.key));
      }
    });
  }

  void _toggleEntry(dynamic key) {
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedKeys.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text(
          'Delete history?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          _selectedKeys.length == 1
              ? 'This entry will be permanently deleted.'
              : '${_selectedKeys.length} entries will be permanently deleted.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: orange)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await HistoryService.deleteByKeys(_selectedKeys);
    _exitSelectionMode();
    _refresh();
  }

  void _recalculateSelected() {
    if (_selectedKeys.length != 1) return;
    final key = _selectedKeys.first;
    final entry = _entries.firstWhere((e) => e.key == key).value;
    // Sends the expression back to the calculator screen to reload it.
    Navigator.pop(context, entry.expression);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _entries.isEmpty
                  ? const Center(
                      child: Text(
                        'No history yet',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _entries.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: Colors.white24,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        final isSelected = _selectedKeys.contains(entry.key);
                        return _buildRow(entry, isSelected);
                      },
                    ),
            ),
            if (_isSelectionMode) _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              _isSelectionMode ? Icons.close : Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              if (_isSelectionMode) {
                _exitSelectionMode();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const Text(
            'History',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          IconButton(
            icon: Icon(
              _isSelectionMode
                  ? (_selectedKeys.length == _entries.length &&
                          _entries.isNotEmpty
                      ? Icons.check_box
                      : Icons.check_box_outline_blank)
                  : Icons.delete_outline,
              color: Colors.white,
            ),
            onPressed: () {
              if (_isSelectionMode) {
                _toggleSelectAll();
              } else if (_entries.isNotEmpty) {
                _enterSelectionMode();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRow(MapEntry<dynamic, HistoryEntry> entry, bool isSelected) {
    final item = entry.value;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.expression,
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          Row(
            children: [
              Text(
                item.result,
                style: const TextStyle(color: orange, fontSize: 20),
              ),
              if (_isSelectionMode) ...[
                const SizedBox(width: 12),
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? orange : Colors.white54,
                  size: 24,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (!_isSelectionMode) return row;

    return InkWell(
      onTap: () => _toggleEntry(entry.key),
      child: row,
    );
  }

  Widget _buildBottomActionBar() {
    final hasSingleSelection = _selectedKeys.length == 1;
    final hasSelection = _selectedKeys.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _bottomButton(
            icon: Icons.undo,
            label: 'recalculate',
            enabled: hasSingleSelection,
            onTap: _recalculateSelected,
          ),
          _bottomButton(
            icon: Icons.delete,
            label: 'Delete',
            enabled: hasSelection,
            onTap: _deleteSelected,
          ),
        ],
      ),
    );
  }

  Widget _bottomButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final color = enabled ? Colors.white : Colors.white24;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}