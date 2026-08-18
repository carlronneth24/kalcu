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
  late List<HistoryEntry> historyList;

  @override
  void initState() {
    super.initState();
    historyList = HistoryService.getAllEntries();
  }

  void _clearAll() async {
    await HistoryService.clearAll();
    setState(() {
      historyList = HistoryService.getAllEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'History',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: _clearAll,
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: historyList.isEmpty
                  ? const Center(
                      child: Text(
                        'No history yet',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: historyList.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: Colors.white24,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final item = historyList[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.expression,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                item.result,
                                style: const TextStyle(
                                  color: orange,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
