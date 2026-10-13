// Reads existing API responses without changing endpoints or request bodies.
// Error pages should not appear as raw HTML in the UI.
export async function readJson<T>(response: Response): Promise<T> {
  const text = await response.text();
  let body;
  try { body = text ? JSON.parse(text) : {}; }
  catch {
    if (!response.ok && text && !text.trimStart().startsWith("<")) throw new Error(text);
    throw new Error(`The server returned an unreadable response (${response.status}).`);
  }
  if (!response.ok) {
    const details = body && typeof body.details === "object" && body.details
      ? Object.values(body.details).filter(value => typeof value === "string").join("; ") : "";
    const message = typeof body === "string" ? body : typeof body?.message === "string" ? body.message : details;
    throw new Error(message || `Request failed (${response.status}).`);
  }
  return body as T;
}

export function errorText(error: unknown): string {
  return error instanceof Error ? error.message : "Please try again.";
}
