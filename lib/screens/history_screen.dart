import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/session_card.dart';
import 'session_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _platform = 'Toutes';
  String _action = 'Tous';
  DateTimeRange? _range;
  String _keyword = '';
  bool _withoutProofOnly = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SessionProvider>();
    final settings = context.watch<SettingsProvider>();
    final all = provider.sessions;

    final filtered = all.where((s) {
      final platformOk = _platform == 'Toutes' || s.platform == _platform;
      final actionOk = _action == 'Tous' || s.actionType == _action;
      final dateOk =
          _range == null ||
          (!s.startTime.isBefore(_range!.start) &&
              !s.endTime.isAfter(_range!.end));
      final keywordOk =
          _keyword.trim().isEmpty ||
          s.notes.toLowerCase().contains(_keyword.toLowerCase()) ||
          s.platform.toLowerCase().contains(_keyword.toLowerCase()) ||
          s.actionType.toLowerCase().contains(_keyword.toLowerCase());
      final proofOk = !_withoutProofOnly || s.proofs.isEmpty;
      return platformOk && actionOk && dateOk && keywordOk && proofOk;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Recherche mot-clé',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _keyword = v),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 420;
                  final platformField = DropdownButtonFormField<String>(
                    initialValue: _platform,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Plateforme',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Toutes', ...settings.allPlatforms]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _platform = v ?? 'Toutes'),
                  );
                  final actionField = DropdownButtonFormField<String>(
                    initialValue: _action,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Action',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Tous', ...provider.actionTypes]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _action = v ?? 'Tous'),
                  );

                  if (compact) {
                    return Column(
                      children: [
                        platformField,
                        const SizedBox(height: 8),
                        actionField,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: platformField),
                      const SizedBox(width: 8),
                      Expanded(child: actionField),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  avatar: const Icon(Icons.warning_amber_outlined),
                  label: const Text('Sans preuve'),
                  selected: _withoutProofOnly,
                  onSelected: (selected) =>
                      setState(() => _withoutProofOnly = selected),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 2),
                    lastDate: DateTime(now.year + 1),
                  );
                  if (picked != null) setState(() => _range = picked);
                },
                icon: const Icon(Icons.date_range),
                label: Text(
                  _range == null
                      ? 'Filtrer par date'
                      : '${DateFormat('dd/MM/yyyy').format(_range!.start)} - ${DateFormat('dd/MM/yyyy').format(_range!.end)}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  title: 'Aucune session trouvée',
                  subtitle:
                      'Ajustez les filtres ou créez une session depuis l\'onglet Session.',
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => SessionCard(
                    session: filtered[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SessionDetailScreen(sessionId: filtered[i].id),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
