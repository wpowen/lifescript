#!/usr/bin/env python3

from __future__ import annotations

import json
import hashlib
import math
import re
import sys
from pathlib import Path
from typing import Any


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def dump_json(path: Path, payload: Any) -> None:
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    digest.update(path.read_bytes())
    return digest.hexdigest()


def content_version(package_root: Path, chapter_paths: list[Path]) -> str:
    digest = hashlib.sha256()
    digest.update((package_root / "story_package.json").read_bytes())
    for chapter_path in chapter_paths:
        digest.update(chapter_path.name.encode("utf-8"))
        digest.update(chapter_path.read_bytes())
    return digest.hexdigest()


def normalize_whitespace(content: str) -> str:
    return re.sub(r"\s+", " ", content).strip()


def narrative_snippet(content: str) -> str:
    snippet = normalize_whitespace(content)
    return snippet[:52] if snippet else ""


def iter_node_payloads(nodes: list[Any]) -> list[dict[str, Any]]:
    payloads: list[dict[str, Any]] = []

    for node in nodes:
        if isinstance(node, str):
            payloads.append({"text": {"content": node}})
            continue

        if isinstance(node, list):
            payloads.extend(iter_node_payloads(node))
            continue

        if not isinstance(node, dict):
            continue

        if any(key in node for key in ("text", "dialogue", "choice", "notification")):
            payloads.append(node)
            continue

        for value in node.values():
            if isinstance(value, dict):
                payloads.extend(iter_node_payloads([value]))
            elif isinstance(value, list):
                payloads.extend(iter_node_payloads(value))

    return payloads


def fallback_summary(chapter: dict[str, Any]) -> str:
    for node in iter_node_payloads(chapter.get("nodes", [])):
        text_payload = node.get("text")
        if isinstance(text_payload, dict):
            snippet = narrative_snippet(str(text_payload.get("content", "")))
            if snippet:
                return snippet

        dialogue_payload = node.get("dialogue")
        if isinstance(dialogue_payload, dict):
            snippet = narrative_snippet(str(dialogue_payload.get("content", "")))
            if snippet:
                return snippet

    hook = chapter.get("next_chapter_hook")
    if isinstance(hook, str) and hook.strip():
        return normalize_whitespace(hook)[:52]

    return "这一章的局势仍在继续发酵。"


def fallback_objective(chapter: dict[str, Any]) -> str:
    for node in iter_node_payloads(chapter.get("nodes", [])):
        choice_payload = node.get("choice")
        if isinstance(choice_payload, dict):
            prompt = normalize_whitespace(str(choice_payload.get("prompt", "")))
            if prompt:
                return prompt

    return f"推进「{chapter.get('title', '当前章节')}」并接住下一次因果变化。"


def interaction_count(chapter: dict[str, Any]) -> int:
    count = 0
    for node in iter_node_payloads(chapter.get("nodes", [])):
        if isinstance(node.get("choice"), dict):
            count += 1
    return count


def estimated_minutes(chapter: dict[str, Any]) -> int:
    node_count = len(chapter.get("nodes", []))
    return max(3, min(12, max(1, math.ceil(node_count / 4))))


def parse_chapter_range(raw_value: str) -> tuple[int, int] | None:
    values = [int(token) for token in re.findall(r"\d+", raw_value)]
    if not values:
        return None
    return values[0], values[-1]


