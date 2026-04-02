#!/usr/bin/env python3
"""
Apply translated emotion/processLabel values to all chapter translation files.
Also fixes scattered Chinese words in EN/KO content text.

Usage:
    python3 Scripts/apply_translations_to_chapters.py

Requires:
    /tmp/emotion_translations.json
    /tmp/process_label_translations.json
"""

import json
import os
import re
import sys
from collections import Counter

# Language code mapping
LANG_MAP = {"en": "en", "ja": "ja", "ko": "ko"}

# Common Chinese words found scattered in EN/KO content text and their translations
CONTENT_FIXES_EN = {
    "废物": "trash",
    "熟练": "practiced",
    "波动": "fluctuation",
    "平淡": "plain",
    "平静": "calm",
    "愣了一下": "was momentarily stunned",
    "小弟": "lackeys",
    "记下了": "took note of this",
    "废物的觉悟": "awareness of being trash",
    "暴怒": "furious",
    "不屑": "disdainful",
    "冷哼": "scoffed coldly",
    "冷笑": "sneered",
    "淡然": "indifferent",
    "释然": "relieved",
    "凝重": "grave",
    "阴沉": "gloomy",
    "疑惑": "puzzled",
    "沉声": "said in a deep voice",
    "低声": "whispered",
    "喃喃": "murmured",
    "嗤笑": "scoffed",
    "嘲讽": "mocked",
    "震惊": "shocked",
    "惊讶": "surprised",
    "恍然": "suddenly realized",
    "茫然": "bewildered",
    "犹豫": "hesitated",
    "坚定": "resolute",
    "决然": "determined",
    "若有所思": "pensive",
    "意味深长": "meaningful",
    "不以为然": "dismissive",
    "心中一动": "heart stirred",
    "暗暗": "secretly",
    "悄然": "quietly",
    "骤然": "suddenly",
    "猛然": "abruptly",
    "缓缓": "slowly",
    "微微": "slightly",
}

CONTENT_FIXES_KO = {
    "废物": "폐물",
    "熟练": "숙련된",
    "波动": "파동",
    "平淡": "담담한",
    "平静": "평온한",
    "愣了一下": "잠시 멍했다",
    "小弟": "부하들",
    "记下了": "기억해 두었다",
    "暴怒": "격노",
    "不屑": "불쾌한",
    "冷哼": "냉소",
    "冷笑": "냉소",
    "淡然": "담담한",
    "释然": "안도",
    "凝重": "무거운",
    "阴沉": "음침한",
    "疑惑": "의혹",
    "沉声": "낮은 목소리로",
    "低声": "낮은 소리로",
    "喃喃": "중얼거렸다",
    "嗤笑": "비웃었다",
    "嘲讽": "조롱",
    "震惊": "충격",
    "惊讶": "놀란",
    "恍然": "문득 깨달았다",
    "茫然": "멍한",
    "犹豫": "망설였다",
    "坚定": "단호한",
    "决然": "결연한",
    "暗暗": "몰래",
    "悄然": "조용히",
    "骤然": "갑자기",
    "猛然": "갑자기",
    "缓缓": "천천히",
    "微微": "살짝",
}


def load_translations(filepath: str) -> dict:
    """Load translation dictionary from JSON file."""
    if not os.path.exists(filepath):
        print(f"WARNING: {filepath} not found, skipping")
        return {}
    with open(filepath) as f:
        return json.load(f)


def apply_field_translations(obj, field_name: str, translations: dict, lang: str, stats: Counter):
    """Recursively apply translations to a specific field in the chapter JSON."""
    if isinstance(obj, dict):
        if field_name in obj and isinstance(obj[field_name], str):
            zh_val = obj[field_name].strip()
            if zh_val in translations and lang in translations[zh_val]:
                translated = translations[zh_val][lang]
                if translated and translated != zh_val:
                    obj[field_name] = translated
                    stats["translated"] += 1
                else:
                    stats["no_translation"] += 1
            elif re.search(r'[\u4e00-\u9fff]', zh_val):
                stats["missing"] += 1
                stats.setdefault("missing_values", set())
                stats["missing_values"].add(zh_val)
        for v in obj.values():
            if isinstance(v, (dict, list)):
                apply_field_translations(v, field_name, translations, lang, stats)
    elif isinstance(obj, list):
        for item in obj:
            apply_field_translations(item, field_name, translations, lang, stats)


