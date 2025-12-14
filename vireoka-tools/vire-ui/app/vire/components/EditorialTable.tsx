export default function EditorialTable({ rows }: { rows: any[] }) {
  return (
    <table width="100%">
      <thead>
        <tr><th>Title</th><th>Topic</th><th>Date</th><th>Mode</th></tr>
      </thead>
      <tbody>
        {rows.map((r, i) => (
          <tr key={i}>
            <td>{r.title}</td>
            <td>{r.topic}</td>
            <td>{r.target_date}</td>
            <td>{r.mode}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
