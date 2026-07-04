import curatedJson from "../../nokhchiin/assets/data/curated_vocabulary.json";

export type PreviewWord = {
  ce: string;
  tr: string | null;
  ru: string;
  emoji: string;
  cat: string;
  verified: boolean;
};

type RawEntry = {
  chechen?: string;
  russian?: string;
  pronunciation?: string;
  category?: string | null;
  emoji?: string;
  sources?: string[];
  quality?: number;
};

const CATEGORY_LABELS: Record<string, string> = {
  greetings: "Приветствия",
  animals: "Животные",
  colors: "Цвета",
  numbers: "Числа",
  family: "Семья",
  food: "Еда",
  nature: "Природа",
  body: "Тело",
  home: "Дом",
  verbs: "Глаголы",
};

const LESSON_CATEGORIES = new Set(Object.keys(CATEGORY_LABELS));

const PREVIEW_DICT_LIMIT = 5000;

function capitalize(s: string) {
  const t = s.trim();
  return t ? t[0].toUpperCase() + t.slice(1) : t;
}

function normalizePalochka(s: string) {
  return s.replace(/[1Iil|!]/g, "Ӏ").toLowerCase().replace(/\s+/g, "");
}

function categoryLabel(category: string | null | undefined, sources: string[] = []) {
  if (category && CATEGORY_LABELS[category]) return CATEGORY_LABELS[category];
  if (sources.includes("verified") || sources.includes("lessons")) return "Проверено";
  return "Мациев";
}

function transcription(chechen: string, pronunciation?: string | null) {
  const p = (pronunciation ?? "").trim();
  if (!p) return null;
  if (normalizePalochka(p.replace(/·/g, "")) === normalizePalochka(chechen)) return null;
  if (p.toLowerCase() === chechen.toLowerCase()) return null;
  return p;
}

function isVerified(entry: RawEntry) {
  const sources = entry.sources ?? [];
  const category = entry.category;
  if (sources.includes("verified") || sources.includes("lessons")) return true;
  if (category && LESSON_CATEGORIES.has(category)) return true;
  return (entry.quality ?? 0) >= 95 && Boolean(category);
}

function mapEntry(j: RawEntry, capitalizeCe: boolean): PreviewWord | null {
  const ceRaw = (j.chechen ?? "").trim();
  const ru = (j.russian ?? "").trim();
  if (!ceRaw || !ru) return null;
  const ce = capitalizeCe ? capitalize(ceRaw) : ceRaw;
  const sources = j.sources ?? [];
  return {
    ce,
    tr: transcription(ce, j.pronunciation ?? ceRaw),
    ru,
    emoji: j.emoji ?? "📖",
    cat: categoryLabel(j.category, sources),
    verified: isVerified(j),
  };
}

function dedupeKey(w: PreviewWord) {
  return `${w.ce.toLowerCase().replace(/\s+/g, "")}|${w.ru.toLowerCase()}`;
}

/** Полный офлайн-словарь (curated + maciev), как в Flutter-приложении.
 *  Async: fetch dictionary.json (62 МБ) вместо статического import.
 *  Preview лимит: 5000 слов из dictionary для производительности. */
export async function loadFullDictionary(): Promise<PreviewWord[]> {
  const seen = new Set<string>();
  const words: PreviewWord[] = [];

  const curated = curatedJson as { entries: RawEntry[] };
  for (const item of curated.entries) {
    const w = mapEntry(item, true);
    if (!w) continue;
    const key = dedupeKey(w);
    if (seen.has(key)) continue;
    seen.add(key);
    words.push(w);
  }

  const resp = await fetch("/assets/data/preview_dictionary.json");
  const dict = await resp.json() as { entries: RawEntry[] };
  for (const item of dict.entries) {
    const w = mapEntry(item, false);
    if (!w) continue;
    const key = dedupeKey(w);
    if (seen.has(key)) continue;
    seen.add(key);
    words.push(w);
  }

  words.sort((a, b) => a.ce.localeCompare(b.ce, "ru"));
  return words;
}

export function formatWordCount(n: number) {
  return n.toLocaleString("ru-RU");
}
