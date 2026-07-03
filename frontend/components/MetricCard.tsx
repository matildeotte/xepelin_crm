import { Card, Text, Title } from "@mantine/core";

export function MetricCard({
  label,
  value,
  description
}: {
  label: string;
  value: string;
  description?: string;
}) {
  return (
    <Card withBorder radius="lg" p="lg">
      <Text size="xs" tt="uppercase" c="dimmed" fw={700}>
        {label}
      </Text>
      <Title order={2} mt={6}>
        {value}
      </Title>
      {description ? (
        <Text size="sm" c="dimmed" mt={4}>
          {description}
        </Text>
      ) : null}
    </Card>
  );
}
