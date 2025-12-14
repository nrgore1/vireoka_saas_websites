(() => {
  const root = document.documentElement;
  const mount = document.getElementById("v-neural-canvas");
  if (!mount) return;

  const canvas = document.createElement("canvas");
  canvas.style.position = "absolute";
  canvas.style.inset = "0";
  canvas.style.width = "100%";
  canvas.style.height = "100%";
  canvas.style.pointerEvents = "none";
  canvas.style.opacity = "0.65";
  mount.appendChild(canvas);

  const resize = () => {
    const dpr = Math.min(2, window.devicePixelRatio || 1);
    canvas.width = Math.floor(mount.clientWidth * dpr);
    canvas.height = Math.floor(mount.clientHeight * dpr);
  };
  resize();
  window.addEventListener("resize", resize, { passive: true });

  // Try WebGL2 first
  const gl = canvas.getContext("webgl2", { antialias: false, alpha: true, premultipliedAlpha: true });
  if (!gl) {
    // Fallback: simple 2D neural dots + lines
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let t = 0;
    const nodes = Array.from({ length: 70 }, (_, i) => ({
      x: Math.random(), y: Math.random(),
      vx: (Math.random() - 0.5) * 0.0006,
      vy: (Math.random() - 0.5) * 0.0006,
      r: 1 + Math.random() * 1.5,
    }));

    const step = () => {
      t += 1;
      const w = canvas.width, h = canvas.height;
      ctx.clearRect(0, 0, w, h);

      // background faint haze
      ctx.globalCompositeOperation = "lighter";
      ctx.fillStyle = "rgba(90,47,227,0.06)";
      ctx.fillRect(0, 0, w, h);

      // move
      for (const n of nodes) {
        n.x += n.vx; n.y += n.vy;
        if (n.x < 0 || n.x > 1) n.vx *= -1;
        if (n.y < 0 || n.y > 1) n.vy *= -1;
      }

      // lines
      for (let i = 0; i < nodes.length; i++) {
        for (let j = i + 1; j < nodes.length; j++) {
          const a = nodes[i], b = nodes[j];
          const dx = (a.x - b.x), dy = (a.y - b.y);
          const d = Math.hypot(dx, dy);
          if (d < 0.12) {
            const alpha = (0.12 - d) / 0.12;
            ctx.strokeStyle = `rgba(58,244,211,${0.08 * alpha})`;
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.moveTo(a.x * w, a.y * h);
            ctx.lineTo(b.x * w, b.y * h);
            ctx.stroke();
          }
        }
      }

      // dots
      for (const n of nodes) {
        ctx.fillStyle = "rgba(228,180,72,0.22)";
        ctx.beginPath();
        ctx.arc(n.x * w, n.y * h, n.r, 0, Math.PI * 2);
        ctx.fill();
      }

      ctx.globalCompositeOperation = "source-over";
      requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
    return;
  }

  const vert = `#version 300 es
  precision highp float;
  layout(location=0) in vec2 aPos;
  out vec2 vUv;
  void main() {
    vUv = (aPos + 1.0) * 0.5;
    gl_Position = vec4(aPos, 0.0, 1.0);
  }`;

  const frag = `#version 300 es
  precision highp float;
  in vec2 vUv;
  out vec4 outColor;

  float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453123); }
  float noise(vec2 p){
    vec2 i=floor(p), f=fract(p);
    float a=hash(i), b=hash(i+vec2(1,0)), c=hash(i+vec2(0,1)), d=hash(i+vec2(1,1));
    vec2 u=f*f*(3.0-2.0*f);
    return mix(a,b,u.x) + (c-a)*u.y*(1.0-u.x) + (d-b)*u.x*u.y;
  }

  void main() {
    vec2 uv = vUv;
    float t = float(mod(uint(gl_FragCoord.x + gl_FragCoord.y), 1024u)) * 0.0; // keep deterministic

    // animate via time uniform packed in alpha channel of clear color? we'll use gl_FragCoord time approximation via frame counter in JS
    // actual time comes from uTime uniform (set below)
    outColor = vec4(0.0); // overwritten in JS by real shader with uniforms
  }`;

  const compile = (type, src) => {
    const s = gl.createShader(type);
    gl.shaderSource(s, src);
    gl.compileShader(s);
    if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) {
      console.warn(gl.getShaderInfoLog(s));
      gl.deleteShader(s);
      return null;
    }
    return s;
  };

  // Real fragment with uniforms
  const frag2 = `#version 300 es
  precision highp float;
  in vec2 vUv;
  out vec4 outColor;
  uniform vec2 uRes;
  uniform float uTime;

  float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453123); }
  float noise(vec2 p){
    vec2 i=floor(p), f=fract(p);
    float a=hash(i), b=hash(i+vec2(1,0)), c=hash(i+vec2(0,1)), d=hash(i+vec2(1,1));
    vec2 u=f*f*(3.0-2.0*f);
    return mix(a,b,u.x) + (c-a)*u.y*(1.0-u.x) + (d-b)*u.x*u.y;
  }

  float glow(float d, float r){ return pow(clamp(1.0 - d/r, 0.0, 1.0), 2.2); }

  void main(){
    vec2 uv = vUv;
    vec2 p = (uv - 0.5) * vec2(uRes.x/uRes.y, 1.0);

    // drifting waves
    float n = noise(p*2.2 + vec2(uTime*0.05, -uTime*0.03));
    float n2 = noise(p*4.0 + vec2(-uTime*0.08, uTime*0.06));
    float wave = 0.55*n + 0.45*n2;

    // node field
    vec2 q = p*1.6;
    float m = 0.0;
    for (int i=0;i<7;i++){
      q = mat2(1.2, 0.3, -0.3, 1.2) * q + vec2(0.12, -0.08);
      float d = length(fract(q) - 0.5);
      m += glow(d, 0.22) * (0.25 + 0.12*sin(uTime*0.7 + float(i)));
    }

    // palette: deep blue + purple + teal + gold
    vec3 deep = vec3(0.04, 0.06, 0.14);
    vec3 purple = vec3(0.35, 0.18, 0.89);
    vec3 teal = vec3(0.23, 0.96, 0.83);
    vec3 gold = vec3(0.89, 0.71, 0.28);

    vec3 col = deep;
    col += purple * (0.22 + 0.35*wave);
    col += teal * (0.10 + 0.18*m);
    col += gold * (0.06 + 0.10*pow(m, 1.2));

    float vign = smoothstep(1.2, 0.35, length(p));
    float alpha = 0.9 * vign;

    outColor = vec4(col, alpha);
  }`;

  const vs = compile(gl.VERTEX_SHADER, vert);
  const fs = compile(gl.FRAGMENT_SHADER, frag2);
  if (!vs || !fs) return;

  const prog = gl.createProgram();
  gl.attachShader(prog, vs);
  gl.attachShader(prog, fs);
  gl.linkProgram(prog);
  if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) {
    console.warn(gl.getProgramInfoLog(prog));
    return;
  }
  gl.useProgram(prog);

  const quad = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, quad);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
    -1,-1,  1,-1, -1, 1,
    -1, 1,  1,-1,  1, 1
  ]), gl.STATIC_DRAW);

  gl.enableVertexAttribArray(0);
  gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0);

  const uRes = gl.getUniformLocation(prog, "uRes");
  const uTime = gl.getUniformLocation(prog, "uTime");

  let start = performance.now();
  const frame = () => {
    resize();
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.uniform2f(uRes, canvas.width, canvas.height);
    gl.uniform1f(uTime, (performance.now() - start) / 1000.0);
    gl.drawArrays(gl.TRIANGLES, 0, 6);
    requestAnimationFrame(frame);
  };
  requestAnimationFrame(frame);
})();
