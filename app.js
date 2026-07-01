// --- 1. SAFE STORAGE ENGINE (Bypasses all Sandbox SecurityErrors) ---
        class SafeStorage {
            constructor() {
                this.memory = {};
            }
            get(key, fallback) {
                try {
                    const val = window.localStorage.getItem(key);
                    return val !== null ? JSON.parse(val) : fallback;
                } catch(e) {
                    return this.memory[key] !== undefined ? this.memory[key] : fallback;
                }
            }
            set(key, val) {
                try {
                    window.localStorage.setItem(key, JSON.stringify(val));
                } catch(e) {
                    this.memory[key] = val;
                }
            }
        }
        const storage = new SafeStorage();

        // --- 2. HIGH-FIDELITY SOUND EFFECTS ENGINE (Web Audio API) ---
        const playSound = (type) => {
            try {
                const ctx = new (window.AudioContext || window.webkitAudioContext)();
                if (ctx.state === 'suspended') {
                    ctx.resume();
                }
                const now = ctx.currentTime;

                if (type === 'tap') {
                    const osc = ctx.createOscillator();
                    const gain = ctx.createGain();
                    osc.type = 'sine';
                    osc.frequency.setValueAtTime(450, now);
                    osc.frequency.exponentialRampToValueAtTime(850, now + 0.08);
                    gain.gain.setValueAtTime(0.2, now);
                    gain.gain.linearRampToValueAtTime(0, now + 0.08);
                    osc.connect(gain);
                    gain.connect(ctx.destination);
                    osc.start(now);
                    osc.stop(now + 0.08);
                } else if (type === 'success') {
                    const osc1 = ctx.createOscillator();
                    const osc2 = ctx.createOscillator();
                    const gain = ctx.createGain();
                    osc1.type = 'sine';
                    osc2.type = 'triangle';
                    osc1.frequency.setValueAtTime(523.25, now); // C5
                    osc1.frequency.exponentialRampToValueAtTime(659.25, now + 0.12); // E5
                    osc1.frequency.exponentialRampToValueAtTime(783.99, now + 0.24);  // G5
                    osc1.frequency.exponentialRampToValueAtTime(1046.50, now + 0.36); // C6
                    osc2.frequency.setValueAtTime(261.63, now); // C4
                    osc2.frequency.exponentialRampToValueAtTime(523.25, now + 0.36); // C5
                    gain.gain.setValueAtTime(0.25, now);
                    gain.gain.linearRampToValueAtTime(0, now + 0.6);
                    osc1.connect(gain);
                    osc2.connect(gain);
                    gain.connect(ctx.destination);
                    osc1.start(now);
                    osc2.start(now);
                    osc1.stop(now + 0.6);
                    osc2.stop(now + 0.6);
                } else if (type === 'wrong') {
                    const osc = ctx.createOscillator();
                    const gain = ctx.createGain();
                    osc.type = 'sawtooth';
                    osc.frequency.setValueAtTime(180, now);
                    osc.frequency.linearRampToValueAtTime(130, now + 0.25);
                    gain.gain.setValueAtTime(0.15, now);
                    gain.gain.linearRampToValueAtTime(0, now + 0.25);
                    osc.connect(gain);
                    gain.connect(ctx.destination);
                    osc.start(now);
                    osc.stop(now + 0.25);
                } else if (type === 'fanfare') {
                    const notes = [523.25, 659.25, 783.99, 1046.50, 1318.51];
                    notes.forEach((freq, idx) => {
                        const osc = ctx.createOscillator();
                        const gain = ctx.createGain();
                        osc.type = 'triangle';
                        osc.frequency.setValueAtTime(freq, now + idx * 0.12);
                        gain.gain.setValueAtTime(0.3, now + idx * 0.12);
                        gain.gain.linearRampToValueAtTime(0, now + idx * 0.12 + 0.4);
                        osc.connect(gain);
                        gain.connect(ctx.destination);
                        osc.start(now + idx * 0.12);
                        osc.stop(now + idx * 0.12 + 0.4);
                    });
                }
            } catch(e) {
                console.log("Web Audio API disabled or blocked");
            }
        };

        // --- 3. SPEECH SYNTHESIS HELPER ---
        const speakWord = (chechenWord) => {
            playSound('tap');
            try {
                if ('speechSynthesis' in window) {
                    window.speechSynthesis.cancel();
                    const utter = new SpeechSynthesisUtterance(chechenWord);
                    utter.rate = 0.85;
                    utter.pitch = 1.1;
                    window.speechSynthesis.speak(utter);
                }
            } catch(e) {
                console.log("SpeechSynthesis error", e);
            }
        };

        // --- 4. BUILT-IN 60FPS CONFETTI FIREWORKS ENGINE ---
        const shootConfetti = () => {
            playSound('fanfare');
            const canvas = document.getElementById('confetti-canvas');
            const ctx = canvas.getContext('2d');
            canvas.width = window.innerWidth;
            canvas.height = window.innerHeight;

            const particles = [];
            const colors = ['#f59e0b', '#ec4899', '#3b82f6', '#10b981', '#8b5cf6', '#ef4444', '#facc15'];

            for (let i = 0; i < 140; i++) {
                particles.push({
                    x: canvas.width * 0.5,
                    y: canvas.height * 0.85,
                    vx: (Math.random() - 0.5) * 28,
                    vy: -(Math.random() * 22 + 12),
                    size: Math.random() * 12 + 8,
                    color: colors[Math.floor(Math.random() * colors.length)],
                    rot: Math.random() * 360,
                    vrot: (Math.random() - 0.5) * 10
                });
            }

            let frame = 0;
            const animate = () => {
                ctx.clearRect(0, 0, canvas.width, canvas.height);
                let alive = false;
                particles.forEach(p => {
                    p.x += p.vx;
                    p.y += p.vy;
                    p.vy += 0.6; // Gravity
                    p.rot += p.vrot;
                    if (p.size > 0.2) p.size -= 0.05;

                    if (p.y < canvas.height && p.size > 0.5) {
                        alive = true;
                        ctx.save();
                        ctx.translate(p.x, p.y);
                        ctx.rotate(p.rot * Math.PI / 180);
                        ctx.fillStyle = p.color;
                        ctx.fillRect(-p.size/2, -p.size/2, p.size, p.size);
                        ctx.restore();
                    }
                });

                if (alive && frame < 180) {
                    frame++;
                    requestAnimationFrame(animate);
                } else {
                    ctx.clearRect(0, 0, canvas.width, canvas.height);
                }
            };
            animate();
        };

        // --- 5. ULTRA-PREMIUM DEFAULT VOCABULARY DATABASE ---
        const defaultLessons = [
            {
                id: 'greetings',
                title: 'Приветствия',
                chechenTitle: 'Маршалла',
                icon: '👋',
                color: 'linear-gradient(135deg, #10b981, #06b6d4)',
                words: [
                    { chechen: 'Маршалла', russian: 'Привет / Здравствуйте', pronunciation: 'Мар-шал-ла', emoji: '👋', hint: 'Традиционное чеченское пожелание мира' },
                    { chechen: 'Баркалла', russian: 'Спасибо', pronunciation: 'Бар-кал-ла', emoji: '🙏', hint: 'Выражение благодарности' },
                    { chechen: 'Ӏуьйре дика', russian: 'Доброе утро', pronunciation: 'Ӏуьй-ре ди-ка', emoji: '🌅', hint: 'Пожелание благословенного начала дня' },
                    { chechen: 'Де дика', russian: 'Добрый день', pronunciation: 'Де ди-ка', emoji: '☀️', hint: 'Приветствие в светлое время суток' },
                    { chechen: 'Суьйре дика', russian: 'Добрый вечер', pronunciation: 'Суьй-ре ди-ка', emoji: '🌇', hint: 'Вечернее дружеское приветствие' },
                    { chechen: 'Марша Ӏайла', russian: 'До свидания', pronunciation: 'Мар-ша Ӏай-ла', emoji: '🚶‍♂️', hint: 'Пожелание оставаться с миром' }
                ]
            },
            {
                id: 'animals',
                title: 'Животные',
                chechenTitle: 'Дийнаташ',
                icon: '🐾',
                color: 'linear-gradient(135deg, #f59e0b, #ea580c)',
                words: [
                    { chechen: 'Цициг', russian: 'Кошка', pronunciation: 'Цѝ-циг', emoji: '🐱', hint: 'Любит пить молоко и мурлыкать' },
                    { chechen: 'ЖӀаьла', russian: 'Собака', pronunciation: 'Жаь-ла', emoji: '🐶', hint: 'Верный и преданный друг' },
                    { chechen: 'Говр', russian: 'Лошадь', pronunciation: 'Говр', emoji: '🐴', hint: 'Быстро скачет по полям' },
                    { chechen: 'Борз', russian: 'Волк', pronunciation: 'Борз', emoji: '🐺', hint: 'Символ смелости, свободы и силы' },
                    { chechen: 'Ча', russian: 'Медведь', pronunciation: 'Ча', emoji: '🐻', hint: 'Большой и любит сладкий мёд' },
                    { chechen: 'Цхьогал', russian: 'Лиса', pronunciation: 'Цхьò-гал', emoji: '🦊', hint: 'Рыжая, пушистая и очень хитрая' },
                    { chechen: 'Лу', russian: 'Олень', pronunciation: 'Лу', emoji: '🦌', hint: 'С красивыми ветвистыми рогами' },
                    { chechen: 'ЦӀокъ', russian: 'Барс', pronunciation: 'ЦӀокъ', emoji: '🐆', hint: 'Быстрый и ловкий хищник гор' }
                ]
            },
            {
                id: 'colors',
                title: 'Цвета',
                chechenTitle: 'Бесаш',
                icon: '🎨',
                color: 'linear-gradient(135deg, #ec4899, #f43f5e)',
                words: [
                    { chechen: 'ЦӀе', russian: 'Красный', pronunciation: 'ЦӀе', emoji: '🍎', hint: 'Цвет спелого яблока и розы' },
                    { chechen: 'Сийна', russian: 'Синий', pronunciation: 'Сѝй-на', emoji: '🌊', hint: 'Цвет глубокого моря и неба' },
                    { chechen: 'Баьццара', russian: 'Зеленый', pronunciation: 'Баьц-ца-ра', emoji: '🌿', hint: 'Цвет свежей весенней травки' },
                    { chechen: 'Можа', russian: 'Желтый', pronunciation: 'Мò-жа', emoji: '☀️', hint: 'Цвет теплого солнышка и подсолнуха' },
                    { chechen: 'КӀайн', russian: 'Белый', pronunciation: 'КӀайн', emoji: '☁️', hint: 'Цвет чистого пушистого снега' },
                    { chechen: 'Ӏаьржа', russian: 'Черный', pronunciation: 'Ӏаьр-жа', emoji: '🌌', hint: 'Цвет звездной ночи' }
                ]
            },
            {
                id: 'numbers',
                title: 'Цифры (1-10)',
                chechenTitle: 'Терахьаш',
                icon: '🔢',
                color: 'linear-gradient(135deg, #3b82f6, #4f46e5)',
                words: [
                    { chechen: 'Цхьаъ', russian: 'Один (1)', pronunciation: 'Цхьаъ', emoji: '1️⃣', hint: 'Первая цифра счета' },
                    { chechen: 'Шиъ', russian: 'Два (2)', pronunciation: 'Шиъ', emoji: '2️⃣', hint: 'Пара глаз или пара рук' },
                    { chechen: 'Кхоъ', russian: 'Три (3)', pronunciation: 'Кхоъ', emoji: '3️⃣', hint: 'Три колеса у детского велосипеда' },
                    { chechen: 'Диъ', russian: 'Четыре (4)', pronunciation: 'Диъ', emoji: '4️⃣', hint: 'Четыре лапки у котенка' },
                    { chechen: 'Пхиъ', russian: 'Пять (5)', pronunciation: 'Пхиъ', emoji: '5️⃣', hint: 'Пять пальцев на одной руке' },
                    { chechen: 'Ялх', russian: 'Шесть (6)', pronunciation: 'Ялх', emoji: '6️⃣', hint: 'Шесть граней у кубика' },
                    { chechen: 'ВорхӀ', russian: 'Семь (7)', pronunciation: 'ВорхӀ', emoji: '7️⃣', hint: 'Семь цветов у радуги' },
                    { chechen: 'БархӀ', russian: 'Восемь (8)', pronunciation: 'БархӀ', emoji: '8️⃣', hint: 'Восемь ног у осьминога' },
                    { chechen: 'Исс', russian: 'Девять (9)', pronunciation: 'Исс', emoji: '9️⃣', hint: 'Самая большая однозначная цифра' },
                    { chechen: 'Итт', russian: 'Десять (10)', pronunciation: 'Итт', emoji: '🔟', hint: 'Все пальцы на обеих руках!' }
                ]
            },
            {
                id: 'family',
                title: 'Семья',
                chechenTitle: 'Доьзал',
                icon: '❤️',
                color: 'linear-gradient(135deg, #10b981, #059669)',
                words: [
                    { chechen: 'Нана', russian: 'Мама', pronunciation: 'Нà-на', emoji: '👩‍👧', hint: 'Самый близкий и родной человек' },
                    { chechen: 'Да', russian: 'Папа', pronunciation: 'Да', emoji: '👨‍👦', hint: 'Глава семьи, наш защитник и опора' },
                    { chechen: 'Ваша', russian: 'Брат', pronunciation: 'Вà-ша', emoji: '👦', hint: 'Смелый мальчик в нашей семье' },
                    { chechen: 'Йиша', russian: 'Сестра', pronunciation: 'Йѝ-ша', emoji: '👧', hint: 'Добрая и заботливая девочка' },
                    { chechen: 'Деда', russian: 'Дедушка', pronunciation: 'Дè-да', emoji: '👴', hint: 'Самый мудрый и старший в семье' },
                    { chechen: 'Денана', russian: 'Бабушка', pronunciation: 'Дè-на-на', emoji: '👵', hint: 'Рассказывает самые интересные сказки' }
                ]
            },
            {
                id: 'food',
                title: 'Еда и Напитки',
                chechenTitle: 'Кхача',
                icon: '🍎',
                color: 'linear-gradient(135deg, #8b5cf6, #6d28d9)',
                words: [
                    { chechen: 'Хи', russian: 'Вода', pronunciation: 'Хи', emoji: '💧', hint: 'Источник жизни, утоляет жажду' },
                    { chechen: 'Шура', russian: 'Молоко', pronunciation: 'Шу-рà', emoji: '🥛', hint: 'Полезное для роста и крепких костей' },
                    { chechen: 'Бепиг', russian: 'Хлеб', pronunciation: 'Бè-пиг', emoji: '🍞', hint: 'Главный продукт за любым столом' },
                    { chechen: 'Чай', russian: 'Чай', pronunciation: 'Чай', emoji: '☕', hint: 'Горячий и ароматный напиток для гостей' },
                    { chechen: 'Ӏаж', russian: 'Яблоко', pronunciation: 'Ӏаж', emoji: '🍏', hint: 'Сочный, сладкий и хрустящий фрукт' },
                    { chechen: 'Жижиг', russian: 'Мясо', pronunciation: 'Жѝ-жиг', emoji: '🥩', hint: 'Дает настоящую богатырскую силу' }
                ]
            },
            {
                id: 'nature',
                title: 'Природа',
                chechenTitle: 'Ӏалам',
                icon: '🌳',
                color: 'linear-gradient(135deg, #06b6d4, #0e7490)',
                words: [
                    { chechen: 'Маьлхан', russian: 'Солнце', pronunciation: 'Маьл-хан', emoji: '☀️', hint: 'Согревает всю землю своим теплом' },
                    { chechen: 'Лам', russian: 'Гора', pronunciation: 'Лам', emoji: '🏔️', hint: 'Высокие вершины Кавказа' },
                    { chechen: 'Зезаг', russian: 'Цветок', pronunciation: 'Зè-заг', emoji: '🌷', hint: 'Красиво растет на весеннем лугу' },
                    { chechen: 'Хьун', russian: 'Лес', pronunciation: 'Хьун', emoji: '🌲', hint: 'Дом для множества диких зверей' },
                    { chechen: 'Стигал', russian: 'Небо', pronunciation: 'Сти-гал', emoji: '🌌', hint: 'Бесконечное, синее над головой' },
                    { chechen: 'ДогӀа', russian: 'Дождь', pronunciation: 'Дò-гӀа', emoji: '🌧️', hint: 'Поит все растения и цветы' }
                ]
            }
        ];

        // --- 6. SHOP REWARDS DATABASE ---
        const shopItems = [
            { id: 'hat_crown', name: 'Золотая Корона', price: 20, icon: '👑', type: 'hat', desc: 'Для настоящих королей и королев знаний!' },
            { id: 'hat_cap', name: 'Кепка Героя', price: 15, icon: '🧢', type: 'hat', desc: 'Модная кепка для быстрых и точных ответов.' },
            { id: 'glasses_cool', name: 'Крутые Очки', price: 18, icon: '🕶️', type: 'glasses', desc: 'Самый стильный образ на всем Кавказе.' },
            { id: 'friend_cat', name: 'Спутник Цициг', price: 30, icon: '🐱', type: 'friend', desc: 'Милый котенок будет сопровождать в уроках.' },
            { id: 'friend_wolf', name: 'Волчонок Борз', price: 40, icon: '🐺', type: 'friend', desc: 'Маленький смелый волчонок будет рядом.' },
            { id: 'friend_deer', name: 'Олененок Лу', price: 35, icon: '🦌', type: 'friend', desc: 'Прекрасный олененок из горных лесов.' }
        ];

        // --- 7. CENTRAL APP STATE & CONTROLLER ---
        class ChechenGameApp {
            constructor() {
                // Persistent State
                this.stars = storage.get('chechen_stars', 20);
                this.xp = storage.get('chechen_xp', 140);
                this.streak = storage.get('chechen_streak', 3);
                this.inventory = storage.get('chechen_inventory', []);
                this.equipped = storage.get('chechen_equipped', {});
                this.mastery = storage.get('chechen_mastery', {});
                this.lastLessonId = storage.get('chechen_last_lesson', null);
                this.lessons = this.loadLessons();

                // Maciev Dictionary State
                this.macievDictionary = [];
                this.dictSearchQuery = '';
                this.dictVisibleCount = 80;
                this.dictSearchTimer = null;

                // Game Execution State
                this.activeLesson = null;
                this.activeGameMode = null;
                this.activeTimer = null;
                this.currentCardIdx = 0;
                this.quizScore = 0;
                this.matchingPairs = [];
                this.selectedMatchChechen = null;
                this.selectedMatchRussian = null;
                this.isMatchingBusy = false;
                this.constSpelled = [];
                this.constAvailable = [];

                // Initialize Core Setup
                this.initUI();
                this.bindGlobalEvents();
                this.renderDashboard();
                this.renderLessonsGrid();
                this.updateStatsUI();
                this.updateMascotVisuals();
                this.loadMacievDictionary();
            }

            loadLessons() {
                const base = (window.MACIEV_LESSONS && window.MACIEV_LESSONS.length)
                    ? window.MACIEV_LESSONS
                    : defaultLessons;
                const saved = storage.get('chechen_custom_lessons', null);
                const version = storage.get('chechen_lessons_version', 0);

                if (!Array.isArray(saved) || saved.length === 0 || version < 5) {
                    storage.set('chechen_lessons_version', 5);
                    const customs = Array.isArray(saved)
                        ? saved.filter(l => l && l.id && String(l.id).startsWith('custom_'))
                        : [];
                    const merged = [...customs, ...base];
                    storage.set('chechen_custom_lessons', merged);
                    return merged;
                }

                const valid = saved.filter(l => l && Array.isArray(l.words) && l.words.length > 0);
                if (valid.length === 0) {
                    storage.set('chechen_custom_lessons', base);
                    return base;
                }
                return valid;
            }

            getLessonMastery(lessonId) {
                return this.mastery[lessonId] || { percent: 0, completedModes: [] };
            }

            addLessonMastery(lessonId, mode, amount = 25) {
                const m = this.getLessonMastery(lessonId);
                if (!m.completedModes.includes(mode)) m.completedModes.push(mode);
                m.percent = Math.min(100, m.percent + amount);
                this.mastery[lessonId] = m;
                this.lastLessonId = lessonId;
                storage.set('chechen_mastery', this.mastery);
                storage.set('chechen_last_lesson', lessonId);
                this.renderDashboard();
                this.renderLessonsGrid();
            }

            renderDashboard() {
                const el = document.getElementById('dashboard-continue');
                if (!el) return;
                const lesson = this.lastLessonId
                    ? this.lessons.find(l => l.id === this.lastLessonId)
                    : this.lessons[0];
                if (!lesson) {
                    el.innerHTML = '';
                    return;
                }
                const m = this.getLessonMastery(lesson.id);
                el.innerHTML = `
                    <div class="ka-continue-card" id="btn-continue-lesson">
                        <div class="ka-continue-label">Продолжить обучение</div>
                        <div class="ka-continue-title">${lesson.icon} ${lesson.title}</div>
                        <div class="ka-continue-ce">${lesson.chechenTitle} · ${lesson.words.length} слов</div>
                        <div class="ka-progress-bar"><div class="ka-progress-fill" style="width:${m.percent}%"></div></div>
                        <div class="ka-continue-meta">Освоено: ${m.percent}%</div>
                    </div>`;
                document.getElementById('btn-continue-lesson').onclick = () => {
                    playSound('tap');
                    this.openLessonModes(lesson);
                };
                const totalPct = this.lessons.length
                    ? Math.round(this.lessons.reduce((s, l) => s + this.getLessonMastery(l.id).percent, 0) / this.lessons.length)
                    : 0;
                const ring = document.getElementById('course-progress-text');
                if (ring) ring.textContent = `${totalPct}% курса`;
            }

            async loadMacievDictionary() {
                try {
                    const res = await fetch('dictionary.json');
                    if (!res.ok) throw new Error('Dictionary not found');
                    const data = await res.json();
                    this.macievDictionary = data.entries || [];
                    const badge = document.getElementById('dict-source-badge');
                    if (badge) {
                        const src = (data.sources || []).map(s => s.title.split(' ')[0]).join(' + ');
                        badge.textContent = `${data.totalEntries} слов · ${src || 'Мациев + Алироев'}`;
                    }
                } catch (e) {
                    this.macievDictionary = [];
                    const badge = document.getElementById('dict-source-badge');
                    if (badge) {
                        badge.textContent = 'Словарь Мациева (запустите через локальный сервер)';
                    }
                }
            }

            // Save user progression instantly
            saveProgress() {
                storage.set('chechen_stars', this.stars);
                storage.set('chechen_xp', this.xp);
                storage.set('chechen_streak', this.streak);
                storage.set('chechen_inventory', this.inventory);
                storage.set('chechen_equipped', this.equipped);
                storage.set('chechen_custom_lessons', this.lessons);
                this.updateStatsUI();
            }

            addRewards(addedXp, addedStars) {
                this.xp += addedXp;
                this.stars += addedStars;
                this.saveProgress();
                shootConfetti();
            }

            // Set mascot text
            setMascot(msg) {
                document.getElementById('mascot-message').innerHTML = msg;
            }

            // Update Header Stats
            updateStatsUI() {
                const curLevel = Math.floor(this.xp / 100) + 1;
                document.getElementById('stat-level-text').innerText = `Уровень ${curLevel}`;
                document.getElementById('stat-streak-text').innerText = `${this.streak} дня`;
                document.getElementById('stat-stars-text').innerText = `${this.stars}`;
                document.getElementById('shop-balance-text').innerText = `${this.stars}`;
            }

            // Update Equipped Mascot Items
            updateMascotVisuals() {
                const h = shopItems.find(i => i.id === this.equipped['hat']);
                const g = shopItems.find(i => i.id === this.equipped['glasses']);
                const f = shopItems.find(i => i.id === this.equipped['friend']);

                document.getElementById('mascot-eq-hat').innerText = h ? h.icon : '';
                document.getElementById('mascot-eq-glasses').innerText = g ? g.icon : '';
                document.getElementById('mascot-eq-friend').innerText = f ? f.icon : '';
            }

            // Screen switcher with rigorous timeout cancellation
            switchScreen(targetId) {
                if (this.activeTimer) {
                    clearTimeout(this.activeTimer);
                    this.activeTimer = null;
                }
                document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
                document.getElementById(targetId).classList.add('active');
            }

            // Helper to exit any mini-game safely
            exitMiniGame() {
                playSound('tap');
                this.activeGameMode = null;
                if (this.activeTimer) {
                    clearTimeout(this.activeTimer);
                    this.activeTimer = null;
                }
                this.switchScreen('screen-lesson-modes');
                this.setMascot(`Тема "${this.activeLesson.title}" (${this.activeLesson.chechenTitle}). В какой тренажер сыграем?`);
            }

            // Bind persistent buttons
            bindGlobalEvents() {
                document.getElementById('brand-home-btn').onclick = () => {
                    playSound('tap');
                    this.activeGameMode = null;
                    this.switchScreen('screen-lessons-menu');
                    this.setMascot("Салам! Что выберем сегодня?");
                };
                document.getElementById('btn-open-shop').onclick = () => {
                    playSound('tap');
                    this.activeGameMode = null;
                    this.renderShop();
                    this.switchScreen('screen-shop');
                    this.setMascot("Добро пожаловать в Магазин! Выбери классный наряд за заработанные звездочки!");
                };
                document.getElementById('btn-shop-back').onclick = () => {
                    playSound('tap');
                    this.switchScreen('screen-lessons-menu');
                };
                document.getElementById('btn-modes-back').onclick = () => {
                    playSound('tap');
                    this.activeGameMode = null;
                    this.switchScreen('screen-lessons-menu');
                };
                document.getElementById('btn-open-import').onclick = () => {
                    playSound('tap');
                    this.activeGameMode = null;
                    this.switchScreen('screen-import');
                    this.setMascot("Портал создания уроков: здесь можно вставить слова из любого домашнего задания или вашего файла!");
                };
                document.getElementById('btn-import-back').onclick = () => {
                    playSound('tap');
                    this.switchScreen('screen-lessons-menu');
                };
                document.getElementById('btn-open-dictionary').onclick = () => {
                    playSound('tap');
                    this.activeGameMode = null;
                    this.dictSearchQuery = '';
                    this.dictVisibleCount = 80;
                    const searchInput = document.getElementById('dict-search-input');
                    if (searchInput) searchInput.value = '';
                    this.renderDictionary();
                    this.switchScreen('screen-dictionary');
                    this.setMascot("Словарь Мациева: 7600+ слов! Ищи на чеченском или русском и нажми 🔊 чтобы послушать.");
                };
                document.getElementById('btn-dict-back').onclick = () => {
                    playSound('tap');
                    this.switchScreen('screen-lessons-menu');
                };
                const dictSearch = document.getElementById('dict-search-input');
                if (dictSearch) {
                    dictSearch.oninput = (e) => {
                        clearTimeout(this.dictSearchTimer);
                        this.dictSearchTimer = setTimeout(() => {
                            this.dictSearchQuery = e.target.value;
                            this.dictVisibleCount = 80;
                            this.renderDictionary();
                        }, 250);
                    };
                }
                const dictLoadMore = document.getElementById('btn-dict-load-more');
                if (dictLoadMore) {
                    dictLoadMore.onclick = () => {
                        playSound('tap');
                        this.dictVisibleCount += 80;
                        this.renderDictionary();
                    };
                }

                // Mini-Game Back Buttons
                document.getElementById('btn-cards-back').onclick = () => this.exitMiniGame();
                document.getElementById('btn-quiz-back').onclick = () => this.exitMiniGame();
                document.getElementById('btn-match-back').onclick = () => this.exitMiniGame();
                document.getElementById('btn-const-back').onclick = () => this.exitMiniGame();

                // Execute Custom Import
                document.getElementById('btn-execute-import').onclick = () => {
                    this.executeImportLesson();
                };
            }

            // --- RENDER LESSONS GRID ---
            renderLessonsGrid() {
                const container = document.getElementById('grid-lessons-container');
                container.innerHTML = '';

                this.lessons.forEach(l => {
                    const m = this.getLessonMastery(l.id);
                    const card = document.createElement('div');
                    card.className = 'card-lesson';
                    card.innerHTML = `
                        <div class="card-lesson-bg-glow" style="background: ${l.color}"></div>
                        <div class="card-lesson-top">
                            <div class="lesson-icon-box" style="background: ${l.color}">${l.icon}</div>
                            <div class="lesson-word-count">${l.words.length} слов</div>
                        </div>
                        <div class="card-lesson-mid">
                            <div class="lesson-chechen-title">${l.chechenTitle}</div>
                            <div class="lesson-russian-title">${l.title}</div>
                        </div>
                        <div class="ka-unit-progress"><div class="ka-progress-fill" style="width:${m.percent}%"></div></div>
                        <div class="card-lesson-btm">
                            <span>${m.percent >= 100 ? 'Повторить' : m.percent > 0 ? 'Продолжить' : 'Начать'}</span>
                            <span style="font-size: 16px">▶</span>
                        </div>
                    `;

                    card.onclick = () => {
                        playSound('tap');
                        this.openLessonModes(l);
                    };
                    container.appendChild(card);
                });
            }

            // Open Modes screen
            openLessonModes(lesson) {
                this.activeLesson = lesson;
                document.getElementById('mode-header-chechen').innerText = lesson.chechenTitle;
                document.getElementById('mode-header-russian').innerText = lesson.title;
                this.switchScreen('screen-lesson-modes');
                this.setMascot(`Тема "${lesson.title}" (${lesson.chechenTitle}). Отличный выбор! В какой тренажер сыграем?`);

                // Bind mode cards
                document.querySelectorAll('.card-mode').forEach(card => {
                    card.onclick = () => {
                        playSound('tap');
                        const mode = card.getAttribute('data-mode');
                        this.activeGameMode = mode;
                        if (mode === 'cards') this.startCardsGame();
                        else if (mode === 'quiz') this.startQuizGame();
                        else if (mode === 'matching') this.startMatchingGame();
                        else if (mode === 'constructor') this.startConstructorGame();
                    };
                });
            }

            // --- GAME 1: FLASHCARDS ---
            startCardsGame() {
                this.currentCardIdx = 0;
                this.switchScreen('screen-game-cards');
                this.renderCurrentCard();
                this.setMascot("Обучающие карточки! Нажимай на карточку, чтобы перевернуть, и слушай произношение.");

                // Event handlers
                document.getElementById('btn-cards-speak').onclick = () => { speakWord(this.activeLesson.words[this.currentCardIdx].chechen); };
                document.getElementById('flashcard-scene').onclick = () => {
                    playSound('tap');
                    const wrap = document.getElementById('flashcard-wrapper');
                    wrap.classList.toggle('flipped');
                    if (!wrap.classList.contains('flipped')) {
                        speakWord(this.activeLesson.words[this.currentCardIdx].chechen);
                    }
                };

                document.getElementById('btn-cards-prev').onclick = () => {
                    if (this.currentCardIdx > 0) {
                        playSound('tap');
                        this.currentCardIdx--;
                        this.renderCurrentCard();
                    }
                };
                document.getElementById('btn-cards-next').onclick = () => {
                    playSound('tap');
                    if (this.currentCardIdx < this.activeLesson.words.length - 1) {
                        this.currentCardIdx++;
                        this.renderCurrentCard();
                    } else {
                        // Completed!
                        this.addRewards(30, 3);
                        this.addLessonMastery(this.activeLesson.id, 'cards', 25);
                        this.setMascot("Ура! Ты просмотрел все карточки и заработал +3 звездочки!");
                        this.exitMiniGame();
                    }
                };
            }

            renderCurrentCard() {
                const word = this.activeLesson.words[this.currentCardIdx];
                document.getElementById('flashcard-wrapper').classList.remove('flipped');
                document.getElementById('cards-progress-text').innerText = `Карточка ${this.currentCardIdx + 1} / ${this.activeLesson.words.length}`;
                
                document.getElementById('card-front-emoji').innerText = word.emoji;
                document.getElementById('card-front-word').innerText = word.chechen;
                document.getElementById('card-front-phonetic').innerText = `[${word.pronunciation}]`;

                document.getElementById('card-back-emoji').innerText = word.emoji;
                document.getElementById('card-back-word').innerText = word.russian;
                document.getElementById('card-back-hint').innerText = `💡 ${word.hint}`;

                // Prev/Next states
                document.getElementById('btn-cards-prev').disabled = (this.currentCardIdx === 0);
                if (this.currentCardIdx === this.activeLesson.words.length - 1) {
                    document.getElementById('cards-next-text').innerText = "Завершить ⭐️";
                    document.getElementById('cards-next-arrow').innerText = "✓";
                } else {
                    document.getElementById('cards-next-text').innerText = "Следующая";
                    document.getElementById('cards-next-arrow').innerText = "▶";
                }

                speakWord(word.chechen);
            }

            // --- GAME 2: VISUAL QUIZ ---
            startQuizGame() {
                this.currentCardIdx = 0;
                this.quizScore = 0;
                this.switchScreen('screen-game-quiz');
                this.renderCurrentQuiz();
                this.setMascot("Викторина! Слушай слово и выбирай правильную картинку из четырех!");
            }

            // Helper to pull extra random options if a lesson is incredibly short
            getQuizAlternatives(targetWord) {
                const sameLessonOthers = this.activeLesson.words.filter(w => w.chechen !== targetWord.chechen);
                if (sameLessonOthers.length >= 3) {
                    return [...sameLessonOthers].sort(() => 0.5 - Math.random()).slice(0, 3);
                }

                // If lesson has fewer than 4 words, pull from all lessons
                const globalOthers = [];
                this.lessons.forEach(l => {
                    l.words.forEach(w => {
                        if (w.chechen !== targetWord.chechen) globalOthers.push(w);
                    });
                });
                
                const uniqueOthers = [];
                const seen = new Set([targetWord.chechen]);
                sameLessonOthers.forEach(w => { seen.add(w.chechen); uniqueOthers.push(w); });

                const shuffledGlobal = [...globalOthers].sort(() => 0.5 - Math.random());
                for (let w of shuffledGlobal) {
                    if (uniqueOthers.length >= 3) break;
                    if (!seen.has(w.chechen)) {
                        seen.add(w.chechen);
                        uniqueOthers.push(w);
                    }
                }
                return uniqueOthers;
            }

            renderCurrentQuiz() {
                if (this.activeGameMode !== 'quiz') return;
                const targetWord = this.activeLesson.words[this.currentCardIdx];
                document.getElementById('quiz-progress-text').innerText = `Вопрос ${this.currentCardIdx + 1} / ${this.activeLesson.words.length}`;
                document.getElementById('quiz-score-text').innerText = `★ ${this.quizScore}`;
                
                document.getElementById('quiz-question-word').innerText = targetWord.chechen;
                document.getElementById('quiz-question-phonetic').innerText = `[${targetWord.pronunciation}]`;

                // Build exactly 4 options
                const falseOpts = this.getQuizAlternatives(targetWord);
                const allOpts = [...falseOpts, targetWord].sort(() => 0.5 - Math.random());

                const optionsContainer = document.getElementById('quiz-options-container');
                optionsContainer.innerHTML = '';

                let answered = false;
                allOpts.forEach(opt => {
                    const btn = document.createElement('div');
                    btn.className = 'quiz-option-btn';
                    btn.innerHTML = `
                        <div class="quiz-opt-emoji">${opt.emoji}</div>
                        <div class="quiz-opt-label">${opt.russian}</div>
                    `;

                    btn.onclick = () => {
                        if (answered || this.activeGameMode !== 'quiz') return;
                        answered = true;
                        
                        if (opt.chechen === targetWord.chechen) {
                            btn.classList.add('correct');
                            playSound('success');
                            this.quizScore++;
                            this.setMascot("Нийса ду! Абсолютно верно! Ты молодец!");
                        } else {
                            btn.classList.add('wrong');
                            playSound('wrong');
                            this.setMascot(`Ой! Правильным ответом было: ${targetWord.chechen} (${targetWord.russian}).`);
                            Array.from(optionsContainer.children).forEach(childBtn => {
                                if (childBtn.innerText.includes(targetWord.russian)) {
                                    childBtn.style.borderColor = '#10b981';
                                    childBtn.style.background = '#ecfdf5';
                                }
                            });
                        }

                        document.getElementById('quiz-score-text').innerText = `★ ${this.quizScore}`;

                        this.activeTimer = setTimeout(() => {
                            this.activeTimer = null;
                            if (this.activeGameMode !== 'quiz') return;
                            if (this.currentCardIdx < this.activeLesson.words.length - 1) {
                                this.currentCardIdx++;
                                this.renderCurrentQuiz();
                            } else {
                                this.addRewards(50, 5);
                                this.addLessonMastery(this.activeLesson.id, 'quiz', 25);
                                this.setMascot(`Умница! Викторина пройдена! Правильных ответов: ${this.quizScore}. Заработано 5 звездочек!`);
                                this.exitMiniGame();
                            }
                        }, 1800);
                    };
                    optionsContainer.appendChild(btn);
                });

                speakWord(targetWord.chechen);
            }

            // --- GAME 3: PAIR MATCHING ---
            startMatchingGame() {
                this.matchingPairs = [];
                this.selectedMatchChechen = null;
                this.selectedMatchRussian = null;
                this.isMatchingBusy = false;
                this.switchScreen('screen-game-matching');
                this.renderMatchingBoard();
                this.setMascot("Головоломка! Соедини чеченское слово с его русским значением!");
            }

            renderMatchingBoard() {
                const matchWords = this.activeLesson.words.slice(0, 5);
                const chechenList = [...matchWords].sort(() => 0.5 - Math.random());
                const russianList = [...matchWords].sort(() => 0.5 - Math.random());

                document.getElementById('match-pairs-count').innerText = `✓ 0 / ${matchWords.length}`;

                const chContainer = document.getElementById('match-col-chechen-btns');
                const ruContainer = document.getElementById('match-col-russian-btns');
                chContainer.innerHTML = '';
                ruContainer.innerHTML = '';

                // Chechen buttons
                chechenList.forEach(w => {
                    const btn = document.createElement('div');
                    btn.className = 'btn-match';
                    btn.setAttribute('data-word', w.chechen);
                    btn.innerText = w.chechen;

                    btn.onclick = () => {
                        if (this.isMatchingBusy || btn.classList.contains('matched') || this.activeGameMode !== 'matching') return;
                        playSound('tap');
                        Array.from(chContainer.children).forEach(b => b.classList.remove('selected'));
                        btn.classList.add('selected');
                        this.selectedMatchChechen = w;
                        this.checkMatchingPair(matchWords.length);
                    };
                    chContainer.appendChild(btn);
                });

                // Russian buttons
                russianList.forEach(w => {
                    const btn = document.createElement('div');
                    btn.className = 'btn-match';
                    btn.setAttribute('data-word', w.chechen);
                    btn.innerHTML = `<span style="font-size: 28px">${w.emoji}</span> <span>${w.russian}</span>`;

                    btn.onclick = () => {
                        if (this.isMatchingBusy || btn.classList.contains('matched') || this.activeGameMode !== 'matching') return;
                        playSound('tap');
                        Array.from(ruContainer.children).forEach(b => b.classList.remove('selected-rus'));
                        btn.classList.add('selected-rus');
                        this.selectedMatchRussian = w;
                        this.checkMatchingPair(matchWords.length);
                    };
                    ruContainer.appendChild(btn);
                });
            }

            checkMatchingPair(totalCount) {
                if (!this.selectedMatchChechen || !this.selectedMatchRussian) return;

                this.isMatchingBusy = true;
                const chContainer = document.getElementById('match-col-chechen-btns');
                const ruContainer = document.getElementById('match-col-russian-btns');

                const chBtn = Array.from(chContainer.children).find(b => b.getAttribute('data-word') === this.selectedMatchChechen.chechen);
                const ruBtn = Array.from(ruContainer.children).find(b => b.getAttribute('data-word') === this.selectedMatchRussian.chechen);

                if (this.selectedMatchChechen.chechen === this.selectedMatchRussian.chechen) {
                    // Match!
                    playSound('success');
                    chBtn.classList.remove('selected');
                    ruBtn.classList.remove('selected-rus');
                    chBtn.classList.add('matched');
                    ruBtn.classList.add('matched');
                    this.matchingPairs.push(this.selectedMatchChechen.chechen);
                    
                    this.selectedMatchChechen = null;
                    this.selectedMatchRussian = null;
                    this.isMatchingBusy = false;
                    this.setMascot("Супер! Идеальное совпадение!");

                    document.getElementById('match-pairs-count').innerText = `✓ ${this.matchingPairs.length} / ${totalCount}`;

                    if (this.matchingPairs.length === totalCount) {
                        this.activeTimer = setTimeout(() => {
                            this.activeTimer = null;
                            if (this.activeGameMode !== 'matching') return;
                            this.addRewards(60, 6);
                            this.addLessonMastery(this.activeLesson.id, 'matching', 25);
                            this.setMascot("Вау! Ты соединил все слова как настоящий знаток! Получено 6 звездочек!");
                            this.exitMiniGame();
                        }, 1200);
                    }
                } else {
                    // Wrong match
                    playSound('wrong');
                    this.setMascot("Не совсем... Эти карточки не подходят друг к другу.");
                    chBtn.style.animation = 'error-shake 0.4s ease';
                    ruBtn.style.animation = 'error-shake 0.4s ease';

                    this.activeTimer = setTimeout(() => {
                        this.activeTimer = null;
                        if (this.activeGameMode !== 'matching') return;
                        chBtn.classList.remove('selected');
                        ruBtn.classList.remove('selected-rus');
                        chBtn.style.animation = '';
                        ruBtn.style.animation = '';
                        this.selectedMatchChechen = null;
                        this.selectedMatchRussian = null;
                        this.isMatchingBusy = false;
                    }, 700);
                }
            }

            // --- GAME 4: WORD CONSTRUCTOR ---
            startConstructorGame() {
                this.currentCardIdx = 0;
                this.switchScreen('screen-game-constructor');
                document.getElementById('btn-const-reset').onclick = () => { playSound('tap'); this.renderCurrentConstructor(); };
                this.renderCurrentConstructor();
                this.setMascot("Собери слово из букв! Нажимай на плавающие буквы в правильном порядке.");
            }

            renderCurrentConstructor() {
                if (this.activeGameMode !== 'constructor') return;
                const targetWord = this.activeLesson.words[this.currentCardIdx];
                document.getElementById('const-progress-text').innerText = `Слово ${this.currentCardIdx + 1} / ${this.activeLesson.words.length}`;
                document.getElementById('const-target-emoji').innerText = targetWord.emoji;
                document.getElementById('const-target-russian').innerText = targetWord.russian;
                document.getElementById('const-target-hint').innerText = `Подсказка: [${targetWord.pronunciation}]`;

                const letters = targetWord.chechen.toUpperCase().split('');
                this.constSpelled = [];
                this.constAvailable = [...letters].sort(() => 0.5 - Math.random());

                this.updateConstructorSlotsUI(letters);
                speakWord(targetWord.chechen);
            }

            updateConstructorSlotsUI(wordLetters) {
                if (this.activeGameMode !== 'constructor') return;
                const slotsContainer = document.getElementById('const-slots-container');
                slotsContainer.innerHTML = '';
                
                wordLetters.forEach((_, idx) => {
                    const char = this.constSpelled[idx];
                    const slot = document.createElement('div');
                    slot.className = `letter-slot ${char ? 'filled' : 'empty'}`;
                    slot.innerText = char ? char : '?';
                    slotsContainer.appendChild(slot);
                });

                // Available tiles
                const tilesContainer = document.getElementById('const-letters-container');
                tilesContainer.innerHTML = '';

                this.constAvailable.forEach((char, availIdx) => {
                    const tile = document.createElement('div'); tile.className = 'btn-letter-tile';
                    tile.innerText = char;

                    tile.onclick = () => {
                        if (this.constSpelled.length >= wordLetters.length || this.activeGameMode !== 'constructor') return;
                        playSound('tap');
                        tile.classList.add('used');
                        this.constSpelled.push(char);
                        
                        // Remove from avail
                        this.constAvailable.splice(availIdx, 1);
                        this.updateConstructorSlotsUI(wordLetters);

                        // Check word completion
                        if (this.constSpelled.length === wordLetters.length) {
                            if (this.constSpelled.join('') === wordLetters.join('')) {
                                playSound('success');
                                this.setMascot("Браво! Слово собрано абсолютно верно!");
                                this.activeTimer = setTimeout(() => {
                                    this.activeTimer = null;
                                    if (this.activeGameMode !== 'constructor') return;
                                    if (this.currentCardIdx < this.activeLesson.words.length - 1) {
                                        this.currentCardIdx++;
                                        this.renderCurrentConstructor();
                                    } else {
                                        this.addRewards(80, 8);
                                        this.addLessonMastery(this.activeLesson.id, 'constructor', 25);
                                        this.setMascot("Ура! Все слова собраны! Ты мастер чеченского языка! Заработано 8 звездочек!");
                                        this.exitMiniGame();
                                    }
                                }, 1400);
                            } else {
                                playSound('wrong');
                                this.setMascot("Ой! Похоже, буквы перепутались местами. Попробуем еще раз!"); 
                                slotsContainer.style.animation = 'error-shake 0.5s ease';
                                this.activeTimer = setTimeout(() => {
                                    this.activeTimer = null;
                                    if (this.activeGameMode !== 'constructor') return;
                                    slotsContainer.style.animation = '';
                                    this.renderCurrentConstructor();
                                }, 1100);
                            }
                        }
                    };
                    tilesContainer.appendChild(tile);
                });
            }

            // --- REWARD SHOP ---
            renderShop() {
                const container = document.getElementById('shop-items-container');
                container.innerHTML = '';

                shopItems.forEach(item => {
                    const isOwned = this.inventory.includes(item.id);
                    const isEq = this.equipped[item.type] === item.id;

                    const card = document.createElement('div');
                    card.className = 'card-shop-item';
                    card.innerHTML = `
                        <div class="shop-item-icon-box">${item.icon}</div>
                        <div>
                            <h3 class="shop-item-name">${item.name}</h3>
                            <p class="shop-item-desc">${item.desc}</p>
                        </div>
                    `;

                    const btn = document.createElement('button');
                    if (isOwned) {
                        if (isEq) {
                            btn.className = 'shop-btn-action shop-btn-unequip';
                            btn.innerHTML = `<span>Снять</span>`;
                            btn.onclick = () => { playSound('tap'); delete this.equipped[item.type]; this.saveProgress(); this.renderShop(); this.updateMascotVisuals(); };
                        } else {
                            btn.className = 'shop-btn-action shop-btn-equip';
                            btn.innerHTML = `<span>Надеть ✓</span>`;
                            btn.onclick = () => { playSound('tap'); this.equipped[item.type] = item.id; this.saveProgress(); this.renderShop(); this.updateMascotVisuals(); shootConfetti(); };
                        }
                    } else {
                        btn.className = 'shop-btn-action shop-btn-buy';
                        btn.innerHTML = `<span>Купить за ${item.price}</span> <span style="font-size: 16px">⭐️</span>`;
                        btn.onclick = () => {
                            if (this.stars >= item.price) {
                                this.stars -= item.price;
                                this.inventory.push(item.id);
                                this.equipped[item.type] = item.id;
                                this.saveProgress();
                                this.renderShop();
                                this.updateMascotVisuals();
                                this.setMascot(`Ура! Новая обновка: ${item.name}! Какая красота!`);
                                shootConfetti();
                            } else {
                                playSound('wrong');
                                this.setMascot("Не хватает звездочек! Пройди еще игры, чтобы заработать!");
                            }
                        };
                    }
                    card.appendChild(btn);
                    container.appendChild(card);
                });
            }

            // --- MACIEV DICTIONARY (FULL LEXICON WITH SEARCH) ---
            renderDictionary() {
                const container = document.getElementById('dict-words-container');
                const countEl = document.getElementById('dict-count-text');
                const loadMoreBtn = document.getElementById('btn-dict-load-more');
                container.innerHTML = '';

                let allWords = [];

                if (this.macievDictionary.length > 0) {
                    allWords = this.macievDictionary.map(w => ({
                        chechen: w.chechen,
                        russian: w.russian,
                        pronunciation: w.pronunciation || w.chechen,
                        emoji: w.emoji || '📖',
                        sources: w.sources || ['maciev'],
                        categoryTitle: w.category ? w.category : 'Словарь'
                    }));
                } else {
                    const seen = new Set();
                    this.lessons.forEach(l => {
                        l.words.forEach(w => {
                            if (!seen.has(w.chechen)) {
                                seen.add(w.chechen);
                                allWords.push({ ...w, categoryTitle: l.title });
                            }
                        });
                    });
                }

                const query = (this.dictSearchQuery || '').trim().toLowerCase();
                if (query) {
                    allWords = allWords.filter(w =>
                        w.chechen.toLowerCase().includes(query) ||
                        w.russian.toLowerCase().includes(query)
                    );
                } else {
                    allWords.sort((a, b) => a.chechen.localeCompare(b.chechen, 'ru'));
                }

                const total = allWords.length;
                const toShow = allWords.slice(0, this.dictVisibleCount);

                if (countEl) {
                    countEl.textContent = query
                        ? `Найдено: ${total} слов`
                        : `Показано ${toShow.length} из ${total} слов`;
                }

                if (loadMoreBtn) {
                    loadMoreBtn.style.display = this.dictVisibleCount < total ? 'block' : 'none';
                }

                if (toShow.length === 0) {
                    container.innerHTML = '<div class="dict-empty">Ничего не найдено. Попробуйте другое слово.</div>';
                    return;
                }

                toShow.forEach(w => {
                    const srcLabel = (w.sources || []).includes('curated') ? '✓ проверено' :
                        (w.sources || []).includes('aliroev') ? 'Алироев' : 'Мациев';
                    const card = document.createElement('div');
                    card.className = 'card-dict-word';
                    card.innerHTML = `
                        <div class="dict-emoji-box">${w.emoji || '📖'}</div>
                        <div class="dict-info">
                            <div class="dict-chechen">${w.chechen}</div>
                            <div class="dict-russian">${w.russian}</div>
                            <div class="dict-pronunciation">${w.pronunciation || w.chechen} · <span class="dict-src">${srcLabel}</span></div>
                        </div>
                        <button class="btn-dict-audio" title="Произнести">🔊</button>
                    `;

                    card.querySelector('.btn-dict-audio').onclick = (e) => {
                        e.stopPropagation();
                        speakWord(w.chechen);
                    };

                    card.onclick = () => { speakWord(w.chechen); };
                    container.appendChild(card);
                });
            }

            // --- EXECUTE IMPORT LESSON ---
            executeImportLesson() {
                const titleInput = document.getElementById('import-title').value.trim() || 'Мой Урок';
                const chechenTitleInput = document.getElementById('import-chechen-title').value.trim() || 'Сан Дарс';
                const wordsText = document.getElementById('import-words-text').value.trim();

                const lines = wordsText.split('\n');
                const parsedWords = [];

                lines.forEach(line => {
                    if (!line.trim()) return;
                    // Format: Чеченское - Русское | Эмодзи
                    const parts = line.split(/[|\-—=]/);
                    const chechen = parts[0] ? parts[0].trim() : '';
                    const russian = parts[1] ? parts[1].trim() : '';
                    let emoji = '⭐️';
                    if (parts[2]) {
                        emoji = parts[2].trim();
                    } else {
                        const matchEmoji = russian.match(/\p{Extended_Pictographic}/u);
                        if (matchEmoji) emoji = matchEmoji[0];
                    }

                    if (chechen && russian) {
                        parsedWords.push({
                            chechen: chechen[0].toUpperCase() + chechen.slice(1),
                            russian: russian[0].toUpperCase() + russian.slice(1),
                            pronunciation: chechen,
                            emoji: emoji,
                            hint: `Слово из твоего списка: ${russian}`
                        });
                    }
                });

                if (parsedWords.length < 2) {
                    playSound('wrong');
                    alert("Пожалуйста, добавьте хотя бы 2 пары слов (например: Говр - Лошадь)");
                    return;
                }

                const newLesson = {
                    id: `custom_${Date.now()}`,
                    title: titleInput,
                    chechenTitle: chechenTitleInput,
                    icon: '🌟',
                    color: 'linear-gradient(135deg, #10b981, #06b6d4)',
                    words: parsedWords
                };

                this.lessons = [newLesson, ...this.lessons];
                this.saveProgress();
                this.renderLessonsGrid();
                this.switchScreen('screen-lessons-menu');
                this.setMascot(`Супер! Ваш собственный урок "${titleInput}" успешно создан и добавлен на главное меню!`);
                shootConfetti();
            }

            initUI() {
                console.log("Chechen Premium iOS App initialized successfully");
            }
        }

        // --- Execute Application Instantly on DOM Load or Ready State ---
        const initApp = () => {
            try {
                if (!window.ChechenApp) {
                    window.ChechenApp = new ChechenGameApp();
                }
            } catch (err) {
                console.error('ChechenApp init failed:', err);
                const container = document.getElementById('grid-lessons-container');
                if (container) {
                    container.innerHTML = '<div class="dict-empty">Ошибка запуска. Обновите страницу (Ctrl+F5).</div>';
                }
            }
        };

        if (document.readyState === 'loading') {
            window.addEventListener('DOMContentLoaded', initApp);
        } else {
            initApp();
        }