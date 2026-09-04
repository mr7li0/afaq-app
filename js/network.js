(function () {
  'use strict';

  var platformIcons = {
    instagram: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/></svg>',
    youtube: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/></svg>',
    tiktok: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"/></svg>',
    telegram: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z"/>'
  };

  function getPlatformIcon(url) {
    if (!url) return platformIcons.telegram;
    var u = url.toLowerCase();
    if (u.indexOf('instagram') !== -1) return platformIcons.instagram;
    if (u.indexOf('youtube') !== -1) return platformIcons.youtube;
    if (u.indexOf('tiktok') !== -1) return platformIcons.tiktok;
    return platformIcons.telegram;
  }

  var networkData = {
    channels: {
      title: 'القنوات',
      items: [
        { name: 'آفاق التلاوة', username: '@Afaq0t' },
        { name: 'خطوط آفاق', username: '@FontsAfaq' },
        { name: 'آفاق التلاوة | كرومات قرآن', username: '@Afaq0t1' },
        { name: 'شروحات آفاق', username: '@Afaq0t2' },
        { name: 'آفاق القراءة', username: '@Afaq0t3' },
        { name: 'كرومات آفاق', username: '@Afaq0b' },
        { name: 'الورد القرآني', username: '@AfaqQW' },
        { name: 'آفاق تيك', username: '@TechAfaq' },
      ]
    },
    reminders: {
      title: 'قنوات المنبهات',
      items: [
        { name: 'منبه الصلاة على النبي', username: '@AfaqR1' },
        { name: 'منبه الإستغفار', username: '@AfaqR2' },
        { name: 'منبه الباقيات الصالحات', username: '@AfaqR3' },
        { name: 'منبه الحوقلة', username: '@AfaqR4' },
        { name: 'منبه آيات الله', username: '@AfaqR5' },
      ]
    },
    bots: {
      title: 'بوتات إسلامية مفيدة',
      items: [
        { name: 'بوت إسلامي شامل', username: '@Afaqbot' },
        { name: 'بوت التذكير بالصلاة على النبي', username: '@AfaqRbot' },
        { name: 'بوت الورد اليومي', username: '@AfaqWbot' },
      ]
    },
    social: {
      title: 'حسابات السوشيال ميديا',
      items: [
        { name: 'إنستغرام آفاق', url: 'https://www.instagram.com/afaq0t', username: '@afaq0t' },
        { name: 'يوتيوب آفاق', url: 'https://www.youtube.com/@Afaq0t', username: '@Afaq0t' },
        { name: 'تيك توك آفاق', url: 'https://www.tiktok.com/@afaq0t', username: '@afaq0t' },
      ]
    }
  };

  var splash = document.getElementById('splash');
  if (splash) {
    if (sessionStorage.getItem('afaq_splash')) {
      splash.remove();
    } else {
      sessionStorage.setItem('afaq_splash', '1');
      setTimeout(function () {
        splash.classList.add('hide');
        document.body.style.overflow = '';
        setTimeout(function () { if (splash.parentNode) splash.remove(); }, 700);
      }, 1800);
    }
  }

  var menuToggle = document.querySelector('.menu-toggle');
  var navLinks = document.querySelector('.nav-links');
  if (menuToggle) {
    menuToggle.addEventListener('click', function () {
      menuToggle.classList.toggle('active');
      navLinks.classList.toggle('open');
    });
  }
  (document.querySelectorAll('.nav-links a') || []).forEach(function (l) {
    l.addEventListener('click', function () {
      if (menuToggle) menuToggle.classList.remove('active');
      if (navLinks) navLinks.classList.remove('open');
    });
  });

  var container = document.getElementById('network-categories');
  if (!container) return;

  var categories = ['channels', 'reminders', 'bots', 'social'];
  categories.forEach(function (catKey) {
    var cat = networkData[catKey];
    if (!cat) return;

    var categoryEl = document.createElement('div');
    categoryEl.className = 'network-category';

    var h2 = document.createElement('h2');
    h2.textContent = cat.title;
    categoryEl.appendChild(h2);

    var grid = document.createElement('div');
    grid.className = 'network-grid';

    cat.items.forEach(function (item) {
      var card = document.createElement('a');
      card.className = 'network-card';
      card.href = item.url || 'https://t.me/' + item.username.replace('@', '');
      card.target = '_blank';
      card.rel = 'noopener noreferrer';

      var iconSvg = item.url ? getPlatformIcon(item.url) : platformIcons.telegram;

      card.innerHTML =
        '<div class="network-card-icon">' +
        iconSvg +
        '</div>' +
        '<div class="network-card-info">' +
        '<div class="network-card-title">' + item.name + '</div>' +
        '<span class="network-card-username">' + (item.username || item.url) + '</span>' +
        '</div>';

      grid.appendChild(card);
    });

    categoryEl.appendChild(grid);
    container.appendChild(categoryEl);
  });

})();
