"use client";

import { useEffect, useState, useRef } from "react";
import { useRouter } from "next/navigation";
import { readJson, errorText } from "../lib/api-response";
import { Notice } from "../components/Feedback";

const API =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:8081";

type Options = {
  trains: {
    train_id: string;
    size: number;
  }[];
  stores: {
    store_id: string;
    city_name: string;
  }[];
};

export default function Trips() {
  const router = useRouter();

  const [options, setOptions] = useState<Options>({
    trains: [],
    stores: [],
  });

  const [error, setError] = useState("");
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);

  const lock = useRef(false);
  const [attempt, setAttempt] = useState(0);

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

    fetch(`${API}/api/trains/options`, {
      headers: {
        Authorization: `Bearer ${localStorage.getItem("token")}`,
      },
      signal: controller.signal,
    })
      .then(readJson<Options>)
      .then(setOptions)
      .catch((e) => {
        if (!controller.signal.aborted) {
          setError(errorText(e));
        }
      });

    return () => controller.abort();
  }, [router, attempt]);

  async function save(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();

    if (lock.current) return;

    lock.current = true;
    setBusy(true);
    setError("");
    setMessage("");

    const form = e.currentTarget;
    const formData = new FormData(form);

    try {
      const result = await fetch(`${API}/api/trains`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${localStorage.getItem("token")}`,
        },
        body: JSON.stringify({
          trainId: formData.get("train"),
          storeId: formData.get("store"),
          departure: formData.get("departure"),
          arrival: formData.get("arrival"),
          capacity: Number(formData.get("capacity")),
        }),
      }).then(readJson<{ tripId: string }>);

      setMessage(
        `Trip ${result.tripId} created. Customers can now reserve its capacity when ordering.`
      );

      form.reset();
    } catch (e) {
      setError(errorText(e));
    } finally {
      lock.current = false;
      setBusy(false);
    }
  }

  const inputClass = "block w-full border rounded p-2 mt-1";

  return (
    <div className="workspace-shell">
      <section className="workspace-panel">
        <h1 className="text-2xl font-bold">
          Add a future train trip
        </h1>

        <p className="my-3">
          Use the actual railway cargo allocation. All times are
          Sri Lanka local time. Existing orders and old trips stay
          unchanged.
        </p>

        {error && (
          <Notice kind="error">
            {error}
            <button
              type="button"
              className="secondary-button ml-3"
              disabled={busy}
              onClick={() => {
                setError("");
                setAttempt((n) => n + 1);
              }}
            >
              Reload options
            </button>
          </Notice>
        )}

        {message && (
          <Notice kind="success">{message}</Notice>
        )}

        <form onSubmit={save}>
          <fieldset
            disabled={busy}
            className="grid md:grid-cols-2 gap-4 my-5"
          >
            <label>
              Train
              <select
                name="train"
                className={inputClass}
                required
              >
                <option value="">Select train</option>

                {options.trains.map((train) => (
                  <option
                    key={train.train_id}
                    value={train.train_id}
                  >
                    {train.train_id} — size {train.size}
                  </option>
                ))}
              </select>
            </label>

            <label>
              Destination store
              <select
                name="store"
                className={inputClass}
                required
              >
                <option value="">Select store</option>

                {options.stores.map((store) => (
                  <option
                    key={store.store_id}
                    value={store.store_id}
                  >
                    {store.city_name} — {store.store_id}
                  </option>
                ))}
              </select>
            </label>

            <label>
              Departure
              <input
                name="departure"
                className={inputClass}
                required
                type="datetime-local"
              />
            </label>

            <label>
              Arrival
              <input
                name="arrival"
                className={inputClass}
                required
                type="datetime-local"
              />
            </label>

            <label>
              Allocated cargo capacity
              <input
                name="capacity"
                className={inputClass}
                required
                type="number"
                min="0.01"
                step="0.01"
              />
            </label>

            <button
              type="submit"
              className="primary-button self-end"
              disabled={
                busy ||
                options.trains.length === 0 ||
                options.stores.length === 0
              }
            >
              {busy ? "Saving…" : "Create trip"}
            </button>
          </fieldset>
        </form>
      </section>
    </div>
  );
}