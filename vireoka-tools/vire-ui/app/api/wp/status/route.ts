import { NextResponse } from "next/server";

const WP_BASE = process.env.WP_BASE_URL;

export async function GET() {
  if (!WP_BASE) {
    return NextResponse.json(
      { error: "WP_BASE_URL not configured" },
      { status: 500 }
    );
  }

  const r = await fetch(`${WP_BASE}/wp-json/vire/status`, {
    cache: "no-store",
  });

  const data = await r.json();
  return NextResponse.json(data);
}
