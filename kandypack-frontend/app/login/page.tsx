"use client";

import { useState } from "react";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  return (
    <div className="auth-shell">
      <div className="auth-panel">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-bold text-slate-800">
            Kandypack
          </h1>

          <p className="text-sm text-slate-500 mt-1">
            Sign in to your account
          </p>
        </div>
      </div>
    </div>
  );
}