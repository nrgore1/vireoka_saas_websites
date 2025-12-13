import { NextResponse } from "next/server";

const WP_BASE = process.env.WP_BASE_URL;

export async function GET(
  _req: Request,
  { params }: { params: { path: string[] } }
) {
  if (!WP_BASE) {
    return NextResponse.json(
      { ok: false, error: "WP_BASE_URL not configured" },
      { status: 500 }
    );
  }

  const url = `${WP_BASE}/wp-json/vire/${params.path.join("/")}`;
  const r = await fetch(url, { cache: "no-store" });
  const data = await r.json();

  return NextResponse.json(data, { status: r.status });
}

export async function POST(
  req: Request,
  { params }: { params: { path: string[] } }
) {
  if (!WP_BASE) {
    return NextResponse.json(
      { ok: false, error: "WP_BASE_URL not configured" },
      { status: 500 }
    );
  }

  const body = await req.text();
  const url = `${WP_BASE}/wp-json/vire/${params.path.join("/")}`;

  const r = await fetch(url, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body,
    cache: "no-store",
  });

  const data = await r.json();
  return NextResponse.json(data, { status: r.status });
}
