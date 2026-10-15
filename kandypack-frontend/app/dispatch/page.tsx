"use client";

import { useEffect, useState, useRef } from "react";
import { useRouter } from "next/navigation";
import { readJson, errorText } from "../lib/api-response";
import { Notice, LoadingState } from "../components/Feedback";

const API = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8081";

type Row = Record<string, string | number | null>;

type Options = {
  trucks: Row[];
  routes: Row[];
  drivers: Row[];
  assistants: Row[];
  orders: Row[];
};

const blank: Options = {
  trucks: [],
  routes: [],
  drivers: [],
  assistants: [],
  orders: [],
};

export default function Dispatch() {
  const router = useRouter();

  const [options, setOptions] = useState<Options>(blank);
  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [attempt, setAttempt] = useState(0);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);

  const flight = useRef(false);

  const [route, setRoute] = useState("");
  const [truck, setTruck] = useState("");
  const [driver, setDriver] = useState("");
  const [assistant, setAssistant] = useState("");
  const [start, setStart] = useState("");
  const [end, setEnd] = useState("");
  const [selected, setSelected] = useState<string[]>([]);

  useEffect(() => {
    if (
      !["ADMIN", "DISPATCHER"].includes(
        localStorage.getItem("role") || ""
      )
    ) {
      router.replace("/login");
      return;
    }

    const controller = new AbortController();
    let live = true;

    const init = {
      headers: {
        Authorization: `Bearer ${localStorage.getItem("token")}`,
      },
      signal: controller.signal,
    };

    Promise.all([
      fetch(`${API}/api/dispatches/options`, init).then(
        readJson<Options>
      ),
      fetch(`${API}/api/dispatches`, init).then(readJson<Row[]>),
    ])
      .then(([o, d]) => {
        if (live) {
          setOptions(o);
          setRows(d);
        }
      })
      .catch((e) => {
        if (live) setError(errorText(e));
      })
      .finally(() => {
        if (live) setLoading(false);
      });

    return () => {
      live = false;
      controller.abort();
    };
  }, [router, attempt]);

  const routeRow = options.routes.find(
    (r) => r.route_id === route
  );

  const orders = options.orders.filter(
    (o) => o.route_id === route
  );

  const trucks = options.trucks.filter(
    (t) => t.store_id === routeRow?.store_id
  );

  const space = orders
    .filter((o) => selected.includes(String(o.order_id)))
    .reduce((n, o) => n + Number(o.required_space), 0);

  async function save(e: React.FormEvent) {
    e.preventDefault();

    if (flight.current) return;

    if (selected.length === 0) {
      setError("Select at least one order.");
      return;
    }

    flight.current = true;
    setBusy(true);
    setError("");
    setMessage("");

    try {
      const r = await fetch(`${API}/api/dispatches`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${localStorage.getItem("token")}`,
        },
        body: JSON.stringify({
          truckId: truck,
          routeId: route,
          driverId: driver,
          assistantId: assistant,
          startTime: start,
          endTime: end,
          orderIds: selected,
        }),
      }).then(readJson<{ dispatchId: string }>);

      setMessage(
        `Dispatch ${r.dispatchId} created. Mark orders dispatched in the dashboard when the truck leaves.`
      );

      setSelected([]);
      setLoading(true);
      setAttempt((n) => n + 1);
    } catch (e) {
      setError(
        errorText(e) +
          " If the connection was interrupted, refresh the list before retrying."
      );
    } finally {
      setBusy(false);
      flight.current = false;
    }
  }

  const inputClass =
    "block w-full border border-slate-300 rounded-lg p-2 mt-1";

  return (
    <div className="workspace-shell">
      <section className="workspace-panel">
        <h1 className="text-2xl font-bold">Delivery planning</h1>

        <p className="my-3 text-sm text-slate-600">
          Assign whole orders after their final train arrival. Times
          are Sri Lanka local time. A one-hour break ends consecutive
          work; drivers need it after each route and assistants after
          two. Weekly limits are 40 and 60 hours.
        </p>

        {error && (
          <Notice kind="error">
            {error}
            <button
              className="secondary-button ml-3"
              disabled={busy}
              onClick={() => {
                setError("");
                setLoading(true);
                setAttempt((n) => n + 1);
              }}
            >
              Refresh
            </button>
          </Notice>
        )}

        {message && <Notice kind="success">{message}</Notice>}

        {loading && (
          <LoadingState>Loading delivery resources…</LoadingState>
        )}

        {!loading && (
          <form onSubmit={save}>
            <fieldset
              disabled={busy}
              className="grid gap-4 md:grid-cols-2 my-5"
            >
              <label>
                Delivery route
                <select
                  required
                  className={inputClass}
                  value={route}
                  onChange={(e) => {
                    setRoute(e.target.value);
                    setTruck("");
                    setSelected([]);
                  }}
                >
                  <option value="">Select route</option>
                  {options.routes.map((r) => (
                    <option
                      key={String(r.route_id)}
                      value={String(r.route_id)}
                    >
                      {r.route_id} — {r.coverage_area}
                    </option>
                  ))}
                </select>
              </label>

              <label>
                Truck
                <select
                  required
                  className={inputClass}
                  value={truck}
                  onChange={(e) => setTruck(e.target.value)}
                >
                  <option value="">
                    Select truck from route store
                  </option>
                  {trucks.map((t) => (
                    <option
                      key={String(t.truck_id)}
                      value={String(t.truck_id)}
                    >
                      {t.plate_number} — capacity {t.capacity}
                    </option>
                  ))}
                </select>
              </label>

              <label>
                Driver
                <select
                  required
                  className={inputClass}
                  value={driver}
                  onChange={(e) => setDriver(e.target.value)}
                >
                  <option value="">Select driver</option>
                  {options.drivers.map((d) => (
                    <option
                      key={String(d.driver_id)}
                      value={String(d.driver_id)}
                    >
                      {d.driver_name}
                    </option>
                  ))}
                </select>
              </label>

              <label>
                Assistant
                <select
                  required
                  className={inputClass}
                  value={assistant}
                  onChange={(e) => setAssistant(e.target.value)}
                >
                  <option value="">Select assistant</option>
                  {options.assistants.map((a) => (
                    <option
                      key={String(a.assistant_id)}
                      value={String(a.assistant_id)}
                    >
                      {a.assistant_name}
                    </option>
                  ))}
                </select>
              </label>

              <label>
                Departure
                <input
                  required
                  className={inputClass}
                  type="datetime-local"
                  value={start}
                  onChange={(e) => setStart(e.target.value)}
                />
              </label>

              <label>
                Expected finish
                <input
                  required
                  className={inputClass}
                  type="datetime-local"
                  value={end}
                  min={start}
                  onChange={(e) => setEnd(e.target.value)}
                />
              </label>

              <div className="md:col-span-2">
                <p className="font-semibold">
                  Orders on this route · selected space:{" "}
                  {space.toFixed(2)}
                </p>

                <p className="text-sm text-slate-500">
                  Maximum route duration:{" "}
                  {routeRow?.max_delivery_time ?? "—"} hours. Each
                  order is assigned once.
                </p>

                {orders.length === 0 && (
                  <p className="my-3">
                    No unassigned scheduled orders for this route.
                  </p>
                )}

                {orders.map((o) => (
                  <label
                    className="flex gap-3 items-start border-b py-3"
                    key={String(o.order_id)}
                  >
                    <input
                      type="checkbox"
                      checked={selected.includes(String(o.order_id))}
                      onChange={(e) =>
                        setSelected((s) =>
                          e.target.checked
                            ? [...s, String(o.order_id)]
                            : s.filter(
                                (id) => id !== String(o.order_id)
                              )
                        )
                      }
                    />

                    <span>
                      {o.order_id} · deliver by{" "}
                      {String(o.delivery_date).slice(0, 10)} · space{" "}
                      {o.required_space}
                      <br />
                      <small>
                        Last train arrives:{" "}
                        {String(o.ready_at).replace("T", " ")}
                      </small>
                    </span>
                  </label>
                ))}
              </div>

              <button
                className="primary-button"
                disabled={busy || selected.length === 0}
              >
                {busy ? "Saving…" : "Assign truck and crew"}
              </button>
            </fieldset>
          </form>
        )}

        <h2 className="font-bold text-lg mt-8 mb-3">
          Truck schedule
        </h2>

        <div className="overflow-x-auto">
          <table className="w-full text-sm text-left">
            <thead>
              <tr>
                {[
                  "Dispatch",
                  "Truck",
                  "Route",
                  "Crew",
                  "Start",
                  "Finish",
                  "Orders",
                ].map((h) => (
                  <th className="p-2 border-b" key={h}>
                    {h}
                  </th>
                ))}
              </tr>
            </thead>

            <tbody>
              {rows.map((r) => (
                <tr key={String(r.dispatch_id)}>
                  {[
                    r.dispatch_id,
                    r.plate_number,
                    r.route_id,
                    `${r.driver_name} / ${r.assistant_name}`,
                    r.start_time,
                    r.end_time,
                    r.orders ?? "Historical: order link not recorded",
                  ].map((v, i) => (
                    <td className="p-2 border-b" key={i}>
                      {String(v).replace("T", " ")}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}