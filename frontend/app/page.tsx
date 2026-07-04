"use client";

import { Fragment, useState } from "react";
import Link from "next/link";
import { Anchor, Button, Card, Group, SimpleGrid, Stack, Table, Text, Title } from "@mantine/core";
import { ErrorState, LoadingState } from "@/components/AsyncState";
import { MetricCard } from "@/components/MetricCard";
import { formatClp, formatDateDash, formatPercent } from "@/lib/format";
import { useApiResource } from "@/lib/useApiResource";
import type { DashboardResponse, Invoice } from "@/lib/types";
import { AppNavigation } from "@/components/AppNavigation";

type CollectionBlockerGroup = {
  company: NonNullable<Invoice["company"]>;
  invoices: Invoice[];
  amount: number;
};

function collectionBlockerGroups(invoices: Invoice[]): CollectionBlockerGroup[] {
  const groups = new Map<number, CollectionBlockerGroup>();

  invoices.forEach((invoice) => {
    if (!invoice.company) return;

    const current = groups.get(invoice.company.id) ?? {
      company: invoice.company,
      invoices: [],
      amount: 0
    };

    current.invoices.push(invoice);
    current.amount += invoice.amount;
    groups.set(invoice.company.id, current);
  });

  return Array.from(groups.values()).sort((a, b) => b.amount - a.amount);
}

export default function DashboardPage() {
  const { data, error, loading } = useApiResource<DashboardResponse>("/api/v1/dashboard");
  const [expandedCompanyIds, setExpandedCompanyIds] = useState<Set<number>>(new Set());

  if (loading) return <LoadingState />;
  if (error || !data) return <ErrorState message={error ?? "No hay datos disponibles."} />;

  const collectionGroups = collectionBlockerGroups(data.unpaid_invoices);

  function toggleCompany(companyId: number) {
    setExpandedCompanyIds((currentIds) => {
      const nextIds = new Set(currentIds);

      if (nextIds.has(companyId)) {
        nextIds.delete(companyId);
      } else {
        nextIds.add(companyId);
      }

      return nextIds;
    });
  }

  return (
    <AppNavigation>
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
      </Group>

      <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }}>
        <MetricCard
          label="SOW promedio cartera"
          value={formatPercent(data.metrics.share_of_wallet)}
          description="Financiado por Xepelin / volumen visible en SII"
        />
        <MetricCard
          label="Pipeline de expansión"
          value={formatClp(data.metrics.eligible_expansion_pipeline)}
          description="Facturas SII vigentes con pagador elegible por Riesgo"
        />
        <MetricCard
          label="Clientes operando"
          value={`${data.metrics.operating_companies_count}/${data.metrics.portfolio_count}`}
          description={`${formatPercent(data.metrics.operating_rate)} operó en los últimos 30 días`}
        />
        <MetricCard
          label="Monto financiado vs. meta"
          value={formatClp(data.metrics.financed_amount)}
          description={`${formatPercent(data.metrics.monthly_goal_progress)} de ${formatClp(data.metrics.monthly_goal_amount)}`}
        />
      </SimpleGrid>

      <SimpleGrid cols={{ base: 1, lg: 2 }}>
        <Card withBorder radius="lg">
          <Title order={3}>Nuevas líneas desbloqueadas por Riesgo</Title>
          <Text c="dimmed" size="sm" mb="md">
            Combinaciones empresa-pagador con luz verde y monto visible en SII para ofrecer hoy.
          </Text>
          <Table.ScrollContainer minWidth={900}>
            <Table>
              <Table.Thead>
                <Table.Tr>
                  <Table.Th>Empresa</Table.Th>
                  <Table.Th>Pagador aprobado</Table.Th>
                  <Table.Th>Monto disponible SII</Table.Th>
                  <Table.Th>Facturas</Table.Th>
                  <Table.Th>Acción</Table.Th>
                </Table.Tr>
              </Table.Thead>
              <Table.Tbody>
                {data.risk_unlocked_opportunities.map((opportunity) => (
                  <Table.Tr key={opportunity.id}>
                    <Table.Td>
                      <Anchor component={Link} href={`/companies/${opportunity.company.id}`} className="table-link">
                        {opportunity.company.legal_name}
                      </Anchor>
                    </Table.Td>
                    <Table.Td>
                      <Anchor component={Link} href={`/debtors/${opportunity.debtor.id}`} className="table-link">
                        {opportunity.debtor.legal_name}
                      </Anchor>
                    </Table.Td>
                    <Table.Td>{formatClp(opportunity.available_amount)}</Table.Td>
                    <Table.Td>{opportunity.invoice_count}</Table.Td>
                    <Table.Td>
                      <Group gap="xs">
                        <Button size="xs">{opportunity.action}</Button>
                        <Button size="xs" variant="light">
                          {opportunity.secondary_action}
                        </Button>
                      </Group>
                    </Table.Td>
                  </Table.Tr>
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
            <MetricCard label="Monto en riesgo de bloqueo" value={formatClp(data.metrics.collection_blocker_amount)} />
          </SimpleGrid>
          <Table.ScrollContainer minWidth={680}>
            <Table>
              <Table.Thead>
                <Table.Tr>
                  <Table.Th>Empresa</Table.Th>
                  <Table.Th>Facturas impagas</Table.Th>
                  <Table.Th>Monto en riesgo de bloqueo</Table.Th>
                  <Table.Th>Detalle</Table.Th>
                </Table.Tr>
              </Table.Thead>
              <Table.Tbody>
                {collectionGroups.map((group) => (
                  <Fragment key={group.company.id}>
                    <Table.Tr>
                      <Table.Td>
                        <Anchor component={Link} href={`/companies/${group.company.id}`} className="table-link">
                          {group.company.legal_name}
                        </Anchor>
                      </Table.Td>
                      <Table.Td>{group.invoices.length}</Table.Td>
                      <Table.Td>{formatClp(group.amount)}</Table.Td>
                      <Table.Td>
                        <Button size="xs" variant="subtle" onClick={() => toggleCompany(group.company.id)}>
                          {expandedCompanyIds.has(group.company.id) ? "▾ Ocultar" : "▸ Ver facturas"}
                        </Button>
                      </Table.Td>
                    </Table.Tr>
                    {expandedCompanyIds.has(group.company.id) ? (
                      <Table.Tr>
                        <Table.Td colSpan={4}>
                          <Stack gap={4}>
                            {group.invoices.map((invoice) => (
                              <Text key={invoice.id} size="sm" c="dimmed">
                                Factura N°{invoice.invoice_number} - Monto: {formatClp(invoice.amount)} - Vence:{" "}
                                {formatDateDash(invoice.due_date)}
                              </Text>
                            ))}
                          </Stack>
                        </Table.Td>
                      </Table.Tr>
                    ) : null}
                  </Fragment>
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

      </SimpleGrid>
      </Stack>
    </AppNavigation>
  );
}
