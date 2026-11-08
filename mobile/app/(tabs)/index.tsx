import { useCallback, useEffect, useState } from "react";
import {
  ActivityIndicator,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { useRouter } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { Listing, loadListings, isSupabaseConfigured, supabase } from "@/lib/supabase";
import { ListingCard } from "@/components/ListingCard";
import { colors, categories } from "@/theme";

const categoryIcons = [
  "grid-outline", "phone-portrait-outline", "laptop-outline", "home-outline",
  "shirt-outline", "shirt-outline", "car-outline", "construct-outline",
  "football-outline", "color-palette-outline", "heart-outline", "ellipsis-horizontal-outline",
] as const;

export default function HomeScreen() {
  const router = useRouter();
  const [items, setItems] = useState<Listing[]>([]);
  const [busy, setBusy] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [favorites, setFavorites] = useState<string[]>([]);
  const [error, setError] = useState("");

  const load = useCallback(async () => {
    if (!isSupabaseConfigured) {
      setItems([]);
      setBusy(false);
      setRefreshing(false);
      return;
    }
    try {
      setError("");
      setItems(await loadListings());
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "İlanlar yüklenemedi. Tekrar deneyebilirsin.");
    } finally {
      setBusy(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => { void load(); }, [load]);

  useEffect(() => {
    let active = true;
    const loadFavorites = async () => {
      if (!supabase) return;
      const { data: userData } = await supabase.auth.getUser();
      if (!userData.user) return;
      const { data } = await supabase.from("favorites").select("listing_id").eq("user_id", userData.user.id);
      if (active && data) setFavorites(data.map((row) => row.listing_id));
    };
    void loadFavorites();
    return () => { active = false; };
  }, []);

  const toggleFavorite = async (id: string) => {
    if (!supabase) { router.push("/auth"); return; }
    const { data } = await supabase.auth.getUser();
    if (!data.user) { router.push("/auth"); return; }
    const exists = favorites.includes(id);
    setFavorites((current) => exists ? current.filter((value) => value !== id) : [...current, id]);
    const result = exists
      ? await supabase.from("favorites").delete().eq("user_id", data.user.id).eq("listing_id", id)
      : await supabase.from("favorites").insert({ user_id: data.user.id, listing_id: id });
    if (result.error) setFavorites((current) => exists ? [...current, id] : current.filter((value) => value !== id));
  };

  const openCategory = (category: string) => router.push({ pathname: "/search", params: { category } });
  const listingRows = Array.from({ length: Math.ceil(items.slice(0, 8).length / 2) }, (_, index) => items.slice(0, 8).slice(index * 2, index * 2 + 2));

  return (
    <SafeAreaView style={s.safe} edges={["top"]}>
      <ScrollView
        style={s.screen}
        contentContainerStyle={s.content}
        showsVerticalScrollIndicator={false}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); void load(); }} tintColor={colors.green} />}
      >
        <View style={s.header}>
          <View>
            <Text style={s.brand}>ALV<Text style={s.brandAccent}>O</Text></Text>
            <Text style={s.tagline}>İkinci elin yeni adresi</Text>
          </View>
          <Pressable accessibilityLabel="İlan ver" onPress={() => router.push("/publish")} style={({ pressed }) => [s.sellButton, pressed && s.pressed]}>
            <Ionicons name="add" size={19} color={colors.white} />
            <Text style={s.sellButtonText}>İlan ver</Text>
          </Pressable>
        </View>

        <View style={s.hero}>
          <View style={s.heroOrb} />
          <View style={s.heroOrbSmall} />
          <View style={s.heroCopy}>
            <View style={s.eyebrowWrap}><View style={s.liveDot} /><Text style={s.eyebrow}>ALVO’DA YENİDEN DEĞER KAZAN</Text></View>
            <Text style={s.heroTitle}>Aradığını bul, iyi bir fırsat yakala.</Text>
            <Text style={s.heroDescription}>Binlerce ilanı keşfet. Kullanmadıkların yeni sahibini bulsun.</Text>
            <Pressable onPress={() => router.push("/search")} style={({ pressed }) => [s.heroButton, pressed && s.pressed]}>
              <Text style={s.heroButtonText}>Keşfet</Text><Ionicons name="arrow-forward" size={17} color={colors.greenDark} />
            </Pressable>
          </View>
          <View style={s.heroIcon}><Ionicons name="sparkles" size={25} color="#D7F2DF" /></View>
        </View>

        <View style={s.sectionHead}>
          <View><Text style={s.sectionTitle}>Kategoriler</Text><Text style={s.sectionSubtitle}>Aradığını kolayca bul</Text></View>
          <Pressable onPress={() => router.push("/search")} hitSlop={8} style={s.seeAll}><Text style={s.link}>Tümünü gör</Text><Ionicons name="chevron-forward" size={15} color={colors.green} /></Pressable>
        </View>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={s.categoryList}>
          {categories.slice(1).map((category, index) => (
            <Pressable key={category} onPress={() => openCategory(category)} style={({ pressed }) => [s.categoryItem, pressed && s.pressed]}>
              <View style={s.categoryIcon}><Ionicons name={categoryIcons[index + 1] ?? "albums-outline"} size={22} color={colors.green} /></View>
              <Text numberOfLines={1} style={s.categoryLabel}>{category}</Text>
            </Pressable>
          ))}
        </ScrollView>

        <View style={[s.sectionHead, s.listingHeading]}>
          <View><Text style={s.sectionTitle}>Yeni ilanlar</Text><Text style={s.sectionSubtitle}>Sana yakın fırsatları keşfet</Text></View>
          <Pressable onPress={() => router.push("/search")} hitSlop={8} style={s.seeAll}><Text style={s.link}>Hepsini gör</Text><Ionicons name="chevron-forward" size={15} color={colors.green} /></Pressable>
        </View>

        {!isSupabaseConfigured ? (
          <View style={s.notice}>
            <View style={s.noticeIcon}><Ionicons name="cloud-outline" size={22} color={colors.green} /></View>
            <View style={s.noticeCopy}><Text style={s.noticeTitle}>ALVO bağlantısı kurulmaya hazır</Text><Text style={s.noticeText}>İlanları görmek için Supabase ayarlarını tamamla.</Text></View>
          </View>
        ) : busy ? (
          <View style={s.loading}><ActivityIndicator color={colors.green} size="large" /><Text style={s.loadingText}>Güzel fırsatlar yükleniyor…</Text></View>
        ) : error ? (
          <View style={s.notice}><View style={s.noticeIcon}><Ionicons name="cloud-offline-outline" size={22} color={colors.danger} /></View><View style={s.noticeCopy}><Text style={s.noticeTitle}>İlanlara ulaşılamadı</Text><Text style={s.noticeText}>{error}</Text><Pressable onPress={() => { setBusy(true); void load(); }}><Text style={s.retry}>Tekrar dene</Text></Pressable></View></View>
        ) : items.length === 0 ? (
          <View style={s.empty}><Ionicons name="file-tray-outline" size={28} color={colors.green} /><Text style={s.emptyTitle}>Şimdilik yeni ilan yok</Text><Text style={s.noticeText}>Biraz sonra tekrar göz atabilirsin.</Text></View>
        ) : (
          <View style={s.grid}>
            {listingRows.map((row, rowIndex) => <View key={`row-${rowIndex}`} style={s.gridRow}>
              {row.map((item) => <ListingCard key={item.id} item={item} favorite={favorites.includes(item.id)} onFavorite={() => void toggleFavorite(item.id)} onPress={() => router.push({ pathname: "/listing/[id]", params: { id: item.id } })} />)}
              {row.length === 1 && <View style={s.cardSpacer} />}
            </View>)}
          </View>
        )}
        <View style={s.bottomNote}><Ionicons name="shield-checkmark-outline" size={16} color={colors.green} /><Text style={s.bottomNoteText}>Alışverişinde dikkatli ol, güvenle keşfet.</Text></View>
      </ScrollView>
    </SafeAreaView>
  );
}

