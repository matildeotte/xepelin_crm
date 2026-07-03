import { Suspense } from "react";
import { LoadingState } from "@/components/AsyncState";
import { LoginContent } from "./LoginContent";

export default function LoginPage() {
  return (
    <Suspense fallback={<LoadingState />}>
      <LoginContent />
    </Suspense>
  );
}
