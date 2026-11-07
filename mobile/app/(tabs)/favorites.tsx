import { useCallback,useEffect,useState } from "react";
import { View,Text,FlatList,StyleSheet,ActivityIndicator } from "react-native";
import { useRouter } from "expo-router";
import { Listing,loadListings,supabase } from "@/lib/supabase";
import { ListingCard } from "@/components/ListingCard";
import { colors } from "@/theme";

export default function FavoritesScreen(){
 const router=useRouter();const [items,setItems]=useState<Listing[]>([]);const [busy,setBusy]=useState(true);const [message,setMessage]=useState("Giriş yaptığında favorilerine eklediğin ilanlar burada görünür.");
 const load=useCallback(async()=>{if(!supabase){setBusy(false);return;}const{data:user}=await supabase.auth.getUser();if(!user.user){setMessage("Favorilerini görmek için giriş yap.");setBusy(false);return;}const{data,error}=await supabase.from("favorites").select("listing_id").eq("user_id",user.user.id);if(error){setMessage(error.message);setBusy(false);return;}const ids=(data??[]).map(x=>x.listing_id);if(!ids.length){setItems([]);setMessage("Henüz favori ilan eklemedin.");setBusy(false);return;}const all=await loadListings();setItems(all.filter(x=>ids.includes(x.id)));setBusy(false);},[]);
 useEffect(()=>{load();},[load]);
 return <View style={s.page}><Text style={s.title}>Favorilerim</Text>{busy?<ActivityIndicator color={colors.green}/>:items.length===0?<View style={s.empty}><Text style={s.emptyTitle}>♡</Text><Text style={s.text}>{message}</Text></View>:<FlatList data={items} numColumns={2} columnWrapperStyle={{gap:10,marginBottom:10}} keyExtractor={x=>x.id} renderItem={({item})=><ListingCard item={item} onPress={()=>router.push({pathname:"/listing/[id]",params:{id:item.id}})}/>}/>}</View>;
}
const s=StyleSheet.create({page:{flex:1,padding:18,backgroundColor:colors.background},title:{fontSize:25,fontWeight:"900",color:colors.ink,marginBottom:18},empty:{marginTop:35,padding:24,backgroundColor:"white",borderRadius:15,alignItems:"center",gap:10},emptyTitle:{fontSize:36,color:colors.green},text:{fontSize:12,color:colors.muted,textAlign:"center",lineHeight:18}});
