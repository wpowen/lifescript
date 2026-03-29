#!/usr/bin/env python3

from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path


def dump_json(path: Path, payload: object) -> None:
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def compile_translations(translations_root: Path, output_dir: Path) -> None:
    if not translations_root.exists():
        raise SystemExit(f"missing translations directory: {translations_root}")

    output_dir.mkdir(parents=True, exist_ok=True)

    for existing in output_dir.glob("translation_*_ch*.json"):
        existing.unlink()

    manifest: dict[str, object] = {
        "languages": {},
        "total_files": 0,
    }

    for language_dir in sorted(path for path in translations_root.iterdir() if path.is_dir()):
        chapter_dir = language_dir / "chapters"
        if not chapter_dir.exists():
            continue

        chapter_paths = sorted(chapter_dir.glob("*.json"))
        copied_names: list[str] = []

        for chapter_path in chapter_paths:
            target_name = f"translation_{language_dir.name}_{chapter_path.name}"
            shutil.copy2(chapter_path, output_dir / target_name)
            copied_names.append(target_name)

        manifest["languages"][language_dir.name] = {
            "chapter_count": len(chapter_paths),
            "files": copied_names,
        }
        manifest["total_files"] = int(manifest["total_files"]) + len(chapter_paths)

    glossary_path = translations_root / "glossary.json"
    if glossary_path.exists():
        shutil.copy2(glossary_path, output_dir / "translation_glossary.json")
        manifest["glossary"] = "translation_glossary.json"

    dump_json(output_dir / "translation_manifest.json", manifest)

    print(
        f"compiled translations: {manifest['total_files']} files -> {output_dir}",
        flush=True,
    )


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(
            "usage: compile_directory_story_translations.py <translations_root> <output_dir>",
            file=sys.stderr,
        )
        return 1

    translations_root = Path(argv[1]).resolve()
    output_dir = Path(argv[2]).resolve()
    compile_translations(translations_root, output_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
