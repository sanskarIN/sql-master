#!/usr/bin/env python3
import argparse, csv, random, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

REQUIRED = [
    'README.md', 'sql/01_schema.sql', 'sql/02_seed.sql',
    'sql/03_practice_questions.sql', 'sql/04_selected_solutions.sql',
    'workbook/flashcards.csv', 'workbook/mock_interview.md',
    'workbook/answer_framework.md'
]

def check_package():
    missing = [p for p in REQUIRED if not (ROOT/p).is_file()]
    cards = list(csv.DictReader((ROOT/'workbook/flashcards.csv').open(encoding='utf-8')))
    errors = []
    if missing: errors.append('missing: ' + ', '.join(missing))
    if len(cards) != 60: errors.append(f'expected 60 flashcards, found {len(cards)}')
    schema = (ROOT/'sql/01_schema.sql').read_text(encoding='utf-8')
    for token in ['PRIMARY KEY', 'REFERENCES', 'CHECK', 'CREATE INDEX']:
        if token not in schema: errors.append(f'schema missing {token}')
    if errors:
        print('FAIL'); [print(' -', e) for e in errors]; return 1
    print('PASS: package structure, 60 flashcards, and schema contracts verified')
    return 0

def quiz(count):
    cards = list(csv.DictReader((ROOT/'workbook/flashcards.csv').open(encoding='utf-8')))
    random.shuffle(cards)
    for i, card in enumerate(cards[:count], 1):
        print(f'\n{i}. {card["question"]}')
        input('Press Enter to reveal the reference answer...')
        print('Answer:', card['strong_answer'])
        print('Pitfall:', card['example_or_pitfall'])
    return 0

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check-package', action='store_true')
    ap.add_argument('--quiz', type=int, default=0)
    args = ap.parse_args()
    if args.check_package: return check_package()
    if args.quiz: return quiz(max(1, min(args.quiz, 60)))
    ap.print_help(); return 0
if __name__ == '__main__':
    raise SystemExit(main())
