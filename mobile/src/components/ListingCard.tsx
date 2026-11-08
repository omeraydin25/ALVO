import { Pressable, View, Text, Image, StyleSheet } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { Listing } from "@/lib/supabase";
import { colors, formatPrice } from "@/theme";

export function ListingCard({ item, onPress, favorite, onFavorite }: { item: Listing; onPress: () => void; favorite?: boolean; onFavorite?: () => void }) {
  return (
    <Pressable onPress={onPress} accessibilityRole="button" style={({ pressed }) => [s.card, pressed && s.pressed]}>
      <View style={s.photoWrap}>
        {item.imageUrl
          ? <Image source={{ uri: item.imageUrl }} style={s.photo} resizeMode="cover" />
          : <View style={s.placeholder}><Ionicons name="image-outline" size={31} color={colors.green} /><Text style={s.placeholderText}>ALVO</Text></View>}
        <View style={s.condition}><Text style={s.conditionText}>İKİNCİ EL</Text></View>
        {onFavorite && <Pressable accessibilityRole="button" accessibilityLabel={favorite ? "Favorilerden çıkar" : "Favorilere ekle"} onPress={(event) => { event.stopPropagation(); onFavorite(); }} hitSlop={6} style={({ pressed }) => [s.heart, pressed && s.heartPressed]}>
          <Ionicons name={favorite ? "heart" : "heart-outline"} size={19} color={favorite ? colors.danger : colors.ink} />
        </Pressable>}
      </View>
      <View style={s.body}>
        <Text numberOfLines={2} style={s.title}>{item.title}</Text>
        <Text numberOfLines={1} style={s.price}>{formatPrice(Number(item.price))}</Text>
        <View style={s.metaRow}><Ionicons name="location-outline" size={12} color={colors.muted} /><Text numberOfLines={1} style={s.meta}>{item.city}{item.district ? " · " + item.district : ""}</Text></View>
      </View>
    </Pressable>
  );
}

const s = StyleSheet.create({
  card: { backgroundColor: colors.white, borderRadius: 18, borderWidth: 1, borderColor: colors.line, overflow: "hidden", flex: 1, shadowColor: "#163624", shadowOpacity: 0.045, shadowRadius: 9, shadowOffset: { width: 0, height: 3 }, elevation: 1 },
  pressed: { opacity: 0.9 }, photoWrap: { height: 151, backgroundColor: colors.greenSoft, position: "relative" },
  photo: { width: "100%", height: "100%" }, placeholder: { flex: 1, alignItems: "center", justifyContent: "center", gap: 4 }, placeholderText: { fontSize: 9, letterSpacing: 1.5, fontWeight: "900", color: colors.green },
  condition: { position: "absolute", left: 9, bottom: 9, paddingHorizontal: 8, paddingVertical: 5, borderRadius: 7, backgroundColor: "#FFFFFFE8" }, conditionText: { color: colors.greenDark, fontSize: 8, fontWeight: "900", letterSpacing: 0.5 },
  heart: { position: "absolute", right: 9, top: 9, width: 36, height: 36, borderRadius: 18, backgroundColor: "#FFFFFFF2", alignItems: "center", justifyContent: "center", shadowColor: "#000", shadowOpacity: 0.08, shadowRadius: 5, shadowOffset: { width: 0, height: 2 }, elevation: 2 }, heartPressed: { transform: [{ scale: 0.92 }] },
  body: { paddingHorizontal: 11, paddingTop: 11, paddingBottom: 12 }, title: { fontSize: 12, fontWeight: "650", color: colors.ink, minHeight: 34, lineHeight: 17 },
  price: { fontSize: 16, fontWeight: "900", color: colors.ink, marginTop: 7, letterSpacing: -0.3 },
  metaRow: { flexDirection: "row", alignItems: "center", gap: 3, marginTop: 7 }, meta: { flex: 1, fontSize: 10, color: colors.muted },
});
