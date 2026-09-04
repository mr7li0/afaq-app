const QURAN_DATA = {
  _data: null,
  _loaded: false,
  _loading: false,
  _callbacks: [],

  async load() {
    if (this._loaded) return;
    if (this._loading) return new Promise(function (r) { QURAN_DATA._callbacks.push(r); });
    this._loading = true;
    try {
      /* Try embedded data first (for file:// protocol) */
      if (typeof QURAN_EMBEDDED_DATA !== 'undefined' && QURAN_EMBEDDED_DATA) {
        this._data = QURAN_EMBEDDED_DATA;
        this._loaded = true;
        console.log('Quran data loaded from embedded');
        this._callbacks.forEach(function (c) { c(); });
        this._callbacks = [];
        return;
      }
      /* Fallback: fetch from server */
      var resp = await fetch('quran_data.json');
      this._data = await resp.json();
      this._loaded = true;
      this._callbacks.forEach(function (c) { c(); });
      this._callbacks = [];
    } catch (e) {
      console.error('Failed to load quran_data.json', e);
      this._callbacks.forEach(function (c) { c(); });
      this._callbacks = [];
    }
  },

  getAyahText(surahId, ayahNum) {
    /* Check QURAN_KHATT first (Digital Khatt data) */
    if (typeof QURAN_KHATT !== 'undefined' && QURAN_KHATT) {
      for (var i = 0; i < QURAN_KHATT.length; i++) {
        if (QURAN_KHATT[i].s === surahId && QURAN_KHATT[i].a === ayahNum) {
          return QURAN_KHATT[i].t;
        }
      }
    }
    /* Fallback to embedded data */
    if (!this._data) return null;
    for (var i = 0; i < this._data.length; i++) {
      if (this._data[i].surah === surahId && this._data[i].ayah === ayahNum) {
        return this._data[i].text.replace(/[\uFEFF\u200B-\u200F\u2028-\u202F\uFEFF]/g, '');
      }
    }
    return null;
  },

  getSurah(id) {
    if (!this._data) return null;
    var surahMap = {};
    for (var i = 0; i < this._data.length; i++) {
      surahMap[this._data[i].surah] = this._data[i].surah_name;
    }
    var keys = Object.keys(surahMap).map(Number).sort(function (a,b) { return a - b; });
    for (var j = 0; j < keys.length; j++) {
      if (keys[j] === id) return { id: id, name: surahMap[id] };
    }
    return null;
  },

  getSurahs() {
    if (!this._data) return [];
    var seen = {}, result = [];
    for (var i = 0; i < this._data.length; i++) {
      var item = this._data[i];
      if (!seen[item.surah]) {
        seen[item.surah] = true;
        result.push({ id: item.surah, name: item.surah_name, nameEn: item.surah_english });
      }
    }
    return result;
  },

  getSurahVersesCount(surahId) {
    if (!this._data) return 0;
    var count = 0;
    for (var i = 0; i < this._data.length; i++) {
      if (this._data[i].surah === surahId) count++;
    }
    return count;
  },

  searchAyahs(query, surahId) {
    if (!this._data || !query) return [];
    var q = query.trim();
    if (!q) return [];
    var results = [];
    for (var i = 0; i < this._data.length; i++) {
      var item = this._data[i];
      if (surahId && item.surah !== surahId) continue;
      if (item.text.indexOf(q) !== -1) {
        results.push({ surah: item.surah, ayah: item.ayah, text: item.text, surah_name: item.surah_name });
        if (results.length >= 50) break;
      }
    }
    return results;
  },

  /* ========== Digital Madina Font Conversion ========== */

  _charPos(text, index) {
    var ch = text[index];
    var prev = index > 0 ? text[index - 1] : '';
    var next = index < text.length - 1 ? text[index + 1] : '';
    var nonConnecting = new Set(['\u0627','\u062F','\u0630','\u0631','\u0632','\u0648','\u0621','\u0622','\u0623','\u0625','\u0624','\u0629','\u0649','\u06D2','\u06D3']);
    if (/[\u064B-\u0652\u0670]/.test(ch)) return 'med';
    var hasPrev = prev && !nonConnecting.has(prev) && /[\u0600-\u06FF]/.test(prev);
    var hasNext = next && !nonConnecting.has(next) && /[\u0600-\u06FF]/.test(next);
    if (!hasPrev && !hasNext) return 'iso';
    if (hasPrev && hasNext) return 'med';
    if (hasPrev && !hasNext) return 'fin';
    if (!hasPrev && hasNext) return 'ini';
    return 'iso';
  },

  convertToFont(text, fontType) {
    var map = fontType === 'new' ? this._fontMapNew : this._fontMapOld;
    var result = '';
    var cleanText = '';
    var indices = [];
    for (var ci = 0; ci < text.length; ci++) {
      var cc = text[ci];
      if (/[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF\u0600-\u06FF\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u08D0-\u08E3]/.test(cc) || cc === '\u200D' || map[cc]) {
        cleanText += cc;
        indices.push(ci);
      }
    }
    for (var j = 0; j < cleanText.length; j++) {
      var idx = indices[j];
      var ch = cleanText[j];
      if (map[ch]) {
        var pos = this._charPos(cleanText, j);
        result += map[ch][pos] || map[ch].iso;
      } else {
        result += ch;
      }
    }
    return result;
  },

  _fontMapOld: {
    '\u0627': { iso: '\uEE01', ini: '\uEE01', med: '\uEE01', fin: '\uEE01' },
    '\u0628': { iso: '\uEE02', ini: '\uEE03', med: '\uEE04', fin: '\uEE05' },
    '\u062A': { iso: '\uEE06', ini: '\uEE07', med: '\uEE08', fin: '\uEE09' },
    '\u062B': { iso: '\uEE0A', ini: '\uEE0B', med: '\uEE0C', fin: '\uEE0D' },
    '\u062C': { iso: '\uEE0E', ini: '\uEE0F', med: '\uEE10', fin: '\uEE11' },
    '\u062D': { iso: '\uEE12', ini: '\uEE13', med: '\uEE14', fin: '\uEE15' },
    '\u062E': { iso: '\uEE16', ini: '\uEE17', med: '\uEE18', fin: '\uEE19' },
    '\u062F': { iso: '\uEE1A', ini: '\uEE1A', med: '\uEE1A', fin: '\uEE1B' },
    '\u0630': { iso: '\uEE1C', ini: '\uEE1C', med: '\uEE1C', fin: '\uEE1D' },
    '\u0631': { iso: '\uEE1E', ini: '\uEE1E', med: '\uEE1E', fin: '\uEE1F' },
    '\u0632': { iso: '\uEE20', ini: '\uEE20', med: '\uEE20', fin: '\uEE21' },
    '\u0633': { iso: '\uEE22', ini: '\uEE23', med: '\uEE24', fin: '\uEE25' },
    '\u0634': { iso: '\uEE26', ini: '\uEE27', med: '\uEE28', fin: '\uEE29' },
    '\u0635': { iso: '\uEE2A', ini: '\uEE2B', med: '\uEE2C', fin: '\uEE2D' },
    '\u0636': { iso: '\uEE2E', ini: '\uEE2F', med: '\uEE30', fin: '\uEE31' },
    '\u0637': { iso: '\uEE32', ini: '\uEE33', med: '\uEE34', fin: '\uEE35' },
    '\u0638': { iso: '\uEE36', ini: '\uEE37', med: '\uEE38', fin: '\uEE39' },
    '\u0639': { iso: '\uEE3A', ini: '\uEE3B', med: '\uEE3C', fin: '\uEE3D' },
    '\u063A': { iso: '\uEE3E', ini: '\uEE3F', med: '\uEE40', fin: '\uEE41' },
    '\u0641': { iso: '\uEE42', ini: '\uEE43', med: '\uEE44', fin: '\uEE45' },
    '\u0642': { iso: '\uEE46', ini: '\uEE47', med: '\uEE48', fin: '\uEE49' },
    '\u0643': { iso: '\uEE4A', ini: '\uEE4B', med: '\uEE4C', fin: '\uEE4D' },
    '\u0644': { iso: '\uEE4E', ini: '\uEE4F', med: '\uEE50', fin: '\uEE51' },
    '\u0645': { iso: '\uEE52', ini: '\uEE53', med: '\uEE54', fin: '\uEE55' },
    '\u0646': { iso: '\uEE56', ini: '\uEE57', med: '\uEE58', fin: '\uEE59' },
    '\u0647': { iso: '\uEE5A', ini: '\uEE5B', med: '\uEE5C', fin: '\uEE5D' },
    '\u0648': { iso: '\uEE5E', ini: '\uEE5E', med: '\uEE5E', fin: '\uEE5F' },
    '\u064A': { iso: '\uEE60', ini: '\uEE61', med: '\uEE62', fin: '\uEE63' },
    '\u0621': { iso: '\uEE64', ini: '\uEE64', med: '\uEE64', fin: '\uEE64' },
    '\u0622': { iso: '\uEE65', ini: '\uEE65', med: '\uEE65', fin: '\uEE65' },
    '\u0623': { iso: '\uEE66', ini: '\uEE66', med: '\uEE66', fin: '\uEE67' },
    '\u0625': { iso: '\uEE68', ini: '\uEE68', med: '\uEE68', fin: '\uEE69' },
    '\u0624': { iso: '\uEE6A', ini: '\uEE6A', med: '\uEE6A', fin: '\uEE6A' },
    '\u0626': { iso: '\uEE6B', ini: '\uEE6C', med: '\uEE6D', fin: '\uEE6E' },
    '\u0629': { iso: '\uEE6F', ini: '\uEE6F', med: '\uEE6F', fin: '\uEE70' },
    '\u0649': { iso: '\uEE71', ini: '\uEE71', med: '\uEE71', fin: '\uEE72' },
    '\u06D2': { iso: '\uEE73', ini: '\uEE73', med: '\uEE73', fin: '\uEE73' },
    '\u06D3': { iso: '\uEE74', ini: '\uEE74', med: '\uEE74', fin: '\uEE74' },
    '\u064E': { iso: '\uEE75', ini: '\uEE75', med: '\uEE75', fin: '\uEE75' },
    '\u064F': { iso: '\uEE76', ini: '\uEE76', med: '\uEE76', fin: '\uEE76' },
    '\u0650': { iso: '\uEE77', ini: '\uEE77', med: '\uEE77', fin: '\uEE77' },
    '\u0651': { iso: '\uEE78', ini: '\uEE78', med: '\uEE78', fin: '\uEE78' },
    '\u0652': { iso: '\uEE79', ini: '\uEE79', med: '\uEE79', fin: '\uEE79' },
    '\u0640': { iso: '\uEE7A', ini: '\uEE7A', med: '\uEE7A', fin: '\uEE7A' },
    '\u06D6': { iso: '\uEE7B', ini: '\uEE7B', med: '\uEE7B', fin: '\uEE7B' },
    '\u06DD': { iso: '\uEE7C', ini: '\uEE7C', med: '\uEE7C', fin: '\uEE7C' },
  },

  _fontMapNew: {
    '\u0627': { iso: '\uEF01', ini: '\uEF01', med: '\uEF01', fin: '\uEF01' },
    '\u0628': { iso: '\uEF02', ini: '\uEF03', med: '\uEF04', fin: '\uEF05' },
    '\u062A': { iso: '\uEF06', ini: '\uEF07', med: '\uEF08', fin: '\uEF09' },
    '\u062B': { iso: '\uEF0A', ini: '\uEF0B', med: '\uEF0C', fin: '\uEF0D' },
    '\u062C': { iso: '\uEF0E', ini: '\uEF0F', med: '\uEF10', fin: '\uEF11' },
    '\u062D': { iso: '\uEF12', ini: '\uEF13', med: '\uEF14', fin: '\uEF15' },
    '\u062E': { iso: '\uEF16', ini: '\uEF17', med: '\uEF18', fin: '\uEF19' },
    '\u062F': { iso: '\uEF1A', ini: '\uEF1A', med: '\uEF1A', fin: '\uEF1B' },
    '\u0630': { iso: '\uEF1C', ini: '\uEF1C', med: '\uEF1C', fin: '\uEF1D' },
    '\u0631': { iso: '\uEF1E', ini: '\uEF1E', med: '\uEF1E', fin: '\uEF1F' },
    '\u0632': { iso: '\uEF20', ini: '\uEF20', med: '\uEF20', fin: '\uEF21' },
    '\u0633': { iso: '\uEF22', ini: '\uEF23', med: '\uEF24', fin: '\uEF25' },
    '\u0634': { iso: '\uEF26', ini: '\uEF27', med: '\uEF28', fin: '\uEF29' },
    '\u0635': { iso: '\uEF2A', ini: '\uEF2B', med: '\uEF2C', fin: '\uEF2D' },
    '\u0636': { iso: '\uEF2E', ini: '\uEF2F', med: '\uEF30', fin: '\uEF31' },
    '\u0637': { iso: '\uEF32', ini: '\uEF33', med: '\uEF34', fin: '\uEF35' },
    '\u0638': { iso: '\uEF36', ini: '\uEF37', med: '\uEF38', fin: '\uEF39' },
    '\u0639': { iso: '\uEF3A', ini: '\uEF3B', med: '\uEF3C', fin: '\uEF3D' },
    '\u063A': { iso: '\uEF3E', ini: '\uEF3F', med: '\uEF40', fin: '\uEF41' },
    '\u0641': { iso: '\uEF42', ini: '\uEF43', med: '\uEF44', fin: '\uEF45' },
    '\u0642': { iso: '\uEF46', ini: '\uEF47', med: '\uEF48', fin: '\uEF49' },
    '\u0643': { iso: '\uEF4A', ini: '\uEF4B', med: '\uEF4C', fin: '\uEF4D' },
    '\u0644': { iso: '\uEF4E', ini: '\uEF4F', med: '\uEF50', fin: '\uEF51' },
    '\u0645': { iso: '\uEF52', ini: '\uEF53', med: '\uEF54', fin: '\uEF55' },
    '\u0646': { iso: '\uEF56', ini: '\uEF57', med: '\uEF58', fin: '\uEF59' },
    '\u0647': { iso: '\uEF5A', ini: '\uEF5B', med: '\uEF5C', fin: '\uEF5D' },
    '\u0648': { iso: '\uEF5E', ini: '\uEF5E', med: '\uEF5E', fin: '\uEF5F' },
    '\u064A': { iso: '\uEF60', ini: '\uEF61', med: '\uEF62', fin: '\uEF63' },
    '\u0621': { iso: '\uEF64', ini: '\uEF64', med: '\uEF64', fin: '\uEF64' },
    '\u0622': { iso: '\uEF65', ini: '\uEF65', med: '\uEF65', fin: '\uEF65' },
    '\u0623': { iso: '\uEF66', ini: '\uEF66', med: '\uEF66', fin: '\uEF67' },
    '\u0625': { iso: '\uEF68', ini: '\uEF68', med: '\uEF68', fin: '\uEF69' },
    '\u0624': { iso: '\uEF6A', ini: '\uEF6A', med: '\uEF6A', fin: '\uEF6A' },
    '\u0626': { iso: '\uEF6B', ini: '\uEF6C', med: '\uEF6D', fin: '\uEF6E' },
    '\u0629': { iso: '\uEF6F', ini: '\uEF6F', med: '\uEF6F', fin: '\uEF70' },
    '\u0649': { iso: '\uEF71', ini: '\uEF71', med: '\uEF71', fin: '\uEF72' },
    '\u06D2': { iso: '\uEF73', ini: '\uEF73', med: '\uEF73', fin: '\uEF73' },
    '\u06D3': { iso: '\uEF74', ini: '\uEF74', med: '\uEF74', fin: '\uEF74' },
    '\u064E': { iso: '\uEF75', ini: '\uEF75', med: '\uEF75', fin: '\uEF75' },
    '\u064F': { iso: '\uEF76', ini: '\uEF76', med: '\uEF76', fin: '\uEF76' },
    '\u0650': { iso: '\uEF77', ini: '\uEF77', med: '\uEF77', fin: '\uEF77' },
    '\u0651': { iso: '\uEF78', ini: '\uEF78', med: '\uEF78', fin: '\uEF78' },
    '\u0652': { iso: '\uEF79', ini: '\uEF79', med: '\uEF79', fin: '\uEF79' },
    '\u0640': { iso: '\uEF7A', ini: '\uEF7A', med: '\uEF7A', fin: '\uEF7A' },
    '\u06D6': { iso: '\uEF7B', ini: '\uEF7B', med: '\uEF7B', fin: '\uEF7B' },
    '\u06DD': { iso: '\uEF7C', ini: '\uEF7C', med: '\uEF7C', fin: '\uEF7C' },
  },
};
