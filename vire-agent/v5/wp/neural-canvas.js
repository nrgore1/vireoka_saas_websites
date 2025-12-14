/* Vire Neural Canvas (V5) - lightweight, prefers-reduced-motion aware */
(function () {
  const reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (reduce) return;

  function qs(sel, root = document) { return root.querySelector(sel); }

  const host = qs('.vire-neural-host');
  const canvas = qs('.vire-neural-canvas');
  if (!host || !canvas) return;

  const ctx = canvas.getContext('2d', { alpha: true });

  function cssVar(name, fallback) {
    const v = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
    return v || fallback;
  }

  function resize() {
    const w = Math.max(320, host.clientWidth);
    const h = Math.max(200, Math.min(520, Math.floor(window.innerHeight * 0.38)));
    canvas.width = Math.floor(w * devicePixelRatio);
    canvas.height = Math.floor(h * devicePixelRatio);
    canvas.style.width = w + 'px';
    canvas.style.height = h + 'px';
    ctx.setTransform(devicePixelRatio, 0, 0, devicePixelRatio, 0, 0);
  }

  const nodes = [];
  function init() {
    nodes.length = 0;
    const w = host.clientWidth;
    const h = parseFloat(getComputedStyle(canvas).height);
    const n = Math.max(18, Math.min(44, Math.floor(w / 30)));
    for (let i = 0; i < n; i++) {
      nodes.push({
        x: Math.random() * w,
        y: Math.random() * h,
        vx: (Math.random() - 0.5) * 0.35,
        vy: (Math.random() - 0.5) * 0.25,
        r: 1 + Math.random() * 1.6
      });
    }
  }

  let t = 0;
  function step() {
    const w = host.clientWidth;
    const h = parseFloat(getComputedStyle(canvas).height);

    const purple = cssVar('--vire-neural-purple', '#5A2FE3');
    const teal = cssVar('--vire-electric-teal', '#3AF4D3');
    const gold = cssVar('--vire-quantum-gold', '#E4B448');

    ctx.clearRect(0, 0, w, h);

    const g = ctx.createLinearGradient(0, 0, w, h);
    g.addColorStop(0, 'rgba(90,47,227,0.16)');
    g.addColorStop(0.55, 'rgba(58,244,211,0.08)');
    g.addColorStop(1, 'rgba(228,180,72,0.10)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, w, h);

    for (const p of nodes) {
      p.x += p.vx; p.y += p.vy;
      if (p.x < -10) p.x = w + 10;
      if (p.x > w + 10) p.x = -10;
      if (p.y < -10) p.y = h + 10;
      if (p.y > h + 10) p.y = -10;
    }

    ctx.lineWidth = 1;
    for (let i = 0; i < nodes.length; i++) {
      for (let j = i + 1; j < nodes.length; j++) {
        const a = nodes[i], b = nodes[j];
        const dx = a.x - b.x, dy = a.y - b.y;
        const d2 = dx * dx + dy * dy;
        if (d2 < 140 * 140) {
          const alpha = 1 - Math.sqrt(d2) / 140;
          ctx.strokeStyle = `rgba(90,47,227,${alpha * 0.18})`;
          ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke();
        }
      }
    }

    for (const p of nodes) {
      const pulse = (Math.sin(t / 32 + p.x / 40) + 1) / 2;
      const rad = p.r + pulse * 1.2;

      ctx.beginPath();
      ctx.fillStyle = `rgba(58,244,211,${0.20 + pulse * 0.25})`;
      ctx.arc(p.x, p.y, rad, 0, Math.PI * 2);
      ctx.fill();

      ctx.beginPath();
      ctx.fillStyle = `rgba(228,180,72,${0.08 + pulse * 0.12})`;
      ctx.arc(p.x, p.y, rad * 2.1, 0, Math.PI * 2);
      ctx.fill();
    }

    t++;
    requestAnimationFrame(step);
  }

  resize();
  init();
  window.addEventListener('resize', () => { resize(); init(); }, { passive: true });
  requestAnimationFrame(step);
})();
