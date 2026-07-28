#!/usr/bin/env python3
"""Structural publication gate for Deshar learning content."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "nokhchiin" / "assets" / "data"

FREQUENCY_TIERS = {"common", "uncommon", "rare"}
REGISTERS = {"modern", "archaic", "dialect", "technical"}
REVIEW_STATUSES = {"draft", "source_checked", "native_verified", "published"}
CANONICAL_PALOCHKA = "\u04c0"
LOWERCASE_PALOCHKA = "\u04cf"


def load(name: str) -> Any:
    return json.loads((DATA / name).read_text(encoding="utf-8-sig"))


def pair_key(entry: dict[str, Any]) -> str:
    ce = re.sub(r"\s+", " ", entry["chechen"].strip().casefold())
    ru = re.sub(r"\s+", " ", entry["russian"].strip().casefold())
    return f"{ce}|{ru}"


def iter_learning_entries(
    lessons: list[dict[str, Any]], curated: dict[str, Any]
) -> Iterable[tuple[str, dict[str, Any]]]:
    for lesson in lessons:
        for index, entry in enumerate(lesson.get("words", [])):
            yield f"lessons.{lesson.get('id')}[{index}]", entry
    for index, entry in enumerate(curated.get("entries", [])):
        yield f"curated[{index}]", entry


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []

    lessons = load("lessons.json")
    curated = load("curated_vocabulary.json")
    learning_path = load("learning_path.json")
    worlds = load("worlds.json")
    stories = load("stories.json")
    illustrations = load("illustrations_manifest.json")
    audio = load("audio_manifest.json")
    conversations = load("conversation_categories.json")

    lesson_ids = {lesson.get("id") for lesson in lessons}
    unit_ids = {unit.get("id") for unit in learning_path.get("units", [])}
    audio_clips = audio.get("clips", [])
    audio_ids = {clip.get("id") for clip in audio_clips}
    base_pack = audio.get("basePack", {})
    downloadable_packs = audio.get("downloadablePacks", [])
    pack_ids = {
        base_pack.get("id"),
        *(pack.get("id") for pack in downloadable_packs),
    }
    speakers = audio.get("speakers", [])
    speaker_ids = {speaker.get("id") for speaker in speakers}
    category_images = set(illustrations.get("categories", {}))
    override_images = set(illustrations.get("wordOverrides", {}).values())
    image_ids = category_images | override_images

    if len(lesson_ids) != len(lessons):
        errors.append("lessons.json: duplicate lesson id")
    if len(unit_ids) != len(learning_path.get("units", [])):
        errors.append("learning_path.json: duplicate unit id")

    seen_pairs: set[str] = set()
    curated_by_pair: dict[str, dict[str, Any]] = {}
    for marker, entry in iter_learning_entries(lessons, curated):
        for field in ("chechen", "russian", "reviewStatus"):
            if not isinstance(entry.get(field), str) or not entry[field].strip():
                errors.append(f"{marker}: missing required field {field}")

        ce = entry.get("chechen", "")
        if LOWERCASE_PALOCHKA in ce:
            errors.append(
                f"{marker}: use canonical Ӏ U+04C0, found U+04CF"
            )
        status = entry.get("reviewStatus")
        if status not in REVIEW_STATUSES:
            errors.append(f"{marker}: invalid reviewStatus {status!r}")
        tier = entry.get("frequencyTier")
        if tier is not None and tier not in FREQUENCY_TIERS:
            errors.append(f"{marker}: invalid frequencyTier {tier!r}")
        register = entry.get("register")
        if register is not None and register not in REGISTERS:
            errors.append(f"{marker}: invalid register {register!r}")
        if status == "published" and (
            not entry.get("sourceRef") or not entry.get("license")
        ):
            errors.append(
                f"{marker}: published content requires sourceRef and license"
            )
        audio_id = entry.get("audioId")
        if audio_id and audio_id not in audio_ids:
            errors.append(f"{marker}: unknown audioId {audio_id}")
        illustration_id = entry.get("illustrationKey")
        if illustration_id and illustration_id not in image_ids:
            errors.append(
                f"{marker}: unknown illustrationKey {illustration_id}"
            )

        key = pair_key(entry) if entry.get("chechen") and entry.get("russian") else ""
        if marker.startswith("curated") and key:
            if key in seen_pairs:
                errors.append(f"{marker}: duplicate curated pair {key}")
            seen_pairs.add(key)
            curated_by_pair[key] = entry

    for unit in learning_path.get("units", []):
        unit_id = unit.get("id")
        if unit.get("enabled", True) and unit_id not in lesson_ids:
            errors.append(f"learning_path.{unit_id}: enabled unit has no lesson")

    for world in worlds.get("worlds", []):
        for unit_id in world.get("units", []):
            if unit_id not in unit_ids:
                errors.append(f"worlds.{world.get('id')}: unknown unit {unit_id}")

    for story in stories.get("stories", []):
        if story.get("unitId") not in unit_ids:
            errors.append(
                f"stories.{story.get('id')}: unknown unit {story.get('unitId')}"
            )
        for panel in story.get("panels", []):
            if not panel.get("imageKey"):
                warnings.append(
                    f"stories.{story.get('id')}: panel without imageKey"
                )

    conversation_ids: set[str] = set()
    for category in conversations.get("categories", []):
        category_id = category.get("id")
        if not category_id or category_id in conversation_ids:
            errors.append(f"conversation category duplicate/empty id {category_id!r}")
        conversation_ids.add(category_id)
        refs = category.get("entries", [])
        if category.get("enabled") and not refs:
            errors.append(f"conversation.{category_id}: enabled but empty")
        for ref in refs:
            key = pair_key(ref)
            target = curated_by_pair.get(key)
            if target is None:
                errors.append(
                    f"conversation.{category_id}: entry is not in curated data"
                )
            elif target.get("reviewStatus") == "draft":
                errors.append(
                    f"conversation.{category_id}: draft entry cannot be enabled"
                )

    if audio.get("schemaVersion") != 1:
        errors.append("audio_manifest.json: unsupported schemaVersion")
    if not base_pack.get("id") or base_pack.get("bundled") is not True:
        errors.append("audio_manifest.json: basePack must be bundled and have an id")
    if len(pack_ids) != 1 + len(downloadable_packs):
        errors.append("audio_manifest.json: duplicate/empty pack id")
    for pack in downloadable_packs:
        pack_id = pack.get("id")
        if pack.get("bundled") is not False:
            errors.append(f"audio pack {pack_id}: downloadable pack cannot be bundled")
        if (
            not pack.get("downloadUrl")
            or not re.fullmatch(r"[0-9a-fA-F]{64}", str(pack.get("sha256", "")))
            or not isinstance(pack.get("sizeBytes"), int)
            or pack["sizeBytes"] <= 0
        ):
            errors.append(
                f"audio pack {pack_id}: URL, SHA-256 and positive size are required"
            )

    if len(speaker_ids) != len(speakers) or None in speaker_ids:
        errors.append("audio_manifest.json: duplicate/empty speaker id")
    for speaker in speakers:
        for required in ("displayName", "dialect", "consentRef"):
            if not isinstance(speaker.get(required), str) or not speaker[required].strip():
                errors.append(f"audio speaker {speaker.get('id')}: missing {required}")

    if len(audio_ids) != len(audio_clips):
        errors.append("audio_manifest.json: duplicate clip id")
    for clip in audio_clips:
        clip_id = clip.get("id")
        if clip.get("languageTag") not in {"ce", "ce-RU"}:
            errors.append(
                f"audio.{clip_id}: only ce/ce-RU native recordings are allowed"
            )
        if clip.get("kind") != "native_recording":
            errors.append(
                f"audio.{clip_id}: only native_recording is allowed"
            )
        for required in (
            "speakerId",
            "dialect",
            "durationMs",
            "version",
            "sha256",
            "license",
            "packId",
        ):
            if required not in clip:
                errors.append(f"audio.{clip_id}: missing {required}")
        if clip.get("speakerId") not in speaker_ids:
            errors.append(f"audio.{clip_id}: unknown speakerId")
        if clip.get("packId") not in pack_ids:
            errors.append(f"audio.{clip_id}: unknown packId")
        if not re.fullmatch(r"[0-9a-fA-F]{64}", str(clip.get("sha256", ""))):
            errors.append(f"audio.{clip_id}: invalid SHA-256")
        if not isinstance(clip.get("durationMs"), int) or clip["durationMs"] <= 0:
            errors.append(f"audio.{clip_id}: durationMs must be positive")
        if not isinstance(clip.get("version"), int) or clip["version"] <= 0:
            errors.append(f"audio.{clip_id}: version must be positive")
        if not str(clip.get("license", "")).strip():
            errors.append(f"audio.{clip_id}: license is required")
        has_asset = bool(clip.get("assetPath"))
        has_remote = bool(clip.get("remotePath"))
        if has_asset == has_remote:
            errors.append(
                f"audio.{clip_id}: exactly one assetPath or remotePath is required"
            )

    for warning in warnings:
        print(f"WARN: {warning}")
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    if errors:
        print(f"FAILED: {len(errors)} content validation error(s)")
        return 1
    print(
        "PASSED: content metadata, references, publication status, "
        "Unicode and audio policy are valid"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
