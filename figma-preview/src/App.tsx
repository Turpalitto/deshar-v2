import { useState, useEffect, useRef, useMemo, useCallback } from "react";
import { loadFullDictionary, formatWordCount, type PreviewWord } from "./loadDictionary";

let FULL_DICTIONARY: PreviewWord[] = [];

// ─── Tokens ───────────────────────────────────────────────────────────────────
const C = {
  bg: "#F7F4EF",
  bgEl: "#FFFCF8",
  surface: "#FFFFFF",
  surfMuted: "#F0EBE4",
  sep: "rgba(61,56,50,0.10)",
  text: "#1C1917",
  textSec: "#57534E",
  textTert: "#78716C",
  terra: "#C4724E",
  terraMuted: "#F5E0D4",
  meadow: "#3D7A5C",
  meadowMuted: "#D4EDE3",
  gold: "#D4A84B",
  goldMuted: "#FFF4D4",
  ok: "#3D7A5C",
  warn: "#B8860B",
  err: "#B54A4A",
  dark: { bg: "#121110", surface: "#221F1C", text: "#F5F0E8", terra: "#E8A87C" },
};

type Screen =
  | "splash" | "onboarding" | "age"
  | "home" | "path" | "lesson"
  | "flashcard" | "match" | "quiz"
  | "culture" | "worlds" | "dictionary"
  | "profile" | "paywall" | "reward" | "design";

type Mode = "adult" | "kids";
type Tab = "home" | "worlds" | "repeat" | "profile";

// ─── Data ─────────────────────────────────────────────────────────────────────
const WORDS = [
  { ce: "Беркат", tr: "berkat", ru: "Благодать", emoji: "✨", cat: "Духовное" },
  { ce: "Нана", tr: "nana", ru: "Мать", emoji: "🤱", cat: "Семья" },
  { ce: "Даймохк", tr: "daymokhk", ru: "Родина", emoji: "🏔️", cat: "Место" },
  { ce: "Сийлахь", tr: "siylakh", ru: "Благородный", emoji: "👑", cat: "Качество" },
  { ce: "Ненан мотт", tr: "nenan mott", ru: "Родной язык", emoji: "🗣️", cat: "Язык" },
  { ce: "ХӀума", tr: "h'uma", ru: "Вещь / Что-то", emoji: "📦", cat: "Общее" },
  { ce: "Хьаша", tr: "khyasha", ru: "Гость", emoji: "🏠", cat: "Традиции" },
  { ce: "Дела реза хийла", tr: "dela reza khiyla", ru: "Спасибо", emoji: "🙏", cat: "Этикет" },
  { ce: "Марша ваийла", tr: "marsha vaiyla", ru: "Добро пожаловать", emoji: "👋", cat: "Этикет" },
  { ce: "Стаг", tr: "stag", ru: "Человек", emoji: "👤", cat: "Общее" },
];

const PATH_NODES = [
  { id: 1, label: "Приветствия", emoji: "👋", status: "completed", x: 50, y: 90 },
  { id: 2, label: "Семья", emoji: "👨‍👩‍👧", status: "completed", x: 28, y: 76 },
  { id: 3, label: "Числа", emoji: "🔢", status: "current", x: 64, y: 62 },
  { id: 4, label: "Дом", emoji: "🏠", status: "locked", x: 26, y: 48 },
  { id: 5, label: "Еда", emoji: "🍲", status: "locked", x: 60, y: 34 },
  { id: 6, label: "Животные", emoji: "🦊", status: "locked", x: 32, y: 20 },
  { id: 7, label: "Природа", emoji: "🏔️", status: "locked", x: 58, y: 8 },
];

const WORLDS = [
  { title: "Повседневная жизнь", emoji: "☀️", prog: 67, color: C.terra, lessons: 12, desc: "Базовые фразы, встречи, рынок" },
  { title: "Семья и традиции", emoji: "🏔️", prog: 34, color: C.meadow, lessons: 8, desc: "Родство, адат, гостеприимство" },
  { title: "Природа и места", emoji: "🌿", prog: 0, color: "#8B7355", lessons: 10, desc: "Горы, реки, сёла Чечни" },
  { title: "Культура и адат", emoji: "🎶", prog: 0, color: "#5C6E7A", lessons: 6, desc: "Тейпы, нохчалла, эпос" },
  { title: "Тело и здоровье", emoji: "💪", prog: 0, color: "#7A5C8B", lessons: 9, desc: "Анатомия, самочувствие" },
];

const QUIZ_QUESTIONS = [
  { q: "Как переводится «Хьаша»?", ce: "Хьаша", hint: "хьаша", opts: ["Друг", "Гость", "Сосед", "Брат"], correct: 1 },
  { q: "Как переводится «Нана»?", ce: "Нана", hint: "nana", opts: ["Сестра", "Бабушка", "Мать", "Тётя"], correct: 2 },
  { q: "Как переводится «Даймохк»?", ce: "Даймохк", hint: "daymokhk", opts: ["Дом", "Родина", "Гора", "Село"], correct: 1 },
  { q: "Как переводится «Марша ваийла»?", ce: "Марша ваийла", hint: "marsha vaiyla", opts: ["До свидания", "Спасибо", "Добро пожаловать", "Извините"], correct: 2 },
  { q: "Как переводится «Стаг»?", ce: "Стаг", hint: "stag", opts: ["Ребёнок", "Человек", "Воин", "Старик"], correct: 1 },
];

const MATCH_PAIRS = [
  { ce: "Нана", ru: "Мать" },
  { ce: "ДА", ru: "Отец" },
  { ce: "Воша", ru: "Брат" },
  { ce: "Йиша", ru: "Сестра" },
];

// ─── Helpers ──────────────────────────────────────────────────────────────────
function useAnimIn(delay = 0) {
  const [show, setShow] = useState(false);
  useEffect(() => { const t = setTimeout(() => setShow(true), delay); return () => clearTimeout(t); }, [delay]);
  return show;
}

function spring(val: boolean) {
  return { transform: val ? "scale(1) translateY(0)" : "scale(0.94) translateY(8px)", opacity: val ? 1 : 0, transition: "all 0.4s cubic-bezier(0.34,1.56,0.64,1)" };
}

// ─── SVG App Icon ─────────────────────────────────────────────────────────────
function AppIcon({ size = 44 }: { size?: number }) {
  const r = size * 0.22;
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" fill="none">
      <rect width="100" height="100" rx="22" fill="#C4724E" />
      {/* Mountain silhouette */}
      <path d="M12 72 L35 38 L50 52 L65 32 L88 72 Z" fill="rgba(255,255,255,0.15)" />
      <path d="M22 72 L42 44 L50 52 L58 40 L78 72 Z" fill="rgba(255,255,255,0.12)" />
      {/* Н letter */}
      <text x="50" y="74" textAnchor="middle" fontSize="52" fontWeight="700" fontFamily="'Inter', sans-serif" fill="white" letterSpacing="-2">Н</text>
      {/* Palochka ornament */}
      <rect x="47" y="13" width="3" height="14" rx="1.5" fill="rgba(255,255,255,0.5)" />
    </svg>
  );
}

// ─── Wainakh ornament ─────────────────────────────────────────────────────────
function Ornament({ opacity = 0.05, light = false }: { opacity?: number; light?: boolean }) {
  const stroke = light ? "#E8D5C4" : "#3D2E1C";
  return (
    <svg style={{ position: "absolute", inset: 0, width: "100%", height: "100%", pointerEvents: "none", opacity }} viewBox="0 0 390 844" fill="none" preserveAspectRatio="xMidYMid slice">
      {Array.from({ length: 9 }).map((_, i) =>
        Array.from({ length: 14 }).map((_, j) => {
          const x = i * 46 - 6, y = j * 62 - 4;
          return (
            <g key={`${i}${j}`} transform={`translate(${x},${y})`}>
              <polygon points="23,0 33,10 23,20 13,10" stroke={stroke} strokeWidth="0.9" fill="none" />
              <polygon points="23,4 29,10 23,16 17,10" stroke={stroke} strokeWidth="0.5" fill="none" />
              <line x1="23" y1="0" x2="23" y2="20" stroke={stroke} strokeWidth="0.4" />
              <line x1="13" y1="10" x2="33" y2="10" stroke={stroke} strokeWidth="0.4" />
            </g>
          );
        })
      )}
    </svg>
  );
}

// ─── Status bar ───────────────────────────────────────────────────────────────
function StatusBar({ light = false, dark = false }: { light?: boolean; dark?: boolean }) {
  const col = light ? "rgba(255,255,255,0.75)" : dark ? "rgba(245,240,232,0.6)" : C.textTert;
  return (
    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "14px 24px 4px", position: "relative", zIndex: 10 }}>
      <span style={{ fontSize: 15, fontWeight: 600, color: col }}>9:41</span>
      <div style={{ display: "flex", alignItems: "center", gap: 6, color: col }}>
        <svg width="17" height="11" viewBox="0 0 17 11"><rect x="0" y="3" width="3" height="8" rx="1" fill="currentColor" opacity="0.35"/><rect x="4.5" y="1.5" width="3" height="9.5" rx="1" fill="currentColor" opacity="0.6"/><rect x="9" y="0" width="3" height="11" rx="1" fill="currentColor"/><rect x="13.5" y="4" width="3" height="7" rx="1" fill="currentColor" opacity="0.25"/></svg>
        <svg width="16" height="11" viewBox="0 0 16 11"><path d="M8 2C10.5 2 12.7 3.1 14.1 4.8L15.3 3.4C13.5 1.3 10.9 0 8 0 5.1 0 2.5 1.3.7 3.4L1.9 4.8C3.3 3.1 5.5 2 8 2z" fill="currentColor" opacity="0.4"/><path d="M8 5C9.7 5 11.2 5.7 12.3 6.9L13.5 5.5C12 4 10.1 3.1 8 3.1 5.9 3.1 4 4 2.5 5.5L3.7 6.9C4.8 5.7 6.3 5 8 5z" fill="currentColor" opacity="0.7"/><circle cx="8" cy="9.5" r="1.5" fill="currentColor"/></svg>
        <svg width="25" height="11" viewBox="0 0 25 11"><rect x=".5" y=".5" width="21" height="10" rx="3.5" stroke="currentColor" strokeOpacity="0.35"/><rect x="2" y="2" width="15" height="7" rx="2" fill="currentColor"/><path d="M23 3.5v4c.8-.3 1.5-1 1.5-2s-.7-1.7-1.5-2z" fill="currentColor" opacity="0.4"/></svg>
      </div>
    </div>
  );
}

