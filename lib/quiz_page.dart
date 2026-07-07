import 'dart:math';

import 'package:flutter/material.dart';

import 'api.dart';
import 'theme.dart';

const _rounds = 10;
const _maxHints = 5;

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  static List<QuizCountry>? _pool; // fetched once per app run
  static int _best = 0;

  String? _error;
  bool _loading = false;
  final _rng = Random();

  // game state
  List<QuizCountry>? _answers;
  int _round = 0;
  int _score = 0;
  List<QuizCountry> _options = [];
  List<String> _hints = [];
  int _hintsShown = 1;
  bool _answered = false;
  QuizCountry? _picked;
  final List<bool> _results = [];

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _pool ??= await fetchQuizPool();
      final pool = List<QuizCountry>.from(_pool!)..shuffle(_rng);
      _answers = pool.take(_rounds).toList();
      _round = 0;
      _score = 0;
      _results.clear();
      _setupRound();
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _setupRound() {
    final answer = _answers![_round];
    final sameRegion = _pool!
        .where((c) => c.region == answer.region && c.name != answer.name)
        .toList()
      ..shuffle(_rng);
    final others = _pool!
        .where((c) => c.region != answer.region && c.name != answer.name)
        .toList()
      ..shuffle(_rng);
    final distractors = [...sameRegion, ...others].take(3).toList();
    _options = [answer, ...distractors]..shuffle(_rng);
    _hints = List<String>.from(answer.facts)..shuffle(_rng);
    _hintsShown = 1;
    _answered = false;
    _picked = null;
  }

  int get _worth => (_maxHints + 1 - _hintsShown).clamp(1, _maxHints);

  void _pick(QuizCountry c) {
    if (_answered) return;
    final answer = _answers![_round];
    final correct = c.name == answer.name;
    setState(() {
      _answered = true;
      _picked = c;
      _results.add(correct);
      if (correct) _score += _worth;
    });
  }

  void _next() {
    if (_round + 1 >= _rounds) {
      if (_score > _best) _best = _score;
      setState(() => _round = _rounds); // finished screen
    } else {
      setState(() {
        _round++;
        _setupRound();
      });
    }
  }

  String _verdict() {
    final s = _score;
    if (s >= 45) return '🏆 Geo-oracle. The atlas consults YOU.';
    if (s >= 38) return '🥇 Outstanding — conference-keynote material.';
    if (s >= 30) return '🥈 Sharp eye. The world holds few secrets.';
    if (s >= 22) return '🥉 Solid. A few more quizzes and you\'re dangerous.';
    if (s >= 15) return '🌍 Decent instincts, keep exploring.';
    if (s >= 8) return '🧭 The compass spins, but it points somewhere.';
    return '🍌 A chimpanzee picking at random scores about this. Rematch?';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _centered(Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Couldn\'t load the quiz.\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: kTextDim)),
        const SizedBox(height: 12),
        FilledButton(onPressed: _start, child: const Text('Retry')),
      ]));
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kAmber));
    }
    if (_answers == null) return _startScreen();
    if (_round >= _rounds) return _endScreen();
    return _gameScreen();
  }

  Widget _centered(Widget child) => Center(
      child:
          Padding(padding: const EdgeInsets.all(24), child: child));

  Widget _startScreen() {
    return _centered(Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('🌍', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        const Text('Guess the country', style: pageTitleStyle),
        const SizedBox(height: 8),
        const Text(
          '10 rounds. Real data as clues — population, happiness, corruption…\nFewer hints, more points.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: kTextDim, height: 1.5),
        ),
        if (_best > 0) ...[
          const SizedBox(height: 8),
          Text('Session best: $_best / ${_rounds * _maxHints}',
              style: const TextStyle(fontSize: 12, color: kAmber)),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(
              backgroundColor: kAmber, foregroundColor: kBg),
          onPressed: _start,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Play',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }

  Widget _gameScreen() {
    final answer = _answers![_round];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Round ${_round + 1} / $_rounds',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: kAmber)),
            Text('Score: $_score',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (_round + (_answered ? 1 : 0)) / _rounds,
          color: kAmber,
          backgroundColor: kBgCard,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Which country is this?',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(colors: [kAmber, kOrange]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('worth $_worth',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: kBg)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < _hintsShown && i < _hints.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                  decoration: BoxDecoration(
                    color: kBgElev,
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(
                        left: BorderSide(color: kAmber, width: 3)),
                  ),
                  child: Text('${_hintEmoji(i)} ${_hints[i]}',
                      style: const TextStyle(fontSize: 13, height: 1.35)),
                ),
              if (_answered)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${answer.flag} ${answer.name} · ${answer.region}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              if (!_answered && _hintsShown < _maxHints)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _hintsShown++),
                    icon: const Icon(Icons.lightbulb_outline,
                        size: 16, color: kAmber),
                    label: Text(
                        _hintsShown == _maxHints - 1
                            ? 'Last hint: the flag'
                            : 'One more hint (−1 point)',
                        style:
                            const TextStyle(fontSize: 12, color: kAmber)),
                  ),
                ),
              // 5th hint is the flag, like on the site
              if (!_answered && _hintsShown == _maxHints)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Flag: ${answer.flag}',
                      style: const TextStyle(fontSize: 22)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final c in _options)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _OptionButton(
              country: c,
              answered: _answered,
              isAnswer: c.name == answer.name,
              isPicked: _picked?.name == c.name,
              onTap: () => _pick(c),
            ),
          ),
        if (_answered) ...[
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: kAmber, foregroundColor: kBg),
            onPressed: _next,
            child: Text(
                _round + 1 >= _rounds ? 'See results 🏁' : 'Next round →',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    );
  }

  String _hintEmoji(int i) => const ['🧩', '🔍', '💡', '🎲', '🏁'][i % 5];

  Widget _endScreen() {
    final grid = _results.map((r) => r ? '🟩' : '🟥').join();
    return _centered(Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_score >= 30 ? '🎉' : '🌍', style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 8),
        Text('$_score / ${_rounds * _maxHints}',
            style: const TextStyle(
                fontSize: 40, fontWeight: FontWeight.w800, color: kAmber)),
        Text('Session best: $_best',
            style: const TextStyle(fontSize: 12, color: kTextDim)),
        const SizedBox(height: 10),
        Text(grid, style: const TextStyle(fontSize: 18, letterSpacing: 2)),
        const SizedBox(height: 10),
        Text(_verdict(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.4)),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(
              backgroundColor: kAmber, foregroundColor: kBg),
          onPressed: _start,
          icon: const Icon(Icons.casino),
          label: const Text('New game',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }
}

class _OptionButton extends StatelessWidget {
  final QuizCountry country;
  final bool answered;
  final bool isAnswer;
  final bool isPicked;
  final VoidCallback onTap;

  const _OptionButton(
      {required this.country,
      required this.answered,
      required this.isAnswer,
      required this.isPicked,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color border = kBorder;
    Color bg = kBgCard;
    if (answered && isAnswer) {
      border = kUp;
      bg = kUp.withValues(alpha: 0.12);
    } else if (answered && isPicked && !isAnswer) {
      border = kDown;
      bg = kDown.withValues(alpha: 0.12);
    }
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: answered ? 1.5 : 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(country.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            if (answered && isAnswer)
              const Icon(Icons.check_circle, color: kUp, size: 18),
            if (answered && isPicked && !isAnswer)
              const Icon(Icons.cancel, color: kDown, size: 18),
          ],
        ),
      ),
    );
  }
}
