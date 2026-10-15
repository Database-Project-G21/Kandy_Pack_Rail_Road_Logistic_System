"use client";

import { useEffect, useRef } from "react";
import { BusyLabel } from "./Feedback";

export default function CancelOrderDialog({ orderId, busy, onKeep, onConfirm }: {
  orderId: string | null;
  busy: boolean;
  onKeep: () => void;
  onConfirm: () => void;
}) {
  const dialog = useRef<HTMLDialogElement>(null);
  const keepButton = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    const element = dialog.current;
    if (!element) return;
    if (!orderId) {
      element.close();
      return;
    }
    element.showModal();
    keepButton.current?.focus();
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      element.close();
      document.body.style.overflow = previousOverflow;
    };
  }, [orderId]);

  return <dialog ref={dialog} className="cancel-dialog" aria-labelledby="cancel-title" aria-describedby="cancel-description"
    onCancel={event => { event.preventDefault(); if (!busy) onKeep(); }}>
    <span className="eyebrow">ORDER UPDATE</span>
    <h2 id="cancel-title">Cancel this order?</h2>
    <p id="cancel-description">You are about to cancel <strong>{orderId}</strong>. A cancelled order cannot be reopened from this page.</p>
    {busy && <p className="dialog-progress" role="status">Sending your cancellation. Please wait...</p>}
    <div className="dialog-actions">
      <button ref={keepButton} type="button" className="secondary-button" disabled={busy} onClick={onKeep}>Keep order</button>
      <button type="button" className="danger-button" disabled={busy} onClick={onConfirm}>{busy ? <BusyLabel>Cancelling...</BusyLabel> : "Yes, cancel order"}</button>
    </div>
  </dialog>;
}
