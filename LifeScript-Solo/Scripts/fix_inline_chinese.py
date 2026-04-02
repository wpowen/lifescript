#!/usr/bin/env python3
"""
Second pass: fix inline Chinese characters remaining in translated chapter files.
Handles mixed-language strings like "act the废物 properly" or "冷笑하지만虚弱".

Scans ALL string fields in translation JSON files and replaces known Chinese
words/phrases with their target-language equivalents.
"""

import json
import os
import re
import sys
from collections import Counter

# Comprehensive Chinese → English inline replacement dictionary
# These are words that appear embedded in otherwise translated text
INLINE_FIXES_EN = {
    # Characters and terms
    "废物": "trash",
    "熟练": "practiced",
    "波动": "fluctuation",
    "平淡": "indifferent",
    "平静": "calm",
    "愣了一下": "was momentarily stunned",
    "小弟": "lackeys",
    "记下了": "took note",
    "废物的觉悟": "a trash's awareness",
    "灵力": "spiritual energy",
    "灵气": "spiritual energy",
    "灵根": "spiritual root",
    "丹田": "dantian",
    "经脉": "meridians",
    "修为": "cultivation",
    "修士": "cultivator",
    "真气": "true qi",
    "元神": "primordial spirit",
    "法器": "artifact",
    "法宝": "treasure",
    "阵法": "formation",
    "禁制": "restriction",
    "结界": "barrier",
    "天劫": "heavenly tribulation",
    "渡劫": "tribulation",
    "筑基": "foundation establishment",
    "金丹": "golden core",
    "元婴": "nascent soul",
    "化神": "spirit transformation",
    "合体": "integration",
    "大乘": "mahayana",
    "飞升": "ascension",
    # Common emotions/states
    "震惊": "shocked",
    "冷静": "calm",
    "坚定": "resolute",
    "沉重": "heavy",
    "凝重": "grave",
    "决绝": "determined",
    "嘲讽": "mocking",
    "警告": "warning",
    "冷漠": "cold",
    "冷笑": "sneered",
    "警惕": "vigilant",
    "审视": "scrutinizing",
    "复杂": "complex",
    "愤怒": "furious",
    "冷酷": "ruthless",
    "阴冷": "sinister",
    "轻蔑": "contemptuous",
    "感动": "moved",
    "激动": "excited",
    "威严": "dignified",
    "试探": "probing",
    "从容": "composed",
    "严肃": "serious",
    "暴怒": "furious",
    "隐忍": "endured",
    "紧张": "nervous",
    "意味深长": "meaningfully",
    "傲慢": "arrogant",
    "担忧": "worried",
    "急切": "urgent",
    "威胁": "threatening",
    "沉思": "pensive",
    "惊恐": "terrified",
    "无奈": "helpless",
    "戏谑": "playful",
    "感慨": "emotional",
    "冷厉": "cold and stern",
    "威压": "imposing",
    "压抑": "suppressed",
    "温柔": "gentle",
    "心疼": "heartache",
    "痛苦": "agonized",
    "深沉": "profound",
    "冰冷": "icy",
    "疑惑": "puzzled",
    "沉稳": "steady",
    "关切": "concerned",
    "冷淡": "indifferent",
    "神秘": "mysterious",
    "动容": "touched",
    "狡黠": "cunning",
    "苦涩": "bitter",
    "淡然": "nonchalant",
    "自信": "confident",
    "阴沉": "gloomy",
    "讥讽": "sarcastic",
    "算计": "calculating",
    "挑衅": "provocative",
    "疯狂": "crazed",
    "恐惧": "fearful",
    "淡漠": "detached",
    "心痛": "pained",
    "阴险": "sinister",
    "赞许": "approving",
    "诱惑": "tempting",
    "悲壮": "tragic",
    "癫狂": "maniacal",
    "坦诚": "candid",
    "困惑": "confused",
    "傲然": "proudly",
    "若有所思": "thoughtful",
    "虚弱": "weak",
    "锐利": "sharp",
    "疲惫": "exhausted",
    "满意": "satisfied",
    "悲伤": "sorrowful",
    "焦虑": "anxious",
    "惊骇": "horrified",
    "哽咽": "choking up",
    "洞察": "insightful",
    "信任": "trusting",
    "真诚": "sincere",
    "好奇": "curious",
    "绝望": "despairing",
    "伪装": "disguised",
    "杀意": "murderous",
    "讽刺": "ironic",
    "迷茫": "lost",
    "释然": "relieved",
    "期待": "expectant",
    "焦急": "anxious",
    "郑重": "solemn",
    "玩味": "amused",
    "期许": "hopeful",
    "悲凉": "desolate",
    "冷峻": "stern",
    "沉痛": "grieving",
    "激昂": "passionate",
    "兴奋": "excited",
    "挣扎": "struggling",
    "动摇": "wavering",
    "惶恐": "panicked",
    "悲痛": "grief-stricken",
    "决意": "resolute",
    "狂傲": "wildly arrogant",
    "赞赏": "admiring",
    "欣赏": "appreciating",
    "决然": "resolute",
    "克制": "restrained",
    "探究": "inquiring",
    "诚恳": "earnest",
    "坦然": "composed",
    "倔强": "stubborn",
    "低沉": "low",
    "嚣张": "brazen",
    "真挚": "heartfelt",
    "欣慰": "gratified",
    "认真": "serious",
    "震撼": "awestruck",
    "紧迫": "pressing",
    "恼怒": "annoyed",
    "调侃": "teasing",
    "叹息": "sighing",
    "温和": "warm",
    "不舍": "reluctant",
    "贪婪": "greedy",
    "怯懦": "timid",
    "质问": "questioning",
    "质疑": "doubting",
    "谨慎": "cautious",
    "悲愤": "indignant",
    "谦卑": "humble",
    # Actions/strategies
    "以退为进": "retreat to advance",
    "借力打力": "turn their force against them",
    "以静制动": "stillness controls motion",
    "静观其变": "wait and watch",
    "主动出击": "take initiative",
    "孤注一掷": "all or nothing",
    "以命相搏": "fight with one's life",
    "暗中布局": "scheme in secret",
    "隐忍蛰伏": "endure and bide time",
    "追问真相": "pursue the truth",
    "隐忍待机": "endure and wait",
    "坦诚相待": "be honest and open",
    "暗度陈仓": "covert maneuvering",
    "逆天改命": "defy fate",
    "冷静分析": "analyze calmly",
    "先发制人": "preemptive strike",
    "步步为营": "advance step by step",
    "锋芒": "edge",
    "时机": "the right moment",
    "坦然": "calmly",
    "激进": "aggressive",
    # Relationship/system terms
    "好感": "affection",
    "敌意": "hostility",
    "信任": "trust",
    "敬畏": "awe",
    "依赖": "reliance",
    "名望": "reputation",
    "天命值": "fate",
    "战力": "combat",
    "谋略": "strategy",
    "财富": "wealth",
    "魅力": "charm",
    "黑化值": "corruption",
}

