import type { ReactNode } from "react";

export type NoticeKind = "info" | "success" | "error";
export type NoticeMessage = { kind: NoticeKind; text: string };

export function BusyLabel({ children }: { children: ReactNode }) {
  return <span className="busy-label"><span className="busy-spinner" aria-hidden="true" />{children}</span>;
}

export function LoadingState({ children }: { children: ReactNode }) {
  return <div className="loading-state" role="status"><BusyLabel>{children}</BusyLabel></div>;
}

export function Notice({ kind, children }: { kind: NoticeKind; children: ReactNode }) {
  const label = kind === "error" ? "Please check" : kind === "success" ? "Success" : "Update";
  return <div className={`feedback feedback-${kind}`} role={kind === "error" ? "alert" : "status"} aria-atomic="true">
    <span className="feedback-icon" aria-hidden="true">{kind === "error" ? "!" : kind === "success" ? "✓" : "i"}</span>
    <div><strong className="feedback-label">{label}</strong><div>{children}</div></div>
  </div>;
}
