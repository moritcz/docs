// ── Data Layer ──
const STORAGE_KEY = 'expense_tracker_data';
const CATEGORIES_KEY = 'expense_tracker_categories';

const DEFAULT_CATEGORIES = {
  expense: [
    { id: 'food', emoji: '\ud83c\udf5c', name: '\u0415\u0434\u0430', color: '#e16259' },
    { id: 'transport', emoji: '\ud83d\ude8c', name: '\u0422\u0440\u0430\u043d\u0441\u043f\u043e\u0440\u0442', color: '#e8a44a' },
    { id: 'shopping', emoji: '\ud83d\udecd\ufe0f', name: '\u041f\u043e\u043a\u0443\u043f\u043a\u0438', color: '#9b59b6' },
    { id: 'entertainment', emoji: '\ud83c\udfac', name: '\u0420\u0430\u0437\u0432\u043b\u0435\u0447\u0435\u043d\u0438\u044f', color: '#e67e22' },
    { id: 'health', emoji: '\ud83d\udc8a', name: '\u0417\u0434\u043e\u0440\u043e\u0432\u044c\u0435', color: '#2ecc71' },
    { id: 'home', emoji: '\ud83c\udfe0', name: '\u0414\u043e\u043c', color: '#3498db' },
    { id: 'education', emoji: '\ud83d\udcda', name: '\u041e\u0431\u0440\u0430\u0437\u043e\u0432\u0430\u043d\u0438\u0435', color: '#1abc9c' },
    { id: 'other_exp', emoji: '\ud83d\udce6', name: '\u0414\u0440\u0443\u0433\u043e\u0435', color: '#95a5a6' },
  ],
  income: [
    { id: 'salary', emoji: '\ud83d\udcb0', name: '\u0417\u0430\u0440\u043f\u043b\u0430\u0442\u0430', color: '#4dab9a' },
    { id: 'freelance', emoji: '\ud83d\udcbb', name: '\u0424\u0440\u0438\u043b\u0430\u043d\u0441', color: '#2eaadc' },
    { id: 'gift', emoji: '\ud83c\udf81', name: '\u041f\u043e\u0434\u0430\u0440\u043e\u043a', color: '#e67e22' },
    { id: 'other_inc', emoji: '\ud83d\udcb8', name: '\u0414\u0440\u0443\u0433\u043e\u0435', color: '#9b59b6' },
  ],
};

const EMOJI_PICKER = [
  '\ud83d\udcb0','\ud83d\udcb8','\ud83d\udcb3','\ud83c\udfe6','\ud83d\uded2','\ud83c\udf5c','\ud83c\udf55','\u2615',
  '\ud83d\ude97','\ud83d\ude8c','\u2708\ufe0f','\u26fd','\ud83c\udfe0','\ud83d\udee0\ufe0f','\ud83d\udca1','\ud83d\udcf1',
  '\ud83d\udc8a','\ud83c\udfcb\ufe0f','\ud83c\udfac','\ud83c\udfae','\ud83d\udcda','\ud83c\udf81','\ud83d\udc55','\u2702\ufe0f',
  '\ud83d\udc36','\ud83c\udf33','\ud83c\udfd6\ufe0f','\ud83c\udfb5','\ud83d\udcbb','\ud83d\udce6','\u2b50','\u2764\ufe0f',
];

const COLOR_PICKER = [
  '#e16259','#e8a44a','#e67e22','#9b59b6','#2ecc71','#3498db',
  '#1abc9c','#4dab9a','#2eaadc','#95a5a6','#e74c3c','#34495e',
];

function loadData() {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEY)) || [];
  } catch {
    return [];
  }
}

function saveData(transactions) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(transactions));
}

function loadCustomCategories() {
  try {
    return JSON.parse(localStorage.getItem(CATEGORIES_KEY)) || { expense: [], income: [] };
  } catch {
    return { expense: [], income: [] };
  }
}

function saveCustomCategories(cats) {
  localStorage.setItem(CATEGORIES_KEY, JSON.stringify(cats));
}

