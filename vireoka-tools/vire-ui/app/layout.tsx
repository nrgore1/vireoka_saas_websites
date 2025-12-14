import { theme } from "./vire/ui/theme";

export const metadata = {
  title: "Vire 6 Admin Console",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body
        style={{
          margin: 0,
          background: `radial-gradient(900px circle at 20% 20%, rgba(56,189,248,.08), transparent 60%), ${theme.bg}`,
          color: theme.text,
          fontFamily: theme.font,
          lineHeight: 1.6,
        }}
      >
        {children}
      </body>
    </html>
  );
}
