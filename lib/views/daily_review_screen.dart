import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/views/fact_card.dart';
import 'package:dziesiatka/views/fact_details_sheet.dart';
import 'package:flutter/material.dart';

const _pageChangeDuration = Duration(milliseconds: 240);

/// Today's finished deck to look through. It changes no stored data.
class DailyReviewScreen extends StatefulWidget {
  const DailyReviewScreen({super.key, required this.facts});

  final List<Fact> facts;

  @override
  State<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends State<DailyReviewScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: _pageChangeDuration,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastPage = widget.facts.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: Text('Powtórka ${_page + 1} / ${widget.facts.length}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 24,
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  clipBehavior: Clip.none,
                  itemCount: widget.facts.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) {
                    final fact = widget.facts[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FactCard(
                        fact: fact,
                        onExpand: () => FactDetailsSheet.show(context, fact),
                      ),
                    );
                  },
                ),
              ),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _page == 0 ? null : () => _goToPage(_page - 1),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: const Text('Poprzednia'),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: _page == lastPage
                          ? null
                          : () => _goToPage(_page + 1),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: const Text('Następna'),
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
