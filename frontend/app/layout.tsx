import "@mantine/core/styles.css";
import "./globals.css";

import type { Metadata } from "next";
import type { ReactNode } from "react";
import Link from "next/link";
import { Anchor, Container, Group, Title } from "@mantine/core";
import { Providers } from "./providers";

export const metadata: Metadata = {
  title: "Xepelin CRM",
  description: "CRM para priorización comercial KAM"
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="es">
      <body>
        <Providers>
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
                </Group>
              </Group>
            </Container>
          </header>
          <main className="app-main">
            <Container size="xl">{children}</Container>
          </main>
        </Providers>
      </body>
    </html>
  );
}
