# ALVO Mobil — Android & iOS

ALVO mobil uygulaması Expo + React Native + TypeScript + Supabase ile geliştirilir. Web prototipinin yanında ayrı bir uygulama olarak tutulur.

## Gereksinimler
- Node.js LTS
- Expo Go (ilk test için) veya Android Studio / Xcode
- Supabase projesi

## Kurulum
```bash
cd mobile
npm install
```

`mobile/.env.example` dosyasını `.env` olarak kopyala ve Supabase proje URL'si ile **anon/publishable** anahtarını ekle:

```env
EXPO_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Service-role anahtarını mobil uygulamaya kesinlikle koyma. Mobil uygulama public istemci olduğu için erişim RLS politikalarıyla korunmalıdır.

## Veritabanı
Önce ana depodaki `supabase/migrations/20261107000000_initial_schema.sql` migration'ını Supabase SQL Editor'de güvenli bir geliştirme projesinde çalıştır. Mevcut canlı veritabanına uygulamadan önce yedek al ve eski `listings` tablosunun taşınmasını kontrol et. Migration henüz otomatik olarak çalıştırılmaz.

## Başlat
```bash
npx expo start
``
Terminaldeki QR kodunu Expo Go ile okut. Android emülatör için `npm run android`, iOS simülatör için macOS üzerinde `npm run ios`.

## Mağaza paketi
EAS hesabını bağladıktan sonra:
```bash
npx eas build:configure
npx eas build --platform android --profile preview
npx eas build --platform ios --profile preview
``

## Şu anki kapsam
- Ana sayfa ve canlı ilan akışı
- Kategori ve metin araması
- İlan detay ekranı
- E-posta/şifre ile Supabase kayıt ve giriş
- Fotoğraf seçme, private Storage'a yükleme ve ilan kaydı
- Favori ekleme/çıkarma ve listeleme
- Profil, çıkış ve sohbet listesi
- Satıcıyla gerçek mesaj gönderme ve Supabase Realtime üzerinden yeni mesajları alma
- Android/iOS uyumlu sekmeli gezinme

## Henüz tamamlanmayanlar
- Realtime mesajların çalışması için Supabase Dashboard'da `messages` tablosunun `supabase_realtime` publication'a eklenmesi gerekir.
- Satıcı ilanlarını yönetme, düzenleme ve silme
- Push bildirimleri, moderasyon ve mağaza yayınlama
- Uygulama cihazlarda çalıştırılıp test edilmedi; build alınmadı.