let customCategories = loadCustomCategories();

function getCategories(type) {
  return [...DEFAULT_CATEGORIES[type], ...customCategories[type]];
}

function findCategory(id) {
  const all = [...DEFAULT_CATEGORIES.expense, ...DEFAULT_CATEGORIES.income,
    ...customCategories.expense, ...customCategories.income];
  return all.find((c) => c.id === id) || DEFAULT_CATEGORIES.expense[7];
}

function formatMoney(n) {
  const abs = Math.abs(n);
  if (abs >= 1_000_000) return (n / 1_000_000).toFixed(1).replace('.0', '') + 'M';
  return n.toLocaleString('ru-RU', { maximumFractionDigits: 0 });
}

// ── Date Helpers ──
function relativeDate(dateStr) {
  const d = new Date(dateStr);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const target = new Date(d);
  target.setHours(0, 0, 0, 0);
  const diff = (today - target) / 86400000;
  if (diff === 0) return '\u0421\u0435\u0433\u043e\u0434\u043d\u044f';
  if (diff === 1) return '\u0412\u0447\u0435\u0440\u0430';
  return d.toLocaleDateString('ru-RU', { day: 'numeric', month: 'short' });
}

function dateKey(dateStr) {
  return new Date(dateStr).toISOString().slice(0, 10);
}

function startOfWeek() {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() - d.getDay() + (d.getDay() === 0 ? -6 : 1));
  return d;
}

function startOfMonth() {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth(), 1);
}

function startOfYear() {
  return new Date(new Date().getFullYear(), 0, 1);
}

// ── App State ──
let transactions = loadData();
let currentTab = 'home';
let currentPeriod = 'month';
let filterType = 'all';
let searchQuery = '';

// ── Filtering ──
function filterByPeriod(list) {
  let cutoff;
  switch (currentPeriod) {
    case 'week': cutoff = startOfWeek(); break;
    case 'month': cutoff = startOfMonth(); break;
    case 'year': cutoff = startOfYear(); break;
    default: return list;
  }
  return list.filter((t) => new Date(t.date) >= cutoff);
}

function getFiltered() {
  let list = filterByPeriod(transactions);
  if (filterType === 'income') list = list.filter((t) => t.isIncome);
  if (filterType === 'expense') list = list.filter((t) => !t.isIncome);
  if (searchQuery) {
    const q = searchQuery.toLowerCase();
    list = list.filter((t) => {
      const cat = findCategory(t.categoryId);
      return (t.note || '').toLowerCase().includes(q) || cat.name.toLowerCase().includes(q);
    });
  }
  return list.sort((a, b) => new Date(b.date) - new Date(a.date));
}

function groupByDate(list) {
  const groups = {};
  for (const t of list) {
    const key = dateKey(t.date);
    (groups[key] = groups[key] || []).push(t);
  }
  return Object.entries(groups)
    .sort(([a], [b]) => b.localeCompare(a))
    .map(([key, items]) => ({
      label: relativeDate(items[0].date),
      total: items.reduce((s, t) => s + (t.isIncome ? t.amount : -t.amount), 0),
      items,
    }));
}

// ── Rendering ──
function render() {
  renderHome();
  renderList();
  renderStats();
}

