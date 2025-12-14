"use client";

import React from "react";

export default function ModeBanner({
  modes,
  right,
}: {
  modes: string[];
  right?: React.ReactNode;
}) {
  return (
    <div style={{
      position: "sticky",
      top: 0,
      zIndex: 50,
      padding: "12px 16px",
      borderBottom: "1px solid rgba(255,255,255,.10)",
      background: "rgba(2,6,23,.75)",
      backdropFilter: "blur(14px)"
    }}>
      <div style={{
        maxWidth: 1200,
        margin: "0 auto",
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        gap: 12,
        flexWrap: "wrap"
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <span style={{
            width: 10, height: 10, borderRadius: 999,
            background: "#3AF4D3",
            boxShadow: "0 0 18px rgba(58,244,211,.45)"
          }} />
          <span style={{ fontSize: 13, opacity: .85 }}>
            Active Modes: <b>{modes.join(" | ")}</b>
          </span>
        </div>
        <div>{right}</div>
      </div>
    </div>
  );
}
