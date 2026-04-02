#!/usr/bin/env python3
"""
Find keys in EN Localizable.strings that are missing from JA/KO/ZH-Hans,
and add translations for them.

For JA/KO: Uses the EN translation as a reasonable fallback (better than Chinese).
For ZH-Hans: Uses the key itself as value (self-mapping).
"""

import os
import re

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RESOURCES = os.path.join(BASE, "Sources", "LifeScriptSolo", "Resources")

def parse_strings_file(filepath):
    """Parse a Localizable.strings file, returning ordered list of (key, value) and set of keys."""
    entries = []
    keys = set()
    if not os.path.exists(filepath):
        return entries, keys
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            # Match "key" = "value";
            m = re.match(r'^"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;', line)
            if m:
                key = m.group(1).replace('\\"', '"')
                value = m.group(2).replace('\\"', '"')
                entries.append((key, value))
                keys.add(key)
    return entries, keys

def append_entries(filepath, entries, section_comment=""):
    with open(filepath, "a", encoding="utf-8") as f:
        if section_comment:
            f.write(f"\n/* {section_comment} */\n")
        for key, value in entries:
            escaped_key = key.replace('"', '\\"')
            escaped_value = value.replace('"', '\\"')
            f.write(f'"{escaped_key}" = "{escaped_value}";\n')

def main():
    en_path = os.path.join(RESOURCES, "en.lproj", "Localizable.strings")
    ja_path = os.path.join(RESOURCES, "ja.lproj", "Localizable.strings")
    ko_path = os.path.join(RESOURCES, "ko.lproj", "Localizable.strings")
    zh_path = os.path.join(RESOURCES, "zh-Hans.lproj", "Localizable.strings")

    en_entries, en_keys = parse_strings_file(en_path)
    _, ja_keys = parse_strings_file(ja_path)
    _, ko_keys = parse_strings_file(ko_path)
    _, zh_keys = parse_strings_file(zh_path)

    # Build EN lookup
    en_lookup = {k: v for k, v in en_entries}

    # Find missing keys, preserving EN order
    ja_missing = [(k, v) for k, v in en_entries if k not in ja_keys]
    ko_missing = [(k, v) for k, v in en_entries if k not in ko_keys]
    zh_missing = [(k, k) for k, v in en_entries if k not in zh_keys]  # self-mapping

    if ja_missing:
        append_entries(ja_path, ja_missing, "Synced from EN (missing keys)")
        print(f"[JA] Added {len(ja_missing)} missing keys (EN translation as fallback)")
    else:
        print("[JA] No missing keys")

    if ko_missing:
        append_entries(ko_path, ko_missing, "Synced from EN (missing keys)")
        print(f"[KO] Added {len(ko_missing)} missing keys (EN translation as fallback)")
    else:
        print("[KO] No missing keys")

    if zh_missing:
        append_entries(zh_path, zh_missing, "Synced self-mappings for missing keys")
        print(f"[ZH-Hans] Added {len(zh_missing)} self-mapping keys")
    else:
        print("[ZH-Hans] No missing keys")

    # Print some examples
    if ja_missing:
        print("\nFirst 5 missing JA keys (using EN fallback):")
        for k, v in ja_missing[:5]:
            print(f'  "{k}" = "{v}"')

if __name__ == "__main__":
    main()
