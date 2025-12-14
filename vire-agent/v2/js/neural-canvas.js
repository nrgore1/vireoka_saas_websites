(function () {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  const root = document.querySelector('.vire-site');
  if (!root) return;

  const host = document.createElement('div');
  host.className = 'vire-neural-host';
  root.prepend(host);

  const canvas = document.createElement('canvas');
  host.appendChild(canvas);
  const ctx = canvas.getContext('2d');

  function resize() {
    canvas.width = host.clientWidth;
    canvas.height = 320;
  }

  const nodes = Array.from({length: 28}, () => ({
    x: Math.random() * canvas.width,
    y: Math.random() * canvas.height,
    vx: (Math.random() - 0.5) * 0.4,
    vy: (Math.random() - 0.5) * 0.4
  }));

  function tick() {
    ctx.clearRect(0,0,canvas.width,canvas.height);
    nodes.forEach(n => {
      n.x += n.vx; n.y += n.vy;
      if (n.x<0||n.x>canvas.width) n.vx*=-1;
      if (n.y<0||n.y>canvas.height) n.vy*=-1;
      ctx.fillStyle='rgba(90,47,227,.5)';
      ctx.beginPath();
      ctx.arc(n.x,n.y,2,0,Math.PI*2);
      ctx.fill();
    });
    requestAnimationFrame(tick);
  }

  resize();
  window.addEventListener('resize', resize);
  tick();
})();
