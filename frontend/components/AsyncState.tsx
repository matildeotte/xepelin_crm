import { Alert, Center, Loader, Stack, Text } from "@mantine/core";

export function LoadingState() {
  return (
    <Center py="xl">
      <Loader />
    </Center>
  );
}

export function ErrorState({ message }: { message: string }) {
  return (
    <Alert color="red" title="No se pudo cargar la información">
      {message}
    </Alert>
  );
}

export function EmptyState({ message }: { message: string }) {
  return (
    <Stack align="center" py="lg">
      <Text c="dimmed">{message}</Text>
    </Stack>
  );
}
