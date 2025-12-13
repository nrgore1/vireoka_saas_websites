import ApprovalButtons from "./components/ApprovalButtons";

type AnyJson = any;

async function loadJson(url: string): Promise<AnyJson> {
  const r = await fetch(url, { cache: "no-store" });
  if (!r.ok) return null;
  return r.json();
}

export default async function Page() {
  const base =
    process.env.NEXT_PUBLIC_VIRE_API ||
    "http://localhost:3000/api/vire";

  const status = await loadJson(`${base}/status`);
  const plan = await loadJson(`${base}/plan`);
  const explain = await loadJson(`${base}/explain`);
  const risk = await loadJson(`${base}/plugin-risk`);
  const editorial = await loadJson(`${base}/editorial`);
  const monitor = await loadJson(`${base}/monitor`);

  return (
    <main style={{ padding: 24, maxWidth: 1100, margin: "0 auto" }}>
      <h1>Vire 6 UI</h1>
      <p style={{ opacity: 0.8 }}>
        Admin-only. Reads sync artifacts, explains conflicts, scores plugin risk,
        runs prompt→draft→publish, and monitors health.
      </p>

      <section style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
        <Card title="Run Status" json={status} />
        <Card title="Monitor" json={monitor} />
      </section>

      <section style={{ marginTop: 18 }}>
        <h2>🔐 Approvals</h2>
        <pre>
          POST {base}/approval {"{ action: 'apply' | 'reject' }"}
        </pre>

        <ApprovalButtons base={base} />
      </section>

      <section style={{ marginTop: 18, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
        <Card title="Resolution Plan" json={plan} />
        <Card title="AI Explainer" json={explain} />
      </section>

      <section style={{ marginTop: 18 }}>
        <h2>🧩 Plugin Risk Scoring</h2>
        <pre>{JSON.stringify(risk, null, 2)}</pre>
      </section>

      <section style={{ marginTop: 18 }}>
        <h2>🗓 Editorial Calendar</h2>
        <pre>{JSON.stringify(editorial, null, 2)}</pre>
      </section>
    </main>
  );
}

function Card({ title, json }: { title: string; json: any }) {
  return (
    <div style={{
      border: "1px solid rgba(0,0,0,.15)",
      borderRadius: 14,
      padding: 14,
      background: "#F9FAFB"
    }}>
      <h3>{title}</h3>
      <pre>{JSON.stringify(json, null, 2)}</pre>
    </div>
  );
}
