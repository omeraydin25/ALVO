# ALVO Mobil — Android & iOS

ALVO mobil uygulaması Expo + React Native + TypeScript + Supabase ile geliştirilir. Web prototipinin yanında ayrı bir uygulama olarak tutulur.

## Gereksinimler
- Node.js 22.13 veya üzeri (Expo SDK 58 gereksinimi)
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
Önce ana depodaki `supabase/migrations/20261107000000_initial_schema.sql` ve ardından `supabase/migrations/20261108000000_enable_message_realtime.sql` migration'larını Supabase SQL Editor'de güvenli bir geliştirme projesinde çalıştır. Mevcut canlı veritabanına uygulamadan önce yedek al ve eski `listings` tablosunun taşınmasını kontrol et. Migration henüz otomatik olarak çalıştırılmaz.

## Başlat
```bash
npx expo start
``
Terminaldeki QR kodunu Expo Go ile okut. Android emülatör için `npm run android`, iOS simülatör için macOS üzerinde `npm run ios`. Windows bilgisayardan iOS uygulaması derlemek için EAS bulut derlemesini kullan; yerel iOS Simulator/Xcode Windows'ta çalışmaz.

## Mağaza paketi

Expo SDK 58, React Native 0.88 ve Node.js 22.13+ kullanır. SDK 58 için fiziksel cihazda geliştirme/testte Expo Go yerine EAS development build kullanılması önerilir.
EAS hesabını bağladıktan sonra:
```bash
npx eas-cli@latest build:configure
npx eas-cli@latest build --platform android --profile preview
npx eas-cli@latest build --platform ios --profile preview
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
