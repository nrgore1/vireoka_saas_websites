"use client";

type Props = {
  base: string;
};

export default function ApprovalButtons({ base }: Props) {
  async function approve(action: "apply" | "reject") {
    const r = await fetch(`${base}/approval`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ action }),
    });

    if (!r.ok) {
      alert(`Approval failed`);
      return;
    }

    alert(`Plan ${action.toUpperCase()}ED successfully`);
  }

  const btn: React.CSSProperties = {
    padding: "10px 12px",
    borderRadius: 12,
    border: "1px solid rgba(255,255,255,.2)",
    background: "#020617",
    color: "#E5E7EB",
    cursor: "pointer",
  };

  const primary: React.CSSProperties = {
    ...btn,
    background: "#22c55e",
    color: "#020617",
    border: "1px solid #22c55e",
    fontWeight: 600,
  };

  return (
    <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
      <button onClick={() => approve("apply")} style={primary}>
        ✅ Apply Plan
      </button>

      <button onClick={() => approve("reject")} style={btn}>
        ❌ Reject Plan
      </button>

      <a href="/wp-admin/" style={btn}>Open WP Admin</a>
      <a href="/_sync_status/dashboard.html" style={btn}>Sync Dashboard</a>
      <a href="/_sync_status/ai_conflicts_report.md" style={btn}>AI Report</a>
    </div>
  );
}
