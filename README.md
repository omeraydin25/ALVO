# ALVO

**İkinci elin yeni adresi.** ALVO, Türkiye genelinde ücretsiz ikinci el ilanlarını keşfetmek ve yayınlamak için tasarlanan Türkçe, mobil uyumlu pazar yeri prototipidir.

## Ön yüz özellikleri

- Light tema, duyarlı mobil/tablet/masaüstü tasarım ve çalışan mobil menü
- Ana sayfa, kategori listesi, arama sonuçları ve ilan detayları
- Türkiye geneli kategoriler, örnek ilanlar, arama, filtre ve fiyat sıralama
- Ücretsiz ilan formu, fotoğraf önizleme, favoriler ve demo profil/kayıt ekranı
- Bağımlılıksız statik HTML/CSS/JavaScript ön yüz

## Supabase veritabanı

`supabase/migrations/20261107000000_initial_schema.sql` dosyası sekiz uygulama tablosu, indeksler, RLS politikaları, güvenli mesajlaşma RPC’si ve private ilan görseli bucket’ını içerir. Eski ALVO `public.listings` tablosunu verileri silmeden koşullu olarak `listings_legacy_backup_20261108` adına taşır, eski erişim politikalarını kaldırıp yedeği kapatır ve yeni şemayı kurar. Kurulum ve kontrol adımları: [`supabase/README.md`](supabase/README.md).

> SQL bu değişiklikle hiçbir gerçek Supabase projesinde çalıştırılmadı. Uygulamadan önce üretim yedeği alın ve önce geliştirme projesinde deneyin. Ön yüz henüz Supabase’e bağlı değildir.

## Çalıştırma

```bash
python3 -m http.server 8000
```

Sonra `http://localhost:8000` adresini açın. Supabase secret/service-role anahtarını hiçbir zaman istemci koduna koymayın; gerçek erişim RLS ile korunmalıdır.


## Native mobile app (Android & iOS)

The Expo + React Native application lives in [`mobile/`](mobile/README.md). It includes native navigation, Supabase authentication, live listing reads, listing publishing with private image storage, favorites and direct conversations. Start with the setup guide in `mobile/README.md`.

The mobile app is a separate application from the static web prototype. It requires its own Supabase URL and anon/publishable key in `mobile/.env`; no service-role key belongs in the client. A native app build and device testing are still required before release.