const s = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background }, screen: { flex: 1, backgroundColor: colors.background },
  content: { paddingHorizontal: 20, paddingTop: 8, paddingBottom: 28 },
  header: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 19 },
  brand: { color: colors.ink, fontSize: 29, fontWeight: "900", letterSpacing: -1.5 }, brandAccent: { color: colors.green },
  tagline: { color: colors.muted, fontSize: 11, marginTop: -2, letterSpacing: 0.1 },
  sellButton: { backgroundColor: colors.green, borderRadius: 14, paddingHorizontal: 14, height: 42, flexDirection: "row", alignItems: "center", gap: 5, shadowColor: colors.green, shadowOpacity: 0.18, shadowRadius: 9, shadowOffset: { width: 0, height: 4 }, elevation: 3 },
  sellButtonText: { color: colors.white, fontSize: 12, fontWeight: "800" }, pressed: { opacity: 0.82, transform: [{ scale: 0.98 }] },
  hero: { minHeight: 224, backgroundColor: colors.greenDark, borderRadius: 25, overflow: "hidden", marginBottom: 27, position: "relative", justifyContent: "center" },
  heroCopy: { padding: 21, paddingRight: 58, zIndex: 2 }, eyebrowWrap: { flexDirection: "row", alignItems: "center", gap: 7, marginBottom: 13 },
  liveDot: { width: 7, height: 7, borderRadius: 4, backgroundColor: "#B8EBC7" }, eyebrow: { color: "#CDE9D5", fontSize: 9, fontWeight: "800", letterSpacing: 1.05 },
  heroTitle: { color: colors.white, fontSize: 26, lineHeight: 31, fontWeight: "900", letterSpacing: -0.75, maxWidth: 280 },
  heroDescription: { color: "#D6EBDD", fontSize: 12, lineHeight: 18, marginTop: 8, maxWidth: 260 },
  heroButton: { alignSelf: "flex-start", marginTop: 16, backgroundColor: colors.white, borderRadius: 12, paddingHorizontal: 15, paddingVertical: 10, flexDirection: "row", alignItems: "center", gap: 9 },
  heroButtonText: { color: colors.greenDark, fontSize: 12, fontWeight: "800" },
  heroOrb: { position: "absolute", width: 205, height: 205, borderRadius: 110, backgroundColor: "#FFFFFF0D", right: -48, top: -69 },
  heroOrbSmall: { position: "absolute", width: 145, height: 145, borderRadius: 80, borderWidth: 1, borderColor: "#FFFFFF1C", right: -7, bottom: -83 },
  heroIcon: { position: "absolute", right: 20, top: 21, width: 43, height: 43, borderRadius: 15, backgroundColor: "#FFFFFF17", alignItems: "center", justifyContent: "center" },
  sectionHead: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 14 },
  sectionTitle: { fontSize: 18, fontWeight: "850", color: colors.ink, letterSpacing: -0.4 }, sectionSubtitle: { fontSize: 11, color: colors.muted, marginTop: 3 },
  seeAll: { flexDirection: "row", alignItems: "center", gap: 1 }, link: { fontSize: 11, color: colors.green, fontWeight: "800" },
  categoryList: { gap: 12, paddingBottom: 3, paddingRight: 5 }, categoryItem: { width: 73, alignItems: "center" },
  categoryIcon: { width: 58, height: 58, borderRadius: 20, backgroundColor: colors.greenSoft, alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: "#E4F0E7" },
  categoryLabel: { color: colors.ink, fontSize: 10, fontWeight: "650", marginTop: 8, textAlign: "center", width: 74 },
  listingHeading: { marginTop: 27, marginBottom: 13 }, grid: { gap: 12 }, gridRow: { flexDirection: "row", gap: 12, alignItems: "stretch" }, cardSpacer: { flex: 1 },
  notice: { flexDirection: "row", alignItems: "flex-start", gap: 12, padding: 16, backgroundColor: colors.white, borderRadius: 18, borderWidth: 1, borderColor: colors.line },
  noticeIcon: { width: 42, height: 42, borderRadius: 14, backgroundColor: colors.greenSoft, alignItems: "center", justifyContent: "center" },
  noticeCopy: { flex: 1 }, noticeTitle: { color: colors.ink, fontSize: 13, fontWeight: "800", marginBottom: 4 }, noticeText: { color: colors.muted, fontSize: 11, lineHeight: 17 }, retry: { color: colors.green, fontSize: 12, fontWeight: "800", marginTop: 10 },
  loading: { minHeight: 160, alignItems: "center", justifyContent: "center", gap: 11 }, loadingText: { color: colors.muted, fontSize: 12 },
  empty: { alignItems: "center", justifyContent: "center", padding: 24, backgroundColor: colors.white, borderRadius: 18, borderWidth: 1, borderColor: colors.line, gap: 7 }, emptyTitle: { color: colors.ink, fontSize: 14, fontWeight: "800" },
  bottomNote: { flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 7, marginTop: 21 }, bottomNoteText: { color: colors.muted, fontSize: 10 },
});
