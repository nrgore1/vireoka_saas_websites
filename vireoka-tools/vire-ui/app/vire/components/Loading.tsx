export default function Loading({ label }: { label: string }) {
  return <p style={{ opacity: .6 }}>⏳ Loading {label}…</p>;
}
