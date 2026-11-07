import { Pressable, View, Text, Image, StyleSheet } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { Listing } from "@/lib/supabase";
import { colors, formatPrice } from "@/theme";

export function ListingCard({ item, onPress, favorite, onFavorite }: { item: Listing; onPress: () => void; favorite?: boolean; onFavorite?: () => void }) {
  return <Pressable onPress={onPress} style={s.card}>
    <View style={s.photoWrap}>
      {item.imageUrl ? <Image source={{uri:item.imageUrl}} style={s.photo}/> : <View style={s.placeholder}><Ionicons name="image-outline" size={30} color={colors.green}/></View>}
      {onFavorite && <Pressable onPress={(e) => {e.stopPropagation();onFavorite();}} style={s.heart}><Ionicons name={favorite ? "heart" : "heart-outline"} size={19} color={favorite ? colors.danger : colors.ink}/></Pressable>}
    </View>
    <View style={s.body}>
      <Text numberOfLines={2} style={s.title}>{item.title}</Text>
      <Text style={s.price}>{formatPrice(Number(item.price))}</Text>
      <Text numberOfLines={1} style={s.meta}>{item.city}{item.district ? " · "+item.district : ""}</Text>
    </View>
  </Pressable>;
}
const s=StyleSheet.create({
 card:{backgroundColor:colors.white,borderRadius:15,borderWidth:1,borderColor:colors.line,overflow:"hidden",flex:1},
 photoWrap:{height:145,backgroundColor:colors.greenSoft},
 photo:{width:"100%",height:"100%",resizeMode:"cover"},
 placeholder:{flex:1,alignItems:"center",justifyContent:"center"},
 heart:{position:"absolute",right:9,top:9,width:34,height:34,borderRadius:17,backgroundColor:"#ffffffed",alignItems:"center",justifyContent:"center"},
 body:{padding:11},title:{fontSize:12,fontWeight:"600",color:colors.ink,minHeight:34,lineHeight:17},price:{fontSize:16,fontWeight:"800",color:colors.ink,marginTop:7},meta:{fontSize:10,color:colors.muted,marginTop:5}
});
