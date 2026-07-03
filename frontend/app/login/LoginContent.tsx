"use client";

import { Alert, Button, Card, Center, Stack, Text, Title } from "@mantine/core";
import { useSearchParams } from "next/navigation";
import { authBaseUrl } from "@/lib/api";

export function LoginContent() {
  const searchParams = useSearchParams();
  const authFailed = searchParams.get("auth") === "failed";

  return (
    <Center mih="70vh">
      <Card withBorder radius="lg" p="xl" maw={460}>
        <Stack>
          <div>
            <Text size="sm" tt="uppercase" c="dimmed" fw={700}>
              Xepelin CRM
            </Text>
            <Title order={2}>Inicia sesión</Title>
            <Text c="dimmed" mt="xs">
              Accede con Google para ver la cartera asignada a tu KAM.
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
        </Stack>
      </Card>
    </Center>
  );
}
