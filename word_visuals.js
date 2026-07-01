/**
 * Premium word visuals — Disney-soft scenes + verified emoji map.
 * Fixes semantic mismatches (e.g. стол ≠ стул 🪑).
 */
window.WordVisuals = (function () {
  const EMOJI_FIX = {
    стол: "🍽️",
    стул: "🪑",
    книга: "📚",
    школа: "🏫",
    ухо: "👂",
    сидеть: "💺",
  };

  const PALETTES = {
    greetings: ["#E1BEE7", "#CE93D8"],
    animals: ["#FFE0B2", "#FFCC80"],
    colors: ["#F8BBD9", "#F48FB1"],
    numbers: ["#B3E5FC", "#81D4FA"],
    family: ["#F8BBD9", "#F48FB1"],
    food: ["#C8E6C9", "#A5D6A7"],
    nature: ["#B3E5FC", "#81D4FA"],
    body: ["#FFCDD2", "#EF9A9A"],
    home: ["#E8EAF6", "#C5CAE9"],
    verbs: ["#FFF9C4", "#FFF176"],
    default: ["#E8EAF6", "#C5CAE9"],
  };

  function primaryRu(russian) {
    return (russian || "").toLowerCase().split(",")[0].split("/")[0].trim();
  }

  function resolveEmoji(word) {
    const ru = primaryRu(word.russian);
    for (const [key, emo] of Object.entries(EMOJI_FIX)) {
      if (ru.includes(key)) return emo;
    }
    return word.emoji || "📖";
  }

  function paletteFor(lessonId) {
    return PALETTES[lessonId] || PALETTES.default;
  }

  function render(word, lessonId) {
    const emoji = resolveEmoji(word);
    const [c1, c2] = paletteFor(lessonId);
    const ru = primaryRu(word.russian);
    const isTable = ru.includes("стол") && !ru.includes("стул");
    const isChair = ru.includes("стул") || word.chechen === "ГӀант";

    let prop = "";
    if (isTable) {
      prop = `<div class="pv-prop pv-table" aria-hidden="true"></div>`;
    } else if (isChair) {
      prop = `<div class="pv-prop pv-chair" aria-hidden="true"></div>`;
    }

    return `
      <div class="pv-scene" style="--pv-c1:${c1};--pv-c2:${c2}">
        <div class="pv-sun"></div>
        <div class="pv-hill"></div>
        ${prop}
        <span class="pv-emoji">${emoji}</span>
      </div>`;
  }

  function mount(word, el, lessonId) {
    if (!el) return;
    el.innerHTML = render(word, lessonId);
    el.classList.add("pv-mounted");
  }

  return { resolveEmoji, render, mount, paletteFor };
})();
