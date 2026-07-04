"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { Anchor, Card, SimpleGrid, Stack, Table, Text, Title } from "@mantine/core";
import { ErrorState, LoadingState } from "@/components/AsyncState";
import { AppNavigation } from "@/components/AppNavigation";
import { MetricCard } from "@/components/MetricCard";
import { StatusPill } from "@/components/StatusPill";
import { formatClp, formatDate } from "@/lib/format";
import { useApiResource } from "@/lib/useApiResource";
import type { DebtorResponse, Invoice } from "@/lib/types";

function InvoiceRows({ invoices }: { invoices: Invoice[] }) {
  return (
    <>
      {invoices.map((invoice) => (
        <Table.Tr key={invoice.id}>
          <Table.Td>
            {invoice.company ? (
              <Anchor component={Link} href={`/companies/${invoice.company.id}`} className="table-link">
                {invoice.company.legal_name}
              </Anchor>
            ) : null}
          </Table.Td>
          <Table.Td>{invoice.invoice_number}</Table.Td>
          <Table.Td>{formatClp(invoice.amount)}</Table.Td>
          <Table.Td>{formatDate(invoice.financed_on)}</Table.Td>
          <Table.Td>{formatDate(invoice.issue_date)}</Table.Td>
          <Table.Td>{formatDate(invoice.due_date)}</Table.Td>
          <Table.Td>
            <StatusPill label={invoice.status.label} tone={invoice.status.tone} />
          </Table.Td>
          <Table.Td>{formatDate(invoice.paid_on)}</Table.Td>
        </Table.Tr>
      ))}
    </>
  );
}

export default function DebtorDetailPage() {
  const params = useParams<{ id: string }>();
  const { data, error, loading } = useApiResource<DebtorResponse>(`/api/v1/debtors/${params.id}`);

  if (loading) return <LoadingState />;
  if (error || !data) return <ErrorState message={error ?? "No se pudo cargar el pagador."} />;

  const debtor = data.debtor;

  return (
    <AppNavigation>
      <Stack gap="xl">
      <div>
        <Text size="sm" tt="uppercase" c="dimmed" fw={700}>
          Detalle del pagador
        </Text>
        <Title>{debtor.legal_name}</Title>
        <Text c="dimmed">
          {debtor.tax_id} · {debtor.sector}
        </Text>
      </div>

      <Card withBorder radius="lg">
        <Title order={3}>Saldo pendiente con Xepelin</Title>
        <Text c="dimmed" size="sm" mt="xs">
          Deuda del pagador en empresas de tu cartera por facturas financiadas impagas.
        </Text>
        <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }} mt="md">
          <MetricCard label="Total pendiente" value={formatClp(debtor.metrics.outstanding_balance)} />
          <MetricCard label="Vencido" value={formatClp(debtor.metrics.overdue_balance)} />
          <MetricCard label="Por vencer" value={formatClp(debtor.metrics.pending_balance)} />
          <MetricCard
            label="Facturas Xepelin impagas"
            value={String(debtor.metrics.unpaid_xepelin_invoice_count)}
            description="Solo facturas financiadas impagas en tu cartera"
          />
        </SimpleGrid>
      </Card>

      <Card withBorder radius="lg">
        <Title order={3}>Resultados de riesgos en tu cartera</Title>
        <Table.ScrollContainer minWidth={720}>
          <Table>
            <Table.Thead>
              <Table.Tr>
                <Table.Th>Empresa</Table.Th>
                <Table.Th>Estado</Table.Th>
                <Table.Th>Tipo</Table.Th>
                <Table.Th>Motivo</Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              {data.risk_eligibilities.map((risk) => (
                <Table.Tr key={risk.id}>
                  <Table.Td>{risk.company?.legal_name}</Table.Td>
                  <Table.Td>
                    <StatusPill label={risk.status.label} tone={risk.status.tone} />
                  </Table.Td>
                  <Table.Td>{risk.risk_type.label}</Table.Td>
                  <Table.Td>{risk.reason}</Table.Td>
                </Table.Tr>
              ))}
            </Table.Tbody>
          </Table>
        </Table.ScrollContainer>
      </Card>

      <Card withBorder radius="lg">
        <Title order={3}>Facturas financiadas con Xepelin</Title>
        <Text c="dimmed" size="sm" mb="md">
          Solo facturas que Xepelin financió en empresas de tu cartera. Las visibles en SII se revisan en el detalle de cada empresa.
        </Text>
        <Table.ScrollContainer minWidth={960}>
          <Table>
            <Table.Thead>
              <Table.Tr>
                <Table.Th>Empresa</Table.Th>
                <Table.Th>Factura</Table.Th>
                <Table.Th>Monto</Table.Th>
                <Table.Th>Financiada</Table.Th>
                <Table.Th>Emisión</Table.Th>
                <Table.Th>Vencimiento</Table.Th>
                <Table.Th>Estado</Table.Th>
                <Table.Th>Pagada el</Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              <InvoiceRows invoices={data.portfolio_invoices} />
            </Table.Tbody>
          </Table>
        </Table.ScrollContainer>
      </Card>
      </Stack>
    </AppNavigation>
  );
}
