"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { Anchor, Card, SimpleGrid, Stack, Table, Text, Title } from "@mantine/core";
import { ErrorState, LoadingState } from "@/components/AsyncState";
import { MetricCard } from "@/components/MetricCard";
import { StatusPill } from "@/components/StatusPill";
import { formatClp, formatDate, formatPercent } from "@/lib/format";
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
          <Table.Td>{invoice.source.label}</Table.Td>
          <Table.Td>{formatClp(invoice.amount)}</Table.Td>
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

      <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }}>
        <MetricCard label="Facturas Xepelin globales" value={String(debtor.metrics.xepelin_invoice_count)} />
        <MetricCard label="Monto financiado global" value={formatClp(debtor.metrics.global_financed_amount)} />
        <MetricCard label="Exposición abierta" value={formatClp(debtor.metrics.open_exposure)} />
        <MetricCard
          label="Proxy de pago a tiempo"
          value={debtor.metrics.on_time_payment_rate === null ? "N/A" : formatPercent(debtor.metrics.on_time_payment_rate)}
          description={`${debtor.payment_probability.label} según pagos históricos`}
        />
      </SimpleGrid>

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
        <Title order={3}>Facturas vinculadas a tu cartera</Title>
        <Text c="dimmed" size="sm" mb="md">
          Visibilidad limitada a empresas asignadas al KAM logueado.
        </Text>
        <Table.ScrollContainer minWidth={960}>
          <Table>
            <Table.Thead>
              <Table.Tr>
                <Table.Th>Empresa</Table.Th>
                <Table.Th>Factura</Table.Th>
                <Table.Th>Fuente</Table.Th>
                <Table.Th>Monto</Table.Th>
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
  );
}
