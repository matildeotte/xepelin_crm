"use client";

import Link from "next/link";
import { Anchor, Button, Card, Group, SimpleGrid, Stack, Table, Text, Title } from "@mantine/core";
import { ErrorState, LoadingState } from "@/components/AsyncState";
import { MetricCard } from "@/components/MetricCard";
import { StatusPill } from "@/components/StatusPill";
import { logout } from "@/lib/api";
import { formatClp, formatDate, formatPercent } from "@/lib/format";
import { useApiResource } from "@/lib/useApiResource";
import type { CompanySummary, DashboardResponse } from "@/lib/types";

function CompanyRow({ company }: { company: CompanySummary }) {
  return (
    <Table.Tr>
      <Table.Td>
        <Anchor component={Link} href={`/companies/${company.id}`} className="table-link">
          {company.legal_name}
        </Anchor>
        <Text size="xs" c="dimmed">
          {company.tax_id}
        </Text>
      </Table.Td>
      <Table.Td>
        <StatusPill label={company.activation_state.label} tone={company.activation_state.tone} />
      </Table.Td>
      <Table.Td>{formatClp(company.metrics.financed_amount)}</Table.Td>
      <Table.Td>{formatPercent(company.metrics.share_of_wallet)}</Table.Td>
      <Table.Td>{formatClp(company.metrics.expansion_opportunity)}</Table.Td>
    </Table.Tr>
  );
}

