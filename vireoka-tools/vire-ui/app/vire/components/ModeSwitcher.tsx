"use client";

export type VireMode = "Creator" | "Planner" | "Admin";

export default function ModeSwitcher({
  mode,
  onChange,
}: {
  mode: VireMode;
  onChange: (m: VireMode) => void;
}) {
  const modes: VireMode[] = ["Creator", "Planner", "Admin"];

  return (
    <div style={{
      display: "flex",
      gap: 10,
      alignItems: "center",
      flexWrap: "wrap",
      margin: "12px 0 6px"
    }}>
      <span style={{opacity:.75, fontSize:12}}>Mode</span>
      {modes.map(m => (
        <button
          key={m}
          onClick={() => onChange(m)}
          style={{
            cursor: "pointer",
            padding: "10px 12px",
            borderRadius: 12,
            border: "1px solid rgba(255,255,255,.14)",
            background: m === mode ? "rgba(58,244,211,.18)" : "rgba(2,6,23,.2)",
            color: "#E5E7EB",
            fontWeight: 800
          }}
        >
          {m}
        </button>
      ))}
    </div>
  );
}
