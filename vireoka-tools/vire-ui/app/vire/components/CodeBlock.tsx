"use client";

export default function CodeBlock({ children }: { children: any }) {
  return (
    <pre style={{
      margin: 0,
      padding: 14,
      borderRadius: 14,
      background: "rgba(2,6,23,.7)",
      border: "1px solid rgba(255,255,255,.10)",
      overflow: "auto",
      fontSize: 12,
      lineHeight: 1.5,
      color: "#E5E7EB"
    }}>
      {children}
    </pre>
  );
}
