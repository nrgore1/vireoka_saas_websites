import { NextRequest, NextResponse } from "next/server";

const WP_BASE =
  process.env.WP_BASE_URL || "https://vireoka.com/wp-json/vire";

export async function GET(
  _req: NextRequest,
  { params }: { params: { route: string } }
) {
  const r = await fetch(`${WP_BASE}/${params.route}`, {
    cache: "no-store",
  });

  const text = await r.text();
  return new NextResponse(text, {
    status: r.status,
    headers: { "content-type": "application/json" },
  });
}

export async function POST(
  req: NextRequest,
  { params }: { params: { route: string } }
) {
  const body = await req.text();

  const r = await fetch(`${WP_BASE}/${params.route}`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body,
  });

  const text = await r.text();
  return new NextResponse(text, {
    status: r.status,
    headers: { "content-type": "application/json" },
  });
}
