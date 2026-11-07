import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { colors } from "@/theme";

export default function RootLayout() {
  return <>
    <StatusBar style="dark" backgroundColor={colors.background} />
    <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: colors.background } }}>
      <Stack.Screen name="(tabs)" />
      <Stack.Screen name="listing/[id]" options={{ presentation: "card", animation: "slide_from_right" }} />
      <Stack.Screen name="publish" options={{ presentation: "modal", animation: "slide_from_bottom" }} />
      <Stack.Screen name="auth" options={{ presentation: "modal", animation: "slide_from_bottom" }} />
    </Stack>
  </>;
}
