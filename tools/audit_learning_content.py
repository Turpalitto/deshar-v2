#!/usr/bin/env python3
"""Structural quality gate for the learning-content assets.

This cannot replace native-speaker review. It catches incomplete or internally
inconsistent content before it reaches Flutter.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "nokhchiin" / "assets" / "data"
PLACEHOLDERS = ("todo", "tbd", "lorem", "заглуш", "временно")


def load(name: str) -> Any:
    return json.loads((DATA / name).read_text(encoding="utf-8-sig"))


def nonempty(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def has_placeholder(value: Any) -> bool:
    return isinstance(value, str) and any(
        token in value.casefold() for token in PLACEHOLDERS
    )


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []

    lessons = load("lessons.json")
    path_units = load("learning_path.json")["units"]
    capsules = load("culture_capsules.json")["capsules"]
    stories = load("stories.json")["stories"]
    bosses = load("bosses.json")["bosses"]
    worlds = load("worlds.json")["worlds"]
    collections = load("collections.json")["collections"]

    lesson_ids = [lesson.get("id") for lesson in lessons]
    unit_ids = [unit.get("id") for unit in path_units]
    enabled_ids = {
        unit.get("id") for unit in path_units if unit.get("enabled", True)
    }

    for label, ids in (("lesson", lesson_ids), ("unit", unit_ids)):
        duplicates = sorted({item for item in ids if ids.count(item) > 1})
        if duplicates:
            errors.append(f"duplicate {label} ids: {', '.join(duplicates)}")

    missing_lessons = sorted(enabled_ids - set(lesson_ids))
    if missing_lessons:
        errors.append(
            "enabled units without lessons: " + ", ".join(missing_lessons)
        )

    total_words = 0
    words_by_lesson: dict[str, set[tuple[str, str, str]]] = {}
    for lesson in lessons:
        lesson_id = lesson.get("id", "<missing-id>")
        for field in ("id", "title", "chechenTitle"):
            if not nonempty(lesson.get(field)):
                errors.append(f"lesson {lesson_id}: missing {field}")

        words = lesson.get("words")
        if not isinstance(words, list):
            errors.append(f"lesson {lesson_id}: words must be a list")
            continue
        total_words += len(words)
        if len(words) < 8:
            warnings.append(f"lesson {lesson_id}: only {len(words)} words")

        seen: set[str] = set()
        lesson_word_set: set[tuple[str, str, str]] = set()
        for index, word in enumerate(words):
            marker = f"lesson {lesson_id}, word {index + 1}"
            for field in ("chechen", "russian", "pronunciation"):
                if not nonempty(word.get(field)):
                    errors.append(f"{marker}: missing {field}")
                elif has_placeholder(word[field]):
                    errors.append(f"{marker}: placeholder in {field}")

            chechen = str(word.get("chechen", "")).strip().casefold()
            if chechen and chechen in seen:
                errors.append(f"{marker}: duplicate Chechen form")
            seen.add(chechen)
            lesson_word_set.add(
                (
                    str(word.get("chechen", "")).strip(),
                    str(word.get("russian", "")).strip(),
                    str(word.get("pronunciation", "")).strip(),
                )
            )
        words_by_lesson[str(lesson_id)] = lesson_word_set

        linked_unit = next(
            (unit for unit in path_units if unit.get("id") == lesson_id), None
        )
        if linked_unit and lesson.get("chechenTitle") != linked_unit.get("titleCe"):
            errors.append(
                f"lesson {lesson_id}: chechenTitle differs from learning path "
                f"({lesson.get('chechenTitle')} != {linked_unit.get('titleCe')})"
            )
        lesson_title = str(lesson.get("title", "")).casefold()
        path_title = str((linked_unit or {}).get("titleRu", "")).casefold()
        if linked_unit and not (
            lesson_title == path_title
            or lesson_title.startswith(path_title)
            or path_title.startswith(lesson_title)
        ):
            warnings.append(
                f"lesson {lesson_id}: detailed Russian title differs from path "
                f"({lesson.get('title')} != {linked_unit.get('titleRu')})"
            )

    world_ids = [world.get("id") for world in worlds]
    duplicate_world_ids = sorted(
        {world_id for world_id in world_ids if world_ids.count(world_id) > 1}
    )
    if duplicate_world_ids:
        errors.append("duplicate world ids: " + ", ".join(duplicate_world_ids))

    world_unit_counts: dict[str, int] = {}
    for world in worlds:
        world_id = world.get("id", "<missing-id>")
        world_units = world.get("units")
        if not isinstance(world_units, list) or not world_units:
            errors.append(f"world {world_id}: units must be a non-empty list")
            continue
        for unit_id in world_units:
            if unit_id not in set(unit_ids):
                errors.append(f"world {world_id}: unknown unit {unit_id}")
            world_unit_counts[str(unit_id)] = world_unit_counts.get(str(unit_id), 0) + 1

    missing_world_units = sorted(
        unit_id for unit_id in enabled_ids if world_unit_counts.get(str(unit_id), 0) == 0
    )
    if missing_world_units:
        errors.append(
            "enabled units absent from worlds: " + ", ".join(missing_world_units)
        )
    repeated_world_units = sorted(
        unit_id
        for unit_id, count in world_unit_counts.items()
        if count > 1 and unit_id in enabled_ids
    )
    if repeated_world_units:
        errors.append(
            "enabled units assigned to multiple worlds: "
            + ", ".join(repeated_world_units)
        )

    lesson_sizes = {lesson["id"]: len(lesson.get("words", [])) for lesson in lessons}
    for collection in collections:
        collection_id = collection.get("id", "<missing-id>")
        category = collection.get("category")
        if category not in lesson_sizes:
            errors.append(f"collection {collection_id}: unknown lesson {category}")
            continue
        total_cards = collection.get("totalCards")
        if not isinstance(total_cards, int) or not 1 <= total_cards <= lesson_sizes[category]:
            errors.append(
                f"collection {collection_id}: totalCards {total_cards} exceeds "
                f"lesson size {lesson_sizes[category]}"
            )

    capsule_units: set[str] = set()
    for capsule in capsules:
        capsule_id = capsule.get("id", "<missing-id>")
        related = capsule.get("relatedUnitId")
        for field in ("id", "relatedUnitId", "eyebrow", "title", "body"):
            if not nonempty(capsule.get(field)):
                errors.append(f"capsule {capsule_id}: missing {field}")
            elif has_placeholder(capsule[field]):
                errors.append(f"capsule {capsule_id}: placeholder in {field}")
        if related not in set(unit_ids):
            errors.append(f"capsule {capsule_id}: unknown unit {related}")
        if related in capsule_units:
            warnings.append(f"unit {related}: multiple culture capsules")
        capsule_units.add(related)
        tags = capsule.get("tags")
        if (
            not isinstance(tags, list)
            or len(tags) != 3
            or not all(nonempty(tag) for tag in tags)
        ):
            errors.append(f"capsule {capsule_id}: tags must contain 3 labels")

        featured = capsule.get("featuredWord")
        if featured is not None:
            if not isinstance(featured, dict):
                errors.append(f"capsule {capsule_id}: featuredWord must be an object")
            else:
                featured_tuple = tuple(
                    str(featured.get(field, "")).strip()
                    for field in ("chechen", "russian", "pronunciation")
                )
                if not all(featured_tuple):
                    errors.append(f"capsule {capsule_id}: incomplete featuredWord")
                elif featured_tuple not in words_by_lesson.get(str(related), set()):
                    errors.append(
                        f"capsule {capsule_id}: featuredWord is not in lesson {related}"
                    )
        elif related in words_by_lesson:
            warnings.append(f"capsule {capsule_id}: lesson exists but featuredWord is missing")

        image_path = capsule.get("imagePath")
        if not nonempty(image_path):
            warnings.append(f"capsule {capsule_id}: no illustration")
        elif not (ROOT / "nokhchiin" / str(image_path)).is_file():
            errors.append(f"capsule {capsule_id}: missing image asset {image_path}")

    missing_capsules = sorted(enabled_ids - capsule_units)
    if missing_capsules:
        warnings.append(
            "enabled units without culture capsules: "
            + ", ".join(missing_capsules)
        )

    for story in stories:
        story_id = story.get("id", "<missing-id>")
        if story.get("unitId") not in set(unit_ids):
            errors.append(f"story {story_id}: unknown unit {story.get('unitId')}")
        panels = story.get("panels", [])
        if not panels:
            errors.append(f"story {story_id}: no panels")
        if not story.get("quiz"):
            warnings.append(f"story {story_id}: no comprehension quiz")
        for quiz_index, quiz in enumerate(story.get("quiz", [])):
            if quiz.get("answer") not in quiz.get("options", []):
                errors.append(
                    f"story {story_id}, quiz {quiz_index + 1}: answer not in options"
                )
        for index, panel in enumerate(panels):
            if not panel.get("dialogue"):
                warnings.append(f"story {story_id}, panel {index + 1}: no dialogue")

    for boss in bosses:
        boss_id = boss.get("id", "<missing-id>")
        questions = boss.get("questionsCount", 0)
        pass_score = boss.get("passScore", 0)
        if boss.get("unitId") not in set(unit_ids):
            errors.append(f"boss {boss_id}: unknown unit {boss.get('unitId')}")
        if not isinstance(questions, int) or questions <= 0:
            errors.append(f"boss {boss_id}: invalid questionsCount")
        if not isinstance(pass_score, int) or not 1 <= pass_score <= questions:
            errors.append(f"boss {boss_id}: invalid passScore")
        lesson_size = lesson_sizes.get(boss.get("unitId"))
        if lesson_size is not None and questions > lesson_size:
            errors.append(
                f"boss {boss_id}: {questions} questions exceed {lesson_size} lesson words"
            )

    print(
        "Content audit: "
        f"{len(lessons)} lessons, {total_words} lesson entries, "
        f"{len(capsules)} capsules, {len(stories)} stories, "
        f"{len(bosses)} bosses, {len(worlds)} worlds, "
        f"{len(collections)} collections"
    )
    for warning in warnings:
        print(f"WARN: {warning}")
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)

    if errors:
        print(f"FAILED: {len(errors)} error(s), {len(warnings)} warning(s)")
        return 1
    print(f"PASSED with {len(warnings)} editorial warning(s)")
    print("Native-speaker review remains mandatory; this gate is structural only.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