INLINE_FIXES_KO = {
    "废物": "폐물",
    "灵力": "영력",
    "灵气": "영기",
    "灵根": "영근",
    "修为": "수련",
    "修士": "수련자",
    "真气": "진기",
    "元神": "원신",
    "法器": "법기",
    "法宝": "법보",
    "阵法": "진법",
    "禁制": "금제",
    "结界": "결계",
    "天劫": "천겁",
    "渡劫": "도겁",
    "筑基": "축기",
    "金丹": "금단",
    "元婴": "원영",
    "熟练": "숙련된",
    "波动": "파동",
    "平淡": "담담",
    "平静": "평온",
    "震惊": "충격",
    "冷静": "침착",
    "坚定": "단호",
    "沉重": "무거운",
    "凝重": "침중",
    "决绝": "결연",
    "嘲讽": "조롱",
    "警告": "경고",
    "冷漠": "냉담",
    "冷笑": "냉소",
    "警惕": "경계",
    "审视": "심시",
    "复杂": "복잡",
    "愤怒": "분노",
    "冷酷": "냉혹",
    "阴冷": "음침",
    "轻蔑": "경멸",
    "感动": "감동",
    "激动": "격동",
    "威严": "위엄",
    "试探": "탐색",
    "从容": "여유",
    "严肃": "진지",
    "暴怒": "격노",
    "隐忍": "인내",
    "紧张": "긴장",
    "傲慢": "오만",
    "担忧": "걱정",
    "虚弱": "허약",
    "困惑": "당혹",
    "痛苦": "고통",
    "恐惧": "공포",
    "绝望": "절망",
    "伪装": "위장",
    "好感": "호감",
    "敌意": "적의",
    "信任": "신뢰",
    "敬畏": "경외",
    "名望": "명성",
    "天命值": "천명",
    "战力": "전투력",
    "谋略": "계략",
    "财富": "재화",
    "魅力": "매력",
    "黑化值": "흑화",
    "以退为进": "물러서며 전진",
    "静观其变": "지켜보며 대기",
    "主动出击": "선제공격",
    "孤注一掷": "올인",
    "锋芒": "기세",
    "时机": "적절한 시기",
}

