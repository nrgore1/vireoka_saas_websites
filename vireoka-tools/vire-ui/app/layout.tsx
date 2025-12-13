export const metadata = {
  title: "Vire Admin Console",
  description: "Agentic control plane for WordPress & AI operations",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body style={{
        margin: 0,
        background: "#020617",
        color: "#E5E7EB",
        fontFamily: "Inter, system-ui, sans-serif"
      }}>
        {children}
      </body>
    </html>
  );
}
