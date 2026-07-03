import { Badge } from "@mantine/core";
import type { Tone } from "@/lib/types";

const toneColors: Record<Tone, string> = {
  success: "green",
  warning: "yellow",
  danger: "red",
  info: "blue",
  neutral: "gray"
};

export function StatusPill({ label, tone = "neutral" }: { label: string; tone?: Tone }) {
  return (
    <Badge color={toneColors[tone]} variant="light">
      {label}
    </Badge>
  );
}
