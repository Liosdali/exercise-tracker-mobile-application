import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';
import '../services/exercise_localizer.dart';
import '../widgets/category_style.dart';
import '../widgets/exercise_thumbnail.dart';

/// Lets the user search/browse all exercises and pick one, returning the
/// selected [Exercise] via [Navigator.pop].
class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = context.watch<ExerciseProvider>();
    final l10n = AppLocalizations.of(context)!;
    final lang = l10n.localeName;
    final categories = exerciseProvider.categories;
    final List<Exercise> results = exerciseProvider.search(_query, category: _category);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exercisePickerTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: l10n.exerciseSearchLabel,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(l10n.exercisePickerAllChip),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                ),
                ...categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(titleCase(ExerciseLocalizer.localizedBodyPart(category, lang))),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(child: Text(l10n.exerciseSearchNoResults))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final exercise = results[index];
                      return ListTile(
                        leading: ExerciseThumbnail(exercise: exercise),
                        title: Text(exercise.name),
                        subtitle: Text(titleCase(ExerciseLocalizer.localizedBodyPart(exercise.bodyPart, lang))),
                        onTap: () => Navigator.of(context).pop(exercise),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
