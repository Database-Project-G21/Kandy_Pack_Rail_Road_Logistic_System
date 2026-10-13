"use client";
import { useEffect, useRef, useSyncExternalStore } from "react";
import { usePathname, useRouter } from "next/navigation";
import Link from "next/link";
import Brand from "./Brand";
function subscribeToSession(onChange: () => void) {
  const onStorage = (event: StorageEvent) => {
    if (event.key === "token" || event.key === "role" || event.key === null) {
      onChange();
      window.location.reload();
    }
  };
  window.addEventListener("storage", onStorage);
  return () => window.removeEventListener("storage", onStorage);
}

export default function Navbar() {
  const role = useSyncExternalStore(subscribeToSession, () => localStorage.getItem("role"), () => null);
  const header = useRef<HTMLElement>(null);
  const pathname = usePathname();
  const router = useRouter();
  useEffect(() => {
    const element = header.current;
    if (!element) return;
    // Measure wrapping navigation, browser zoom and the logo loading.
    const measure = () => document.documentElement.style.setProperty("--site-nav-height", `${element.getBoundingClientRect().height}px`);
    measure();
    const observer = new ResizeObserver(measure);
    observer.observe(element);
    return () => {
      observer.disconnect();
      document.documentElement.style.removeProperty("--site-nav-height");
    };
  }, [pathname]);
  if (pathname === "/login" || pathname === "/signup") return null;
  return <header ref={header} className="site-nav"><div className="nav-top">FROM KANDY TO YOUR BUSINESS • RAIL & ROAD DISTRIBUTION</div><nav className="nav-inner" aria-label="Main navigation"><Link className="brand" href={role === "CUSTOMER" ? "/" : "/dashboard"}><Brand /></Link><div className="nav-links">{role === "CUSTOMER" ? <><Link href="/" aria-current={pathname === "/" ? "page" : undefined}>Shop & order</Link><Link href="/orders" aria-current={pathname === "/orders" ? "page" : undefined}>My orders</Link></> : role && <Link href="/dashboard" aria-current={pathname === "/dashboard" ? "page" : undefined}>Dashboard</Link>}{role && <><span className="role-pill">{role.replaceAll("_", " ")}</span><button onClick={() => { ["token", "role", "customerId"].forEach(key => localStorage.removeItem(key)); router.push("/login"); }}>Log out ↗</button></>}</div></nav></header>;
}