# JA doesn't need inline fixes since kanji overlap with Chinese naturally
INLINE_FIXES_JA = {
    "废物": "廃物",
    "灵力": "霊力",
    "灵气": "霊気",
    "灵根": "霊根",
}


def fix_chinese_in_string(text: str, fixes: dict) -> str:
    """Replace Chinese characters in a string using the fixes dictionary.
    Sort by length (longest first) to avoid partial replacements."""
    if not re.search(r'[\u4e00-\u9fff]', text):
        return text

    # Sort by length descending to replace longer phrases first
    sorted_fixes = sorted(fixes.items(), key=lambda x: len(x[0]), reverse=True)
    for zh, replacement in sorted_fixes:
        if zh in text:
            text = text.replace(zh, replacement)
    return text


def process_all_fields(obj, fixes: dict, stats: Counter):
    """Recursively process all string fields in the JSON, fixing inline Chinese."""
    if isinstance(obj, dict):
        for key, value in obj.items():
            if key in ('id', 'book_id', 'character_id', 'choice_type',
                       'branch_route_id', 'memory_label'):
                continue  # Skip ID fields
            if isinstance(value, str) and re.search(r'[\u4e00-\u9fff]', value):
                fixed = fix_chinese_in_string(value, fixes)
                if fixed != value:
                    obj[key] = fixed
                    stats["fixed"] += 1
                    # Check if still has Chinese
                    if re.search(r'[\u4e00-\u9fff]', fixed):
                        stats["still_has_chinese"] += 1
            elif isinstance(value, (dict, list)):
                process_all_fields(value, fixes, stats)
    elif isinstance(obj, list):
        for item in obj:
            process_all_fields(item, fixes, stats)


def count_remaining_chinese(obj, skip_keys=None):
    """Count remaining Chinese characters in all string fields."""
    if skip_keys is None:
        skip_keys = {'id', 'book_id', 'character_id', 'choice_type',
                     'branch_route_id', 'memory_label'}
    count = 0
    if isinstance(obj, dict):
        for key, value in obj.items():
            if key in skip_keys:
                continue
            if isinstance(value, str):
                count += len(re.findall(r'[\u4e00-\u9fff]', value))
            elif isinstance(value, (dict, list)):
                count += count_remaining_chinese(value, skip_keys)
    elif isinstance(obj, list):
        for item in obj:
            count += count_remaining_chinese(item, skip_keys)
    return count


def process_language(lang: str, fixes: dict):
    """Process all chapter files for a language."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = os.path.dirname(script_dir)
    chapters_dir = os.path.join(base_dir, "天机录", "translations", lang, "chapters")
    if not os.path.isdir(chapters_dir):
        print(f"  Directory not found: {chapters_dir}")
        return

    files = sorted(f for f in os.listdir(chapters_dir) if f.endswith('.json'))
    print(f"\n  [{lang}] Processing {len(files)} chapter files...")

    stats = Counter()
    remaining_chinese_total = 0
    chapters_with_chinese = 0

    for fname in files:
        filepath = os.path.join(chapters_dir, fname)
        with open(filepath) as f:
            data = json.load(f)

        process_all_fields(data, fixes, stats)

        remaining = count_remaining_chinese(data)
        remaining_chinese_total += remaining
        if remaining > 0:
            chapters_with_chinese += 1

        with open(filepath, 'w') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"    Fields fixed: {stats['fixed']}")
    print(f"    Fields still with Chinese after fix: {stats['still_has_chinese']}")
    print(f"    Remaining Chinese chars total: {remaining_chinese_total}")
    print(f"    Chapters with remaining Chinese: {chapters_with_chinese}/{len(files)}")


def main():
    print("=" * 60)
    print("Fix Inline Chinese Characters - Second Pass")
    print("=" * 60)

    process_language("en", INLINE_FIXES_EN)
    process_language("ja", INLINE_FIXES_JA)
    process_language("ko", INLINE_FIXES_KO)

    print("\n" + "=" * 60)
    print("Done!")
    print("=" * 60)


if __name__ == "__main__":
    main()