function renderHome() {
  const page = document.getElementById('page-home');
  const filtered = filterByPeriod(transactions);
  const income = filtered.filter((t) => t.isIncome).reduce((s, t) => s + t.amount, 0);
  const expense = filtered.filter((t) => !t.isIncome).reduce((s, t) => s + t.amount, 0);
  const net = income - expense;
  const pct = income > 0 ? Math.min((expense / income) * 100, 100) : 0;

  const recent = filtered.sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 5);

  const monthNames = ['\u042f\u043d\u0432\u0430\u0440\u044c','\u0424\u0435\u0432\u0440\u0430\u043b\u044c','\u041c\u0430\u0440\u0442','\u0410\u043f\u0440\u0435\u043b\u044c','\u041c\u0430\u0439','\u0418\u044e\u043d\u044c','\u0418\u044e\u043b\u044c','\u0410\u0432\u0433\u0443\u0441\u0442','\u0421\u0435\u043d\u0442\u044f\u0431\u0440\u044c','\u041e\u043a\u0442\u044f\u0431\u0440\u044c','\u041d\u043e\u044f\u0431\u0440\u044c','\u0414\u0435\u043a\u0430\u0431\u0440\u044c'];
  const now = new Date();

  page.innerHTML = `
    <div class="page-header">
      <div class="page-title">\ud83d\udcca \u0424\u0438\u043d\u0430\u043d\u0441\u044b</div>
      <div class="page-subtitle">${monthNames[now.getMonth()]} ${now.getFullYear()}</div>
    </div>

    ${renderPeriodSelector()}

    <div class="balance-row">
      <div class="balance-item">
        <div class="balance-label">\u0414\u043e\u0445\u043e\u0434\u044b</div>
        <div class="balance-amount income">+${formatMoney(income)}</div>
      </div>
      <div class="balance-item">
        <div class="balance-label">\u0420\u0430\u0441\u0445\u043e\u0434\u044b</div>
        <div class="balance-amount expense">\u2212${formatMoney(expense)}</div>
      </div>
    </div>

    <div class="balance-net">
      <div class="balance-label">\u0411\u0430\u043b\u0430\u043d\u0441</div>
      <div class="balance-amount" style="color: ${net >= 0 ? 'var(--income)' : 'var(--expense)'}">
        ${net >= 0 ? '+' : '\u2212'}${formatMoney(Math.abs(net))}
      </div>
    </div>

    <div class="progress-bar-container">
      <div class="progress-bar-fill" style="width: ${pct}%"></div>
    </div>

    <div class="section-heading">\u041f\u043e\u0441\u043b\u0435\u0434\u043d\u0438\u0435 \u0437\u0430\u043f\u0438\u0441\u0438</div>
    <div class="tx-list">
      ${recent.length === 0 ? `
        <div class="empty-state">
          <div class="emoji">\ud83d\udcdd</div>
          <p>\u041d\u0430\u0436\u043c\u0438\u0442\u0435 + \u0447\u0442\u043e\u0431\u044b \u0434\u043e\u0431\u0430\u0432\u0438\u0442\u044c \u0437\u0430\u043f\u0438\u0441\u044c</p>
        </div>
      ` : recent.map(renderTxRow).join('')}
    </div>
  `;
}

function renderList() {
  const page = document.getElementById('page-list');
  const filtered = getFiltered();
  const groups = groupByDate(filtered);

  page.innerHTML = `
    <div class="page-header">
      <div class="page-title">\ud83d\uddd2\ufe0f \u0417\u0430\u043f\u0438\u0441\u0438</div>
    </div>

    <div class="search-bar">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>
      </svg>
      <input type="text" placeholder="\u041f\u043e\u0438\u0441\u043a..." value="${searchQuery}" oninput="searchQuery=this.value;render()"/>
    </div>

    <div class="filter-tabs">
      ${['all', 'expense', 'income'].map((t) => `
        <button class="filter-tab ${filterType === t ? 'active' : ''}" onclick="filterType='${t}';render()">
          ${t === 'all' ? '\u0412\u0441\u0435' : t === 'expense' ? '\u0420\u0430\u0441\u0445\u043e\u0434\u044b' : '\u0414\u043e\u0445\u043e\u0434\u044b'}
        </button>
      `).join('')}
    </div>

    ${renderPeriodSelector()}

    <div class="tx-list">
      ${groups.length === 0 ? `
        <div class="empty-state">
          <div class="emoji">\ud83d\udd0d</div>
          <p>\u041d\u0435\u0442 \u0437\u0430\u043f\u0438\u0441\u0435\u0439</p>
        </div>
      ` : groups.map((g) => `
        <div class="tx-group-header">
          <span>${g.label}</span>
          <span style="color: ${g.total >= 0 ? 'var(--income)' : 'var(--expense)'}">
            ${g.total >= 0 ? '+' : '\u2212'}${formatMoney(Math.abs(g.total))}
          </span>
        </div>
        ${g.items.map(renderTxRow).join('')}
      `).join('')}
    </div>
  `;
}

