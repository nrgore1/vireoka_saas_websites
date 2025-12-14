(() => {
  const canvas = document.createElement('canvas');
  canvas.id = 'vireoka-neural-canvas';
  document.body.appendChild(canvas);
  const ctx = canvas.getContext('2d', { alpha: true });

  const css = getComputedStyle(document.documentElement);
  const linkColor = () => css.getPropertyValue('--v-canvas-link').trim() || 'rgba(90,47,227,.35)';
  const dotColor  = () => css.getPropertyValue('--v-canvas-dot').trim()  || 'rgba(228,180,72,.55)';

  let W=0,H=0;
  const resize = () => { W=canvas.width=window.innerWidth; H=canvas.height=window.innerHeight; };
  window.addEventListener('resize', resize); resize();

  const baseCount = 64;
  let nodes = [];
  const makeNodes = (count) => Array.from({length:count}, () => ({
    x: Math.random()*W, y: Math.random()*H,
    vx: (Math.random()-0.5)*0.45, vy:(Math.random()-0.5)*0.45
  }));
  nodes = makeNodes(baseCount);

  const clamp = (v,a,b)=>Math.max(a,Math.min(b,v));
  const scrollStrength = () => {
    const y = window.scrollY || 0;
    const max = Math.max(document.body.scrollHeight - H, 1);
    return clamp(y / max, 0, 1);
  };

  function tick(){
    const s = scrollStrength(); // 0..1
    const target = Math.round(baseCount + s * 40);
    if (nodes.length < target) nodes.push(...makeNodes(target - nodes.length));
    if (nodes.length > target) nodes = nodes.slice(0, target);

    ctx.clearRect(0,0,W,H);

    // Move
    for (const n of nodes){
      n.x += n.vx; n.y += n.vy;
      if (n.x < 0 || n.x > W) n.vx *= -1;
      if (n.y < 0 || n.y > H) n.vy *= -1;
    }

    // Links
    const maxD = 130 + s*40;
    ctx.lineWidth = 1;
    for (let i=0;i<nodes.length;i++){
      const a = nodes[i];
      for (let j=i+1;j<nodes.length;j++){
        const b = nodes[j];
        const dx=a.x-b.x, dy=a.y-b.y;
        const d = Math.hypot(dx,dy);
        if (d < maxD){
          const alpha = (1 - d/maxD) * (0.25 + s*0.35);
          ctx.strokeStyle = linkColor().replace(/rgba\(([^)]+)\)/, (m,inner)=>{
            const parts = inner.split(',').map(x=>x.trim());
            return `rgba(${parts[0]},${parts[1]},${parts[2]},${alpha.toFixed(3)})`;
          });
          ctx.beginPath(); ctx.moveTo(a.x,a.y); ctx.lineTo(b.x,b.y); ctx.stroke();
        }
      }
    }

    // Dots
    ctx.fillStyle = dotColor();
    for (const n of nodes){
      ctx.beginPath(); ctx.arc(n.x,n.y,1.3 + s*0.6,0,Math.PI*2); ctx.fill();
    }

    requestAnimationFrame(tick);
  }
  tick();
})();
