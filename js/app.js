(function () {
  'use strict';

  var splash = document.getElementById('splash');
  if (splash) {
    if (sessionStorage.getItem('afaq_splash')) {
      splash.remove();
    } else {
      sessionStorage.setItem('afaq_splash', '1');
      setTimeout(function () {
        splash.classList.add('hide');
        document.body.style.overflow = '';
        setTimeout(function () { if (splash.parentNode) splash.remove(); }, 600);
      }, 1900);
    }
  }

  var header = document.querySelector('.header');
  var ticking = false;
  window.addEventListener('scroll', function () {
    if (!ticking) {
      requestAnimationFrame(function () {
        header.classList.toggle('scrolled', window.scrollY > 50);
        ticking = false;
      });
      ticking = true;
    }
  }, { passive: true });

  var menuToggle = document.querySelector('.menu-toggle');
  var navLinks = document.querySelector('.nav-links');
  if (menuToggle) {
    menuToggle.addEventListener('click', function () {
      menuToggle.classList.toggle('active');
      navLinks.classList.toggle('open');
    });
  }
  (document.querySelectorAll('.nav-links a') || []).forEach(function (link) {
    link.addEventListener('click', function () {
      if (menuToggle) menuToggle.classList.remove('active');
      if (navLinks) navLinks.classList.remove('open');
    });
  });

  var wrapper = document.getElementById('gallery-swiper-wrapper');
  if (wrapper && typeof Swiper !== 'undefined') {
    var colors = ['#4a5c5e','#5c6e70','#3a4c4e','#6a7c7e','#2a3c3e','#7a8c8e','#4a6a6c','#5a7a7c','#3a5a5c','#6a8a8c','#2a4a4c','#5a6a6c'];
    for (var i = 0; i < 12; i++) {
      var slide = document.createElement('div');
      slide.className = 'swiper-slide';
      var img = document.createElement('img');
      var idx = i + 1;
      img.loading = 'lazy';
      img.src = './assets/gallery/' + idx + '.jpg';
      img.alt = 'Afaq Gallery ' + idx;
      img.onerror = (function (index) {
        return function () {
          this.style.display = 'none';
          var p = this.parentNode;
          p.style.background = colors[index % colors.length];
          p.style.display = 'flex';
          p.style.alignItems = 'center';
          p.style.justifyContent = 'center';
          p.innerHTML = '<svg viewBox="0 0 24 24" fill="currentColor" width="48" height="48" opacity="0.3"><path fill-rule="evenodd" d="M1.5 6a2.25 2.25 0 0 1 2.25-2.25h16.5A2.25 2.25 0 0 1 22.5 6v12a2.25 2.25 0 0 1-2.25 2.25H3.75A2.25 2.25 0 0 1 1.5 18V6ZM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0 0 21 18v-1.94l-2.69-2.689a1.5 1.5 0 0 0-2.12 0l-.88.879.97.97a.75.75 0 1 1-1.06 1.06l-5.16-5.159a1.5 1.5 0 0 0-2.12 0L3 16.061Zm10.125-7.81a1.125 1.125 0 1 1 2.25 0 1.125 1.125 0 0 1-2.25 0Z" clip-rule="evenodd"/></svg>';
        };
      })(i);
      slide.appendChild(img);
      wrapper.appendChild(slide);
    }

    new Swiper('.swiper', {
      slidesPerView: 'auto',
      centeredSlides: true,
      loop: true,
      speed: 500,
      autoplay: { delay: 4000, disableOnInteraction: false },
      spaceBetween: 12,
      allowTouchMove: true,
      grabCursor: true,
      watchSlidesProgress: true,
    });
  }

})();
