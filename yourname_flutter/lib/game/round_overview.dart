import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import 'game_controller.dart';
import 'paper_theme.dart';

/// Shared by the live reveal and saved completed rounds.
class RoundOverview extends StatefulWidget {
  const RoundOverview({super.key, required this.room});
  final Json room;
  @override
  State<RoundOverview> createState() => _RoundOverviewState();
}

class _RoundOverviewState extends State<RoundOverview> {
  String? _selected;
  @override
  Widget build(BuildContext context) {
    final results = (widget.room['results'] as List? ?? []).cast<Json>();
    final personal = results
        .where(
          (r) =>
              widget.room['selfId'] != null &&
              r['playerId'] == widget.room['selfId'],
        )
        .firstOrNull;
    final review = (widget.room['answerReview'] as List? ?? []).cast<Json>();
    final selected =
        review.where((p) => p['playerId'] == _selected).firstOrNull ??
        review.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (personal != null) ...[
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: personal['correct'] == true
                    ? mint
                    : const Color(0xFFFBE2D9),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        personal['correct'] == true
                            ? Icons.auto_awesome
                            : Icons.close_rounded,
                        size: 28,
                        color: personal['correct'] == true
                            ? forest
                            : const Color(0xFF913C29),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        personal['correct'] == true
                            ? Icons.emoji_events_rounded
                            : Icons.sentiment_dissatisfied_rounded,
                        size: 80,
                        color: personal['correct'] == true
                            ? forest
                            : const Color(0xFF913C29),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        personal['correct'] == true
                            ? Icons.auto_awesome
                            : Icons.close_rounded,
                        size: 28,
                        color: personal['correct'] == true
                            ? forest
                            : const Color(0xFF913C29),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr(
                      personal['correct'] == true
                          ? 'Congratulations! You found your double!'
                          : 'Not quite! Your guess was incorrect.',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('{0} was playing you.', [personal['actual']]),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(
                      personal['correct'] == true
                          ? '+1 point · Well spotted!'
                          : '0 points · Another round, another chance!',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
        SizedBox(height: 12),
        Text(
          context.tr('The big reveal!'),
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        SizedBox(height: 8),
        Text(
          context.tr(
            '{0} / {1} found their double. Now compare everyone’s answers.',
            [results.where((r) => r['correct'] == true).length, results.length],
          ),
        ),
        SizedBox(height: 20),
        Text(
          context.tr('ROUND OVERVIEW'),
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStatePropertyAll(mint),
            columnSpacing: 24,
            columns: [
              DataColumn(label: Text(context.tr('Player'))),
              DataColumn(label: Text(context.tr('Played as'))),
              DataColumn(label: Text(context.tr('Guessed'))),
              DataColumn(label: Text(context.tr('Their double'))),
              DataColumn(label: Text(context.tr('Points'))),
            ],
            rows: [
              for (final r in results)
                DataRow(
                  selected:
                      selected != null && selected['playerId'] == r['playerId'],
                  onSelectChanged:
                      review.any((p) => p['playerId'] == r['playerId'])
                      ? (_) =>
                            setState(() => _selected = r['playerId'] as String)
                      : null,
                  cells: [
                    DataCell(Text(r['name'] as String)),
                    DataCell(Text(r['actedAs'] as String)),
                    DataCell(Text(r['guessed'] as String)),
                    DataCell(Text(r['actual'] as String)),
                    DataCell(Text(r['correct'] == true ? '+1' : '0')),
                  ],
                ),
            ],
          ),
        ),
        SizedBox(height: 24),
        if (review.isNotEmpty) ...[
          Text(
            context.tr('Whose answers shall we see?'),
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in review)
                ChoiceChip(
                  label: Text(p['name'] as String),
                  selected: p == selected,
                  selectedColor: sunshine,
                  onSelected: (_) =>
                      setState(() => _selected = p['playerId'] as String),
                ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            context.tr('{0} was playing {1}', [
              selected!['name'],
              selected['actedAs'],
            ]),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 12),
          for (final answer in selected['answers'] as List)
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Container(
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: paper,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${answer['number']}. ${context.tr(answer['prompt'] as String)}',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: sunshine,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        context.tr(answer['answer'] as String),
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ] else ...[
          Text(
            context.tr(
              'Full answer review isn’t available for this older round.',
            ),
          ),
          for (final clue in widget.room['clues'] as List? ?? [])
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr(clue['prompt'] as String)),
              subtitle: Text(context.tr(clue['answer'] as String)),
            ),
        ],
      ],
    );
  }
}
