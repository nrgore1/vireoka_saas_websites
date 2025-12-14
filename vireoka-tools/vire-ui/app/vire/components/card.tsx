"use client";

import React from "react";
import CodeBlock from "./CodeBlock";

export default function Card({
  title,
  subtitle,
  json,
  children,
}: {
  title: string;
  subtitle?: string;
  json?: any;
  children?: React.ReactNode;
}) {
  return (
    <section style={{
      background: "rgba(15,23,42,.62)",
      border: "1px solid rgba(255,255,255,.10)",
      borderRadius: 18,
      padding: 16,
      boxShadow: "0 10px 30px rgba(0,0,0,.25)",
      overflow: "hidden",
    }}>
      <div style={{ display:"flex", justifyContent:"space-between", gap: 12, alignItems: "baseline", flexWrap: "wrap" }}>
        <div>
          <h2 style={{ margin: 0, fontSize: 14, letterSpacing: ".08em", textTransform: "uppercase", opacity: .85 }}>
            {title}
          </h2>
          {subtitle && <p style={{ margin: "8px 0 0", opacity: 0.78, fontSize: 13 }}>{subtitle}</p>}
        </div>
      </div>

      <div style={{ marginTop: 12 }}>
        {children}
        {json !== undefined && (
          <CodeBlock>{JSON.stringify(json, null, 2)}</CodeBlock>
        )}
      </div>
    </section>
  );
}