def fix_content_chinese(obj, lang: str, fixes: dict, stats: Counter):
    """Fix scattered Chinese words in content/description text fields."""
    if isinstance(obj, dict):
        for key in ("content", "description", "visible_cost", "visible_reward",
                     "risk_hint", "next_chapter_hook", "title"):
            if key in obj and isinstance(obj[key], str):
                text = obj[key]
                for zh, replacement in fixes.items():
                    if zh in text:
                        text = text.replace(zh, replacement)
                        stats["content_fixes"] += 1
                if text != obj[key]:
                    obj[key] = text
        for v in obj.values():
            if isinstance(v, (dict, list)):
                fix_content_chinese(v, lang, fixes, stats)
    elif isinstance(obj, list):
        for item in obj:
            fix_content_chinese(item, lang, fixes, stats)


def process_language(lang: str, emotion_trans: dict, pl_trans: dict):
    """Process all chapter files for a given language."""
    chapters_dir = f"LifeScript-Solo/天机录/translations/{lang}/chapters"
    if not os.path.isdir(chapters_dir):
        print(f"  Directory not found: {chapters_dir}")
        return

    files = sorted(f for f in os.listdir(chapters_dir) if f.endswith('.json'))
    print(f"\n  [{lang}] Processing {len(files)} chapter files...")

    emotion_stats = Counter()
    pl_stats = Counter()
    content_stats = Counter()

    for fname in files:
        filepath = os.path.join(chapters_dir, fname)
        with open(filepath) as f:
            data = json.load(f)

        # Apply emotion translations
        apply_field_translations(data, "emotion", emotion_trans, lang, emotion_stats)

        # Apply process_label translations
        apply_field_translations(data, "process_label", pl_trans, lang, pl_stats)

        # Fix content text (only for EN and KO, not JA since JA uses kanji)
        if lang == "en":
            fix_content_chinese(data, lang, CONTENT_FIXES_EN, content_stats)
        elif lang == "ko":
            fix_content_chinese(data, lang, CONTENT_FIXES_KO, content_stats)

        # Write back
        with open(filepath, 'w') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"    emotion:       {emotion_stats['translated']} translated, "
          f"{emotion_stats['missing']} missing, {emotion_stats['no_translation']} no-translation")
    print(f"    process_label: {pl_stats['translated']} translated, "
          f"{pl_stats['missing']} missing, {pl_stats['no_translation']} no-translation")
    if lang in ("en", "ko"):
        print(f"    content fixes: {content_stats['content_fixes']} replacements")

    # Report missing values
    for name, stats in [("emotion", emotion_stats), ("process_label", pl_stats)]:
        missing = stats.get("missing_values", set())
        if missing:
            print(f"    {name} missing translations ({len(missing)} values):")
            for v in sorted(missing)[:10]:
                print(f"      - {v}")
            if len(missing) > 10:
                print(f"      ... and {len(missing) - 10} more")


def main():
    print("=" * 60)
    print("Apply Translations to Chapter Files")
    print("=" * 60)

    emotion_trans = load_translations("/tmp/emotion_translations.json")
    pl_trans = load_translations("/tmp/process_label_translations.json")

    print(f"Loaded {len(emotion_trans)} emotion translations")
    print(f"Loaded {len(pl_trans)} process_label translations")

    for lang in ["en", "ja", "ko"]:
        process_language(lang, emotion_trans, pl_trans)

    print("\n" + "=" * 60)
    print("Done! All chapter files updated.")
    print("=" * 60)


if __name__ == "__main__":
    main()
