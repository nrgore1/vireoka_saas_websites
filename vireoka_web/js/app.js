(function () {
  // Smooth anchor scroll
  document.addEventListener('click', function (e) {
    const a = e.target.closest('a[href^="#"]');
    if (!a) return;
    const id = a.getAttribute('href').slice(1);
    const el = document.getElementById(id);
    if (!el) return;
    e.preventDefault();
    el.scrollIntoView({ behavior: 'smooth', block: 'start' });
  });

  // Add a tiny "loaded" class for subtle transitions if needed
  window.addEventListener('load', function () {
    document.documentElement.classList.add('v-loaded');
  });
})();
