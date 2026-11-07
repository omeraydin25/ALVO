# ALVO

**İkinci elin yeni adresi.** ALVO, Türkiye genelinde ücretsiz ikinci el ilanlarını keşfetmek ve yayınlamak için tasarlanan Türkçe, mobil uyumlu pazar yeri prototipidir.

## Ön yüz özellikleri

- Light tema, duyarlı mobil/tablet/masaüstü tasarım ve çalışan mobil menü
- Ana sayfa, kategori listesi, arama sonuçları ve ilan detayları
- Elektronik, Telefon, Bilgisayar, Ev ve Yaşam, Moda, Giyim, Araç, Yedek Parça, Spor, Hobi, Anne ve Bebek, Diğer kategorileri
- Örnek ilanlar; başlık, kategori ve şehir içinde arama; kategori filtreleme ve fiyata göre sıralama
- Ücretsiz ilan formu, fotoğraf önizleme, favoriler ve demo profil/kayıt ekranı
- Hakkımızda, iletişim, kullanım koşulları ve gizlilik sayfaları
- Harici JavaScript kütüphanesi, ücretli servis veya derleme adımı gerektirmeyen statik ön yüz

## Supabase veritabanı temeli

`supabase/migrations/20261107000000_initial_schema.sql` dosyası Supabase Postgres için `profiles`, `listings`, `listing_images`, `favorites`, `conversations`, `conversation_members`, `messages` ve `reports` tablolarını; indeksleri, kısıtları, profil tetikleyicisini, RLS politikalarını ve private ilan fotoğrafı bucket politikalarını içerir. Kurulum, güvenlik yaklaşımı ve test kontrol listesi için [`supabase/README.md`](supabase/README.md) dosyasına bakın.

> Bu aşamada Supabase projesine bağlanılmadı ve ön yüz Supabase’e bağlanmış değildir. Demo verileri halen tarayıcı `localStorage` alanında çalışır. SQL’i önce geliştirme Supabase projesinde uygulayıp RLS senaryolarını doğrulayın.

## Çalıştırma

Dosyaları indirin ve `index.html` dosyasını güncel bir tarayıcıda açın. Alternatif olarak kök dizinde basit bir yerel sunucu başlatın:

```bash
python3 -m http.server 8000
```

Ardından `http://localhost:8000` adresine gidin. GitHub Pages üzerinde yayımlamak için repository ayarlarında Pages kaynağı olarak `main` dalı ve kök dizin seçilebilir.

## Güvenlik notları

Supabase istemci uygulamalarında publishable/anon anahtar kullanılabilir; bu anahtarın güvenliği RLS politikalarına dayanır. Service-role/secret anahtarı RLS’i aşabildiği için asla HTML, JavaScript, Git geçmişi veya mobil uygulama paketine eklemeyin. Bu depoda gerçek proje URL’si veya API anahtarı bulunmaz.

## Dosyalar

- `index.html`, `styles.css`, `app.js` — statik ALVO ön yüz prototipi
- `supabase/migrations/` — sürümlenmiş veritabanı migrasyonları
- `supabase/README.md` — Türkçe Supabase kurulum ve güvenlik notları
