const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL ?? "";
export const authBaseUrl = process.env.NEXT_PUBLIC_AUTH_BASE_URL ?? "http://localhost:3000";

type RequestOptions = {
  method?: "GET" | "POST" | "DELETE";
  body?: unknown;
};

export async function apiRequest<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const response = await fetch(`${apiBaseUrl}${path}`, {
    method: options.method ?? "GET",
    credentials: "include",
    headers: {
      Accept: "application/json",
      ...(options.body ? { "Content-Type": "application/json" } : {})
    },
    body: options.body ? JSON.stringify(options.body) : undefined
  });

  if (response.status === 401 && typeof window !== "undefined") {
    window.location.href = "/login";
  }

  if (!response.ok) {
    const payload = await response.json().catch(() => ({}));
    throw new Error(payload.error ?? payload.errors?.join(", ") ?? `API error ${response.status}`);
  }

  return response.json();
}

export function apiGet<T>(path: string): Promise<T> {
  return apiRequest<T>(path);
}

export function apiPost<T>(path: string, body: unknown): Promise<T> {
  return apiRequest<T>(path, { method: "POST", body });
}

export async function logout(): Promise<void> {
  await fetch(`${apiBaseUrl}/logout`, {
    method: "DELETE",
    credentials: "include"
  });

  window.location.href = "/login";
}
