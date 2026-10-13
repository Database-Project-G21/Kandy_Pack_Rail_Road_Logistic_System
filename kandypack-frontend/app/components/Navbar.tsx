"use client";
import { useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import Link from "next/link";
import Brand from "./Brand";
export default function Navbar() {
  const [role, setRole] = useState<string | null>(null);
  const pathname = usePathname();
  const router = useRouter();
  useEffect(() => {
    setRole(localStorage.getItem("role"));
    const onStorage = (event: StorageEvent) => {
      if (event.key === "token" || event.key === "role" || event.key === null) window.location.reload();
    };
    window.addEventListener("storage", onStorage);
    return () => window.removeEventListener("storage", onStorage);
  }, [pathname]);
  if (pathname === "/login" || pathname === "/signup") return null;
  return <header className="site-nav"><div className="nav-top">FROM KANDY TO YOUR BUSINESS • RAIL & ROAD DISTRIBUTION</div><nav className="nav-inner" aria-label="Main navigation"><Link className="brand" href={role === "CUSTOMER" ? "/" : "/dashboard"}><Brand /></Link><div className="nav-links">{role === "CUSTOMER" ? <><Link href="/" aria-current={pathname === "/" ? "page" : undefined}>Shop & order</Link><Link href="/orders" aria-current={pathname === "/orders" ? "page" : undefined}>My orders</Link></> : role && <Link href="/dashboard" aria-current={pathname === "/dashboard" ? "page" : undefined}>Dashboard</Link>}{role && <><span className="role-pill">{role.replaceAll("_", " ")}</span><button onClick={() => { ["token", "role", "customerId"].forEach(key => localStorage.removeItem(key)); setRole(null); router.push("/login"); }}>Log out ↗</button></>}</div></nav></header>;
}
