import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/program_suggestion.dart';
import '../providers/team_provider.dart';

class PendingSuggestionsScreen extends StatefulWidget {
  const PendingSuggestionsScreen({Key? key}) : super(key: key);

  @override
  State<PendingSuggestionsScreen> createState() =>
      _PendingSuggestionsScreenState();
}

class _PendingSuggestionsScreenState extends State<PendingSuggestionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSuggestions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    await context.read<TeamProvider>().fetchPendingSuggestions();
  }

  void _showSuggestionDetail(ProgramSuggestion suggestion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SuggestionDetailScreen(
          suggestion: suggestion,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teamProvider = context.watch<TeamProvider>();
    final allSuggestions = teamProvider.pendingSuggestions;

    // Filter by status
    final pending = allSuggestions
        .where((s) => s.status == SuggestionStatus.pending)
        .toList();
    final accepted = allSuggestions
        .where((s) => s.status == SuggestionStatus.accepted)
        .toList();
    final rejected = allSuggestions
        .where((s) => s.status == SuggestionStatus.rejected)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.suggestionTitle),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: l10n.suggestionPending,
            ),
            Tab(text: l10n.suggestionAccepted),
            Tab(text: l10n.suggestionRejected),
          ],
        ),
      ),
      body: teamProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Pending tab
                pending.isEmpty
                    ? Center(
                        child: Text(l10n.suggestionNoPending),
                      )
                    : _buildSuggestionList(pending, l10n),
                // Accepted tab
                accepted.isEmpty
                    ? Center(
                        child: Text(l10n.suggestionNone),
                      )
                    : _buildSuggestionList(accepted, l10n),
                // Rejected tab
                rejected.isEmpty
                    ? Center(
                        child: Text(l10n.suggestionNone),
                      )
                    : _buildSuggestionList(rejected, l10n),
              ],
            ),
    );
  }

  Widget _buildSuggestionList(List<ProgramSuggestion> suggestions, AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: _loadSuggestions,
      child: ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return _buildSuggestionCard(suggestion, l10n);
        },
      ),
    );
  }

  Widget _buildSuggestionCard(ProgramSuggestion suggestion, AppLocalizations l10n) {
    final statusColor = suggestion.status == SuggestionStatus.accepted
        ? Colors.green
        : suggestion.status == SuggestionStatus.rejected
            ? Colors.red
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            _getSuggestionIcon(suggestion.suggestionType),
            color: statusColor,
          ),
        ),
        title: Text(
          _getSuggestionTitle(suggestion, l10n),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              suggestion.message ?? l10n.suggestionNoMessage,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(suggestion.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(_getStatusLabel(suggestion.status, l10n)),
          backgroundColor: statusColor.withOpacity(0.2),
          labelStyle: TextStyle(color: statusColor),
        ),
        onTap: () => _showSuggestionDetail(suggestion),
      ),
    );
  }

  IconData _getSuggestionIcon(SuggestionType type) {
    switch (type) {
      case SuggestionType.exercise:
        return Icons.fitness_center;
      case SuggestionType.programChange:
        return Icons.edit;
      case SuggestionType.feedback:
        return Icons.feedback;
    }
  }

  String _getSuggestionTitle(ProgramSuggestion suggestion, AppLocalizations l10n) {
    // Placeholder - would show sender name from join
    final typeStr = suggestion.suggestionType == SuggestionType.exercise
        ? l10n.suggestionTypeExercise
        : suggestion.suggestionType == SuggestionType.programChange
            ? l10n.suggestionTypeProgram
            : l10n.suggestionTypeFeedback;
    return '$typeStr Suggestion';
  }

  String _getStatusLabel(SuggestionStatus status, AppLocalizations l10n) {
    switch (status) {
      case SuggestionStatus.pending:
        return l10n.suggestionStatusPending;
      case SuggestionStatus.accepted:
        return l10n.suggestionStatusAccepted;
      case SuggestionStatus.rejected:
        return l10n.suggestionStatusRejected;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}

/// Screen showing full suggestion details with accept/reject actions
class SuggestionDetailScreen extends StatefulWidget {
  final ProgramSuggestion suggestion;

  const SuggestionDetailScreen({
    Key? key,
    required this.suggestion,
  }) : super(key: key);

  @override
  State<SuggestionDetailScreen> createState() => _SuggestionDetailScreenState();
}

class _SuggestionDetailScreenState extends State<SuggestionDetailScreen> {
  final _responseController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _respondToSuggestion(SuggestionStatus status) async {
    setState(() => _isProcessing = true);

    try {
      await context.read<TeamProvider>().respondToSuggestion(
            suggestionId: widget.suggestion.id,
            status: status,
            responseMessage: _responseController.text.isNotEmpty
                ? _responseController.text
                : null,
          );

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == SuggestionStatus.accepted
                ? l10n.suggestionAcceptedSuccess
                : l10n.suggestionRejectedSuccess,
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final suggestion = widget.suggestion;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.suggestionDetail),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sender info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Program Suggestion',
                            style:
                                Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, yyyy – h:mm a')
                                .format(suggestion.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Suggestion type and details
              Text(
                l10n.suggestionType,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(
                  suggestion.suggestionType == SuggestionType.exercise
                      ? l10n.suggestionTypeExercise
                      : suggestion.suggestionType == SuggestionType.programChange
                          ? l10n.suggestionTypeProgram
                          : l10n.suggestionTypeFeedback,
                ),
              ),
              const SizedBox(height: 24),

              // Message
              if (suggestion.message != null) ...[
                Text(
                  l10n.suggestionMessage,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(suggestion.message!),
                ),
                const SizedBox(height: 24),
              ],

              // Response text field (only if pending)
              if (suggestion.status == SuggestionStatus.pending) ...[
                Text(
                  l10n.suggestionYourResponse,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _responseController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.suggestionResponseHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Previous response (if accepted/rejected)
              if (suggestion.responseMessage != null) ...[
                Text(
                  l10n.suggestionTheirResponse,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(suggestion.responseMessage!),
                ),
                const SizedBox(height: 24),
              ],

              // Action buttons (only if pending)
              if (suggestion.status == SuggestionStatus.pending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close),
                        label: Text(l10n.suggestionReject),
                        onPressed: _isProcessing
                            ? null
                            : () =>
                                _respondToSuggestion(SuggestionStatus.rejected),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: Text(l10n.suggestionAccept),
                        onPressed: _isProcessing
                            ? null
                            : () =>
                                _respondToSuggestion(SuggestionStatus.accepted),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