function renderStats() {
  const page = document.getElementById('page-stats');
  const filtered = filterByPeriod(transactions);
  const expenses = filtered.filter((t) => !t.isIncome);
  const incomes = filtered.filter((t) => t.isIncome);
  const totalExp = expenses.reduce((s, t) => s + t.amount, 0);
  const totalInc = incomes.reduce((s, t) => s + t.amount, 0);

  const byCatExp = {};
  for (const t of expenses) {
    byCatExp[t.categoryId] = (byCatExp[t.categoryId] || 0) + t.amount;
  }
  const catExpList = Object.entries(byCatExp)
    .map(([id, amount]) => ({ cat: findCategory(id), amount }))
    .sort((a, b) => b.amount - a.amount);

  const byCatInc = {};
  for (const t of incomes) {
    byCatInc[t.categoryId] = (byCatInc[t.categoryId] || 0) + t.amount;
  }
  const catIncList = Object.entries(byCatInc)
    .map(([id, amount]) => ({ cat: findCategory(id), amount }))
    .sort((a, b) => b.amount - a.amount);

  page.innerHTML = `
    <div class="page-header">
      <div class="page-title">\ud83d\udcca \u0421\u0442\u0430\u0442\u0438\u0441\u0442\u0438\u043a\u0430</div>
    </div>

    ${renderPeriodSelector()}

    <div class="export-row">
      <button class="export-btn" onclick="exportCSV()">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" width="16" height="16">
          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
          <polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/>
          <line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/>
        </svg>
        CSV / Excel
      </button>
      <button class="export-btn" onclick="exportJSON()">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" width="16" height="16">
          <polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/>
        </svg>
        JSON / Claude
      </button>
    </div>

    <div class="card">
      <div class="card-header">
        <span>\u0420\u0430\u0441\u0445\u043e\u0434\u044b \u043f\u043e \u043a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044f\u043c</span>
        <span class="tag expense">\u2212${formatMoney(totalExp)}</span>
      </div>
      <div class="card-body">
        ${catExpList.length === 0 ? '<div class="empty-state"><p>\u041d\u0435\u0442 \u0440\u0430\u0441\u0445\u043e\u0434\u043e\u0432</p></div>' :
          catExpList.map((item) => {
            const pct = totalExp > 0 ? (item.amount / totalExp) * 100 : 0;
            return `
              <div class="stat-bar-row">
                <div class="stat-emoji">${item.cat.emoji}</div>
                <div class="stat-info">
                  <div class="stat-name">${item.cat.name}</div>
                  <div class="stat-bar">
                    <div class="stat-bar-fill" style="width:${pct}%;background:${item.cat.color}"></div>
                  </div>
                </div>
                <div class="stat-amount">${formatMoney(item.amount)} <span style="color:var(--text-light);font-weight:400">${Math.round(pct)}%</span></div>
              </div>
            `;
          }).join('')}
      </div>
    </div>

    <div class="card">
      <div class="card-header">
        <span>\u0414\u043e\u0445\u043e\u0434\u044b \u043f\u043e \u043a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044f\u043c</span>
        <span class="tag income">+${formatMoney(totalInc)}</span>
      </div>
      <div class="card-body">
        ${catIncList.length === 0 ? '<div class="empty-state"><p>\u041d\u0435\u0442 \u0434\u043e\u0445\u043e\u0434\u043e\u0432</p></div>' :
          catIncList.map((item) => {
            const pct = totalInc > 0 ? (item.amount / totalInc) * 100 : 0;
            return `
              <div class="stat-bar-row">
                <div class="stat-emoji">${item.cat.emoji}</div>
                <div class="stat-info">
                  <div class="stat-name">${item.cat.name}</div>
                  <div class="stat-bar">
                    <div class="stat-bar-fill" style="width:${pct}%;background:${item.cat.color}"></div>
                  </div>
                </div>
                <div class="stat-amount">${formatMoney(item.amount)} <span style="color:var(--text-light);font-weight:400">${Math.round(pct)}%</span></div>
              </div>
            `;
          }).join('')}
      </div>
    </div>
  `;
}