def build_stages(package: dict[str, Any], chapters: list[dict[str, Any]]) -> list[dict[str, Any]]:
    route_graph = package.get("route_graph") or {}
    milestones = route_graph.get("milestones") or []
    sorted_chapters = sorted(chapters, key=lambda chapter: (chapter.get("number", 0), chapter.get("id", "")))

    stages: list[dict[str, Any]] = []

    for milestone in milestones:
        chapter_range = parse_chapter_range(str(milestone.get("chapter_range", "")))
        if not chapter_range:
            continue

        lower, upper = chapter_range
        chapter_ids = [
            str(chapter.get("id"))
            for chapter in sorted_chapters
            if lower <= int(chapter.get("number", 0)) <= upper
        ]
        if not chapter_ids:
            continue

        title = str(milestone.get("title", "命途阶段"))
        stages.append(
            {
                "id": str(milestone.get("id", f"milestone_{lower}_{upper}")),
                "title": title,
                "summary": f"第{lower}-{upper}章阶段，围绕「{title}」推进。",
                "chapter_ids": chapter_ids,
            }
        )

    if stages:
        return stages

    return [
        {
            "id": "stage_live",
            "title": "天机连载",
            "summary": "当前已生成章节的主线推进与关键抉择。",
            "chapter_ids": [str(chapter.get("id")) for chapter in sorted_chapters],
        }
    ]


def build_walkthrough(package: dict[str, Any], chapters: list[dict[str, Any]]) -> dict[str, Any]:
    stages = build_stages(package, chapters)
    stage_by_chapter_id = {
        chapter_id: stage["id"]
        for stage in stages
        for chapter_id in stage.get("chapter_ids", [])
    }
    walkthrough_seed = package.get("walkthrough") or {}
    route_graph = package.get("route_graph") or {}
    hidden_routes = route_graph.get("hidden_routes") or []
    hidden_route_hint = walkthrough_seed.get("unlock_hint") or (hidden_routes[0] if hidden_routes else None)

    chapter_guides: list[dict[str, Any]] = []
    for chapter in sorted(chapters, key=lambda item: (item.get("number", 0), item.get("id", ""))):
        chapter_id = str(chapter.get("id"))
        chapter_guides.append(
            {
                "chapter_id": chapter_id,
                "stage_id": stage_by_chapter_id.get(chapter_id, stages[0]["id"] if stages else "stage_live"),
                "public_summary": fallback_summary(chapter),
                "objective": fallback_objective(chapter),
                "estimated_minutes": estimated_minutes(chapter),
                "interaction_count": interaction_count(chapter),
                "visible_routes": [],
                "hidden_route_hint": hidden_route_hint,
            }
        )

    return {
        "book_id": str(package["book"]["id"]),
        "title": f"{package['book']['title']}命运图谱",
        "stages": stages,
        "chapter_guides": chapter_guides,
    }


def compile_bundle(package_root: Path, output_dir: Path) -> None:
    story_package_path = package_root / "story_package.json"
    chapter_dir = package_root / "chapters"

    if not story_package_path.exists():
        raise SystemExit(f"missing story package: {story_package_path}")
    if not chapter_dir.exists():
        raise SystemExit(f"missing chapter directory: {chapter_dir}")

    package = load_json(story_package_path)
    chapter_paths = sorted(chapter_dir.glob("*.json"))
    chapters = [load_json(path) for path in chapter_paths]
    book_id = str(package["book"]["id"])
    compiled_version = content_version(package_root, chapter_paths)

    output_dir.mkdir(parents=True, exist_ok=True)

    dump_json(output_dir / f"book_{book_id}.json", package["book"])
    dump_json(output_dir / f"chapters_{book_id}.json", chapters)
    dump_json(output_dir / f"walkthrough_{book_id}.json", build_walkthrough(package, chapters))
    dump_json(
        output_dir / f"manifest_{book_id}.json",
        {
            "book_id": book_id,
            "chapter_count": len(chapters),
            "content_version": compiled_version,
            "story_package_sha256": file_sha256(story_package_path),
        },
    )

    print(
        f"compiled {book_id}: {len(chapters)} chapters @ {compiled_version[:12]} -> {output_dir}",
        flush=True,
    )


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(
            "usage: compile_directory_story_bundle.py <package_root> <output_dir>",
            file=sys.stderr,
        )
        return 1

    package_root = Path(argv[1]).resolve()
    output_dir = Path(argv[2]).resolve()
    compile_bundle(package_root, output_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
