import Link from "next/link";
import type { ReactNode } from "react";
import { Anchor, Container, Group, Title } from "@mantine/core";
import { LogoutButton } from "@/components/LogoutButton";

export function AppNavigation({ children }: { children: ReactNode }) {
  return (
    <>
      <header className="app-header">
        <Container size="xl" h="100%">
          <Group h="100%" justify="space-between">
            <Title order={3}>Xepelin CRM</Title>
            <Group gap="lg">
              <Anchor component={Link} href="/">
                Panel
              </Anchor>
              <Anchor component={Link} href="/companies">
                Empresas
              </Anchor>
              <Anchor component={Link} href="/invoices/unpaid">
                Impagas
              </Anchor>
              <LogoutButton />
            </Group>
          </Group>
        </Container>
      </header>
      <main className="app-main">
        <Container size="xl">{children}</Container>
      </main>
    </>
  );
}
