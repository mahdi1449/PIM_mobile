class VocabularyPair {
  final String term;
  final String meaning;

  const VocabularyPair({required this.term, required this.meaning});
}

enum LessonBlockType { heading, paragraph, bulletList, vocabulary, task }

class LessonBlock {
  final LessonBlockType type;
  final String? title;
  final String? text;
  final List<String>? items;
  final List<VocabularyPair>? vocabulary;

  const LessonBlock._({
    required this.type,
    this.title,
    this.text,
    this.items,
    this.vocabulary,
  });

  factory LessonBlock.heading(String title) =>
      LessonBlock._(type: LessonBlockType.heading, title: title);

  factory LessonBlock.paragraph(String text) =>
      LessonBlock._(type: LessonBlockType.paragraph, text: text);

  factory LessonBlock.bullets(List<String> items) =>
      LessonBlock._(type: LessonBlockType.bulletList, items: items);

  factory LessonBlock.vocab(String title, List<VocabularyPair> pairs) =>
      LessonBlock._(
        type: LessonBlockType.vocabulary,
        title: title,
        vocabulary: pairs,
      );

  factory LessonBlock.task(String title, String text) =>
      LessonBlock._(type: LessonBlockType.task, title: title, text: text);
}

class LessonSection {
  final String title;
  final List<LessonBlock> blocks;
  final List<VocabularyPair> vocabulary;

  const LessonSection({
    required this.title,
    required this.blocks,
    required this.vocabulary,
  });
}

class LessonContentParser {
  LessonContentParser._();

  static List<LessonSection> parse(String raw) {
    final text = _clean(raw);
    final lines = text.split('\n');

    final sections = <LessonSection>[];
    var currentTitle = 'Lesson';
    final currentBlocks = <LessonBlock>[];
    final currentVocab = <VocabularyPair>[];

    void flush() {
      if (currentBlocks.isEmpty) return;
      sections.add(
        LessonSection(
          title: currentTitle,
          blocks: List.unmodifiable(currentBlocks),
          vocabulary: List.unmodifiable(currentVocab),
        ),
      );
      currentBlocks.clear();
      currentVocab.clear();
    }

    final bufferParagraph = <String>[];
    final bufferBullets = <String>[];

    void flushParagraph() {
      final p = bufferParagraph.join(' ').trim();
      bufferParagraph.clear();
      if (p.isNotEmpty) currentBlocks.add(LessonBlock.paragraph(p));
    }

    void flushBullets() {
      final items = bufferBullets
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      bufferBullets.clear();
      if (items.isNotEmpty) currentBlocks.add(LessonBlock.bullets(items));
    }

    // Collect vocab pairs inside a short window to render as flashcards.
    final vocabPairs = <VocabularyPair>[];
    String vocabTitle = 'Key Vocabulary';
    bool inVocab = false;

    void flushVocab() {
      if (vocabPairs.isEmpty) return;
      currentBlocks.add(
        LessonBlock.vocab(vocabTitle, List.unmodifiable(vocabPairs)),
      );
      currentVocab.addAll(vocabPairs);
      vocabPairs.clear();
    }

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        flushParagraph();
        flushBullets();
        if (inVocab) {
          flushVocab();
          inVocab = false;
        }
        continue;
      }

      // Section heading heuristics (all caps and short).
      if (_looksLikeSectionHeading(trimmed)) {
        flushParagraph();
        flushBullets();
        flushVocab();
        inVocab = false;

        flush();
        currentTitle = _titleCase(trimmed);
        currentBlocks.add(LessonBlock.heading(currentTitle));
        continue;
      }

      // Task marker.
      final taskMatch = RegExp(
        r'^TASK\s*\d+',
      ).firstMatch(trimmed.toUpperCase());
      if (taskMatch != null || trimmed.toUpperCase().startsWith('HOMEWORK')) {
        flushParagraph();
        flushBullets();
        flushVocab();
        inVocab = false;
        currentBlocks.add(
          LessonBlock.task(
            trimmed.toUpperCase().startsWith('HOMEWORK') ? 'Homework' : trimmed,
            '',
          ),
        );
        continue;
      }

      // Bullets
      if (trimmed.startsWith('- ') ||
          trimmed.startsWith('– ') ||
          trimmed.startsWith('• ')) {
        flushParagraph();
        bufferBullets.add(trimmed.replaceFirst(RegExp(r'^[-–•]\s+'), ''));
        continue;
      }

      // Vocab pairs: "term = meaning" or "term = ..." (also handle "– term = meaning")
      final vocab = _parseVocabularyPair(trimmed);
      if (vocab != null) {
        flushParagraph();
        flushBullets();
        inVocab = true;
        vocabPairs.add(vocab);
        continue;
      }

      // Vocab title markers
      if (trimmed.toUpperCase().contains('VOCABULARY')) {
        flushParagraph();
        flushBullets();
        flushVocab();
        inVocab = false;
        vocabTitle = _titleCase(trimmed);
        currentBlocks.add(LessonBlock.heading(vocabTitle));
        continue;
      }

      // Default paragraph
      if (inVocab && vocabPairs.length >= 16) {
        flushVocab();
        inVocab = false;
      }
      bufferParagraph.add(trimmed);
    }

    flushParagraph();
    flushBullets();
    flushVocab();
    flush();

    if (sections.isEmpty) {
      return [
        LessonSection(
          title: 'Lesson',
          blocks: [LessonBlock.paragraph(text)],
          vocabulary: const [],
        ),
      ];
    }

    return sections;
  }

  static VocabularyPair? _parseVocabularyPair(String line) {
    final normalized = line.replaceAll(RegExp(r'^\s*[–-]\s*'), '').trim();
    if (!normalized.contains('=')) return null;
    final parts = normalized.split('=');
    if (parts.length < 2) return null;
    final left = parts.first.trim();
    final right = parts.sublist(1).join('=').trim();
    if (left.isEmpty || right.isEmpty) return null;
    // Avoid accidental matches like "Use 'play' with ball games"
    if (left.split(' ').length > 6) return null;
    return VocabularyPair(term: left, meaning: right);
  }

  static bool _looksLikeSectionHeading(String s) {
    if (s.length < 6) return false;
    if (s.length > 60) return false;
    final letters = s.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length < 6) return false;
    final upper = letters.toUpperCase();
    final ratio = upper == letters ? 1.0 : 0.0;
    // Many PDF headings are ALL CAPS in the extraction.
    if (ratio < 1.0) return false;
    // Exclude lines that are clearly sentences.
    if (s.endsWith('.') || s.endsWith('?')) return false;
    return true;
  }

  static String _clean(String raw) {
    return raw
        .replaceAll('\f', '\n')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static String _titleCase(String input) {
    final words = input
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    return words
        .map(
          (w) => w.length <= 2
              ? w.toUpperCase()
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
