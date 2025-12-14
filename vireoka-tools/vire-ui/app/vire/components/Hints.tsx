"use client";

export default function Hints() {
  return (
    <section style={{
      marginTop: 14,
      padding: 14,
      borderRadius: 16,
      border: "1px solid rgba(255,255,255,.10)",
      background: "linear-gradient(135deg, rgba(90,47,227,.20), rgba(58,244,211,.10))",
    }}>
      <div style={{ fontWeight: 900, letterSpacing: ".02em" }}>How to use this console</div>
      <ol style={{ margin: "10px 0 0", lineHeight: 1.8, opacity: .9, fontSize: 13 }}>
        <li>Run sync: <code>./vsync.sh all</code></li>
        <li>Generate explanations: <code>./vsync-ai-diff-explain.sh</code></li>
        <li>Open WP Admin → <b>Vire Console</b> (recommended production path)</li>
        <li>Review <b>Plan</b> + <b>AI Explainer</b>, then <b>Apply/Reject</b></li>
        <li>Audit trail records every admin action automatically</li>
      </ol>
    </section>
  );
}
