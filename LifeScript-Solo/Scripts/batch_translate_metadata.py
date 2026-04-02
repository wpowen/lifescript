#!/usr/bin/env python3
"""
Batch translate emotion and processLabel metadata fields using MiniMax API.

Usage:
    python3 Scripts/batch_translate_metadata.py

Outputs:
    /tmp/emotion_translations.json   - {zh: {en: ..., ja: ..., ko: ...}, ...}
    /tmp/process_label_translations.json - same format
"""

import json
import os
import sys
import time
from openai import OpenAI

# MiniMax API configuration
API_KEY = "sk-cp-lF5a-xCn0ZRgnGitXStQit-VeWNxD8sUPPkAw5ZZ5vxJK5ecnuYsalkMgc1qT-_Q6mCYjCHOf3tlwzCnoYZ7xevpAFBNee3x02XO862icW8pwdAgK_AakKw"
API_BASE = "https://api.minimaxi.com/v1"
MODEL = "MiniMax-M2.7"

client = OpenAI(api_key=API_KEY, base_url=API_BASE)

BATCH_SIZE = 80  # number of terms per API call


def translate_batch(terms: list[str], field_type: str, target_lang: str) -> dict[str, str]:
    """Translate a batch of Chinese terms to the target language."""

    lang_names = {"en": "English", "ja": "Japanese", "ko": "Korean"}
    lang_name = lang_names[target_lang]

    if field_type == "emotion":
        context = (
            "These are emotion/mood labels used in a Chinese xianxia (cultivation fantasy) interactive novel. "
            "They describe the emotional tone of character dialogue. "
            "Translate each Chinese emotion term into natural, concise {lang} equivalents. "
            "Keep translations SHORT (1-3 words preferred, max 5 words). "
            "Use lowercase for English. "
            "Examples: 震惊→shocked, 冷静→calm, 嘲讽→mocking, 意味深长→meaningful, 压抑的愤怒→suppressed rage"
        ).format(lang=lang_name)
    else:
        context = (
            "These are action/strategy labels used in a Chinese xianxia (cultivation fantasy) interactive novel. "
            "They describe the player's approach or tactic when making a decision. "
            "Translate each Chinese term into natural, concise {lang} equivalents. "
            "Keep translations SHORT (2-6 words preferred). "
            "Use lowercase for English. "
            "Examples: 以退为进→retreat to advance, 隐忍→endure silently, 借力打力→turn their force against them, "
            "暗中布局→scheme in secret, 孤注一掷→all or nothing"
        ).format(lang=lang_name)

    terms_text = "\n".join(f"{i+1}. {t}" for i, t in enumerate(terms))

    prompt = f"""{context}

Translate the following {len(terms)} Chinese terms to {lang_name}.
Return ONLY a JSON object mapping each Chinese term to its {lang_name} translation.
No explanations, no markdown, just the JSON object.

{terms_text}"""

    for attempt in range(3):
        try:
            response = client.chat.completions.create(
                model=MODEL,
                messages=[
                    {"role": "system", "content": f"You are a professional translator specializing in Chinese xianxia fiction. Translate to {lang_name}. Return only valid JSON."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.1,
                max_tokens=4096,
            )

            content = response.choices[0].message.content.strip()
            # Remove <think>...</think> blocks (MiniMax reasoning)
            import re as _re
            content = _re.sub(r'<think>.*?</think>', '', content, flags=_re.DOTALL).strip()
            # Remove markdown code blocks if present
            if content.startswith("```"):
                content = content.split("\n", 1)[1] if "\n" in content else content[3:]
                if content.endswith("```"):
                    content = content[:-3]
                content = content.strip()

            result = json.loads(content)
            return result

        except json.JSONDecodeError as e:
            print(f"  JSON parse error (attempt {attempt+1}): {e}", file=sys.stderr)
            print(f"  Response: {content[:200]}...", file=sys.stderr)
            if attempt < 2:
                time.sleep(2)
        except Exception as e:
            print(f"  API error (attempt {attempt+1}): {e}", file=sys.stderr)
            if attempt < 2:
                time.sleep(5)

    return {}


def translate_all(input_file: str, output_file: str, field_type: str):
    """Translate all terms from input file and save to output file."""

    with open(input_file) as f:
        items = json.load(f)

    terms = [item["zh"] for item in items]
    print(f"\nTranslating {len(terms)} {field_type} values...")

    # Load existing translations if any
    translations = {}
    if os.path.exists(output_file):
        with open(output_file) as f:
            translations = json.load(f)
        print(f"  Loaded {len(translations)} existing translations")

    for lang in ["en", "ja", "ko"]:
        # Find terms that need translation for this language
        todo = [t for t in terms if t not in translations or lang not in translations[t]]
        if not todo:
            print(f"  [{lang}] All {len(terms)} terms already translated, skipping")
            continue

        print(f"  [{lang}] Translating {len(todo)} terms in batches of {BATCH_SIZE}...")

        for i in range(0, len(todo), BATCH_SIZE):
            batch = todo[i:i+BATCH_SIZE]
            batch_num = i // BATCH_SIZE + 1
            total_batches = (len(todo) + BATCH_SIZE - 1) // BATCH_SIZE
            print(f"    Batch {batch_num}/{total_batches} ({len(batch)} terms)...", end=" ", flush=True)

            result = translate_batch(batch, field_type, lang)

            translated = 0
            for zh, translation in result.items():
                if zh not in translations:
                    translations[zh] = {}
                translations[zh][lang] = translation
                translated += 1

            print(f"got {translated}/{len(batch)}")

            # Save progress after each batch
            with open(output_file, 'w') as f:
                json.dump(translations, f, ensure_ascii=False, indent=2)

            # Rate limiting
            time.sleep(0.5)

    # Final save
    with open(output_file, 'w') as f:
        json.dump(translations, f, ensure_ascii=False, indent=2)

    # Report coverage
    total = len(terms)
    covered = {lang: sum(1 for t in terms if t in translations and lang in translations[t]) for lang in ["en", "ja", "ko"]}
    print(f"\nFinal coverage for {field_type}:")
    for lang, count in covered.items():
        print(f"  [{lang}] {count}/{total} ({count*100/total:.1f}%)")


def main():
    print("=" * 60)
    print("Batch Translation Script - MiniMax M2.7")
    print("=" * 60)

    # Step 1: Translate emotions
    translate_all(
        "/tmp/emotions_to_translate.json",
        "/tmp/emotion_translations.json",
        "emotion"
    )

    # Step 2: Translate process labels
    translate_all(
        "/tmp/process_labels_to_translate.json",
        "/tmp/process_label_translations.json",
        "process_label"
    )

    print("\n" + "=" * 60)
    print("Translation complete!")
    print("Output files:")
    print("  /tmp/emotion_translations.json")
    print("  /tmp/process_label_translations.json")
    print("=" * 60)


if __name__ == "__main__":
    main()
