import type { Metadata } from "next";
import "./globals.css";
import Brand from "./components/Brand";
import Navbar from "./components/Navbar";

export const metadata: Metadata = {
  title: "KandyPack | Order & Delivery",
  description: "Rail and road distribution system for Kandypack",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="en"
      className="h-full antialiased"
    >
      <body className="min-h-full flex flex-col">
        <Navbar />
        <div className="flex-1 flex flex-col">{children}</div><footer className="site-footer"><div className="footer-brand"><Brand /></div><p>Everyday goods. Carefully packed. Connected by rail and road.</p><span>Sri Lanka · Distribution portal</span></footer>
      </body>
    </html>
  );
}