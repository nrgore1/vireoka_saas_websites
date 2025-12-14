"use client";

type Col = { key: string; label: string };

export default function Table({
  columns,
  rows,
  emptyText,
}: {
  columns: Col[];
  rows: any[];
  emptyText: string;
}) {
  if (!rows || rows.length === 0) {
    return (
      <div style={{
        padding: 14, borderRadius: 14,
        border: "1px dashed rgba(255,255,255,.18)",
        background: "rgba(2,6,23,.35)",
        opacity: .85
      }}>
        {emptyText}
      </div>
    );
  }

  return (
    <div style={{ overflow: "auto", borderRadius: 14, border: "1px solid rgba(255,255,255,.10)" }}>
      <table style={{ width: "100%", borderCollapse: "separate", borderSpacing: 0, fontSize: 13 }}>
        <thead>
          <tr>
            {columns.map(c => (
              <th key={c.key} style={{
                textAlign: "left",
                padding: "10px 12px",
                background: "rgba(15,23,42,.9)",
                borderBottom: "1px solid rgba(255,255,255,.10)",
                position: "sticky",
                top: 0,
                zIndex: 1
              }}>
                {c.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => (
            <tr key={r?.id || r?.file || i} style={{
              background: i % 2 === 0 ? "rgba(2,6,23,.40)" : "rgba(2,6,23,.20)"
            }}>
              {columns.map(c => (
                <td key={c.key} style={{
                  padding: "10px 12px",
                  borderBottom: "1px solid rgba(255,255,255,.06)",
                  whiteSpace: "nowrap"
                }}>
                  {String(r?.[c.key] ?? "")}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
