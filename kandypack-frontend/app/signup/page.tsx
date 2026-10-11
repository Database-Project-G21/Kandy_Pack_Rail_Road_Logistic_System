
"use client";


import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";

interface City {
  cityId: string;
  cityName: string;
}

export default function Signup() {
  const [customerName, setCustomerName] = useState("");
  const [deliveryAddress, setDeliveryAddress] = useState("");
  const [phoneNumber, setPhoneNumber] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [cityId, setCityId] = useState("");
  const [cities, setCities] = useState<City[]>([]);
  const [message, setMessage] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const router = useRouter();

  useEffect(() => {
    setCities([
      { cityId: "CMB", cityName: "Colombo" },
      { cityId: "NEG", cityName: "Negombo" },
      { cityId: "GAL", cityName: "Galle" },
      { cityId: "MAT", cityName: "Matara" },
      { cityId: "JAF", cityName: "Jaffna" },
      { cityId: "TRN", cityName: "Trincomalee" },
    ]);
  }, []);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    if (isLoading) return;

    setIsLoading(true);
    setMessage("Creating account...");

    try {
      const response = await fetch("http://localhost:8081/api/auth/signup", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          customerName,
          deliveryAddress,
          phoneNumber,
          email: email.trim(),
          password,
          cityId,
        }),
      });

      const responseText = await response.text();
      let data: {
        token?: string;
        customerId?: string;
        role?: string;
        message?: string;
      } | string;

      try {
        data = JSON.parse(responseText);
      } catch {
        data = responseText;
      }

      if (!response.ok) {
        const errorMessage =
          typeof data === "string"
            ? data
            : data.message || JSON.stringify(data);

        setMessage("Signup failed: " + errorMessage);
        return;
      }

      if (
        typeof data === "string" ||
        !data.token ||
        !data.customerId ||
        !data.role
      ) {
        setMessage("Signup failed: The server returned an invalid response.");
        return;
      }

      localStorage.setItem("token", data.token);
      localStorage.setItem("customerId", data.customerId);
      localStorage.setItem("role", data.role);

      setMessage("Account created! Redirecting...");
      router.push("/");
    } catch (err: unknown) {
      setMessage(
        "Request failed: " +
          (err instanceof Error ? err.message : "Please try again.")
      );
    } finally {
      setIsLoading(false);
    }
  };

  const hasError =
    message.toLowerCase().includes("failed") ||
    message.toLowerCase().includes("error");

  const hasSuccess = message.toLowerCase().includes("created");

  return (
    <div className="auth-shell">
      <div className="auth-panel">
        <div className="mb-6 text-center">
          <h1 className="auth-title">Create your account</h1>
          <p className="text-sm text-slate-500 mt-1">
            Sign up to start placing orders
          </p>
        </div>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <div>
            <label
              htmlFor="customerName"
              className="block text-sm font-medium text-slate-700 mb-1.5"
            >
              Full Name
            </label>
            <input
              id="customerName"
              type="text"
              autoComplete="name"
              value={customerName}
              onChange={(e) => setCustomerName(e.target.value)}
              required
              disabled={isLoading}
              className="w-full border border-slate-300 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-[#a91d40] focus:border-transparent transition disabled:opacity-60"
            />
          </div>

          <div>
            <label
              htmlFor="deliveryAddress"
              className="block text-sm font-medium text-slate-700 mb-1.5"
            >
              Delivery Address
            </label>
            <input
              id="deliveryAddress"
              type="text"
              autoComplete="street-address"
              value={deliveryAddress}
              onChange={(e) => setDeliveryAddress(e.target.value)}
              required
              disabled={isLoading}
              className="w-full border border-slate-300 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-[#a91d40] focus:border-transparent transition disabled:opacity-60"
            />
          </div>

          <div>
            <label
              htmlFor="cityId"
              className="block text-sm font-medium text-slate-700 mb-1.5"
            >
              City
            </label>
            <select
              id="cityId"
              value={cityId}
              onChange={(e) => setCityId(e.target.value)}
              required
              disabled={isLoading}
              className="w-full border border-slate-300 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-[#a91d40] focus:border-transparent transition disabled:opacity-60"
            >
              <option value="">Select a city</option>
              {cities.map((city) => (
                <option key={city.cityId} value={city.cityId}>
                  {city.cityName}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label
              htmlFor="phoneNumber"
              className="block text-sm font-medium text-slate-700 mb-1.5"
            >
              Phone Number
            </label>
            <input
              id="phoneNumber"
              type="tel"
              autoComplete="tel"
              value={phoneNumber}
              onChange={(e) => setPhoneNumber(e.target.value)}
              required
              disabled={isLoading}
              className="w-full border border-slate-300 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-[#a91d40] focus:border-transparent transition disabled:opacity-60"
            />
          </div>

          <div>
            <label
              htmlFor="email"
              className="block text-sm font-medium text-slate-700 mb-1.5"
            >
              Email
            </label>
            <input
              id="email"
              type="email"
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              disabled={isLoading}
              className="w-full border border-slate-300 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-[#a91d40] focus:border-transparent transition disabled:opacity-60"
            />
          </div>

          <div>
            <label
              htmlFor="password"
              className="block text-sm font-medium text-slate-700 mb-1.5"
            >
              Password
            </label>
            <input
              id="password"
              type="password"
              autoComplete="new-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              disabled={isLoading}
              className="w-full border border-slate-300 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-[#a91d40] focus:border-transparent transition disabled:opacity-60"
            />
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="bg-[#a91d40] text-white font-medium rounded-lg px-4 py-2.5 mt-2 hover:bg-[#891735] transition disabled:cursor-not-allowed disabled:opacity-60"
          >
            {isLoading ? "Creating account..." : "Sign Up"}
          </button>
        </form>

        {message && (
          <div
            role="status"
            aria-live="polite"
            className={`mt-5 text-sm text-center px-4 py-2.5 rounded-lg ${
              hasError
                ? "bg-red-50 text-red-700"
                : hasSuccess
                  ? "bg-green-50 text-green-700"
                  : "bg-slate-50 text-slate-600"
            }`}
          >
            {message}
          </div>
        )}
      </div>
    </div>
  );
}