function renderPeriodSelector() {
  return `
    <div class="period-selector">
      ${['week', 'month', 'year', 'all'].map((p) => `
        <button class="period-btn ${currentPeriod === p ? 'active' : ''}"
          onclick="currentPeriod='${p}';render()">
          ${{ week: '\u041d\u0435\u0434\u0435\u043b\u044f', month: '\u041c\u0435\u0441\u044f\u0446', year: '\u0413\u043e\u0434', all: '\u0412\u0441\u0435' }[p]}
        </button>
      `).join('')}
    </div>
  `;
}

function renderTxRow(t) {
  const cat = findCategory(t.categoryId);
  return `
    <div class="tx-row" onclick="showDetail('${t.id}')">
      <div class="tx-icon" style="background:${cat.color}15">${cat.emoji}</div>
      <div class="tx-info">
        <div class="tx-title">${t.note || cat.name}</div>
        <div class="tx-category">${cat.name}</div>
      </div>
      <div class="tx-amount ${t.isIncome ? 'income' : 'expense'}">
        ${t.isIncome ? '+' : '\u2212'}${formatMoney(t.amount)}
      </div>
    </div>
  `;
}

// ── Tab Navigation ──
function switchTab(tab) {
  currentTab = tab;
  document.querySelectorAll('.page').forEach((p) => p.classList.remove('active'));
  document.getElementById(`page-${tab}`).classList.add('active');
  document.querySelectorAll('.tab-bar button').forEach((b) => {
    b.classList.toggle('active', b.dataset.tab === tab);
  });
  render();
}

// ── Add / Edit Transaction Modal ──
let addType = 'expense';
let addCategory = '';
let addAmount = '';
let addNote = '';
let addDate = new Date().toISOString().slice(0, 10);
let editingTxId = null;

function openAddModal(existingTx) {
  if (existingTx) {
    editingTxId = existingTx.id;
    addType = existingTx.isIncome ? 'income' : 'expense';
    addCategory = existingTx.categoryId;
    addAmount = String(existingTx.amount);
    addNote = existingTx.note || '';
    addDate = new Date(existingTx.date).toISOString().slice(0, 10);
  } else {
    editingTxId = null;
    addType = 'expense';
    addCategory = getCategories('expense')[0].id;
    addAmount = '';
    addNote = '';
    addDate = new Date().toISOString().slice(0, 10);
  }
  renderAddModal();
  document.getElementById('modal-add').classList.add('open');
}

function closeAddModal() {
  document.getElementById('modal-add').classList.remove('open');
}

