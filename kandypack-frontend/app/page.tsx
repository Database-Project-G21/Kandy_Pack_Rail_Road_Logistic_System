"use client";

import { useEffect, useRef, useState } from "react";
import Image from "next/image";
import ProductImage from "./components/ProductImage";
import { BusyLabel, LoadingState, Notice } from "./components/Feedback";
import { readJson, errorText } from "./lib/api-response";
import { useRouter } from "next/navigation";

const API = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8081";
interface Product { productId: string; productName: string; price: number }
interface Route { routeId: string; city: string; coverageArea: string }
interface Item { productId: string; quantity: number }
interface Allocation { tripId: string; productId: string; productName: string; quantity: number; departure: string; arrival: string }
interface Receipt { orderId: string; amount: number; allocations: Allocation[] }

function minimumDeliveryDate(): string {
  const parts = new Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Colombo", year: "numeric", month: "2-digit", day: "2-digit" }).formatToParts(new Date());
  const value = (type: string) => parts.find(p => p.type === type)!.value;
  const date = new Date(`${value("year")}-${value("month")}-${value("day")}T00:00:00Z`);
  date.setUTCDate(date.getUTCDate() + 7);
  return date.toISOString().slice(0, 10);
}
export default function Home() {
  const router = useRouter();
  const [search, setSearch] = useState("");
  const [products, setProducts] = useState<Product[]>([]);
  const [routes, setRoutes] = useState<Route[]>([]);
  const [items, setItems] = useState<Item[]>([{ productId: "", quantity: 1 }]);
  const [routeId, setRouteId] = useState("");
  const [deliveryDate, setDeliveryDate] = useState("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState("");
  const [loadAttempt, setLoadAttempt] = useState(0);
  const [busy, setBusy] = useState(false);
  const submitting = useRef(false);
  const [receipt, setReceipt] = useState<Receipt | null>(null);
  const minDate = minimumDeliveryDate();

  useEffect(() => {
    if (!localStorage.getItem("token")) { router.push("/login"); return; }
    if (localStorage.getItem("role") !== "CUSTOMER") { router.push("/dashboard"); return; }
    let live = true;
    const controller = new AbortController();
    Promise.all([
      fetch(`${API}/api/products`, { signal: controller.signal }).then(readJson<Product[]>),
      fetch(`${API}/api/routes`, { signal: controller.signal }).then(readJson<Route[]>),
    ]).then(([p, r]) => {
      if (!Array.isArray(p) || !Array.isArray(r)) throw new Error("Unexpected catalogue response.");
      if (live) { setProducts(p); setRoutes(r); }
    })
      .catch(err => { if (live) setLoadError("Could not load products and routes: " + errorText(err)); })
      .finally(() => { if (live) setLoading(false); });
    return () => { live = false; controller.abort(); };
  }, [router, loadAttempt]);

  const total = items.reduce((sum, item) => sum + (products.find(p => p.productId === item.productId)?.price || 0) * (Number.isFinite(item.quantity) ? item.quantity : 0), 0);
  function changeItem(index: number, patch: Partial<Item>) {
    setItems(current => current.map((item, i) => i === index ? { ...item, ...patch } : item));
  }
  async function submit(event: React.FormEvent) {
    event.preventDefault();
    if (submitting.current) return;
    if (deliveryDate < minimumDeliveryDate()) { setMessage("Choose a date at least seven days from today."); return; }
    if (items.some(i => !i.productId || !Number.isSafeInteger(i.quantity) || i.quantity < 1)) {
      setMessage("Select a product and a positive whole-number quantity for every item."); return;
    }
    submitting.current = true; setBusy(true); setMessage(""); setReceipt(null);
    try {
      const response = await fetch(`${API}/api/orders`, {
        method: "POST", headers: { "Content-Type": "application/json", Authorization: `Bearer ${localStorage.getItem("token")}` },
        body: JSON.stringify({ routeId, deliveryDate, items }),
      });
      if (response.status === 401) { router.push("/login"); return; }
      const order = await readJson<Receipt>(response);
      setReceipt(order); setItems([{ productId: "", quantity: 1 }]);
    } catch (err) { setMessage("Could not confirm your order: " + errorText(err) + " Check My orders before submitting again."); }
    finally { submitting.current = false; setBusy(false); }
  }

  return <main className="shop-shell">
    <section className="shop-hero"><div className="hero-copy"><span className="eyebrow">KANDY ORIGIN. ISLANDWIDE CONNECTIONS.</span><h1>Everyday essentials.<br /><em>Delivered with care.</em></h1><p>Order for your shop or business. Choose your products and delivery route, and let KandyPack plan the journey by rail and road.</p><a href="#catalog" className="primary-link">Browse the catalogue <span aria-hidden="true">→</span></a><div className="hero-detail">Wholesale & retail orders · Planned delivery</div></div><div className="hero-art"><Image src="/brand/distribution-hero.png" alt="Illustrative packaged goods prepared for distribution" fill sizes="(max-width: 640px) 100vw, 50vw" unoptimized preload /><div className="art-tag"><b>PACKED WITH CARE</b><span>Kandy → Rail → Road → Your business</span></div></div></section>
    <div className="service-strip"><span><b>01</b> Choose your products</span><span><b>02</b> Plan your delivery</span><span><b>03</b> Follow your order</span></div>
    <section id="catalog" className="catalog"><div className="section-heading"><div><span className="eyebrow">THE COLLECTION</span><h2>Stock up on everyday favourites</h2></div><label className="search-box"><span>Search products</span><input type="search" placeholder="Search by name or product ID" value={search} onChange={e => setSearch(e.target.value)} /></label></div>
    {loading && <LoadingState>Loading products and delivery routes...</LoadingState>}
    {loadError && <Notice kind="error">{loadError}<br /><button type="button" className="secondary-button" onClick={() => { setLoadError(""); setLoading(true); setLoadAttempt(value => value + 1); }}>Try again</button></Notice>}
    <div className="product-grid">{products.filter(product => `${product.productName} ${product.productId}`.toLowerCase().includes(search.toLowerCase())).map(product => <article className="product-card" key={product.productId}><ProductImage productName={product.productName} /><div className="product-info"><span className="product-code">{product.productId}</span><h3>{product.productName}</h3><div className="product-bottom"><strong>Rs. {Number(product.price).toFixed(2)}</strong><button disabled={busy} type="button" aria-label={`Add ${product.productName} to order`} onClick={() => {setItems(current => { const existing = current.find(i => i.productId === product.productId); if (existing) return current.map(i => i.productId === product.productId ? {...i, quantity: i.quantity + 1} : i); const blank = current.findIndex(i => !i.productId); return blank >= 0 ? current.map((i, idx) => idx === blank ? {productId: product.productId, quantity: 1} : i) : [...current, {productId: product.productId, quantity: 1}]; }); document.getElementById("checkout")?.scrollIntoView({behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "instant" : "smooth", block: "start"});}}>Add +</button></div></div></article>)}</div>
    {!loading && !loadError && !products.filter(product => `${product.productName} ${product.productId}`.toLowerCase().includes(search.toLowerCase())).length && <p className="empty-state">No products match your search.</p>}
    <p className="catalog-note">Sample product images are illustrative; actual brand packaging may differ. Names and prices are from the live catalogue.</p></section>
    <div id="checkout" className="checkout-panel">
      <span className="eyebrow">YOUR SELECTION</span><h2 className="text-2xl font-bold text-slate-800">Complete your order</h2>
      <p className="mt-2 text-sm text-slate-600">Choose products and the route covering your delivery address. We will reserve suitable trains automatically.</p>
      {loading ? <LoadingState>Preparing your order form...</LoadingState> : loadError ? <p className="empty-state">Please reload the catalogue using Try again above.</p> : <form aria-busy={busy} onSubmit={submit} className="mt-6 space-y-5">
        <fieldset disabled={busy} className="space-y-5 disabled:opacity-70">
          <legend className="font-semibold text-slate-800">Products</legend>
          {items.map((item, index) => <div key={index} className="grid grid-cols-1 gap-3 rounded-lg bg-slate-50 p-4 sm:grid-cols-[1fr_100px_auto]">
            <label className="text-sm">Product {index + 1}
              <select aria-label={`Product ${index + 1}`} required value={item.productId} onChange={e => changeItem(index, { productId: e.target.value })} className="mt-1 w-full rounded-lg border border-slate-300 bg-white p-2">
                <option value="">Choose a product</option>
                {products.map(p => <option key={p.productId} value={p.productId}>{p.productName} - Rs. {p.price}</option>)}
              </select>
            </label>
            <label className="text-sm">Quantity
              <input aria-label={`Quantity ${index + 1}`} type="number" min={1} step={1} required value={Number.isNaN(item.quantity) ? "" : item.quantity} onChange={e => changeItem(index, { quantity: e.target.valueAsNumber })} className="mt-1 w-full rounded-lg border border-slate-300 p-2" />
            </label>
            {items.length > 1 && <button type="button" aria-label={`Remove product ${index + 1}`} onClick={() => setItems(current => current.filter((_, i) => i !== index))} className="self-end rounded-lg p-2 text-sm text-red-700">Remove</button>}
          </div>)}
          <button type="button" onClick={() => setItems(current => [...current, { productId: "", quantity: 1 }])} className="text-sm font-medium text-blue-800">+ Add another product</button>
          <label className="block text-sm font-medium">Delivery route
            <select aria-label="Delivery route" required value={routeId} onChange={e => setRouteId(e.target.value)} className="mt-1 w-full rounded-lg border border-slate-300 p-3">
              <option value="">Choose the route in your delivery city</option>
              {routes.map(r => <option key={r.routeId} value={r.routeId}>{r.city}: {r.coverageArea} ({r.routeId})</option>)}
            </select>
          </label>
          <label className="block text-sm font-medium">Delivery date
            <input aria-label="Delivery date" type="date" required min={minDate} value={deliveryDate} onChange={e => setDeliveryDate(e.target.value)} className="mt-1 w-full rounded-lg border border-slate-300 p-3" />
            <span className="mt-1 block text-xs font-normal text-slate-500">At least seven days from today. All items must have suitable trains before delivery.</span>
          </label>
          <p className="font-semibold">Estimated total: Rs. {total.toFixed(2)}</p>
          <p className="text-xs text-slate-500">An order may use more than one train. The final allocation appears after you place the order.</p>
          <button type="submit" disabled={loading || busy || !products.length || !routes.length} className="w-full rounded-lg bg-[#a91d40] p-3 font-medium text-white disabled:opacity-60">{busy ? <BusyLabel>Reserving your order...</BusyLabel> : "Place order"}</button>
        </fieldset>
      </form>}
      {message && <Notice kind="error">{message}</Notice>}
      {receipt && <section aria-live="polite" className="mt-6 rounded-lg border border-green-200 bg-green-50 p-4">
        <h2 className="font-semibold text-green-900">Order {receipt.orderId} placed successfully</h2>
        <p className="mt-1 text-sm">Total: Rs. {Number(receipt.amount).toFixed(2)}</p>
        <ul className="mt-3 space-y-2 text-sm">{receipt.allocations.map(a => <li key={`${a.tripId}-${a.productId}`}><strong>{a.quantity} x {a.productName}</strong> on {a.tripId}. Train arrival: {a.arrival.replace("T", " ")} (Sri Lanka time).</li>)}</ul>
        <button type="button" onClick={() => router.push("/orders")} className="mt-4 text-sm font-semibold text-green-900 underline">View order history</button>
      </section>}
    </div>
  </main>;
}
