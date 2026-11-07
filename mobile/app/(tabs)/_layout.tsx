import { Tabs } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { colors } from "@/theme";

export default function TabLayout() {
  return <Tabs screenOptions={{
    headerShown: false, tabBarActiveTintColor: colors.green, tabBarInactiveTintColor: colors.muted,
    tabBarStyle: { height: 66, paddingTop: 8, paddingBottom: 8, borderTopColor: colors.line, backgroundColor: colors.white },
    tabBarLabelStyle: { fontSize: 10, fontWeight: "700" },
  }}>
    <Tabs.Screen name="index" options={{ title: "Ana Sayfa", tabBarIcon: ({color,size}) => <Ionicons name="home-outline" color={color} size={size}/> }} />
    <Tabs.Screen name="search" options={{ title: "Keşfet", tabBarIcon: ({color,size}) => <Ionicons name="search-outline" color={color} size={size}/> }} />
    <Tabs.Screen name="favorites" options={{ title: "Favoriler", tabBarIcon: ({color,size}) => <Ionicons name="heart-outline" color={color} size={size}/> }} />
    <Tabs.Screen name="profile" options={{ title: "Hesabım", tabBarIcon: ({color,size}) => <Ionicons name="person-outline" color={color} size={size}/> }} />
  </Tabs>;
}
