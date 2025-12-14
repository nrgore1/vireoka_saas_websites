export default function Empty({ label }: { label: string }) {
  return <p style={{ opacity: .5 }}>— No {label} available</p>;
}
