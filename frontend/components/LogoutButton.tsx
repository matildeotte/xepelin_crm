"use client";

import { Button } from "@mantine/core";
import { logout } from "@/lib/api";

export function LogoutButton() {
  return (
    <Button size="xs" variant="subtle" color="gray" onClick={() => void logout()}>
      Cerrar sesión
    </Button>
  );
}
