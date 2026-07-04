"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import {
  Anchor,
  Button,
  Card,
  Group,
  Select,
  SimpleGrid,
  Stack,
  Table,
  Text,
  Textarea,
  Title
} from "@mantine/core";
import { ErrorState, LoadingState } from "@/components/AsyncState";
import { AppNavigation } from "@/components/AppNavigation";
import { MetricCard } from "@/components/MetricCard";
import { StatusPill } from "@/components/StatusPill";
import { apiPost } from "@/lib/api";
import { formatClp, formatDate, formatPercent } from "@/lib/format";
import { useApiResource } from "@/lib/useApiResource";
import type { CompanyResponse, Interaction } from "@/lib/types";

export default function CompanyDetailPage() {
  const params = useParams<{ id: string }>();
  const { data, error, loading, setData } = useApiResource<CompanyResponse>(`/api/v1/companies/${params.id}`);
  const [kind, setKind] = useState<string | null>(null);
  const [summary, setSummary] = useState("");
  const [submitting, setSubmitting] = useState(false);

  if (loading) return <LoadingState />;
  if (error || !data) return <ErrorState message={error ?? "No se pudo cargar la empresa."} />;

  const company = data.company;
  const relationshipRisks = company.risk_eligibilities.filter((risk) => risk.debtor);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!kind || !summary.trim()) return;

    setSubmitting(true);

    try {
      const response = await apiPost<{ interaction: Interaction }>(`/api/v1/companies/${company.id}/interactions`, {
        interaction: { kind, summary }
      });

      setData((currentData) => {
        if (!currentData) return currentData;

        return {
          ...currentData,
          company: {
            ...currentData.company,
            interactions: [response.interaction, ...currentData.company.interactions]
          }
        };
      });
      setKind(null);
      setSummary("");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <AppNavigation>
      <Stack gap="xl">
      <Group justify="space-between" align="flex-start">
        <div>
          <Text size="sm" tt="uppercase" c="dimmed" fw={700}>
            Detalle de empresa
          </Text>
          <Title>{company.legal_name}</Title>
          <Text c="dimmed">
            {company.tax_id} · {company.sector} · Creada {formatDate(company.created_at)}
          </Text>
        </div>
        <Group>
          <StatusPill label={company.activation_state.label} tone={company.activation_state.tone} />
          {company.latest_risk_eligibility ? (
            <StatusPill
              label={company.latest_risk_eligibility.status.label}
              tone={company.latest_risk_eligibility.status.tone}
            />
          ) : null}
        </Group>
      </Group>

      <SimpleGrid cols={{ base: 1, sm: 2, lg: 4 }}>
        <MetricCard label="Financiado este mes" value={formatClp(company.metrics.financed_amount)} />
        <MetricCard label="Volumen visible en SII" value={formatClp(company.metrics.sii_volume)} />
        <MetricCard label="Participación de cartera" value={formatPercent(company.metrics.share_of_wallet)} />
        <MetricCard label="Oportunidad de expansión" value={formatClp(company.metrics.expansion_opportunity)} />
      </SimpleGrid>

      <SimpleGrid cols={{ base: 1, md: 4 }}>
        <Card withBorder radius="lg">
          <Title order={3}>Siguiente mejor acción</Title>
          <Text mt="sm">{company.next_best_action.label}</Text>
          <Text c="dimmed" size="sm" mt="sm">
            Última operación: {formatDate(company.metrics.last_financed_on)}
          </Text>
        </Card>
        <MetricCard
          label="Concentración de pagadores"
          value={formatPercent(company.metrics.top_debtor_concentration)}
          description="Porcentaje concentrado en el principal pagador"
        />
        <Card withBorder radius="lg">
          <Title order={3}>Health Score AI</Title>
          {company.latest_health_score ? (
            <Stack mt="sm" gap="xs">
              <Group>
                <Text fw={700} size="xl">
                  {company.latest_health_score.score}/100
                </Text>
                <StatusPill
                  label={company.latest_health_score.churn_risk.label}
                  tone={company.latest_health_score.churn_risk.tone}
                />
              </Group>
              <Text size="sm">{company.latest_health_score.summary}</Text>
              <Stack gap={4}>
                {company.latest_health_score.recommended_actions.map((action) => (
                  <Text key={action} size="sm" c="dimmed">
                    {action}
                  </Text>
                ))}
              </Stack>
            </Stack>
          ) : (
            <Text c="dimmed" mt="sm">
              Pendiente de generación con Gemini.
            </Text>
          )}
        </Card>
        <MetricCard label="Estado comercial" value={company.activation_state.label} />
      </SimpleGrid>

      <Card withBorder radius="lg">
        <Title order={3}>Resultado de riesgos por pagador</Title>
        <Text c="dimmed" size="sm" mb="md">
          Señal entregada por Riesgos para priorizar oportunidades comerciales.
        </Text>
        <Table.ScrollContainer minWidth={760}>
          <Table>
            <Table.Thead>
              <Table.Tr>
                <Table.Th>Pagador</Table.Th>
                <Table.Th>Resultado</Table.Th>
                <Table.Th>Tipo</Table.Th>
                <Table.Th>Motivo</Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              {relationshipRisks.map((risk) => (
                <Table.Tr key={risk.id}>
                  <Table.Td>
                    {risk.debtor ? (
                      <Anchor component={Link} href={`/debtors/${risk.debtor.id}`} className="table-link">
                        {risk.debtor.legal_name}
                      </Anchor>
                    ) : null}
                  </Table.Td>
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
        <Title order={3}>Facturas visibles en SII no financiadas</Title>
        <Text c="dimmed" size="sm" mb="md">
          Oportunidad central de crecimiento sobre facturas observadas por el scraper SII.
        </Text>
        <Table.ScrollContainer minWidth={1120}>
          <Table>
            <Table.Thead>
              <Table.Tr>
                <Table.Th>Factura</Table.Th>
                <Table.Th>Pagador</Table.Th>
                <Table.Th>Monto</Table.Th>
                <Table.Th>Emisión</Table.Th>
                <Table.Th>Vencimiento</Table.Th>
                <Table.Th>Acción sugerida</Table.Th>
                <Table.Th>Operar</Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              {company.opportunity_invoices.map((invoice) => {
                const canOffer = invoice.suggested_action.startsWith("Ofrecer");

                return (
                  <Table.Tr key={invoice.id}>
                    <Table.Td>{invoice.invoice_number}</Table.Td>
                    <Table.Td>
                      {invoice.debtor ? (
                        <Anchor component={Link} href={`/debtors/${invoice.debtor.id}`} className="table-link">
                          {invoice.debtor.legal_name}
                        </Anchor>
                      ) : null}
                    </Table.Td>
                    <Table.Td>{formatClp(invoice.amount)}</Table.Td>
                    <Table.Td>{formatDate(invoice.issue_date)}</Table.Td>
                    <Table.Td>{formatDate(invoice.due_date)}</Table.Td>
                    <Table.Td>{invoice.suggested_action}</Table.Td>
                    <Table.Td>
                      <Button size="xs" disabled={!canOffer}>
                        Pre-aprobar y enviar simulación
                      </Button>
                    </Table.Td>
                  </Table.Tr>
                );
              })}
            </Table.Tbody>
          </Table>
        </Table.ScrollContainer>
      </Card>

      <Card withBorder radius="lg">
        <Title order={3}>Facturas financiadas</Title>
        <Table.ScrollContainer minWidth={920}>
          <Table>
            <Table.Thead>
              <Table.Tr>
                <Table.Th>Factura</Table.Th>
                <Table.Th>Pagador</Table.Th>
                <Table.Th>Monto</Table.Th>
                <Table.Th>Financiada</Table.Th>
                <Table.Th>Vencimiento</Table.Th>
                <Table.Th>Estado</Table.Th>
                <Table.Th>Tasa moratoria</Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              {company.financed_invoices.map((invoice) => (
                <Table.Tr key={invoice.id}>
                  <Table.Td>{invoice.invoice_number}</Table.Td>
                  <Table.Td>{invoice.debtor?.legal_name}</Table.Td>
                  <Table.Td>{formatClp(invoice.amount)}</Table.Td>
                  <Table.Td>{formatDate(invoice.financed_on)}</Table.Td>
                  <Table.Td>{formatDate(invoice.due_date)}</Table.Td>
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

      <SimpleGrid cols={{ base: 1, lg: 2 }}>
        <Card withBorder radius="lg">
          <Title order={3}>Agregar interacción</Title>
          <form onSubmit={handleSubmit}>
            <Stack mt="md">
              <Select
                label="Tipo"
                data={data.interaction_kinds.map((item) => ({ value: item.value, label: item.label }))}
                value={kind}
                onChange={setKind}
                required
              />
              <Textarea
                label="Resumen"
                value={summary}
                onChange={(event) => setSummary(event.currentTarget.value)}
                placeholder="Ejemplo: se conversó una oportunidad de financiamiento para facturas SII pendientes."
                minRows={4}
                required
              />
              <Button type="submit" loading={submitting}>
                Agregar interacción
              </Button>
            </Stack>
          </form>
        </Card>

        <Card withBorder radius="lg">
          <Title order={3}>Interacciones recientes</Title>
          <Table mt="md">
            <Table.Thead>
              <Table.Tr>
                <Table.Th>Fecha</Table.Th>
                <Table.Th>Tipo</Table.Th>
                <Table.Th>Resumen</Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              {company.interactions.map((interaction) => (
                <Table.Tr key={interaction.id}>
                  <Table.Td>{formatDate(interaction.created_at)}</Table.Td>
                  <Table.Td>{interaction.kind.label}</Table.Td>
                  <Table.Td>{interaction.summary}</Table.Td>
                </Table.Tr>
              ))}
            </Table.Tbody>
          </Table>
        </Card>
      </SimpleGrid>
      </Stack>
    </AppNavigation>
  );
}