function renderAddModal() {
  const cats = getCategories(addType);
  const isEdit = editingTxId !== null;
  document.getElementById('modal-add-content').innerHTML = `
    <div class="modal-handle"></div>
    <div class="modal-header">
      <div class="modal-title">${isEdit ? '\u0420\u0435\u0434\u0430\u043a\u0442\u0438\u0440\u043e\u0432\u0430\u0442\u044c' : '\u041d\u043e\u0432\u0430\u044f \u0437\u0430\u043f\u0438\u0441\u044c'}</div>
      <button class="modal-close" onclick="closeAddModal()">\u2715</button>
    </div>

    <div class="form-section">
      <div class="type-toggle">
        <button class="${addType === 'expense' ? 'active is-expense' : ''}"
          onclick="addType='expense';addCategory=getCategories('expense')[0].id;renderAddModal()">
          \u0420\u0430\u0441\u0445\u043e\u0434
        </button>
        <button class="${addType === 'income' ? 'active is-income' : ''}"
          onclick="addType='income';addCategory=getCategories('income')[0].id;renderAddModal()">
          \u0414\u043e\u0445\u043e\u0434
        </button>
      </div>

      <input class="form-input amount-input" type="number" inputmode="decimal"
        placeholder="0" value="${addAmount}"
        oninput="addAmount=this.value" autofocus />
    </div>

    <div class="form-section">
      <div class="form-label">\u041a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044f</div>
      <div class="category-grid">
        ${cats.map((c) => `
          <button class="category-btn ${addCategory === c.id ? 'active' : ''}"
            onclick="addCategory='${c.id}';renderAddModal()">
            <span class="emoji">${c.emoji}</span>
            <span class="label">${c.name}</span>
          </button>
        `).join('')}
        <button class="category-btn add-cat-btn" onclick="openCategoryModal()">
          <span class="emoji">+</span>
          <span class="label">\u0414\u043e\u0431\u0430\u0432\u0438\u0442\u044c</span>
        </button>
      </div>
    </div>

    <div class="form-section">
      <div class="form-label">\u0417\u0430\u043c\u0435\u0442\u043a\u0430</div>
      <input class="form-input" type="text" placeholder="\u041e\u043f\u0438\u0441\u0430\u043d\u0438\u0435..." value="${addNote}"
        oninput="addNote=this.value" />
    </div>

    <div class="form-section">
      <div class="form-label">\u0414\u0430\u0442\u0430</div>
      <input class="form-input" type="date" value="${addDate}" onchange="addDate=this.value" />
    </div>

    <div class="form-section">
      <button class="submit-btn ${addType}" onclick="submitTransaction()">
        ${isEdit ? '\u0421\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c' : '\u0414\u043e\u0431\u0430\u0432\u0438\u0442\u044c ${addType === "expense" ? "\u0440\u0430\u0441\u0445\u043e\u0434" : "\u0434\u043e\u0445\u043e\u0434"}'}
      </button>
    </div>
  `;
}

function submitTransaction() {
  const amount = parseFloat(addAmount);
  if (!amount || amount <= 0) return;

  if (editingTxId) {
    const idx = transactions.findIndex((t) => t.id === editingTxId);
    if (idx !== -1) {
      transactions[idx] = {
        ...transactions[idx],
        amount,
        categoryId: addCategory,
        isIncome: addType === 'income',
        note: addNote.trim(),
        date: new Date(addDate).toISOString(),
      };
    }
  } else {
    transactions.push({
      id: Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
      amount,
      categoryId: addCategory,
      isIncome: addType === 'income',
      note: addNote.trim(),
      date: new Date(addDate).toISOString(),
    });
  }
  saveData(transactions);
  closeAddModal();
  render();
}

// ── Custom Category Modal ──
let newCatEmoji = '\ud83d\udccc';
let newCatName = '';
let newCatColor = '#3498db';

function openCategoryModal() {
  newCatEmoji = '\ud83d\udccc';
  newCatName = '';
  newCatColor = '#3498db';
  renderCategoryModal();
  document.getElementById('modal-category').classList.add('open');
}

function closeCategoryModal() {
  document.getElementById('modal-category').classList.remove('open');
}

