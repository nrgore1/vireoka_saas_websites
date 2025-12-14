(() => {
  // Lightweight, no dependencies. Renders a subtle animated neural field behind hero sections.
  // It only runs if a .vireoka-hero / .hero / .page-hero exists.
  const hero = document.querySelector('.vireoka-hero, .vireoka-hero-section, .hero, .page-hero');
  if (!hero) return;

  const canvas = document.createElement('canvas');
  canvas.setAttribute('aria-hidden', 'true');
  canvas.style.position = 'absolute';
  canvas.style.inset = '0';
  canvas.style.width = '100%';
  canvas.style.height = '100%';
  canvas.style.pointerEvents = 'none';
  canvas.style.opacity = '0.55';
  canvas.style.mixBlendMode = 'screen';
  canvas.style.zIndex = '1';

  hero.style.position = hero.style.position || 'relative';
  hero.insertBefore(canvas, hero.firstChild);

  const ctx = canvas.getContext('2d');
  let w = 0, h = 0, dpr = Math.max(1, Math.min(2, window.devicePixelRatio || 1));

  function resize() {
    const r = hero.getBoundingClientRect();
    w = Math.max(320, Math.floor(r.width));
    h = Math.max(220, Math.floor(r.height));
    canvas.width = Math.floor(w * dpr);
    canvas.height = Math.floor(h * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }
  window.addEventListener('resize', resize, { passive: true });
  resize();

  // Nodes
  const N = Math.min(70, Math.floor((w * h) / 18000));
  const nodes = Array.from({ length: N }, () => ({
    x: Math.random() * w,
    y: Math.random() * h,
    vx: (Math.random() - 0.5) * 0.25,
    vy: (Math.random() - 0.5) * 0.25,
  }));

  let t = 0;
  function frame() {
    t += 1;

    ctx.clearRect(0, 0, w, h);

    // Background fade
    ctx.globalAlpha = 0.35;
    ctx.fillStyle = '#0A1A4A';
    ctx.fillRect(0, 0, w, h);

    // Links
    ctx.globalAlpha = 0.55;
    for (let i = 0; i < nodes.length; i++) {
      const a = nodes[i];
      a.x += a.vx; a.y += a.vy;
      if (a.x < 0 || a.x > w) a.vx *= -1;
      if (a.y < 0 || a.y > h) a.vy *= -1;

      for (let j = i + 1; j < nodes.length; j++) {
        const b = nodes[j];
        const dx = a.x - b.x, dy = a.y - b.y;
        const dist = Math.hypot(dx, dy);
        if (dist < 160) {
          const alpha = (1 - dist / 160) * 0.35;
          // alternating violet/teal
          ctx.strokeStyle = ( (i + t) % 120 < 60 ) ? `rgba(90,47,227,${alpha})` : `rgba(58,244,211,${alpha})`;
          ctx.lineWidth = 1;
          ctx.beginPath();
          ctx.moveTo(a.x, a.y);
          ctx.lineTo(b.x, b.y);
          ctx.stroke();
        }
      }
    }

    // Nodes
    for (const n of nodes) {
      ctx.beginPath();
      ctx.fillStyle = 'rgba(228,180,72,.18)';
      ctx.arc(n.x, n.y, 1.6, 0, Math.PI * 2);
      ctx.fill();
    }

    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
})();
