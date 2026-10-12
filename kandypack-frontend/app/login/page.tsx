"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [message, setMessage] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    if (isLoading) return;

    setIsLoading(true);
    setMessage("Logging in...");

    try {
      const response = await fetch("http://localhost:8081/api/auth/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ email, password }),
      });

      const data = await response.json().catch(() => ({}));

      if (!response.ok) {
        setMessage(
          "Login failed: " +
            (data.message || data.error || "Invalid email or password.")
        );
        return;
      }

      if (!data.token || !data.role) {
        setMessage("Login failed: Invalid response from the server.");
        return;
      }

      localStorage.setItem("token", data.token);
      localStorage.setItem(
        "customerId",
        String(data.customerId ?? data.staffId ?? "")
      );
      localStorage.setItem("role", data.role);

      setMessage("Login successful! Redirecting...");

      if (data.role === "CUSTOMER") {
        router.push("/");
      } else {
        router.push("/dashboard");
      }
    } catch (err: unknown) {
      setMessage(
        "Request failed: " +
          (err instanceof Error ? err.message : "Please try again.")
      );
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="auth-shell">
      <div className="auth-panel">
        <div className="mb-6 text-center">
          <div className="auth-brand">
            <span className="text-2xl font-bold tracking-tight text-[#a91d40]">
              KandyPack
            </span>
          </div>

          <h1 className="auth-title">Welcome back</h1>

          <p className="mt-1 text-sm text-slate-500">
            Sign in to your account
          </p>
        </div>

        <form onSubmit={handleSubmit} className="flex flex-col gap-5">
          <div>
            <label
              htmlFor="email"
              className="mb-1.5 block text-sm font-medium text-slate-700"
            >
              Email
            </label>

            <input
              id="email"
              name="email"
              type="email"
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm transition focus:border-transparent focus:outline-none focus:ring-2 focus:ring-[#a91d40]"
            />
          </div>

          <div>
            <label
              htmlFor="password"
              className="mb-1.5 block text-sm font-medium text-slate-700"
            >
              Password
            </label>

            <input
              id="password"
              name="password"
              type="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm transition focus:border-transparent focus:outline-none focus:ring-2 focus:ring-[#a91d40]"
            />
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="mt-2 rounded-lg bg-[#a91d40] px-4 py-2.5 font-medium text-white transition hover:bg-[#891735] disabled:cursor-not-allowed disabled:opacity-60"
          >
            {isLoading ? "Logging in..." : "Log In"}
          </button>
        </form>

        {message && (
          <div
            role="status"
            aria-live="polite"
            className={`mt-5 rounded-lg px-4 py-2.5 text-center text-sm ${
              message.toLowerCase().includes("failed") ||
              message.toLowerCase().includes("error") ||
              message.toLowerCase().includes("request failed")
                ? "bg-red-50 text-red-700"
                : message.toLowerCase().includes("success")
                  ? "bg-green-50 text-green-700"
                  : "bg-slate-50 text-slate-600"
            }`}
          >
            {message}
          </div>
        )}

        <p className="mt-5 text-center text-sm text-slate-500">
          Don&apos;t have an account?{" "}
          <a
            href="/signup"
            className="font-medium text-[#a91d40] hover:underline"
          >
            Sign up
          </a>
        </p>
      </div>
    </div>
  );
}