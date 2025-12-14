"use client";

import { useEffect, useMemo, useState } from "react";
import ModeBanner from "./components/ModeBanner";
import Card from "./components/Card";
import Table from "./components/Table";
import CodeBlock from "./components/CodeBlock";
import ApprovalButtons from "./components/ApprovalButtons";
import Hints from "./components/Hints";
import { useWpAuth } from "./hooks/useWpAuth";

type AnyJson = any;

async function getJson(url: string) {
  const r = await fetch(url, { cache: "no-store", credentials: "include" });
  if (!r.ok) {
    const t = await r.text().catch(() => "");
    throw new Error(`${r.status} ${url}\n${t}`);
  }
  return r.json();
}

function useVire(base: string) {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [whoami, setWhoami] = useState<AnyJson>(null);
  const [status, setStatus] = useState<AnyJson>(null);
  const [plan, setPlan] = useState<AnyJson>(null);
  const [explain, setExplain] = useState<AnyJson>(null);
  const [risk, setRisk] = useState<AnyJson>(null);
  const [editorial, setEditorial] = useState<AnyJson>(null);
  const [monitor, setMonitor] = useState<AnyJson>(null);
  const [audit, setAudit] = useState<AnyJson>(null);

  async function refresh() {
    setLoading(true);
    setError(null);
    try {
      const [
        w, s, p, e, r, ed, m, a
      ] = await Promise.all([
        getJson(`${base}/whoami`),
        getJson(`${base}/status`).catch(() => ({ ok: true, note: "No status available" })),
        getJson(`${base}/plan`).catch(() => ({ ok: true, note: "No plan available" })),
        getJson(`${base}/explain`).catch(() => ({ ok: true, note: "No explainer available" })),
        getJson(`${base}/plugin-risk`).catch(() => ({ ok: true, items: [] })),
        getJson(`${base}/editorial`).catch(() => ({ ok: true, items: [] })),
        getJson(`${base}/monitor`).catch(() => ({ ok: true })),
        getJson(`${base}/audit?limit=30`).catch(() => null),
      ]);
      setWhoami(w);
      setStatus(s);
      setPlan(p);
      setExplain(e);
      setRisk(r);
      setEditorial(ed);
      setMonitor(m);
      setAudit(a);
    } catch (err: any) {
      setError(String(err?.message || err));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { refresh(); }, [base]);

  return { loading, error, refresh, whoami, status, plan, explain, risk, editorial, monitor, audit };
}

export default function ClientDashboard() {
  const wpAuth = useWpAuth(); // dev token OR cookie based
  const base = process.env.NEXT_PUBLIC_VIRE_BASE || "/wp-json/vire/v1";

  const { loading, error, refresh, whoami, status, plan, explain, risk, editorial, monitor, audit } =
    useVire(base);

  const modes = useMemo(() => {
    const caps = whoami?.caps || {};
    const out = [];
    out.push("Creator");
    out.push("Planner");
    if (caps.admin) out.push("Admin");
    return out;
  }, [whoami]);

  // Hard gate if hook says no admin/viewer (cookie path). Token path will set true.
  if (wpAuth === false) {
    return (
      <main style={{ padding: 24, maxWidth: 1100, margin: "0 auto", color: "#E5E7EB" }}>
        <h1 style={{ marginTop: 0 }}>Admin access required.</h1>
        <p style={{ opacity: 0.85 }}>
          This UI requires WordPress authentication cookies (recommended) or a local dev token.
        </p>
        <CodeBlock>
{`Fix options:
1) Production: deploy Vire UI inside WordPress as a plugin (same domain) ✅
2) Local dev: open with token:
   http://localhost:3000/?vire_token=local-admin`}
        </CodeBlock>
      </main>
    );
  }

  return (
    <div style={{ minHeight: "100vh", background: "#020617", color: "#E5E7EB" }}>
      <ModeBanner modes={modes} right={
        <button onClick={refresh} style={{
          padding: "10px 12px", borderRadius: 12, border: "1px solid rgba(255,255,255,.12)",
          background: "rgba(15,23,42,.7)", color: "#E5E7EB", fontWeight: 800, cursor: "pointer"
        }}>
          ↻ Refresh
        </button>
      } />

      <main style={{ padding: 24, maxWidth: 1200, margin: "0 auto" }}>
        <header style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", gap: 14, flexWrap: "wrap" }}>
          <div>
            <h1 style={{
              margin: 0, letterSpacing: "-0.03em",
              background: "linear-gradient(90deg,#0A1A4A,#5A2FE3,#E4B448)",
              WebkitBackgroundClip: "text",
              color: "transparent",
              fontSize: 28
            }}>
              Vire 6.3 Console
            </h1>
            <p style={{ margin: "8px 0 0", opacity: 0.8 }}>
              Live sync status, approvals, risk scoring, editorial calendar, creator loop, and audit trails.
            </p>
          </div>

          <div style={{ opacity: 0.85, fontSize: 13 }}>
            <div><b>User:</b> {whoami?.user?.display_name || "—"}</div>
            <div><b>Role:</b> {whoami?.caps?.admin ? "Admin" : "Viewer"}</div>
          </div>
        </header>

        {loading && (
          <div style={{
            marginTop: 16, padding: 14, borderRadius: 14,
            border: "1px solid rgba(255,255,255,.10)", background: "rgba(15,23,42,.55)"
          }}>
            Loading live data…
          </div>
        )}

        {error && (
          <div style={{
            marginTop: 16, padding: 14, borderRadius: 14,
            border: "1px solid rgba(239,68,68,.35)", background: "rgba(127,29,29,.28)", color: "#FCA5A5",
            whiteSpace: "pre-wrap"
          }}>
            {error}
          </div>
        )}

        <Hints />

        <section style={{ display: "grid", gridTemplateColumns: "repeat(12,1fr)", gap: 14, marginTop: 16 }}>
          <div style={{ gridColumn: "span 6" }}>
            <Card title="Run Status" subtitle="What ran last + which mode + remote host" json={status} />
          </div>
          <div style={{ gridColumn: "span 6" }}>
            <Card title="Monitor" subtitle="WP + PHP environment snapshot" json={monitor} />
          </div>

          <div style={{ gridColumn: "span 12" }}>
            <Card
              title="🔐 Approvals"
              subtitle="Admin-only. Apply/Reject the current plan. Every action is audit-logged."
            >
              <ApprovalButtons base={base} isAdmin={!!whoami?.caps?.admin} />
              <div style={{ marginTop: 10, opacity: 0.8, fontSize: 13 }}>
                Tip: approvals write to WP option <code>vire_last_approval</code> + audit table.
              </div>
            </Card>
          </div>

          <div style={{ gridColumn: "span 6" }}>
            <Card title="Resolution Plan" subtitle="Structured plan JSON from your sync suite" json={plan} />
          </div>

          <div style={{ gridColumn: "span 6" }}>
            <Card title="AI Explainer" subtitle="Plain-English explanation (AI diff explainer)" json={explain} />
          </div>

          <div style={{ gridColumn: "span 12" }}>
            <Card title="🧩 Plugin Risk Scoring" subtitle="Table view (highest risk first)">
              <Table
                columns={[
                  { key: "risk", label: "Risk" },
                  { key: "active", label: "Active" },
                  { key: "plugin", label: "Plugin" },
                  { key: "version", label: "Version" },
                  { key: "file", label: "File" },
                  { key: "notes", label: "Notes" },
                ]}
                rows={(risk?.items || [])}
                emptyText="No plugins found."
              />
            </Card>
          </div>

          <div style={{ gridColumn: "span 12" }}>
            <Card title="🗓 Editorial Calendar" subtitle="Table view (stored in WP option vire_editorial_calendar)">
              <Table
                columns={[
                  { key: "target_date", label: "Target Date" },
                  { key: "mode", label: "Mode" },
                  { key: "title", label: "Title" },
                  { key: "topic", label: "Topic" },
                  { key: "notes", label: "Notes" },
                ]}
                rows={(editorial?.items || [])}
                emptyText="No editorial items yet. Admins can POST /editorial to add."
              />
              <div style={{ marginTop: 10 }}>
                <CodeBlock>
{`Admin add item:
POST ${base}/editorial
{ "title":"...", "topic":"...", "target_date":"2025-12-20", "mode":"Creator", "notes":"..." }`}
                </CodeBlock>
              </div>
            </Card>
          </div>

          {whoami?.caps?.admin && audit && (
            <div style={{ gridColumn: "span 12" }}>
              <Card title="🧾 Audit Trail" subtitle="Last 30 admin actions">
                <Table
                  columns={[
                    { key: "created_at", label: "Time (UTC)" },
                    { key: "user_id", label: "User" },
                    { key: "action", label: "Action" },
                  ]}
                  rows={audit?.items || []}
                  emptyText="No audit events yet."
                />
              </Card>
            </div>
          )}
        </section>

        <footer style={{ marginTop: 22, opacity: 0.7, fontSize: 12 }}>
          <div>Base API: <code>{base}</code></div>
          <div>Deploy recommended: package UI inside WordPress plugin so cookies + auth work cleanly.</div>
        </footer>
      </main>
    </div>
  );
}