function renderCategoryModal() {
  document.getElementById('modal-category-content').innerHTML = `
    <div class="modal-handle"></div>
    <div class="modal-header">
      <div class="modal-title">\u041d\u043e\u0432\u0430\u044f \u043a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044f</div>
      <button class="modal-close" onclick="closeCategoryModal()">\u2715</button>
    </div>

    <div class="form-section">
      <div class="form-label">\u0418\u043a\u043e\u043d\u043a\u0430</div>
      <div class="emoji-grid">
        ${EMOJI_PICKER.map((e) => `
          <button class="emoji-pick ${newCatEmoji === e ? 'active' : ''}"
            onclick="newCatEmoji='${e}';renderCategoryModal()">${e}</button>
        `).join('')}
      </div>
    </div>

    <div class="form-section">
      <div class="form-label">\u041d\u0430\u0437\u0432\u0430\u043d\u0438\u0435</div>
      <input class="form-input" type="text" placeholder="\u041d\u0430\u043f\u0440\u0438\u043c\u0435\u0440: \u041f\u043e\u0434\u043f\u0438\u0441\u043a\u0438" value="${newCatName}"
        oninput="newCatName=this.value" />
    </div>

    <div class="form-section">
      <div class="form-label">\u0426\u0432\u0435\u0442</div>
      <div class="color-grid">
        ${COLOR_PICKER.map((c) => `
          <button class="color-pick ${newCatColor === c ? 'active' : ''}"
            style="background:${c}" onclick="newCatColor='${c}';renderCategoryModal()"></button>
        `).join('')}
      </div>
    </div>

    <div class="form-section">
      <div style="display:flex;align-items:center;gap:10px;margin-bottom:12px;padding:10px;background:var(--bg-secondary);border-radius:var(--radius)">
        <div class="tx-icon" style="background:${newCatColor}15">${newCatEmoji}</div>
        <span style="font-weight:500">${newCatName || '\u041f\u0440\u0435\u0434\u043f\u0440\u043e\u0441\u043c\u043e\u0442\u0440'}</span>
      </div>
      <button class="submit-btn ${addType}" onclick="saveNewCategory()">
        \u0421\u043e\u0437\u0434\u0430\u0442\u044c \u043a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044e
      </button>
    </div>

    ${customCategories[addType].length > 0 ? `
      <div class="form-section">
        <div class="form-label">\u0412\u0430\u0448\u0438 \u043a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u0438</div>
        ${customCategories[addType].map((c) => `
          <div class="custom-cat-row">
            <span>${c.emoji} ${c.name}</span>
            <button class="custom-cat-delete" onclick="deleteCustomCategory('${c.id}')">\u2715</button>
          </div>
        `).join('')}
      </div>
    ` : ''}
  `;
}

function saveNewCategory() {
  if (!newCatName.trim()) return;
  const id = 'custom_' + Date.now().toString(36);
  customCategories[addType].push({
    id,
    emoji: newCatEmoji,
    name: newCatName.trim(),
    color: newCatColor,
  });
  saveCustomCategories(customCategories);
  addCategory = id;
  closeCategoryModal();
  renderAddModal();
}

function deleteCustomCategory(id) {
  customCategories.expense = customCategories.expense.filter((c) => c.id !== id);
  customCategories.income = customCategories.income.filter((c) => c.id !== id);
  saveCustomCategories(customCategories);
  renderCategoryModal();
}

// ── Detail Modal ──
function showDetail(id) {
  const t = transactions.find((tx) => tx.id === id);
  if (!t) return;
  const cat = findCategory(t.categoryId);
  const d = new Date(t.date);

  document.getElementById('modal-detail-content').innerHTML = `
    <div class="modal-handle"></div>
    <div class="modal-header">
      <div class="modal-title">${cat.emoji} ${t.note || cat.name}</div>
      <button class="modal-close" onclick="closeDetail()">\u2715</button>
    </div>
    <div class="form-section">
      <div style="text-align:center;margin-bottom:16px">
        <div class="tx-amount ${t.isIncome ? 'income' : 'expense'}" style="font-size:32px">
          ${t.isIncome ? '+' : '\u2212'}${formatMoney(t.amount)}
        </div>
        <span class="tag ${t.isIncome ? 'income' : 'expense'}">
          ${t.isIncome ? '\u0414\u043e\u0445\u043e\u0434' : '\u0420\u0430\u0441\u0445\u043e\u0434'}
        </span>
      </div>
      <div class="detail-row">
        <span class="detail-label">\u041a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u044f</span>
        <span>${cat.emoji} ${cat.name}</span>
      </div>
      <div class="detail-row">
        <span class="detail-label">\u0414\u0430\u0442\u0430</span>
        <span>${d.toLocaleDateString('ru-RU', { day: 'numeric', month: 'long', year: 'numeric' })}</span>
      </div>
      ${t.note ? `
        <div class="detail-row">
          <span class="detail-label">\u0417\u0430\u043c\u0435\u0442\u043a\u0430</span>
          <span>${t.note}</span>
        </div>
      ` : ''}
      <button class="submit-btn ${t.isIncome ? 'income' : 'expense'}" onclick="editTx('${t.id}')" style="margin-bottom:8px">
        \u0420\u0435\u0434\u0430\u043a\u0442\u0438\u0440\u043e\u0432\u0430\u0442\u044c
      </button>
      <button class="delete-btn" onclick="deleteTx('${t.id}')">\u0423\u0434\u0430\u043b\u0438\u0442\u044c \u0437\u0430\u043f\u0438\u0441\u044c</button>
    </div>
  `;
  document.getElementById('modal-detail').classList.add('open');
}