export default function DashboardPage() {
  const { data, error, loading } = useApiResource<DashboardResponse>("/api/v1/dashboard");

  if (loading) return <LoadingState />;
  if (error || !data) return <ErrorState message={error ?? "No hay datos disponibles."} />;

  return (
    <Stack gap="xl">
      <Group justify="space-between" align="flex-start">
        <div>
          <Text size="sm" tt="uppercase" c="dimmed" fw={700}>
            Panel KAM
          </Text>
          <Title>Tu cartera</Title>
          <Text c="dimmed">
            Priorización comercial basada en clientes operados, monto financiado y oportunidades visibles en SII.
          </Text>
        </div>
        <Group>
          <Button component={Link} href="/companies">
            Ver empresas
          </Button>
          <Button variant="subtle" color="gray" onClick={() => void logout()}>
            Cerrar sesión
          </Button>
        </Group>
      </Group>

      <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }}>
        <MetricCard
          label="Clientes operando"
          value={`${data.metrics.operating_companies_count}/${data.metrics.portfolio_count}`}
          description={`${formatPercent(data.metrics.operating_rate)} operó en los últimos 30 días`}
        />
        <MetricCard label="Monto financiado" value={formatClp(data.metrics.financed_amount)} description="Mes actual" />
        <MetricCard
          label="Participación de cartera"
          value={formatPercent(data.metrics.share_of_wallet)}
          description="Financiado por Xepelin / volumen visible en SII"
        />
        <MetricCard
          label="Oportunidad de expansión"
          value={formatClp(data.metrics.expansion_opportunity)}
          description="Monto visible en SII no financiado"
        />
      </SimpleGrid>

      <SimpleGrid cols={{ base: 1, lg: 2 }}>
        <Card withBorder radius="lg">
          <Title order={3}>Oportunidades de crecimiento</Title>
          <Text c="dimmed" size="sm" mb="md">
            Clientes activos con facturas visibles en SII que aún no fueron financiadas por Xepelin.
          </Text>
          <Table.ScrollContainer minWidth={720}>
            <Table>
              <Table.Thead>
                <Table.Tr>
                  <Table.Th>Empresa</Table.Th>
                  <Table.Th>Estado</Table.Th>
                  <Table.Th>Financiado</Table.Th>
                  <Table.Th>SOW</Table.Th>
                  <Table.Th>Oportunidad</Table.Th>
                </Table.Tr>
              </Table.Thead>
              <Table.Tbody>
                {data.growth_opportunities.map((company) => (
                  <CompanyRow key={company.id} company={company} />
                ))}
              </Table.Tbody>
            </Table>
          </Table.ScrollContainer>
        </Card>

        <Card withBorder radius="lg">
          <Title order={3}>Bloqueos de cobranza</Title>
          <Text c="dimmed" size="sm" mb="md">
            Contexto informativo para entender si una empresa podría tener fricción para seguir operando.
          </Text>
          <SimpleGrid cols={2} mb="md">
            <MetricCard label="Facturas impagas" value={String(data.metrics.unpaid_invoices_count)} />
            <MetricCard label="Monto vencido" value={formatClp(data.metrics.overdue_amount)} />
          </SimpleGrid>
          <Table.ScrollContainer minWidth={640}>
            <Table>
              <Table.Thead>
                <Table.Tr>
                  <Table.Th>Empresa</Table.Th>
                  <Table.Th>Pagador</Table.Th>
                  <Table.Th>Vencimiento</Table.Th>
                  <Table.Th>Monto</Table.Th>
                </Table.Tr>
              </Table.Thead>
              <Table.Tbody>
                {data.unpaid_invoices.map((invoice) => (
                  <Table.Tr key={invoice.id}>
                    <Table.Td>
                      {invoice.company ? (
                        <Anchor component={Link} href={`/companies/${invoice.company.id}`} className="table-link">
                          {invoice.company.legal_name}
                        </Anchor>
                      ) : null}
                    </Table.Td>
                    <Table.Td>
                      {invoice.debtor ? (
                        <Anchor component={Link} href={`/debtors/${invoice.debtor.id}`} className="table-link">
                          {invoice.debtor.legal_name}
                        </Anchor>
                      ) : null}
                    </Table.Td>
                    <Table.Td>{formatDate(invoice.due_date)}</Table.Td>
                    <Table.Td>{formatClp(invoice.amount)}</Table.Td>
                  </Table.Tr>
                ))}
              </Table.Tbody>
            </Table>
          </Table.ScrollContainer>
        </Card>
      </SimpleGrid>

      <SimpleGrid cols={{ base: 1, lg: 2 }}>
        <Card withBorder radius="lg">
          <Title order={3}>Top clientes por monto financiado</Title>
          <Table.ScrollContainer minWidth={720}>
            <Table>
              <Table.Thead>
                <Table.Tr>
                  <Table.Th>Empresa</Table.Th>
                  <Table.Th>Financiado</Table.Th>
                  <Table.Th>SOW</Table.Th>
                  <Table.Th>Siguiente acción</Table.Th>
                </Table.Tr>
              </Table.Thead>
              <Table.Tbody>
                {data.top_financed_companies.map((company) => (
                  <Table.Tr key={company.id}>
                    <Table.Td>
                      <Anchor component={Link} href={`/companies/${company.id}`} className="table-link">
                        {company.legal_name}
                      </Anchor>
                    </Table.Td>
                    <Table.Td>{formatClp(company.metrics.financed_amount)}</Table.Td>
                    <Table.Td>{formatPercent(company.metrics.share_of_wallet)}</Table.Td>
                    <Table.Td>{company.next_best_action.label}</Table.Td>
                  </Table.Tr>
                ))}
              </Table.Tbody>
            </Table>
          </Table.ScrollContainer>
        </Card>

        <Card withBorder radius="lg">
          <Title order={3}>Resultados del equipo de riesgos</Title>
          <Text c="dimmed" size="sm" mb="md">
            Señales externas que Comercial consume antes de ofrecer nuevas operaciones.
          </Text>
          <Table.ScrollContainer minWidth={760}>
            <Table>
              <Table.Thead>
                <Table.Tr>
                  <Table.Th>Empresa</Table.Th>
                  <Table.Th>Pagador</Table.Th>
                  <Table.Th>Estado</Table.Th>
                  <Table.Th>Tipo</Table.Th>
                  <Table.Th>Evaluado</Table.Th>
                </Table.Tr>
              </Table.Thead>
              <Table.Tbody>
                {data.risk_constraints.map((risk) => (
                  <Table.Tr key={risk.id}>
                    <Table.Td>{risk.company?.legal_name}</Table.Td>
                    <Table.Td>{risk.debtor?.legal_name ?? "Nivel empresa"}</Table.Td>
                    <Table.Td>
                      <StatusPill label={risk.status.label} tone={risk.status.tone} />
                    </Table.Td>
                    <Table.Td>{risk.risk_type.label}</Table.Td>
                    <Table.Td>{formatDate(risk.evaluated_at)}</Table.Td>
                  </Table.Tr>
                ))}
              </Table.Tbody>
            </Table>
          </Table.ScrollContainer>
        </Card>
      </SimpleGrid>
    </Stack>
  );
}
