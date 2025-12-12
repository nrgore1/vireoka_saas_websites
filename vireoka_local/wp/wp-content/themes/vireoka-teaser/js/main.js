document.addEventListener("DOMContentLoaded", () => {
  const fadeEls = document.querySelectorAll(".fade-on-scroll");

  const reveal = () => {
    const trigger = window.innerHeight * 0.9;
    fadeEls.forEach((el) => {
      const rect = el.getBoundingClientRect();
      if (rect.top < trigger) {
        el.classList.add("visible");
      }
    });
  };

  reveal();
  window.addEventListener("scroll", reveal, { passive: true });

  // Simple nav background shift after scroll
  const nav = document.querySelector("[data-vireoka-nav]");
  if (nav) {
    const onScroll = () => {
      if (window.scrollY > 40) {
        nav.classList.add("backdrop-blur-md", "bg-slate-950/80", "border-b", "border-slate-800/70");
      } else {
        nav.classList.remove("backdrop-blur-md", "bg-slate-950/80", "border-b", "border-slate-800/70");
      }
    };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
  }
});