function closeDetail() {
  document.getElementById('modal-detail').classList.remove('open');
}

function deleteTx(id) {
  transactions = transactions.filter((t) => t.id !== id);
  saveData(transactions);
  closeDetail();
  render();
}

function editTx(id) {
  const t = transactions.find((tx) => tx.id === id);
  if (!t) return;
  closeDetail();
  setTimeout(() => openAddModal(t), 200);
}

// ── Export ──
function downloadFile(filename, content, mime) {
  const blob = new Blob([content], { type: mime });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

function exportCSV() {
  const list = filterByPeriod(transactions).sort((a, b) => new Date(a.date) - new Date(b.date));
  if (list.length === 0) return;

  const BOM = '\uFEFF';
  const header = 'Дата;Тип;Категория;Сумма;Заметка';
  const rows = list.map((t) => {
    const cat = findCategory(t.categoryId);
    const d = new Date(t.date);
    const dateStr = d.toLocaleDateString('ru-RU');
    const type = t.isIncome ? 'Доход' : 'Расход';
    const amount = t.isIncome ? t.amount : -t.amount;
    const note = (t.note || '').replace(/"/g, '""');
    return `${dateStr};${type};${cat.name};${amount};"${note}"`;
  });

  const income = list.filter((t) => t.isIncome).reduce((s, t) => s + t.amount, 0);
  const expense = list.filter((t) => !t.isIncome).reduce((s, t) => s + t.amount, 0);
  rows.push('');
  rows.push(`;;Итого доходы;${income};`);
  rows.push(`;;Итого расходы;${-expense};`);
  rows.push(`;;Баланс;${income - expense};`);

  downloadFile(
    `expenses_${new Date().toISOString().slice(0, 10)}.csv`,
    BOM + header + '\n' + rows.join('\n'),
    'text/csv;charset=utf-8'
  );
}

function exportJSON() {
  const list = filterByPeriod(transactions).sort((a, b) => new Date(a.date) - new Date(b.date));
  if (list.length === 0) return;

  const income = list.filter((t) => t.isIncome).reduce((s, t) => s + t.amount, 0);
  const expense = list.filter((t) => !t.isIncome).reduce((s, t) => s + t.amount, 0);

  const data = {
    exported: new Date().toISOString(),
    period: currentPeriod,
    summary: {
      total_income: income,
      total_expense: expense,
      balance: income - expense,
      transaction_count: list.length,
    },
    transactions: list.map((t) => {
      const cat = findCategory(t.categoryId);
      return {
        date: new Date(t.date).toLocaleDateString('ru-RU'),
        type: t.isIncome ? 'income' : 'expense',
        category: cat.name,
        amount: t.amount,
        note: t.note || '',
      };
    }),
  };

  downloadFile(
    `expenses_${new Date().toISOString().slice(0, 10)}.json`,
    JSON.stringify(data, null, 2),
    'application/json;charset=utf-8'
  );
}

// ── Init ──
document.addEventListener('DOMContentLoaded', () => {
  switchTab('home');

  // Close modals on overlay click
  document.querySelectorAll('.modal-overlay').forEach((overlay) => {
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) {
        overlay.classList.remove('open');
      }
    });
  });
});

// ── Service Worker ──
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('sw.js').catch(() => {});
}