// ─── Arc ring ─────────────────────────────────────────────────────────────────
function Arc({ p, size = 80, sw = 6, col = C.terra, bg = C.terraMuted, children }: { p: number; size?: number; sw?: number; col?: string; bg?: string; children?: React.ReactNode }) {
  const r = (size - sw) / 2, circ = 2 * Math.PI * r;
  return (
    <div style={{ position: "relative", width: size, height: size, flexShrink: 0 }}>
      <svg width={size} height={size} style={{ transform: "rotate(-90deg)" }}>
        <circle cx={size/2} cy={size/2} r={r} stroke={bg} strokeWidth={sw} fill="none"/>
        <circle cx={size/2} cy={size/2} r={r} stroke={col} strokeWidth={sw} fill="none" strokeDasharray={circ} strokeDashoffset={circ-(p/100)*circ} strokeLinecap="round" style={{transition:"stroke-dashoffset 0.8s cubic-bezier(0.34,1.56,0.64,1)"}}/>
      </svg>
      <div style={{ position:"absolute", inset:0, display:"flex", alignItems:"center", justifyContent:"center" }}>{children}</div>
    </div>
  );
}

// ─── Progress bar ─────────────────────────────────────────────────────────────
function ProgBar({ step, total = 5, col = C.terra }: { step: number; total?: number; col?: string }) {
  return (
    <div style={{ display:"flex", gap:4, flex:1 }}>
      {Array.from({length:total}).map((_,i) => (
        <div key={i} style={{ flex:1, height:4, borderRadius:2, background:i<step?col:C.surfMuted, transition:"background 0.3s cubic-bezier(0.34,1.56,0.64,1)" }}/>
      ))}
    </div>
  );
}

// ─── Primary Button ───────────────────────────────────────────────────────────
function Btn({ ch, onClick, full, col = C.terra, tc = "#fff", sm }: { ch: React.ReactNode; onClick?: () => void; full?: boolean; col?: string; tc?: string; sm?: boolean }) {
  const [pr, setPr] = useState(false);
  return (
    <button onClick={onClick} onPointerDown={() => setPr(true)} onPointerUp={() => setPr(false)} onPointerLeave={() => setPr(false)}
      style={{ background:col, color:tc, borderRadius:14, fontWeight:600, fontSize:sm?15:17, padding:sm?"12px 20px":"15px 28px", width:full?"100%":undefined, border:"none", cursor:"pointer", transform:pr?"scale(0.97)":"scale(1)", transition:"transform 0.15s cubic-bezier(0.34,1.56,0.64,1)", letterSpacing:"-0.2px", fontFamily:"inherit" }}>
      {ch}
    </button>
  );
}

// ─── Chip ─────────────────────────────────────────────────────────────────────
function Chip({ ch, col = C.terra, bg = C.terraMuted }: { ch: React.ReactNode; col?: string; bg?: string }) {
  return <span style={{ background:bg, color:col, borderRadius:20, padding:"4px 10px", fontSize:12, fontWeight:700 }}>{ch}</span>;
}

// ─── Tab bar ──────────────────────────────────────────────────────────────────
function TabBar({ tab, onTab, accent }: { tab: Tab; onTab: (t: Tab) => void; accent: string }) {
  const tabs: { id: Tab; label: string; path: string }[] = [
    { id:"home", label:"Главная", path:"M3 10.5L12 3L21 10.5V20a1 1 0 01-1 1h-5v-5H9v5H4a1 1 0 01-1-1V10.5z" },
    { id:"worlds", label:"Миры", path:"M12 22a10 10 0 100-20 10 10 0 000 20zM2 12h20M12 2c-2.5 3-4 6.3-4 10s1.5 7 4 10c2.5-3 4-6.3 4-10S14.5 5 12 2z" },
    { id:"repeat", label:"Повтор", path:"M4 7h10a6 6 0 010 12H4M7 4L4 7l3 3" },
    { id:"profile", label:"Профиль", path:"M12 4a4 4 0 100 8 4 4 0 000-8zM4 20c0-3.3 3.6-6 8-6s8 2.7 8 6" },
  ];
  return (
    <div style={{ background:C.bgEl, borderTop:`1px solid ${C.sep}`, display:"flex", paddingBottom:20, paddingTop:8, flexShrink:0 }}>
      {tabs.map(t => {
        const act = tab === t.id;
        return (
          <button key={t.id} onClick={() => onTab(t.id)} style={{ flex:1, background:"none", border:"none", cursor:"pointer", display:"flex", flexDirection:"column", alignItems:"center", gap:2, color:act?accent:C.textTert, transition:"color 0.2s", fontFamily:"inherit" }}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
              <path d={t.path}/>
            </svg>
            <span style={{ fontSize:10, fontWeight:600, letterSpacing:"0.2px" }}>{t.label}</span>
          </button>
        );
      })}
    </div>
  );
}

// ════════════════════════════════════════════════════════════════════════════════
// SCREENS
// ════════════════════════════════════════════════════════════════════════════════

// ─── Splash ───────────────────────────────────────────────────────────────────
function SplashScreen({ onDone }: { onDone: () => void }) {
  const show = useAnimIn(100);
  useEffect(() => { const t = setTimeout(onDone, 2200); return () => clearTimeout(t); }, [onDone]);
  return (
    <div style={{ flex:1, background:C.terra, display:"flex", flexDirection:"column", alignItems:"center", justifyContent:"center", gap:20, position:"relative", overflow:"hidden" }}>
      <Ornament opacity={0.08} light />
      <div style={{ ...spring(show), display:"flex", flexDirection:"column", alignItems:"center", gap:16, position:"relative", zIndex:1 }}>
        <AppIcon size={96} />
        <div>
          <div style={{ fontSize:34, fontWeight:700, color:"#fff", letterSpacing:"-0.4px", textAlign:"center" }}>Нохчийн</div>
          <div style={{ fontSize:16, color:"rgba(255,255,255,0.7)", textAlign:"center", marginTop:4 }}>Учи чеченский язык</div>
        </div>
      </div>
      <div style={{ position:"absolute", bottom:48, left:"50%", transform:"translateX(-50%)" }}>
        <div style={{ width:32, height:3, borderRadius:2, background:"rgba(255,255,255,0.4)" }}/>
      </div>
    </div>
  );
}

