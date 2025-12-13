#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/vconfig.sh"

UI="$BASE_DIR/vire-ui"
OUT="$LOCAL_ROOT/vire-ui"

mkdir -p "$OUT"
cd "$UI"

# Build (you must have node/npm available)
npm install
npm run build

# Next export output
cp -r dist/* "$OUT/"

cat <<'EOF' > vire-ui/app/layout.tsx
export const metadata = {
  title: 'Vire UI',
  description: 'Vire 6 – Agentic Content & Web Governance UI',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body
        style={{
          margin: 0,
          background: '#f7f8fb',
          color: '#111',
        }}
      >
        {children}
      </body>
    </html>
  );
}
EOF


echo "✅ Vire UI published to: $OUT"
echo "➡ Open: http://localhost:8085/vire-ui/"
