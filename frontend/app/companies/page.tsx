"use client";

import Link from "next/link";
import { Anchor, Card, Group, Stack, Table, Text, Title } from "@mantine/core";
import { ErrorState, LoadingState } from "@/components/AsyncState";
import { StatusPill } from "@/components/StatusPill";
import { formatClp, formatPercent } from "@/lib/format";
import { useApiResource } from "@/lib/useApiResource";
import type { CompaniesResponse } from "@/lib/types";

export default function CompaniesPage() {
  const { data, error, loading } = useApiResource<CompaniesResponse>("/api/v1/companies");

  if (loading) return <LoadingState />;
  if (error || !data) return <ErrorState message={error ?? "No hay empresas disponibles."} />;

  return (
    <Stack gap="xl">
      <Group justify="space-between">
        <div>
          <Text size="sm" tt="uppercase" c="dimmed" fw={700}>
            Cartera
          </Text>
          <Title>Empresas asignadas</Title>
          <Text c="dimmed">Priorizadas por estado de operación y monto financiado del mes actual.</Text>
        </div>
      </Group>

      <Card withBorder radius="lg">
        <Table.ScrollContainer minWidth={980}>
          <Table>
            <Table.Thead>
              <Table.Tr>
                <Table.Th>Empresa</Table.Th>
                <Table.Th>Estado</Table.Th>
                <Table.Th>Financiado este mes</Table.Th>
                <Table.Th>Volumen SII</Table.Th>
                <Table.Th>SOW</Table.Th>
                <Table.Th>Riesgo</Table.Th>
                <Table.Th>Siguiente acción</Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              {data.companies.map((company) => (
                <Table.Tr key={company.id}>
                  <Table.Td>
                    <Anchor component={Link} href={`/companies/${company.id}`} className="table-link">
                      {company.legal_name}
                    </Anchor>
                    <Text size="xs" c="dimmed">
                      {company.tax_id} · {company.sector}
                    </Text>
                  </Table.Td>
                  <Table.Td>
                    <StatusPill label={company.activation_state.label} tone={company.activation_state.tone} />
                  </Table.Td>
                  <Table.Td>{formatClp(company.metrics.financed_amount)}</Table.Td>
                  <Table.Td>{formatClp(company.metrics.sii_volume)}</Table.Td>
                  <Table.Td>{formatPercent(company.metrics.share_of_wallet)}</Table.Td>
                  <Table.Td>
                    {company.latest_risk_eligibility ? (
                      <StatusPill
                        label={company.latest_risk_eligibility.status.label}
                        tone={company.latest_risk_eligibility.status.tone}
                      />
                    ) : (
                      <StatusPill label="Sin resultado" />
                    )}
                  </Table.Td>
                  <Table.Td>{company.next_best_action.label}</Table.Td>
                </Table.Tr>
              ))}
            </Table.Tbody>
          </Table>
        </Table.ScrollContainer>
      </Card>
    </Stack>
  );
}
