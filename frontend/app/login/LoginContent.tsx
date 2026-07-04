"use client";

import { Alert, Box, Button, Card, Divider, Stack, Text, Title } from "@mantine/core";
import { useSearchParams } from "next/navigation";
import { authBaseUrl } from "@/lib/api";

export function LoginContent() {
  const searchParams = useSearchParams();
  const authFailed = searchParams.get("auth") === "failed";

  return (
    <Box className="login-shell">
      <Stack align="center" gap="xl" className="login-grid">
        <Stack align="center" gap="xs">
          <Text size="sm" tt="uppercase" c="dimmed" fw={700}>
            Panel de gestión KAM
          </Text>
          <Title className="login-title" ta="center">
            Growth CRM
          </Title>
          <Text c="dimmed" size="lg" ta="center">
            Centraliza tu gestión comercial.
          </Text>
        </Stack>

        <Card withBorder radius="xl" p="xl" className="login-card">
          <Stack gap="lg">
            <div>
              <Text size="sm" tt="uppercase" c="dimmed" fw={700}>
                Xepelin CRM
              </Text>
              <Title order={2}>Inicia sesión</Title>
              <Text c="dimmed" mt="xs">
                Usa tu cuenta corporativa de Google para acceder.
              </Text>
            </div>

            {authFailed ? (
              <Alert color="red" title="No se pudo autenticar">
                Intenta nuevamente con tu cuenta de Google.
              </Alert>
            ) : null}

            <Button component="a" href={`${authBaseUrl}/auth/google_oauth2`} size="md">
              Continuar con Google
            </Button>

            <Divider />

            <Text size="xs" c="dimmed">
              Acceso restringido a usuarios con cartera asignada en el CRM.
            </Text>
          </Stack>
        </Card>
      </Stack>
    </Box>
  );
}
