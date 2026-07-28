import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';
import '../services/exercise_localizer.dart';
import '../widgets/category_style.dart';
import '../widgets/exercise_thumbnail.dart';
import 'exercise_detail_screen.dart';

/// Lists all exercises within a single category, with a name/equipment
/// search filter.
class CategoryExercisesScreen extends StatefulWidget {
  final String category;

  const CategoryExercisesScreen({super.key, required this.category});

  @override
  State<CategoryExercisesScreen> createState() =>
      _CategoryExercisesScreenState();
}

class _CategoryExercisesScreenState extends State<CategoryExercisesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

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
    final List<Exercise> exercises = _query.isEmpty
        ? exerciseProvider.byCategory(widget.category)
        : exerciseProvider.search(_query, category: widget.category);

    return Scaffold(
      appBar: AppBar(title: Text(titleCase(ExerciseLocalizer.localizedBodyPart(widget.category, lang)))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
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
          Expanded(
            child: exercises.isEmpty
                ? Center(child: Text(l10n.exerciseSearchNoResults))
                : ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return ListTile(
                        leading: ExerciseThumbnail(exercise: exercise),
                        title: Text(exercise.name),
                        subtitle: Text(ExerciseLocalizer.localizedEquipment(exercise.equipment, lang)),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExerciseDetailScreen(exercise: exercise),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
