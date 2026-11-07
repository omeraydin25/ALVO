import "react-native-url-polyfill/auto";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { createClient } from "@supabase/supabase-js";

const url = process.env.EXPO_PUBLIC_SUPABASE_URL ?? "";
const anonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY ?? "";

export const isSupabaseConfigured = Boolean(url && anonKey && url.startsWith("https://"));
export const supabase = isSupabaseConfigured
  ? createClient(url, anonKey, {
      auth: {
        storage: AsyncStorage,
        autoRefreshToken: true,
        persistSession: true,
        detectSessionInUrl: false,
      },
    })
  : null;

export type Listing = {
  id: string;
  title: string;
  description: string;
  price: number;
  category: string;
  city: string;
  district?: string | null;
  seller_id: string;
  published_at?: string | null;
  created_at: string;
  imageUrl?: string | null;
  sellerName?: string;
};

export async function loadListings(search = "", category = ""): Promise<Listing[]> {
  if (!supabase) return [];
  let query = supabase
    .from("listings")
    .select("id,title,description,price,category,city,district,seller_id,published_at,created_at,listing_images(storage_path,sort_order),profiles!listings_seller_id_fkey(display_name)")
    .eq("status", "active")
    .order("published_at", { ascending: false })
    .limit(60);
  if (category) query = query.eq("category", category);
  if (search.trim()) query = query.or(`title.ilike.%${search.trim()}%,description.ilike.%${search.trim()}%,city.ilike.%${search.trim()}%`);
  const { data, error } = await query;
  if (error) throw error;
  return Promise.all((data ?? []).map(async (row: any) => {
    const firstImage = [...(row.listing_images ?? [])].sort((a: any,b: any) => a.sort_order-b.sort_order)[0];
    let imageUrl: string | null = null;
    if (firstImage?.storage_path) {
      const { data: signed } = await supabase!.storage.from("listing-images").createSignedUrl(firstImage.storage_path, 3600);
      imageUrl = signed?.signedUrl ?? null;
    }
    return { ...row, listing_images: undefined, profiles: undefined, imageUrl, sellerName: row.profiles?.display_name ?? "ALVO kullanıcısı" } as Listing;
  }));
}

export async function loadListing(id: string): Promise<Listing> {
  if (!supabase) throw new Error("Supabase bağlantısı yapılandırılmamış.");
  const { data, error } = await supabase
    .from("listings")
    .select("id,title,description,price,category,city,district,seller_id,published_at,created_at,listing_images(storage_path,sort_order),profiles!listings_seller_id_fkey(display_name)")
    .eq("id", id).single();
  if (error) throw error;
  const firstImage = [...(data.listing_images ?? [])].sort((a: any,b: any) => a.sort_order-b.sort_order)[0];
  let imageUrl: string | null = null;
  if (firstImage?.storage_path) {
    const { data: signed } = await supabase.storage.from("listing-images").createSignedUrl(firstImage.storage_path, 3600);
    imageUrl = signed?.signedUrl ?? null;
  }
  return { ...data, listing_images: undefined, profiles: undefined, imageUrl, sellerName: (data as any).profiles?.display_name ?? "ALVO kullanıcısı" } as Listing;
}
