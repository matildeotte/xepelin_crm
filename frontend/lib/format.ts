export function formatClp(value: number | null | undefined): string {
  return new Intl.NumberFormat("es-CL", {
    style: "currency",
    currency: "CLP",
    maximumFractionDigits: 0
  }).format(value ?? 0);
}

export function formatPercent(value: number | null | undefined): string {
  return `${(value ?? 0).toFixed(1)}%`;
}

export function formatDate(value: string | null | undefined): string {
  if (!value) return "Pendiente";

  return new Intl.DateTimeFormat("es-CL", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  }).format(new Date(value));
}

export function formatDateDash(value: string | null | undefined): string {
  return formatDate(value).replace(/\//g, "-");
}
