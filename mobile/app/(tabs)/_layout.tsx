import { Tabs } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/theme";

export default function TabLayout() {
  return (
    <Tabs screenOptions={{
      headerShown: false,
      tabBarActiveTintColor: colors.green,
      tabBarInactiveTintColor: colors.muted,
      tabBarStyle: {
        height: 70,
        paddingTop: 8,
        paddingBottom: 9,
        borderTopColor: colors.line,
        borderTopWidth: 1,
        backgroundColor: colors.white,
        elevation: 12,
        shadowColor: "#183B27",
        shadowOpacity: 0.07,
        shadowRadius: 12,
        shadowOffset: { width: 0, height: -4 },
      },
      tabBarLabelStyle: { fontSize: 10, fontWeight: "700", marginTop: 2 },
      tabBarItemStyle: { paddingVertical: 1 },
    }}>
      <Tabs.Screen name="index" options={{ title: "Ana Sayfa", tabBarIcon: ({ color, size, focused }) => <Ionicons name={focused ? "home" : "home-outline"} color={color} size={size} /> }} />
      <Tabs.Screen name="search" options={{ title: "Keşfet", tabBarIcon: ({ color, size, focused }) => <Ionicons name={focused ? "search" : "search-outline"} color={color} size={size} /> }} />
      <Tabs.Screen name="favorites" options={{ title: "Favoriler", tabBarIcon: ({ color, size, focused }) => <Ionicons name={focused ? "heart" : "heart-outline"} color={color} size={size} /> }} />
      <Tabs.Screen name="profile" options={{ title: "Hesabım", tabBarIcon: ({ color, size, focused }) => <Ionicons name={focused ? "person" : "person-outline"} color={color} size={size} /> }} />
    </Tabs>
  );
}
