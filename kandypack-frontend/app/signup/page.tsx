"use client";

import { useState, useEffect } from "react";

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

  return (
    <div className="auth-shell">
      <div className="auth-panel">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-bold text-slate-800">
            Create Account
          </h1>

          <p className="text-sm text-slate-500 mt-1">
            Sign up to start placing orders
          </p>
        </div>
      </div>
    </div>
  );
}