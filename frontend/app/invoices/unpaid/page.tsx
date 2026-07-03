"use client";

import Link from "next/link";
import { Anchor, Card, Stack, Table, Text, Title } from "@mantine/core";
import { ErrorState, LoadingState } from "@/components/AsyncState";
import { StatusPill } from "@/components/StatusPill";
import { formatClp, formatDate, formatPercent } from "@/lib/format";
import { useApiResource } from "@/lib/useApiResource";
import type { InvoicesResponse } from "@/lib/types";

export default function UnpaidInvoicesPage() {
  const { data, error, loading } = useApiResource<InvoicesResponse>("/api/v1/invoices/unpaid");

  if (loading) return <LoadingState />;
  if (error || !data) return <ErrorState message={error ?? "No se pudieron cargar las facturas."} />;

  return (
    <Stack gap="xl">
      <div>
        <Text size="sm" tt="uppercase" c="dimmed" fw={700}>
          Cobranza como contexto
        </Text>
        <Title>Facturas financiadas impagas</Title>
        <Text c="dimmed">
          Cobranza gestiona la recuperación. El KAM usa esta señal para entender posibles bloqueos comerciales.
        </Text>
      </div>

      <Card withBorder radius="lg">
        <Table.ScrollContainer minWidth={1040}>
          <Table>
            <Table.Thead>
              <Table.Tr>
                <Table.Th>Empresa</Table.Th>
                <Table.Th>Pagador</Table.Th>
                <Table.Th>Factura</Table.Th>
                <Table.Th>Monto</Table.Th>
                <Table.Th>Vencimiento</Table.Th>
                <Table.Th>Días de mora</Table.Th>
                <Table.Th>Estado</Table.Th>
                <Table.Th>Tasa moratoria</Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              {data.invoices.map((invoice) => (
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
                  <Table.Td>{invoice.invoice_number}</Table.Td>
                  <Table.Td>{formatClp(invoice.amount)}</Table.Td>
                  <Table.Td>{formatDate(invoice.due_date)}</Table.Td>
                  <Table.Td>{invoice.days_overdue}</Table.Td>
                  <Table.Td>
                    <StatusPill label={invoice.status.label} tone={invoice.status.tone} />
                  </Table.Td>
                  <Table.Td>{formatPercent(invoice.moratory_monthly_rate)}</Table.Td>
                </Table.Tr>
              ))}
            </Table.Tbody>
          </Table>
        </Table.ScrollContainer>
      </Card>
    </Stack>
  );
}