// ─── Onboarding ───────────────────────────────────────────────────────────────
function OnboardingScreen({ onMode }: { onMode: (m: Mode) => void }) {
  const [sel, setSel] = useState<Mode | null>(null);
  const [step, setStep] = useState(0);
  const show = useAnimIn(80);

  if (step === 1) return <AgeScreen mode={sel!} onDone={onMode} />;

  return (
    <div style={{ flex:1, background:C.bg, display:"flex", flexDirection:"column", position:"relative", overflow:"hidden" }}>
      <Ornament />
      <StatusBar />
      <div style={{ flex:1, display:"flex", flexDirection:"column", padding:"28px 24px 40px", position:"relative", zIndex:1 }}>
        <div style={{ display:"flex", alignItems:"center", gap:10, marginBottom:36 }}>
          <AppIcon size={44} />
          <div>
            <div style={{ fontSize:18, fontWeight:700, color:C.text, letterSpacing:"-0.2px" }}>Нохчийн</div>
            <div style={{ fontSize:12, color:C.textTert, fontWeight:500 }}>Чеченский язык · {formatWordCount(FULL_DICTIONARY.length)}+ слов</div>
          </div>
        </div>

        <div style={{ ...spring(show) }}>
          <div style={{ fontSize:34, fontWeight:700, color:C.text, letterSpacing:"-0.4px", lineHeight:1.15, marginBottom:10 }}>
            Сайн дог ду хьуна
          </div>
          <div style={{ fontSize:17, color:C.textSec, marginBottom:4 }}>Рады тебя видеть!</div>
          <div style={{ fontSize:15, color:C.textTert, lineHeight:1.5, marginBottom:36 }}>
            Выбери трек — мы подберём уроки и темп специально для тебя.
          </div>

          <div style={{ display:"flex", flexDirection:"column", gap:12, marginBottom:32 }}>
            {([
              { m:"adult" as Mode, label:"Взрослый трек", sub:"SRS, культурные капсулы, инсайты", emoji:"📚", badge:"17+" },
              { m:"kids" as Mode, label:"Детский трек", sub:"Маскот-лис 🦊, игровой формат", emoji:"🎮", badge:"3–12" },
            ]).map(({ m, label, sub, emoji, badge }) => (
              <button key={m} onClick={() => { setSel(m); setStep(1); }}
                style={{ background:C.surface, border:`1.5px solid ${sel===m?C.terra:"rgba(61,56,50,0.1)"}`, borderRadius:20, padding:"20px", display:"flex", alignItems:"center", gap:14, cursor:"pointer", textAlign:"left", transition:"border-color 0.2s, transform 0.15s", fontFamily:"inherit" }}>
                <div style={{ width:52, height:52, borderRadius:15, background:m==="kids"?C.meadowMuted:C.terraMuted, display:"flex", alignItems:"center", justifyContent:"center", fontSize:26 }}>{emoji}</div>
                <div style={{ flex:1 }}>
                  <div style={{ display:"flex", alignItems:"center", gap:8, marginBottom:3 }}>
                    <span style={{ fontSize:17, fontWeight:600, color:C.text }}>{label}</span>
                    <Chip ch={badge} col={m==="kids"?C.meadow:C.terra} bg={m==="kids"?C.meadowMuted:C.terraMuted} />
                  </div>
                  <div style={{ fontSize:13, color:C.textTert }}>{sub}</div>
                </div>
                <svg width="18" height="18" viewBox="0 0 18 18" fill="none"><path d="M7 4l5 5-5 5" stroke={C.textTert} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/></svg>
              </button>
            ))}
          </div>

          {/* Feature row */}
          <div style={{ display:"flex", gap:8 }}>
            {[["🔁","SM-2 SRS"],["📴","Офлайн"],["🏔️","Культура"]].map(([e,l]) => (
              <div key={l} style={{ flex:1, background:C.surfMuted, borderRadius:12, padding:"10px 6px", display:"flex", flexDirection:"column", alignItems:"center", gap:4 }}>
                <span style={{ fontSize:20 }}>{e}</span>
                <span style={{ fontSize:10, color:C.textTert, fontWeight:600, textAlign:"center" }}>{l}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Age picker ───────────────────────────────────────────────────────────────
function AgeScreen({ mode, onDone }: { mode: Mode; onDone: (m: Mode) => void }) {
  const show = useAnimIn(50);
  const groups = mode === "kids"
    ? [{ label:"3–6 лет", sub:"Первые слова", emoji:"🐣" },{ label:"6–9 лет", sub:"Базовые фразы", emoji:"🌱" },{ label:"9–12 лет", sub:"Простые предложения", emoji:"🌿" }]
    : [{ label:"Новичок", sub:"Ни разу не слышал", emoji:"🌱" },{ label:"Начинающий", sub:"Несколько слов", emoji:"🏔️" },{ label:"Наследный носитель", sub:"Слышу дома, не говорю", emoji:"🏡" }];
  const accent = mode === "kids" ? C.meadow : C.terra;

  return (
    <div style={{ flex:1, background:C.bg, display:"flex", flexDirection:"column", position:"relative", overflow:"hidden" }}>
      <Ornament />
      <StatusBar />
      <div style={{ flex:1, display:"flex", flexDirection:"column", padding:"16px 24px 36px", position:"relative", zIndex:1 }}>
        <div style={{ marginBottom:24 }}>
          <div style={{ fontSize:28, fontWeight:700, color:C.text, letterSpacing:"-0.3px", marginBottom:6 }}>
            {mode === "kids" ? "Сколько лет?" : "Твой уровень?"}
          </div>
          <div style={{ fontSize:15, color:C.textTert }}>Подберём темп и контент</div>
        </div>

        <div style={{ ...spring(show), display:"flex", flexDirection:"column", gap:10, marginBottom:"auto" }}>
          {groups.map(({ label, sub, emoji }) => (
            <button key={label} onClick={() => onDone(mode)}
              style={{ background:C.surface, border:"1.5px solid rgba(61,56,50,0.1)", borderRadius:16, padding:"18px 18px", display:"flex", alignItems:"center", gap:14, cursor:"pointer", textAlign:"left", transition:"border-color 0.2s", fontFamily:"inherit" }}
              onPointerEnter={e => e.currentTarget.style.borderColor = accent}
              onPointerLeave={e => e.currentTarget.style.borderColor = "rgba(61,56,50,0.1)"}>
              <div style={{ fontSize:32 }}>{emoji}</div>
              <div>
                <div style={{ fontSize:16, fontWeight:600, color:C.text }}>{label}</div>
                <div style={{ fontSize:13, color:C.textTert, marginTop:2 }}>{sub}</div>
              </div>
            </button>
          ))}
        </div>

        <div style={{ marginTop:24 }}>
          <Btn ch="Начать обучение →" full onClick={() => onDone(mode)} col={accent} />
        </div>
      </div>
    </div>
  );
}

// ─── Home ─────────────────────────────────────────────────────────────────────
function HomeScreen({ mode, nav }: { mode: Mode; nav: (s: Screen) => void }) {
  const accent = mode === "kids" ? C.meadow : C.terra;
  const acMuted = mode === "kids" ? C.meadowMuted : C.terraMuted;
  const weekXP = [45,70,55,90,30,80,60];
  const days = ["Пн","Вт","Ср","Чт","Пт","Сб","Вс"];
  const maxXP = Math.max(...weekXP);
  const show = useAnimIn(50);

  return (
    <div style={{ flex:1, overflowY:"auto", background:C.bg, scrollbarWidth:"none" }}>
      <StatusBar />
      <div style={{ padding:"8px 20px 24px" }}>
        {/* Header */}
        <div style={{ display:"flex", justifyContent:"space-between", alignItems:"flex-start", marginBottom:18, ...spring(show) }}>
          <div>
            <div style={{ fontSize:13, color:C.textTert, fontWeight:500, marginBottom:2 }}>{mode==="kids"?"Привет, Аслан 🦊":"Доброе утро"}</div>
            <div style={{ fontSize:26, fontWeight:700, color:C.text, letterSpacing:"-0.3px" }}>Аслан</div>
          </div>
          <div style={{ display:"flex", gap:8 }}>
            <div onClick={() => nav("profile")} style={{ background:acMuted, borderRadius:20, padding:"7px 12px", display:"flex", alignItems:"center", gap:5, cursor:"pointer" }}>
              <span style={{ fontSize:15 }}>🔥</span>
              <span style={{ fontSize:14, fontWeight:700, color:accent }}>12</span>
            </div>
            <div style={{ background:C.goldMuted, borderRadius:20, padding:"7px 12px", display:"flex", alignItems:"center", gap:5 }}>
              <span style={{ fontSize:14 }}>💰</span>
              <span style={{ fontSize:14, fontWeight:700, color:C.gold }}>340</span>
            </div>
          </div>
        </div>

        {/* Continue */}
        <div onClick={() => nav("flashcard")} style={{ background:accent, borderRadius:22, padding:"22px 22px", marginBottom:14, cursor:"pointer", position:"relative", overflow:"hidden", ...spring(show) }}>
          <div style={{ position:"absolute", right:-30, top:-30, width:140, height:140, borderRadius:"50%", background:"rgba(255,255,255,0.1)" }}/>
          <div style={{ position:"absolute", right:20, bottom:-20, width:90, height:90, borderRadius:"50%", background:"rgba(255,255,255,0.07)" }}/>
          <div style={{ fontSize:11, color:"rgba(255,255,255,0.7)", fontWeight:700, letterSpacing:"1px", marginBottom:5 }}>ПРОДОЛЖИТЬ УРОК</div>
          <div style={{ fontSize:20, fontWeight:700, color:"#fff", marginBottom:12, letterSpacing:"-0.2px" }}>
            {mode==="kids"?"Лесные звери 🦊":"Числа и счёт"}
          </div>
          <ProgBar step={2} col="rgba(255,255,255,0.9)" />
          <div style={{ fontSize:12, color:"rgba(255,255,255,0.65)", marginTop:6 }}>Урок 3 · 2 из 5 шагов</div>
        </div>

        {/* Gifts row */}
        <div style={{ display:"flex", gap:10, marginBottom:14, ...spring(show) }}>
          <div onClick={() => nav("culture")} style={{ flex:1, background:"linear-gradient(135deg,#5C3D2E,#8B5E3C)", borderRadius:16, padding:"14px", cursor:"pointer" }}>
            <div style={{ fontSize:22 }}>🏛️</div>
            <div style={{ fontSize:13, fontWeight:600, color:"#fff", marginTop:6 }}>Капсула</div>
            <div style={{ fontSize:11, color:"rgba(255,255,255,0.6)" }}>Гостеприимство</div>
          </div>
          <div style={{ flex:1, background:C.surface, borderRadius:16, padding:"14px", border:`1px solid ${C.sep}` }}>
            <div style={{ fontSize:22 }}>🎁</div>
            <div style={{ fontSize:13, fontWeight:600, color:C.text, marginTop:6 }}>Подарок</div>
            <div style={{ fontSize:11, color:C.textTert }}>Через 4 ч</div>
          </div>
          <div onClick={() => nav("dictionary")} style={{ flex:1, background:C.surface, borderRadius:16, padding:"14px", border:`1px solid ${C.sep}`, cursor:"pointer" }}>
            <div style={{ fontSize:22 }}>📖</div>
            <div style={{ fontSize:13, fontWeight:600, color:C.text, marginTop:6 }}>Словарь</div>
            <div style={{ fontSize:11, color:C.textTert }}>{formatWordCount(FULL_DICTIONARY.length)} слов</div>
          </div>
        </div>

        {/* Weekly XP */}
        <div style={{ background:C.surface, borderRadius:20, padding:"18px 18px 14px", marginBottom:14, border:`1px solid ${C.sep}`, ...spring(show) }}>
          <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:14 }}>
            <div style={{ fontSize:14, fontWeight:700, color:C.text }}>XP за неделю</div>
            <Chip ch="530 XP" col={accent} bg={acMuted} />
          </div>
          <div style={{ display:"flex", alignItems:"flex-end", gap:5, height:64 }}>
            {weekXP.map((xp, i) => {
              const isToday = i === 5, h = (xp/maxXP)*56;
              return (
                <div key={i} style={{ flex:1, display:"flex", flexDirection:"column", alignItems:"center", gap:5 }}>
                  <div style={{ width:"100%", height:h, borderRadius:5, background:isToday?accent:acMuted, transition:"height 0.6s cubic-bezier(0.34,1.56,0.64,1)" }}/>
                  <span style={{ fontSize:10, color:isToday?accent:C.textTert, fontWeight:isToday?700:400 }}>{days[i]}</span>
                </div>
              );
            })}
          </div>
        </div>

        {/* Worlds strip */}
        <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:10 }}>
          <div style={{ fontSize:15, fontWeight:700, color:C.text }}>Миры</div>
          <button onClick={() => nav("worlds")} style={{ background:"none", border:"none", cursor:"pointer", fontSize:13, color:accent, fontWeight:600, fontFamily:"inherit" }}>Все →</button>
        </div>
        <div style={{ display:"flex", flexDirection:"column", gap:10 }}>
          {WORLDS.slice(0,3).map(w => (
            <div key={w.title} onClick={() => nav("path")} style={{ background:C.surface, borderRadius:16, padding:"14px 16px", display:"flex", alignItems:"center", gap:12, cursor:"pointer", border:`1px solid ${C.sep}` }}>
              <div style={{ width:44, height:44, borderRadius:12, background:w.color+"22", display:"flex", alignItems:"center", justifyContent:"center", fontSize:22 }}>{w.emoji}</div>
              <div style={{ flex:1 }}>
                <div style={{ fontSize:14, fontWeight:600, color:C.text, marginBottom:5 }}>{w.title}</div>
                <div style={{ height:4, borderRadius:2, background:C.surfMuted }}>
                  <div style={{ height:"100%", width:`${w.prog}%`, background:w.color, borderRadius:2, transition:"width 0.6s" }}/>
                </div>
              </div>
              <div style={{ fontSize:13, fontWeight:700, color:w.color }}>{w.prog}%</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ─── Learning path ────────────────────────────────────────────────────────────
function PathScreen({ mode, nav }: { mode: Mode; nav: (s: Screen) => void }) {
  const accent = mode === "kids" ? C.meadow : C.terra;
  const show = useAnimIn(50);
  return (
    <div style={{ flex:1, background:C.bg, display:"flex", flexDirection:"column", overflowY:"auto", scrollbarWidth:"none" }}>
      <StatusBar />
      <div style={{ padding:"8px 24px 0" }}>
        <div style={{ fontSize:26, fontWeight:700, color:C.text, letterSpacing:"-0.3px", marginBottom:2 }}>Путь обучения</div>
        <div style={{ fontSize:13, color:C.textTert, marginBottom:8 }}>Мир 1 · Повседневная жизнь</div>
        {/* Progress bar for world */}
        <div style={{ display:"flex", alignItems:"center", gap:10, marginBottom:20 }}>
          <ProgBar step={2} total={7} col={accent} />
          <span style={{ fontSize:12, color:C.textTert, whiteSpace:"nowrap", fontWeight:600 }}>2 / 7 уроков</span>
        </div>
      </div>

      {/* Path canvas */}
      <div style={{ position:"relative", height:560, margin:"0 0 0", ...spring(show) }}>
        <svg style={{ position:"absolute", inset:0, width:"100%", height:"100%", pointerEvents:"none" }} viewBox="0 0 390 560" fill="none">
          {PATH_NODES.slice(0,-1).map((nd, i) => {
            const nx = PATH_NODES[i+1];
            const x1 = (nd.x/100)*390, y1 = (nd.y/100)*540+10;
            const x2 = (nx.x/100)*390, y2 = (nx.y/100)*540+10;
            const lk = nd.status==="locked"||nx.status==="locked";
            return (
              <path key={i} d={`M${x1} ${y1} C${x1} ${(y1+y2)/2} ${x2} ${(y1+y2)/2} ${x2} ${y2}`}
                stroke={lk?"rgba(61,56,50,0.18)":accent} strokeWidth="2.5" strokeDasharray={lk?"7 5":undefined} strokeLinecap="round"/>
            );
          })}
        </svg>

        {PATH_NODES.map(nd => {
          const x = (nd.x/100)*100, y = (nd.y/100)*100;
          const done = nd.status==="completed", curr = nd.status==="current", lk = nd.status==="locked";
          return (
            <div key={nd.id} onClick={() => !lk && nav("flashcard")}
              style={{ position:"absolute", left:`${x}%`, top:`${y}%`, transform:"translate(-50%,-50%)", display:"flex", flexDirection:"column", alignItems:"center", gap:6, cursor:lk?"default":"pointer" }}>
              {curr && <div style={{ position:"absolute", width:68, height:68, borderRadius:"50%", background:accent+"25", animation:"nodePulse 2s infinite" }}/>}
              <div style={{ width:54, height:54, borderRadius:"50%", background:done?accent:curr?"#fff":C.surfMuted, border:curr?`2.5px solid ${accent}`:done?"none":"2px solid rgba(61,56,50,0.14)", display:"flex", alignItems:"center", justifyContent:"center", fontSize:22, position:"relative", zIndex:1, boxShadow:curr?`0 0 0 5px ${accent}20`:undefined }}>
                {done ? <svg width="22" height="22" viewBox="0 0 22 22" fill="none"><path d="M5 11l4 4 8-8" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
                  : lk ? <svg width="17" height="17" viewBox="0 0 17 17" fill="none"><rect x="3" y="7.5" width="11" height="8" rx="2" stroke="rgba(61,56,50,0.3)" strokeWidth="1.5"/><path d="M5.5 7.5V5C5.5 3.1 11.5 3.1 11.5 5v2.5" stroke="rgba(61,56,50,0.3)" strokeWidth="1.5" strokeLinecap="round"/></svg>
                  : <span>{nd.emoji}</span>}
              </div>
              <div style={{ fontSize:10, fontWeight:600, color:lk?C.textTert:C.text, textAlign:"center", maxWidth:60 }}>{nd.label}</div>
            </div>
          );
        })}
      </div>

      {/* Culture capsule teaser */}
      <div onClick={() => nav("culture")} style={{ margin:"0 20px 20px", background:"linear-gradient(135deg,#4A2E1E,#7A4E32)", borderRadius:18, padding:"18px 20px", cursor:"pointer", display:"flex", alignItems:"center", gap:14 }}>
        <div style={{ width:48, height:48, borderRadius:14, background:"rgba(255,255,255,0.12)", display:"flex", alignItems:"center", justifyContent:"center", fontSize:26 }}>🏛️</div>
        <div style={{ flex:1 }}>
          <div style={{ fontSize:11, color:"rgba(255,255,255,0.55)", fontWeight:700, letterSpacing:"1px", marginBottom:3 }}>КУЛЬТУРНАЯ КАПСУЛА</div>
          <div style={{ fontSize:15, fontWeight:600, color:"#fff" }}>Гостеприимство · Адат</div>
          <div style={{ fontSize:12, color:"rgba(255,255,255,0.5)", marginTop:1 }}>Традиции чеченской культуры</div>
        </div>
        <svg width="18" height="18" viewBox="0 0 18 18" fill="none"><path d="M7 4l5 5-5 5" stroke="rgba(255,255,255,0.5)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>
      </div>
      <style>{`@keyframes nodePulse{0%,100%{transform:translate(-50%,-50%) scale(1);opacity:.6}50%{transform:translate(-50%,-50%) scale(1.25);opacity:.25}}`}</style>
    </div>
  );
}

// ─── Flashcard ────────────────────────────────────────────────────────────────
function FlashcardScreen({ mode, nav }: { mode: Mode; nav: (s: Screen) => void }) {
  const accent = mode === "kids" ? C.meadow : C.terra;
  const [idx, setIdx] = useState(0);
  const [flipped, setFlipped] = useState(false);
  const [step, setStep] = useState(1);
  const [exit, setExit] = useState<"left"|"right"|null>(null);
  const word = WORDS[idx % WORDS.length];

  const next = (dir: "left"|"right") => {
    setExit(dir);
    setTimeout(() => {
      setFlipped(false); setExit(null);
      setIdx(i => (i+1) % WORDS.length);
      const ns = Math.min(step+1, 5);
      setStep(ns);
      if (ns >= 5) nav("quiz");
    }, 280);
  };

  const faceBase: React.CSSProperties = {
    position: "absolute",
    inset: 0,
    borderRadius: 26,
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    gap: 16,
    backfaceVisibility: "hidden",
  };

  return (
    <div style={{ flex:1, minHeight:0, background:C.bg, display:"flex", flexDirection:"column" }}>
      <StatusBar />
      <div style={{ padding:"10px 20px", display:"flex", alignItems:"center", gap:12, flexShrink:0 }}>
        <button onClick={() => nav("path")} style={{ background:"none", border:"none", cursor:"pointer", color:C.textTert, lineHeight:0 }}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M15 19L8 12L15 5"/></svg>
        </button>
        <ProgBar step={step} col={accent} />
        <span style={{ fontSize:12, color:C.textTert, fontWeight:600, whiteSpace:"nowrap" }}>{step}/5</span>
      </div>

      <div style={{ flex:1, minHeight:0, display:"flex", flexDirection:"column", padding:"12px 20px 24px" }}>
        <div style={{ textAlign:"center", marginBottom:8, flexShrink:0 }}>
          <span style={{ fontSize:13, color:C.textTert, fontWeight:500 }}>Слова · {idx+1} / {WORDS.length}</span>
        </div>

        {/* Card area — фиксированная зона, кнопки не пересекаются */}
        <div
          onClick={() => setFlipped(!flipped)}
          style={{
            flex:"1 1 0",
            minHeight: 280,
            marginBottom: 16,
            cursor: "pointer",
            perspective: 1000,
            transform: exit ? `translateX(${exit==="left"?"-120%":"120%"}) rotate(${exit==="left"?-8:8}deg)` : "none",
            transition: exit ? "transform 0.28s ease-in" : "none",
          }}
        >
          <div style={{
            width: "100%",
            height: "100%",
            position: "relative",
            transformStyle: "preserve-3d",
            transition: "transform 0.45s cubic-bezier(0.34,1.2,0.64,1)",
            transform: flipped ? "rotateY(180deg)" : "rotateY(0deg)",
          }}>
            {/* Front */}
            <div style={{
              ...faceBase,
              background: C.surface,
              border: `1.5px solid ${C.sep}`,
              transform: "rotateY(0deg)",
              visibility: flipped ? "hidden" : "visible",
            }}>
              <div style={{ fontSize: 80, lineHeight: 1 }}>{word.emoji}</div>
              <div>
                <div style={{ fontSize: 30, fontWeight: 700, color: C.text, textAlign: "center", letterSpacing: "0.3px" }}>{word.ce}</div>
                <div style={{ fontSize: 14, color: C.textTert, textAlign: "center", marginTop: 4, letterSpacing: "0.5px" }}>[{word.tr}]</div>
              </div>
              <Chip ch={word.cat} col={C.textTert} bg={C.surfMuted} />
              <div style={{ position: "absolute", bottom: 20, left: 0, right: 0, display: "flex", alignItems: "center", justifyContent: "center", gap: 6 }}>
                <div style={{ width: 20, height: 20, borderRadius: "50%", background: C.surfMuted, display: "flex", alignItems: "center", justifyContent: "center" }}>
                  <svg width="10" height="10" viewBox="0 0 10 10" fill="none"><path d="M5 1v4l3 1.5" stroke={C.textTert} strokeWidth="1.5" strokeLinecap="round"/></svg>
                </div>
                <span style={{ fontSize: 11, color: C.textTert }}>Нажми, чтобы перевернуть</span>
              </div>
            </div>
            {/* Back */}
            <div style={{
              ...faceBase,
              background: accent,
              transform: "rotateY(180deg)",
              visibility: flipped ? "visible" : "hidden",
            }}>
              <div style={{ fontSize: 80, lineHeight: 1 }}>{word.emoji}</div>
              <div style={{ fontSize: 34, fontWeight: 700, color: "#fff", textAlign: "center" }}>{word.ru}</div>
              <div style={{ fontSize: 15, color: "rgba(255,255,255,0.7)", letterSpacing: "0.5px" }}>[{word.tr}]</div>
            </div>
          </div>
        </div>

        {/* Actions — всегда под карточкой */}
        <div style={{ display: "flex", gap: 12, flexShrink: 0 }}>
          <button onClick={() => next("right")} style={{ flex:1, background:C.terraMuted, color:C.terra, border:"none", borderRadius:14, padding:"15px", fontSize:15, fontWeight:600, cursor:"pointer", fontFamily:"inherit" }}>↻ Повторить</button>
          <button onClick={() => next("left")} style={{ flex:1, background:accent, color:"#fff", border:"none", borderRadius:14, padding:"15px", fontSize:15, fontWeight:600, cursor:"pointer", fontFamily:"inherit" }}>✓ Знаю</button>
        </div>
      </div>
    </div>
  );
}

// ─── Match pairs ──────────────────────────────────────────────────────────────
function MatchScreen({ mode, nav }: { mode: Mode; nav: (s: Screen) => void }) {
  const accent = mode === "kids" ? C.meadow : C.terra;
  const acMuted = mode === "kids" ? C.meadowMuted : C.terraMuted;
  const [selCE, setSelCE] = useState<number|null>(null);
  const [selRU, setSelRU] = useState<number|null>(null);
  const [matched, setMatched] = useState<number[]>([]);
  const [wrong, setWrong] = useState(false);

  useEffect(() => {
    if (selCE !== null && selRU !== null) {
      if (selCE === selRU) {
        const nm = [...matched, selCE];
        setMatched(nm);
        setSelCE(null); setSelRU(null);
        if (nm.length === MATCH_PAIRS.length) setTimeout(() => nav("reward"), 600);
      } else {
        setWrong(true);
        setTimeout(() => { setSelCE(null); setSelRU(null); setWrong(false); }, 700);
      }
    }
  }, [selCE, selRU]);

  const card = (label: string, idx: number, side: "ce"|"ru", sel: number|null, setSel: (i: number|null) => void) => {
    const isMatched = matched.includes(idx);
    const isSel = sel === idx;
    const isWrong = wrong && isSel;
    return (
      <button key={label} onClick={() => !isMatched && setSel(isSel ? null : idx)}
        style={{ background: isMatched ? acMuted : isSel ? accent : C.surface, color: isMatched ? accent : isSel ? "#fff" : C.text,
          border: `2px solid ${isMatched ? accent+"55" : isSel ? accent : isWrong ? C.err : "rgba(61,56,50,0.1)"}`,
          borderRadius:14, padding:"18px 14px", fontSize:16, fontWeight:600, cursor:isMatched?"default":"pointer",
          opacity:isMatched?0.6:1, textAlign:"center", fontFamily:"inherit", transform:isWrong?"translateX(-4px)":"none", transition:"all 0.2s" }}>
        {label}
      </button>
    );
  };

  return (
    <div style={{ flex:1, background:C.bg, display:"flex", flexDirection:"column" }}>
      <StatusBar />
      <div style={{ padding:"10px 20px", display:"flex", alignItems:"center", gap:12 }}>
        <button onClick={() => nav("path")} style={{ background:"none", border:"none", cursor:"pointer", color:C.textTert, lineHeight:0 }}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M15 19L8 12L15 5"/></svg>
        </button>
        <ProgBar step={4} col={accent} />
      </div>
      <div style={{ padding:"12px 20px 24px", flex:1 }}>
        <div style={{ fontSize:22, fontWeight:700, color:C.text, letterSpacing:"-0.2px", marginBottom:6 }}>Найди пары</div>
        <div style={{ fontSize:14, color:C.textTert, marginBottom:28 }}>Чеченский ↔ Русский</div>
        <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:10 }}>
          <div style={{ display:"flex", flexDirection:"column", gap:10 }}>
            <div style={{ fontSize:11, color:C.textTert, fontWeight:700, letterSpacing:"0.5px", marginBottom:4 }}>ЧЕЧЕНСКИЙ</div>
            {MATCH_PAIRS.map((p,i) => card(p.ce, i, "ce", selCE, setSelCE))}
          </div>
          <div style={{ display:"flex", flexDirection:"column", gap:10 }}>
            <div style={{ fontSize:11, color:C.textTert, fontWeight:700, letterSpacing:"0.5px", marginBottom:4 }}>РУССКИЙ</div>
            {MATCH_PAIRS.map((p,i) => card(p.ru, i, "ru", selRU, setSelRU))}
          </div>
        </div>
        <div style={{ marginTop:24, textAlign:"center", fontSize:14, color:C.textTert }}>
          {matched.length} / {MATCH_PAIRS.length} совпадений
        </div>
      </div>
    </div>
  );
}

// ─── Quiz ─────────────────────────────────────────────────────────────────────
function QuizScreen({ mode, nav }: { mode: Mode; nav: (s: Screen) => void }) {
  const accent = mode === "kids" ? C.meadow : C.terra;
  const [sel, setSel] = useState<number|null>(null);
  const [qIdx, setQIdx] = useState(0);
  const [step, setStep] = useState(5);
  const [score, setScore] = useState(0);
  const [wrong, setWrong] = useState(false);
  const show = useAnimIn(50);
  const q = QUIZ_QUESTIONS[qIdx];

  const choose = (i: number) => {
    if (sel !== null) return;
    setSel(i);
    if (i === q.correct) {
      setScore(s => s + 1);
      setTimeout(() => {
        if (qIdx + 1 >= QUIZ_QUESTIONS.length) {
          nav("reward");
        } else {
          setSel(null);
          setQIdx(idx => idx + 1);
          setStep(s => Math.min(s + 1, 10));
        }
      }, 900);
    } else {
      setWrong(true);
      setTimeout(() => { setWrong(false); setSel(null); }, 900);
    }
  };

  return (
    <div style={{ flex:1, background:C.bg, display:"flex", flexDirection:"column" }}>
      <StatusBar />
      <div style={{ padding:"10px 20px", display:"flex", alignItems:"center", gap:12 }}>
        <button onClick={() => nav("path")} style={{ background:"none", border:"none", cursor:"pointer", color:C.textTert, lineHeight:0 }}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M15 19L8 12L15 5"/></svg>
        </button>
        <ProgBar step={step} total={10} col={accent} />
        <span style={{ fontSize:12, color:C.textTert, fontWeight:600 }}>{qIdx+1}/{QUIZ_QUESTIONS.length}</span>
      </div>
      <div style={{ padding:"16px 20px 24px", flex:1, display:"flex", flexDirection:"column" }}>
        <div style={{ fontSize:12, color:C.textTert, fontWeight:700, letterSpacing:"1px", marginBottom:8 }}>ВОПРОС {qIdx+1}</div>
        <div key={qIdx} style={{ fontSize:22, fontWeight:700, color:C.text, letterSpacing:"-0.2px", marginBottom:22, ...spring(show) }}>
          {q.q}
        </div>
        <div key={"card-"+qIdx} style={{ background:C.surface, borderRadius:22, padding:"28px", marginBottom:28, display:"flex", flexDirection:"column", alignItems:"center", border:`1.5px solid ${C.sep}`, ...spring(show) }}>
          <div style={{ fontSize:52, marginBottom:10 }}>📖</div>
          <div style={{ fontSize:34, fontWeight:700, color:C.text, letterSpacing:"0.3px" }}>{q.ce}</div>
          <div style={{ fontSize:14, color:C.textTert, marginTop:6 }}>[{q.hint}]</div>
        </div>
        <div style={{ display:"flex", flexDirection:"column", gap:10 }}>
          {q.opts.map((opt, i) => {
            const isCorr = i === q.correct, isSel = sel === i;
            let bg = C.surface, border = `1.5px solid rgba(61,56,50,0.1)`, col = C.text;
            if (isSel && isCorr) { bg = "#E8F5EE"; border = `1.5px solid ${C.ok}`; col = C.ok; }
            if (isSel && !isCorr) { bg = "#FBF0F0"; border = `1.5px solid ${C.err}`; col = C.err; }
            if (wrong && isCorr) { bg = "#E8F5EE"; border = `1.5px solid ${C.ok}`; col = C.ok; }
            return (
              <button key={opt} onClick={() => choose(i)}
                style={{ background:bg, border, borderRadius:14, padding:"16px 18px", textAlign:"left", fontSize:16, fontWeight:500, color:col, cursor:sel===null?"pointer":"default", display:"flex", alignItems:"center", gap:12, transition:"all 0.22s", fontFamily:"inherit" }}>
                <div style={{ width:28, height:28, borderRadius:8, background:isSel?(isCorr?C.ok:C.err):C.surfMuted, color:isSel?"#fff":C.textTert, display:"flex", alignItems:"center", justifyContent:"center", fontSize:13, fontWeight:700, transition:"all 0.22s" }}>
                  {isSel ? (isCorr ? "✓" : "✗") : String.fromCharCode(65+i)}
                </div>
                {opt}
              </button>
            );
          })}
        </div>
        {wrong && (
          <div style={{ marginTop:16, textAlign:"center", fontSize:14, color:C.err, fontWeight:600 }}>
            Неверно. Попробуйте ещё раз.
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Culture Capsule ──────────────────────────────────────────────────────────
function CultureScreen({ nav }: { nav: (s: Screen) => void }) {
  const show = useAnimIn(100);
  return (
    <div style={{ flex:1, background:"#1E1510", display:"flex", flexDirection:"column", position:"relative", overflow:"hidden" }}>
      <Ornament opacity={0.055} light />
      <StatusBar dark />
      <div style={{ flex:1, overflowY:"auto", scrollbarWidth:"none", padding:"12px 24px 36px", position:"relative", zIndex:1 }}>
        <button onClick={() => nav("path")} style={{ background:"rgba(255,255,255,0.1)", border:"none", borderRadius:12, padding:"8px 14px", color:"rgba(255,255,255,0.65)", cursor:"pointer", fontSize:14, fontWeight:500, marginBottom:28, fontFamily:"inherit" }}>✕ Закрыть</button>

        <div style={{ ...spring(show) }}>
          <div style={{ fontSize:11, color:"#E8A87C", fontWeight:700, letterSpacing:"1.5px", marginBottom:10 }}>АДАТ · КУЛЬТУРА</div>
          <div style={{ fontSize:30, fontWeight:700, color:"#F5F0E8", letterSpacing:"-0.3px", lineHeight:1.2, marginBottom:24 }}>
            Гостеприимство — больше чем традиция
          </div>

          {/* Illustration */}
          <div style={{ width:"100%", borderRadius:20, overflow:"hidden", marginBottom:24, background:"linear-gradient(135deg,#5C3D2E 0%,#8B5E3C 50%,#6B4423 100%)", height:180, display:"flex", alignItems:"center", justifyContent:"center", position:"relative" }}>
            <div style={{ position:"absolute", inset:0, background:"url('data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 400 180\"><path d=\"M0 120 L80 60 L140 90 L200 40 L260 70 L320 30 L400 80 L400 180 L0 180Z\" fill=\"rgba(0,0,0,0.15)\"/></svg>')" }}/>
            <div style={{ fontSize:72, position:"relative", zIndex:1 }}>🏠</div>
          </div>

          <div style={{ fontSize:16, color:"rgba(245,240,232,0.85)", lineHeight:1.65, marginBottom:14 }}>
            В чеченской культуре гость — священен. Хозяин обязан принять любого путника, накормить и защитить — даже врага. Это не просто вежливость, это <span style={{ color:"#E8A87C", fontWeight:600 }}>хьост</span> — честь дома.
          </div>
          <div style={{ fontSize:15, color:"rgba(245,240,232,0.6)", lineHeight:1.65, marginBottom:28 }}>
            Стол накрывают быстро и щедро. Лучшее место, лучший кусок — гостю. Говорят: «<em>Гость — посланник Бога</em>». Отказать значит нанести обиду, которую помнят годами.
          </div>

          {/* Facts */}
          <div style={{ display:"flex", gap:10, marginBottom:28 }}>
            {[["🤝","Уважение"],["🍽️","Стол"],["🏔️","Нохчалла"]].map(([e,l]) => (
              <div key={l} style={{ flex:1, background:"rgba(255,255,255,0.07)", borderRadius:14, padding:"14px 10px", textAlign:"center" }}>
                <div style={{ fontSize:24, marginBottom:6 }}>{e}</div>
                <div style={{ fontSize:11, color:"rgba(255,255,255,0.5)", fontWeight:600 }}>{l}</div>
              </div>
            ))}
          </div>

          {/* Vocab highlight */}
          <div style={{ background:"rgba(232,168,124,0.12)", border:"1px solid rgba(232,168,124,0.25)", borderRadius:16, padding:"16px 18px", marginBottom:24 }}>
            <div style={{ fontSize:11, color:"#E8A87C", fontWeight:700, letterSpacing:"0.5px", marginBottom:8 }}>СЛОВО ИЗ КАПСУЛЫ</div>
            <div style={{ fontSize:24, fontWeight:700, color:"#F5F0E8", letterSpacing:"0.3px" }}>Хьаша</div>
            <div style={{ fontSize:14, color:"rgba(245,240,232,0.5)", marginTop:2 }}>Гость · [khyasha]</div>
          </div>

          <button onClick={() => nav("flashcard")} style={{ width:"100%", background:C.terra, color:"#fff", border:"none", borderRadius:14, padding:"16px", fontSize:17, fontWeight:600, cursor:"pointer", fontFamily:"inherit" }}>
            Продолжить →
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── Worlds ───────────────────────────────────────────────────────────────────
function WorldsScreen({ mode, nav }: { mode: Mode; nav: (s: Screen) => void }) {
  const accent = mode === "kids" ? C.meadow : C.terra;
  const show = useAnimIn(50);
  return (
    <div style={{ flex:1, overflowY:"auto", background:C.bg, scrollbarWidth:"none" }}>
      <StatusBar />
      <div style={{ padding:"8px 20px 24px" }}>
        <div style={{ fontSize:26, fontWeight:700, color:C.text, letterSpacing:"-0.3px", marginBottom:18 }}>Миры</div>
        <div style={{ display:"flex", flexDirection:"column", gap:14, ...spring(show) }}>
          {WORLDS.map((w, i) => (
            <div key={w.title} onClick={() => w.prog > 0 && nav("path")} style={{ background:C.surface, borderRadius:22, overflow:"hidden", cursor:w.prog>0?"pointer":"default", border:`1px solid ${C.sep}` }}>
              <div style={{ background:`linear-gradient(135deg,${w.color}DD,${w.color}99)`, padding:"22px 20px", display:"flex", alignItems:"center", justifyContent:"space-between" }}>
                <div>
                  <div style={{ fontSize:11, color:"rgba(255,255,255,0.65)", fontWeight:700, letterSpacing:"0.5px", marginBottom:5 }}>МИР {i+1}</div>
                  <div style={{ fontSize:19, fontWeight:700, color:"#fff", marginBottom:3 }}>{w.title}</div>
                  <div style={{ fontSize:12, color:"rgba(255,255,255,0.65)" }}>{w.desc}</div>
                </div>
                <Arc p={w.prog} size={70} sw={5} col="#fff" bg="rgba(255,255,255,0.25)">
                  <span style={{ fontSize:26 }}>{w.emoji}</span>
                </Arc>
              </div>
              <div style={{ padding:"12px 20px", display:"flex", alignItems:"center", justifyContent:"space-between" }}>
                <div style={{ fontSize:13, color:C.textSec }}>{w.prog>0?`${w.prog}% · ${w.lessons} уроков`:`Заблокировано · ${w.lessons} уроков`}</div>
                {w.prog>0 ? <span style={{ fontSize:13, fontWeight:600, color:accent }}>Продолжить →</span>
                  : <svg width="14" height="16" viewBox="0 0 14 16" fill="none"><rect x="1" y="7" width="12" height="9" rx="2" stroke="rgba(61,56,50,0.3)" strokeWidth="1.5"/><path d="M4 7V5C4 2.8 10 2.8 10 5v2" stroke="rgba(61,56,50,0.3)" strokeWidth="1.5" strokeLinecap="round"/></svg>}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ─── Dictionary ───────────────────────────────────────────────────────────────
const DICT_ROW_H = 76;

function DictionaryScreen({ nav }: { nav: (s: Screen) => void }) {
  const [q, setQ] = useState("");
  const [verifiedOnly, setVerifiedOnly] = useState(false);
  const listRef = useRef<HTMLDivElement>(null);
  const [scrollTop, setScrollTop] = useState(0);
  const [viewportH, setViewportH] = useState(520);
  const [dictLoaded, setDictLoaded] = useState(FULL_DICTIONARY.length > 0);

  const source = verifiedOnly ? FULL_DICTIONARY.filter((w) => w.verified) : FULL_DICTIONARY;

  const filtered = useMemo(() => {
    const qq = q.trim().toLowerCase();
    if (!qq) return source;
    return source.filter(
      (w) =>
        w.ce.toLowerCase().includes(qq) ||
        w.ru.toLowerCase().includes(qq) ||
        (w.tr ?? "").toLowerCase().includes(qq)
    );
  }, [q, source]);

  useEffect(() => {
    const el = listRef.current;
    if (!el) return;
    const ro = new ResizeObserver(() => setViewportH(el.clientHeight));
    ro.observe(el);
    setViewportH(el.clientHeight);
    return () => ro.disconnect();
  }, []);

  const onScroll = useCallback(() => {
    if (listRef.current) setScrollTop(listRef.current.scrollTop);
  }, []);

  const start = Math.max(0, Math.floor(scrollTop / DICT_ROW_H) - 3);
  const visibleCount = Math.ceil(viewportH / DICT_ROW_H) + 6;
  const slice = filtered.slice(start, start + visibleCount);
  const totalH = filtered.length * DICT_ROW_H;
  const offsetY = start * DICT_ROW_H;

  return (
    <div style={{ flex:"1 1 0", minHeight:0, background:C.bg, display:"flex", flexDirection:"column", overflow:"hidden" }}>
      <StatusBar />
      <div style={{ flexShrink:0, padding:"8px 20px 12px" }}>
        <div style={{ display:"flex", alignItems:"center", gap:12, marginBottom:14 }}>
          <button onClick={() => nav("home")} style={{ background:"none", border:"none", cursor:"pointer", color:C.textTert, lineHeight:0 }}>
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M15 19L8 12L15 5"/></svg>
          </button>
          <div style={{ fontSize:22, fontWeight:700, color:C.text, letterSpacing:"-0.2px" }}>Словарь</div>
          <Chip ch={`${formatWordCount(source.length)} слов`} col={C.textTert} bg={C.surfMuted} />
        </div>
        <div style={{ display:"flex", gap:8, marginBottom:10, flexWrap:"wrap" }}>
          <button
            onClick={() => { setVerifiedOnly(false); setScrollTop(0); if (listRef.current) listRef.current.scrollTop = 0; }}
            style={{
              border:"none", borderRadius:20, padding:"6px 12px", fontSize:12, fontWeight:700, cursor:"pointer",
              background: !verifiedOnly ? C.terraMuted : C.surfMuted,
              color: !verifiedOnly ? C.terra : C.textTert,
              fontFamily:"inherit",
            }}
          >
            Весь словарь
          </button>
          <button
            onClick={() => { setVerifiedOnly(true); setScrollTop(0); if (listRef.current) listRef.current.scrollTop = 0; }}
            style={{
              border:"none", borderRadius:20, padding:"6px 12px", fontSize:12, fontWeight:700, cursor:"pointer",
              background: verifiedOnly ? C.meadowMuted : C.surfMuted,
              color: verifiedOnly ? C.meadow : C.textTert,
              fontFamily:"inherit",
            }}
          >
            Проверено ({formatWordCount(FULL_DICTIONARY.filter(w => w.verified).length)})
          </button>
        </div>
        <div style={{ position:"relative", marginBottom:4 }}>
          <svg style={{ position:"absolute", left:14, top:"50%", transform:"translateY(-50%)" }} width="18" height="18" viewBox="0 0 18 18" fill="none">
            <circle cx="7.5" cy="7.5" r="5.5" stroke={C.textTert} strokeWidth="1.5"/>
            <path d="M13 13l3 3" stroke={C.textTert} strokeWidth="1.5" strokeLinecap="round"/>
          </svg>
          <input value={q} onChange={e => { setQ(e.target.value); setScrollTop(0); if (listRef.current) listRef.current.scrollTop = 0; }} placeholder="Поиск на чеченском или русском..."
            style={{ width:"100%", background:C.surface, border:`1px solid ${C.sep}`, borderRadius:14, padding:"13px 14px 13px 40px", fontSize:15, color:C.text, outline:"none", fontFamily:"inherit", boxSizing:"border-box" }}/>
        </div>
        {q.trim() && (
          <div style={{ fontSize:12, color:C.textTert, marginTop:8 }}>
            Найдено: {formatWordCount(filtered.length)}
          </div>
        )}
      </div>
      <div style={{ flex:"1 1 0", minHeight:0, position:"relative" }}>
        <div
          ref={listRef}
          onScroll={onScroll}
          style={{
            position:"absolute",
            inset:0,
            overflowY:"scroll",
            overflowX:"hidden",
            WebkitOverflowScrolling:"touch",
            overscrollBehavior:"contain",
            scrollbarWidth:"thin",
            padding:"0 20px 20px",
          }}
        >
          {filtered.length === 0 ? (
            <div style={{ textAlign:"center", paddingTop:48, color:C.textTert, fontSize:15 }}>
              {dictLoaded ? "Ничего не найдено" : "Загрузка словаря…"}
            </div>
          ) : (
            <div style={{ height: totalH, position:"relative", width:"100%" }}>
              <div style={{ position:"absolute", top: offsetY, left:0, right:0 }}>
                {slice.map((w, i) => (
                  <DictionaryRow key={`${w.ce}-${w.ru}-${start + i}`} w={w} />
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function DictionaryRow({ w }: { w: PreviewWord }) {
  const meta = [w.tr ? `[${w.tr}]` : null, w.cat].filter(Boolean).join(" · ");
  return (
    <div style={{ display:"flex", alignItems:"center", gap:14, padding:"14px 0", borderBottom:`1px solid ${C.sep}`, height: DICT_ROW_H, boxSizing:"border-box", overflow:"hidden" }}>
      <div style={{ width:44, height:44, borderRadius:12, background:C.surfMuted, display:"flex", alignItems:"center", justifyContent:"center", fontSize:22, flexShrink:0 }}>{w.emoji}</div>
      <div style={{ flex:1, minWidth:0, overflow:"hidden" }}>
        <div style={{ fontSize:17, fontWeight:700, color:C.text, letterSpacing:"0.2px", overflow:"hidden", textOverflow:"ellipsis", whiteSpace:"nowrap" }}>{w.ce}</div>
        {meta && (
          <div style={{ fontSize:12, color:C.textTert, marginTop:1, overflow:"hidden", textOverflow:"ellipsis", whiteSpace:"nowrap" }}>{meta}</div>
        )}
      </div>
      <div style={{ fontSize:15, color:C.textSec, fontWeight:500, textAlign:"right", maxWidth:"42%", overflow:"hidden", textOverflow:"ellipsis", whiteSpace:"nowrap" }}>{w.ru}</div>
    </div>
  );
}

// ─── Profile ──────────────────────────────────────────────────────────────────
function ProfileScreen({ mode, nav }: { mode: Mode; nav: (s: Screen) => void }) {
  const accent = mode === "kids" ? C.meadow : C.terra;
  const acMuted = mode === "kids" ? C.meadowMuted : C.terraMuted;
  return (
    <div style={{ flex:1, overflowY:"auto", background:C.bg, scrollbarWidth:"none" }}>
      <StatusBar />
      <div style={{ padding:"8px 20px 24px" }}>
        {/* Avatar */}
        <div style={{ display:"flex", alignItems:"center", gap:16, marginBottom:24 }}>
          <div style={{ width:68, height:68, borderRadius:22, background:accent, display:"flex", alignItems:"center", justifyContent:"center", fontSize:32 }}>
            {mode==="kids"?"🦊":"👤"}
          </div>
          <div style={{ flex:1 }}>
            <div style={{ fontSize:22, fontWeight:700, color:C.text }}>Аслан</div>
            <div style={{ display:"flex", alignItems:"center", gap:8, marginTop:3 }}>
              <Chip ch={mode==="kids"?"Детский трек 🦊":"Взрослый трек"} col={accent} bg={acMuted} />
            </div>
          </div>
          <button onClick={() => nav("paywall")} style={{ background:C.goldMuted, border:"none", borderRadius:12, padding:"8px 12px", cursor:"pointer", fontFamily:"inherit" }}>
            <span style={{ fontSize:18 }}>👑</span>
          </button>
        </div>

        {/* Stats */}
        <div style={{ display:"flex", gap:10, marginBottom:16 }}>
          {[["🔥","12","Стрик"],["⭐","2 140","XP"],["📚","87","Слов"]].map(([e,v,l]) => (
            <div key={l} style={{ flex:1, background:C.surface, borderRadius:18, padding:"14px 10px", textAlign:"center", border:`1px solid ${C.sep}` }}>
              <div style={{ fontSize:22, marginBottom:5 }}>{e}</div>
              <div style={{ fontSize:18, fontWeight:700, color:C.text }}>{v}</div>
              <div style={{ fontSize:10, color:C.textTert, fontWeight:600, marginTop:2 }}>{l}</div>
            </div>
          ))}
        </div>

        {/* Big arc */}
        <div style={{ background:C.surface, borderRadius:22, padding:"22px", marginBottom:14, display:"flex", alignItems:"center", gap:18, border:`1px solid ${C.sep}` }}>
          <Arc p={74} size={90} sw={7} col={accent} bg={acMuted}>
            <div style={{ textAlign:"center" }}>
              <div style={{ fontSize:20, fontWeight:700, color:accent }}>74%</div>
            </div>
          </Arc>
          <div>
            <div style={{ fontSize:17, fontWeight:700, color:C.text, marginBottom:4 }}>Недельная цель</div>
            <div style={{ fontSize:13, color:C.textSec }}>5 из 7 дней выполнено</div>
            <div style={{ fontSize:13, color:accent, fontWeight:600, marginTop:6 }}>Отличный прогресс!</div>
          </div>
        </div>

        {/* Weak spot */}
        <div style={{ background:C.surface, borderRadius:18, padding:"16px 18px", marginBottom:14, border:`1px solid ${C.sep}` }}>
          <div style={{ fontSize:11, color:C.textTert, fontWeight:700, letterSpacing:"0.5px", marginBottom:10 }}>СЛАБОЕ МЕСТО</div>
          <div style={{ display:"flex", alignItems:"center", gap:12 }}>
            <span style={{ fontSize:28 }}>🔢</span>
            <div style={{ flex:1 }}>
              <div style={{ fontSize:16, fontWeight:600, color:C.text }}>Числа и счёт</div>
              <div style={{ fontSize:13, color:C.textTert }}>Точность 58% · Нужна практика</div>
            </div>
            <div style={{ background:acMuted, borderRadius:10, padding:"5px 10px", fontSize:13, fontWeight:700, color:accent }}>58%</div>
          </div>
        </div>

        {/* SRS */}
        <div style={{ background:acMuted, borderRadius:16, padding:"16px 18px", marginBottom:16, border:`1px solid ${accent}33` }}>
          <div style={{ fontSize:13, fontWeight:700, color:accent, marginBottom:5 }}>Интервальное повторение (SRS)</div>
          <div style={{ fontSize:13, color:C.textSec, lineHeight:1.5 }}>
            Сегодня к повторению: <strong style={{ color:C.text }}>14 слов</strong>. Следующий сеанс через 2 ч.
          </div>
        </div>

        {/* Settings list */}
        {[["Достижения","🏅"],["Статистика","📊"],["Уведомления","🔔"],["Тёмная тема","🌙"]].map(([l,e]) => (
          <div key={l} style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"16px 0", borderBottom:`1px solid ${C.sep}` }}>
            <div style={{ display:"flex", alignItems:"center", gap:12 }}>
              <span style={{ fontSize:20 }}>{e}</span>
              <span style={{ fontSize:15, color:C.text }}>{l}</span>
            </div>
            <svg width="18" height="18" viewBox="0 0 18 18" fill="none"><path d="M7 4l5 5-5 5" stroke={C.textTert} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/></svg>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Paywall ──────────────────────────────────────────────────────────────────
function PaywallScreen({ nav }: { nav: (s: Screen) => void }) {
  const [sel, setSel] = useState(1);
  const plans = [
    { label:"1 месяц", price:"399 ₽", sub:"399 ₽/мес" },
    { label:"6 месяцев", price:"1 490 ₽", sub:"248 ₽/мес", badge:"Популярно" },
    { label:"12 месяцев", price:"1 990 ₽", sub:"166 ₽/мес", badge:"Выгодно" },
  ];
  const show = useAnimIn(80);
  return (
    <div style={{ flex:1, background:C.bg, display:"flex", flexDirection:"column", position:"relative", overflow:"hidden" }}>
      <Ornament />
      <StatusBar />
      <div style={{ flex:1, overflowY:"auto", scrollbarWidth:"none", padding:"16px 24px 36px", position:"relative", zIndex:1 }}>
        <button onClick={() => nav("home")} style={{ background:"none", border:"none", cursor:"pointer", color:C.textTert, fontSize:22, lineHeight:1, marginBottom:24, fontFamily:"inherit" }}>✕</button>

        <div style={{ ...spring(show) }}>
          <div style={{ textAlign:"center", marginBottom:28 }}>
            <div style={{ fontSize:52, marginBottom:12 }}>👑</div>
            <div style={{ fontSize:28, fontWeight:700, color:C.text, letterSpacing:"-0.3px", marginBottom:8 }}>Нохчийн Premium</div>
            <div style={{ fontSize:15, color:C.textSec, lineHeight:1.5 }}>Все миры, офлайн-доступ, без ограничений</div>
          </div>

          {/* Features */}
          <div style={{ background:C.surface, borderRadius:20, padding:"18px", marginBottom:20, border:`1px solid ${C.sep}` }}>
            {[["♾️","Все 11 учебных миров"],["📴","Полный офлайн-режим"],["🔁","Неограниченный SRS"],["🏛️","Все культурные капсулы"],[`📖`,`Словарь ${formatWordCount(FULL_DICTIONARY.length)}+ слов`],["👨‍👩‍👧","Родительский дашборд"]].map(([e,l]) => (
              <div key={l} style={{ display:"flex", alignItems:"center", gap:12, padding:"9px 0", borderBottom:`1px solid ${C.sep}` }}>
                <span style={{ fontSize:20 }}>{e}</span>
                <span style={{ fontSize:15, color:C.text }}>{l}</span>
                <svg style={{ marginLeft:"auto" }} width="18" height="18" viewBox="0 0 18 18" fill="none"><path d="M4 9l4 4 6-7" stroke={C.ok} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>
              </div>
            ))}
          </div>

          {/* Plans */}
          <div style={{ display:"flex", flexDirection:"column", gap:10, marginBottom:20 }}>
            {plans.map(({ label, price, sub, badge }, i) => (
              <div key={i} onClick={() => setSel(i)}
                style={{ background:sel===i?C.terraMuted:C.surface, border:`2px solid ${sel===i?C.terra:"rgba(61,56,50,0.1)"}`, borderRadius:16, padding:"16px 18px", cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"space-between", transition:"all 0.2s" }}>
                <div style={{ display:"flex", alignItems:"center", gap:10 }}>
                  <div style={{ width:20, height:20, borderRadius:"50%", border:`2px solid ${sel===i?C.terra:"rgba(61,56,50,0.25)"}`, background:sel===i?C.terra:"transparent", display:"flex", alignItems:"center", justifyContent:"center" }}>
                    {sel===i && <div style={{ width:8, height:8, borderRadius:"50%", background:"#fff" }}/>}
                  </div>
                  <div>
                    <div style={{ fontSize:15, fontWeight:600, color:C.text }}>{label}</div>
                    <div style={{ fontSize:12, color:C.textTert }}>{sub}</div>
                  </div>
                </div>
                <div style={{ display:"flex", flexDirection:"column", alignItems:"flex-end", gap:4 }}>
                  <div style={{ fontSize:17, fontWeight:700, color:C.text }}>{price}</div>
                  {badge && <Chip ch={badge} col={C.terra} bg={C.terraMuted} />}
                </div>
              </div>
            ))}
          </div>

          <Btn ch="Начать пробный период →" full onClick={() => nav("home")} />
          <div style={{ textAlign:"center", fontSize:12, color:C.textTert, marginTop:12 }}>
            7 дней бесплатно · Отмена в любое время
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Reward ───────────────────────────────────────────────────────────────────
function RewardScreen({ mode, nav }: { mode: Mode; nav: (s: Screen) => void }) {
  const accent = mode === "kids" ? C.meadow : C.terra;
  const show = useAnimIn(100);
  return (
    <div style={{ flex:1, background:C.bg, display:"flex", flexDirection:"column", alignItems:"center", justifyContent:"center", padding:"32px 24px", position:"relative", overflow:"hidden" }}>
      <Ornament opacity={0.04} />
      {/* Confetti dots */}
      {[...Array(12)].map((_,i) => (
        <div key={i} style={{ position:"absolute", width:8, height:8, borderRadius:"50%", background:[C.terra,C.gold,C.meadow,C.terraMuted][i%4], left:`${10+i*7}%`, top:`${15+((i*37)%65)}%`, opacity:0.5, animation:`confetti ${1.5+(i*0.2)%1}s ${(i*0.15)}s infinite alternate` }}/>
      ))}
      <div style={{ ...spring(show), textAlign:"center", position:"relative", zIndex:1, width:"100%" }}>
        <div style={{ fontSize:96, marginBottom:12, animation:"trophyBounce 0.6s 0.3s cubic-bezier(0.34,1.56,0.64,1) both" }}>🏆</div>
        <div style={{ fontSize:32, fontWeight:700, color:C.text, letterSpacing:"-0.3px", marginBottom:8 }}>Урок завершён!</div>
        <div style={{ fontSize:17, color:C.textSec, marginBottom:36 }}>Отличная работа, Аслан</div>

        <div style={{ display:"flex", gap:12, justifyContent:"center", marginBottom:36 }}>
          {[["⭐","+25 XP",C.goldMuted,C.gold],[" 💰","+10",C.goldMuted,C.gold],["🔥","12 дней",C.terraMuted,C.terra]].map(([e,v,bg,col],i) => (
            <div key={i} style={{ background:bg, borderRadius:18, padding:"16px 14px", textAlign:"center", minWidth:85 }}>
              <div style={{ fontSize:26, marginBottom:5 }}>{e}</div>
              <div style={{ fontSize:16, fontWeight:700, color:col }}>{v}</div>
            </div>
          ))}
        </div>

        <div style={{ display:"flex", flexDirection:"column", gap:10 }}>
          <Btn ch="Следующий урок →" full onClick={() => nav("path")} col={accent} />
          <button onClick={() => nav("home")} style={{ background:"none", border:"none", cursor:"pointer", color:C.textTert, fontSize:15, fontFamily:"inherit", padding:"8px" }}>На главную</button>
        </div>
      </div>
      <style>{`
        @keyframes confetti{from{transform:translateY(0) rotate(0)}to{transform:translateY(-20px) rotate(90deg)}}
        @keyframes trophyBounce{from{transform:scale(0.5) rotate(-10deg);opacity:0}to{transform:scale(1) rotate(0);opacity:1}}
      `}</style>
    </div>
  );
}

// ─── Design system screen ─────────────────────────────────────────────────────
function DesignScreen({ nav }: { nav: (s: Screen) => void }) {
  return (
    <div style={{ flex:1, overflowY:"auto", background:C.bg, scrollbarWidth:"none" }}>
      <StatusBar />
      <div style={{ padding:"8px 20px 32px" }}>
        <button onClick={() => nav("home")} style={{ background:"none", border:"none", cursor:"pointer", color:C.terra, fontSize:14, fontWeight:600, marginBottom:16, fontFamily:"inherit" }}>← Назад</button>
        <div style={{ fontSize:22, fontWeight:700, color:C.text, letterSpacing:"-0.2px", marginBottom:20 }}>Design System</div>

        {/* Colors */}
        <div style={{ fontSize:12, fontWeight:700, color:C.textTert, letterSpacing:"1px", marginBottom:10 }}>ЦВЕТА</div>
        <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:8, marginBottom:24 }}>
          {[
            ["Terracotta","#C4724E"],["Terra Muted","#F5E0D4"],
            ["Background","#F7F4EF"],["Surface","#FFFFFF"],
            ["Meadow","#3D7A5C"],["Meadow Muted","#D4EDE3"],
            ["Sun Gold","#D4A84B"],["Text Primary","#1C1917"],
            ["Text Secondary","#57534E"],["Text Tertiary","#78716C"],
            ["Success","#3D7A5C"],["Error","#B54A4A"],
          ].map(([name, hex]) => (
            <div key={name} style={{ background:C.surface, borderRadius:14, overflow:"hidden", border:`1px solid ${C.sep}` }}>
              <div style={{ height:40, background:hex }}/>
              <div style={{ padding:"8px 10px" }}>
                <div style={{ fontSize:12, fontWeight:600, color:C.text }}>{name}</div>
                <div style={{ fontSize:10, color:C.textTert, fontFamily:"monospace" }}>{hex}</div>
              </div>
            </div>
          ))}
        </div>

        {/* Typography */}
        <div style={{ fontSize:12, fontWeight:700, color:C.textTert, letterSpacing:"1px", marginBottom:10 }}>ТИПОГРАФИКА</div>
        <div style={{ background:C.surface, borderRadius:18, padding:"18px", marginBottom:24, border:`1px solid ${C.sep}` }}>
          {[
            { text:"Нохчийн", size:34, weight:700, note:"Display Large · 34pt / Bold / -0.4" },
            { text:"Беркат — благодать", size:22, weight:600, note:"Headline · 22pt / Semibold" },
            { text:"Учи чеченский язык каждый день", size:17, weight:400, note:"Body · 17pt / Regular" },
            { text:"КАТЕГОРИЯ · СЛОВАРЬ", size:11, weight:700, note:"Label · 11pt / Bold / +1.5 tracking" },
          ].map(({ text, size, weight, note }) => (
            <div key={note} style={{ marginBottom:16, paddingBottom:16, borderBottom:`1px solid ${C.sep}` }}>
              <div style={{ fontSize:size, fontWeight:weight, color:C.text, letterSpacing:size===11?"1.5px":"-0.2px", lineHeight:1.3 }}>{text}</div>
              <div style={{ fontSize:11, color:C.textTert, marginTop:4, fontFamily:"monospace" }}>{note}</div>
            </div>
          ))}
          <div style={{ fontSize:20, fontWeight:700, color:C.text, letterSpacing:"0.3px" }}>
            Хьаша · ХӀума · Ӏедал
          </div>
          <div style={{ fontSize:11, color:C.textTert, marginTop:4 }}>Чеченские слова · +0.3 letter-spacing · Кириллица + Ӏ (palochka)</div>
        </div>

        {/* Components */}
        <div style={{ fontSize:12, fontWeight:700, color:C.textTert, letterSpacing:"1px", marginBottom:10 }}>КОМПОНЕНТЫ</div>
        <div style={{ background:C.surface, borderRadius:18, padding:"18px", marginBottom:20, border:`1px solid ${C.sep}`, display:"flex", flexDirection:"column", gap:12 }}>
          <Btn ch="Primary Button" full col={C.terra} />
          <Btn ch="Meadow Variant" full col={C.meadow} />
          <Btn ch="Secondary" full col={C.terraMuted} tc={C.terra} />
          <div style={{ display:"flex", gap:8, flexWrap:"wrap" }}>
            <Chip ch="🔥 12 стрик" col={C.terra} bg={C.terraMuted} />
            <Chip ch="💰 340 монет" col={C.gold} bg={C.goldMuted} />
            <Chip ch="⭐ +25 XP" col={C.gold} bg={C.goldMuted} />
            <Chip ch="17+" col={C.textTert} bg={C.surfMuted} />
          </div>
          <div style={{ display:"flex", gap:16, alignItems:"center" }}>
            <Arc p={74} size={70} sw={6} col={C.terra} bg={C.terraMuted}><span style={{ fontSize:11, fontWeight:700, color:C.terra }}>74%</span></Arc>
            <Arc p={34} size={70} sw={6} col={C.meadow} bg={C.meadowMuted}><span style={{ fontSize:11, fontWeight:700, color:C.meadow }}>34%</span></Arc>
            <Arc p={100} size={70} sw={6} col={C.gold} bg={C.goldMuted}><span style={{ fontSize:16 }}>🏆</span></Arc>
          </div>
          <div>
            <div style={{ fontSize:12, color:C.textTert, marginBottom:6 }}>Прогресс-бар урока</div>
            <ProgBar step={3} col={C.terra} />
          </div>
        </div>

        {/* Spacing */}
        <div style={{ fontSize:12, fontWeight:700, color:C.textTert, letterSpacing:"1px", marginBottom:10 }}>СЕТКА ОТСТУПОВ (4pt base)</div>
        <div style={{ background:C.surface, borderRadius:18, padding:"16px", border:`1px solid ${C.sep}`, display:"flex", flexDirection:"column", gap:8 }}>
          {[8,16,20,24,32,48].map(v => (
            <div key={v} style={{ display:"flex", alignItems:"center", gap:12 }}>
              <div style={{ width:v, height:16, background:C.terra, borderRadius:3, flexShrink:0 }}/>
              <span style={{ fontSize:12, color:C.textSec, fontFamily:"monospace" }}>{v}pt</span>
            </div>
          ))}
        </div>

        {/* App icon */}
        <div style={{ fontSize:12, fontWeight:700, color:C.textTert, letterSpacing:"1px", marginBottom:10, marginTop:24 }}>APP ICON</div>
        <div style={{ background:C.surface, borderRadius:18, padding:"20px", border:`1px solid ${C.sep}`, display:"flex", gap:20, alignItems:"center" }}>
          <AppIcon size={96} />
          <AppIcon size={60} />
          <AppIcon size={44} />
          <AppIcon size={32} />
          <AppIcon size={20} />
        </div>
      </div>
    </div>
  );
}

// ─── App ──────────────────────────────────────────────────────────────────────
export default function App() {
  const [screen, setScreen] = useState<Screen>("splash");
  const [mode, setMode] = useState<Mode>("adult");
  const [tab, setTab] = useState<Tab>("home");
  const [prevScreen, setPrev] = useState<Screen | null>(null);
  const [transitioning, setTransitioning] = useState(false);
  const [, forceUpdate] = useState(0);

  useEffect(() => {
    loadFullDictionary().then((words) => {
      FULL_DICTIONARY = words;
      forceUpdate((n) => n + 1);
    });
  }, []);

  const nav = (s: Screen) => {
    if (s === screen) return;
    setTransitioning(true);
    setTimeout(() => { setScreen(s); setTransitioning(false); }, 120);
    if (s === "home") setTab("home");
    else if (s === "worlds") setTab("worlds");
    else if (s === "profile") setTab("profile");
  };

  const handleMode = (m: Mode) => { setMode(m); nav("home"); };
  const handleTab = (t: Tab) => {
    setTab(t);
    if (t === "home") nav("home");
    else if (t === "worlds") nav("worlds");
    else if (t === "repeat") nav("flashcard");
    else if (t === "profile") nav("profile");
  };

  const noTab: Screen[] = ["splash","onboarding","age","culture","reward","paywall","design"];
  const showTab = !noTab.includes(screen);
  const accent = mode === "kids" ? C.meadow : C.terra;

  const renderScreen = () => {
    switch (screen) {
      case "splash": return <SplashScreen onDone={() => nav("onboarding")} />;
      case "onboarding": return <OnboardingScreen onMode={handleMode} />;
      case "age": return <AgeScreen mode={mode} onDone={handleMode} />;
      case "home": return <HomeScreen mode={mode} nav={nav} />;
      case "path": return <PathScreen mode={mode} nav={nav} />;
      case "flashcard": return <FlashcardScreen mode={mode} nav={nav} />;
      case "match": return <MatchScreen mode={mode} nav={nav} />;
      case "quiz": return <QuizScreen mode={mode} nav={nav} />;
      case "culture": return <CultureScreen nav={nav} />;
      case "worlds": return <WorldsScreen mode={mode} nav={nav} />;
      case "dictionary": return <DictionaryScreen nav={nav} />;
      case "profile": return <ProfileScreen mode={mode} nav={nav} />;
      case "paywall": return <PaywallScreen nav={nav} />;
      case "reward": return <RewardScreen mode={mode} nav={nav} />;
      case "design": return <DesignScreen nav={nav} />;
      default: return null;
    }
  };

  return (
    <div style={{ minHeight:"100dvh", background:"#D4C8BC", display:"flex", alignItems:"center", justifyContent:"center", fontFamily:"'Inter',-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif", padding:"24px 16px", boxSizing:"border-box" }}>
      {/* Phone */}
      <div style={{ width:390, height:"min(844px, calc(100dvh - 48px))", background:C.bg, borderRadius:50, overflow:"hidden", display:"flex", flexDirection:"column", boxShadow:"0 48px 140px rgba(0,0,0,0.32),0 0 0 1px rgba(255,255,255,0.18),inset 0 0 0 1px rgba(0,0,0,0.08)", position:"relative" }}>
        {/* Dynamic Island */}
        <div style={{ position:"absolute", top:13, left:"50%", transform:"translateX(-50%)", width:118, height:35, background:"#000", borderRadius:22, zIndex:200 }}/>

        <div style={{ flex:1, display:"flex", flexDirection:"column", overflow:"hidden", opacity:transitioning?0:1, transition:"opacity 0.12s", minHeight:0 }}>
          {renderScreen()}
        </div>

        {showTab && <TabBar tab={tab} onTab={handleTab} accent={accent} />}
      </div>

      {/* Nav pills outside phone */}
      <div style={{ position:"fixed", bottom:20, left:"50%", transform:"translateX(-50%)", display:"flex", gap:6, flexWrap:"wrap", justifyContent:"center", maxWidth:500 }}>
        {([
          ["splash","Сплэш"],["onboarding","Онбординг"],["home","Главная"],
          ["path","Путь"],["flashcard","Карточки"],["match","Пары"],
          ["quiz","Тест"],["culture","Капсула"],["worlds","Миры"],
          ["dictionary","Словарь"],["profile","Профиль"],["paywall","Пейвол"],["reward","Награда"],["design","Design Kit"],
        ] as [Screen,string][]).map(([s,l]) => (
          <button key={s} onClick={() => nav(s)}
            style={{ background:screen===s?"#1C1917":"rgba(28,25,23,0.55)", color:screen===s?"#F7F4EF":"rgba(247,244,239,0.7)", border:"none", borderRadius:20, padding:"6px 12px", fontSize:11, fontWeight:600, cursor:"pointer", fontFamily:"inherit", backdropFilter:"blur(12px)", transition:"all 0.2s" }}>
            {l}
          </button>
        ))}
      </div>
    </div>
  );
}
