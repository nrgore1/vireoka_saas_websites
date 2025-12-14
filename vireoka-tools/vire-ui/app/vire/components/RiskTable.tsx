export default function RiskTable({ rows }: { rows: any[] }) {
  return (
    <table width="100%">
      <thead>
        <tr><th>Plugin</th><th>Risk</th><th>Reason</th></tr>
      </thead>
      <tbody>
        {rows.map((r, i) => (
          <tr key={i}>
            <td>{r.plugin}</td>
            <td>{r.score}</td>
            <td>{r.reason}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
