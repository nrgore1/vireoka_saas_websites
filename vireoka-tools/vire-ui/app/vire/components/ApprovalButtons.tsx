"use client";

import { useState } from "react";

export default function ApprovalButtons({ base, isAdmin }: { base: string; isAdmin: boolean }) {
  const [busy, setBusy] = useState<null | "apply" | "reject">(null);
  const [msg, setMsg] = useState<string>("");

  async function approve(action: "apply" | "reject") {
    setMsg("");
    setBusy(action);
    try {
      const r = await fetch(`${base}/approval`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ action }),
        credentials: "include",
        cache: "no-store",
      });
      if (!r.ok) throw new Error(await r.text());
      const j = await r.json();
      setMsg(`✅ ${action.toUpperCase()} OK @ ${j.at}`);
    } catch (e: any) {
      setMsg(`❌ ${action.toUpperCase()} failed: ${String(e?.message || e)}`);
    } finally {
      setBusy(null);
    }
  }

  if (!isAdmin) {
    return (
      <div style={{
        padding: 14,
        borderRadius: 14,
        border: "1px dashed rgba(255,255,255,.18)",
        background: "rgba(2,6,23,.35)",
        opacity: .9
      }}>
        Viewer mode: approvals are admin-only.
      </div>
    );
  }

  const btn = {
    padding: "10px 12px",
    borderRadius: 12,
    border: "1px solid rgba(255,255,255,.12)",
    background: "rgba(15,23,42,.7)",
    color: "#E5E7EB",
    fontWeight: 900,
    cursor: "pointer",
  } as const;

  const primary = {
    ...btn,
    border: "none",
    background: "linear-gradient(135deg,#5A2FE3,#3AF4D3)",
    boxShadow: "0 0 22px rgba(228,180,72,.18)"
  } as const;

  return (
    <div>
      <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
        <button
          disabled={busy !== null}
          onClick={() => approve("apply")}
          style={primary}
        >
          {busy === "apply" ? "Applying…" : "✅ Apply Plan"}
        </button>

        <button
          disabled={busy !== null}
          onClick={() => approve("reject")}
          style={btn}
        >
          {busy === "reject" ? "Rejecting…" : "❌ Reject Plan"}
        </button>

        <a
          href="/wp-admin/"
          style={{ ...btn, textDecoration: "none", display: "inline-flex", alignItems: "center" }}
        >
          Open WP Admin
        </a>
      </div>

      {msg && (
        <div style={{ marginTop: 10, fontSize: 13, opacity: 0.9, whiteSpace: "pre-wrap" }}>
          {msg}
        </div>
      )}
    </div>
  );
}
