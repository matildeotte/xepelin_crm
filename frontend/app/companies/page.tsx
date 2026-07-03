"use client";

import Link from "next/link";
import { Anchor, Card, Group, Stack, Table, Text, Title } from "@mantine/core";
import { ErrorState, LoadingState } from "@/components/AsyncState";
import { StatusPill } from "@/components/StatusPill";
import { formatClp, formatPercent } from "@/lib/format";
import { useApiResource } from "@/lib/useApiResource";
import type { CompaniesResponse, CompanySummary } from "@/lib/types";

function HealthScoreCell({ company }: { company: CompanySummary }) {
  if (!company.latest_health_score) {
    return <StatusPill label="Pendiente AI" tone="neutral" />;
  }

  return (
    <Group gap="xs">
      <Text fw={700}>{company.latest_health_score.score}</Text>
      <StatusPill
        label={company.latest_health_score.churn_risk.label}
        tone={company.latest_health_score.churn_risk.tone}
      />
    </Group>
  );
}

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
          <Text c="dimmed">Priorizadas por salud, Share of Wallet, oportunidad SII y capacidad real de operar.</Text>
        </div>
      </Group>

      <Card withBorder radius="lg">
        <Table.ScrollContainer minWidth={1040}>
          <Table>
            <Table.Thead>
              <Table.Tr>
                <Table.Th>Empresa</Table.Th>
                <Table.Th>Health Score AI</Table.Th>
                <Table.Th>SOW</Table.Th>
                <Table.Th>Oportunidad SII elegible</Table.Th>
                <Table.Th>Estado de riesgo</Table.Th>
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
                    <HealthScoreCell company={company} />
                  </Table.Td>
                  <Table.Td>{formatPercent(company.metrics.share_of_wallet)}</Table.Td>
                  <Table.Td>{formatClp(company.metrics.eligible_expansion_opportunity)}</Table.Td>
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
