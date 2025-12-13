"use client";

export default function PluginRiskTable({ data }: { data: any[] }) {
  if (!Array.isArray(data)) return <pre>null</pre>;

  return (
    <table style={{ width: "100%", borderCollapse: "collapse" }}>
      <thead>
        <tr>
          <th align="left">Plugin</th>
          <th align="left">Risk</th>
          <th align="left">Reason</th>
        </tr>
      </thead>
      <tbody>
        {data.map((p, i) => (
          <tr key={i}>
            <td>{p.name}</td>
            <td style={{ color: p.score > 7 ? "#ef4444" : "#22c55e" }}>
              {p.score}/10
            </td>
            <td>{p.reason}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
