#!/usr/bin/env python3
import argparse
import json
from pathlib import Path
from typing import Any


NODE_KINDS = ("text", "dialogue", "choice", "notification")


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def summarize_directory_package(package_root: Path) -> dict[str, Any]:
    story_package_path = package_root / "story_package.json"
    chapters_dir = package_root / "chapters"

    if not story_package_path.exists():
        raise SystemExit(f"missing story package: {story_package_path}")
    if not chapters_dir.exists():
        raise SystemExit(f"missing chapters directory: {chapters_dir}")

    package = load_json(story_package_path)
    chapter_paths = sorted(chapters_dir.glob("*.json"))
    chapters = [(path, load_json(path)) for path in chapter_paths]

    errors: list[str] = []
    warnings: list[str] = []

    book = package.get("book", {})
    walkthrough = package.get("walkthrough", {})
    route_graph = package.get("route_graph", {})
    book_id = book.get("id")

    if not book_id:
        errors.append("book.id is required")

    generated_count = len(chapters)
    planned_count = book.get("total_chapters", generated_count)

    if planned_count < generated_count:
        errors.append(
            f"book.total_chapters={planned_count} is smaller than generated chapter count={generated_count}"
        )
    elif planned_count > generated_count:
        warnings.append(
            f"serial package is incomplete: generated {generated_count} / planned {planned_count} chapters"
        )

    chapter_numbers = [chapter.get("number") for _, chapter in chapters if isinstance(chapter.get("number"), int)]
    if chapter_numbers and sorted(chapter_numbers) != list(range(1, max(chapter_numbers) + 1)):
        warnings.append("generated chapter numbers are not contiguous from 1 to the latest generated chapter")

    total_choice_nodes = 0
    total_options = 0

    for path, chapter in chapters:
        chapter_id = chapter.get("id", path.stem)
        chapter_number = chapter.get("number")

        if book_id and chapter.get("book_id") != book_id:
            errors.append(f"{path.name}: chapter.book_id must match book.id")

        if path.stem != f"ch{int(chapter_number):04d}" if isinstance(chapter_number, int) else False:
            warnings.append(f"{path.name}: filename does not match chapter.number")

        nodes = chapter.get("nodes", [])
        if not isinstance(nodes, list):
            errors.append(f"{path.name}: nodes must be a list")
            continue

        choice_nodes = 0
        option_count = 0
        for node_index, node in enumerate(nodes):
            node_errors, node_choice_count, node_option_count = validate_story_node(
                node,
                context=f"{path.name}::node[{node_index}]",
                allow_choice_result=False,
            )
            errors.extend(node_errors)
            choice_nodes += node_choice_count
            option_count += node_option_count

        total_choice_nodes += choice_nodes
        total_options += option_count

        if choice_nodes == 0:
            warnings.append(f"{path.name}: chapter has no choice nodes")

    milestone_ids = route_graph.get("milestones", [])
    if not milestone_ids:
        warnings.append("route_graph.milestones is empty")
    if not walkthrough.get("unlock_hint"):
        warnings.append("walkthrough.unlock_hint is empty")

    return {
        "book_id": book_id,
        "generated_chapters": generated_count,
        "planned_chapters": planned_count,
        "choice_nodes": total_choice_nodes,
        "average_choice_nodes_per_chapter": round(total_choice_nodes / max(generated_count, 1), 2),
        "average_options_per_choice_node": round(total_options / max(total_choice_nodes, 1), 2),
        "warnings": warnings,
        "errors": errors,
    }


def validate_story_node(
    node: Any,
    *,
    context: str,
    allow_choice_result: bool,
) -> tuple[list[str], int, int]:
    errors: list[str] = []
    choice_nodes = 0
    option_count = 0

    if not isinstance(node, dict):
        return [f"{context}: story node must be an object"], choice_nodes, option_count

    present_kinds = [kind for kind in NODE_KINDS if kind in node]
    if len(present_kinds) != 1:
        errors.append(
            f"{context}: story node must contain exactly one of {', '.join(NODE_KINDS)}; found {present_kinds or 'none'}"
        )
        return errors, choice_nodes, option_count

    kind = present_kinds[0]
    payload = node[kind]
    if not isinstance(payload, dict):
        errors.append(f"{context}: {kind} payload must be an object")
        return errors, choice_nodes, option_count

    if allow_choice_result and kind == "choice":
        errors.append(f"{context}: nested choice nodes should not appear inside result_nodes")
        return errors, choice_nodes, option_count

    if kind == "choice":
        choice_nodes += 1
        raw_choices = payload.get("choices", [])
        if not isinstance(raw_choices, list):
            errors.append(f"{context}: choice.choices must be a list")
            return errors, choice_nodes, option_count

        option_count += len(raw_choices)
        if not 2 <= len(raw_choices) <= 4:
            errors.append(f"{context}: each choice node must have 2-4 options")

        for option_index, option in enumerate(raw_choices):
            option_context = f"{context}::choice[{option_index}]"
            if not isinstance(option, dict):
                errors.append(f"{option_context}: choice option must be an object")
                continue

            if not isinstance(option.get("id"), str) or not option.get("id"):
                errors.append(f"{option_context}: option id must be a non-empty string")
            if not isinstance(option.get("text"), str) or not option.get("text"):
                leaked_kinds = [kind for kind in NODE_KINDS if kind in option]
                if leaked_kinds:
                    errors.append(f"{option_context}: leaked story node found inside choice array ({', '.join(leaked_kinds)})")
                else:
                    errors.append(f"{option_context}: option text must be a non-empty string")

            result_nodes = option.get("result_nodes", [])
            if result_nodes:
                if not isinstance(result_nodes, list):
                    errors.append(f"{option_context}: result_nodes must be a list")
                else:
                    for result_index, result_node in enumerate(result_nodes):
                        result_errors, _, _ = validate_story_node(
                            result_node,
                            context=f"{option_context}::result[{result_index}]",
                            allow_choice_result=True,
                        )
                        errors.extend(result_errors)
            elif not option.get("result_node_ids"):
                errors.append(f"{option_context}: option must contain result_nodes or result_node_ids")

    return errors, choice_nodes, option_count


def print_report(report: dict[str, Any]) -> None:
    print(json.dumps(report, ensure_ascii=False, indent=2))
    if report["warnings"]:
        print("\nWarnings:")
        for warning in report["warnings"]:
            print(f"- {warning}")
    if report["errors"]:
        print("\nErrors:")
        for error in report["errors"]:
            print(f"- {error}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate a directory-form LifeScript story package.")
    parser.add_argument("package_root", type=Path, help="Directory containing story_package.json and chapters/")
    args = parser.parse_args()

    report = summarize_directory_package(args.package_root)
    print_report(report)
    if report["errors"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
