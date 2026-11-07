# ALVO

**İkinci elin yeni adresi.** ALVO, Türkiye genelinde ücretsiz ikinci el ilanlarını keşfetmek ve yayınlamak için tasarlanan, Türkçe ve mobil uyumlu bir pazar yeri arayüzü prototipidir.

## Özellikler

- Light tema, duyarlı (mobil/tablet/masaüstü) tasarım ve çalışan mobil menü
- Ana sayfa, kategori listesi, arama sonuçları ve ilan detayları
- Elektronik, Telefon, Bilgisayar, Ev ve Yaşam, Moda, Giyim, Araç, Yedek Parça, Spor, Hobi, Anne ve Bebek, Diğer kategorileri
- Örnek ilanlar; başlık, kategori ve şehir içinde arama; kategori filtreleme ve fiyata göre sıralama
- Ücretsiz ilan formu, fotoğraf önizleme ve tarayıcıda küçültülmüş fotoğraf saklama
- Favoriler, demo profil/kayıt ekranı, mesajlar ve Hakkımızda/İletişim/Kullanım Koşulları/Gizlilik sayfaları
- Harici JavaScript kütüphanesi, ücretli servis veya derleme adımı gerektirmez

## Çalıştırma

Dosyaları indirin ve `index.html` dosyasını güncel bir tarayıcıda açın. Alternatif olarak kök dizinde basit bir yerel sunucu başlatın:

```bash
python3 -m http.server 8000
```

Ardından `http://localhost:8000` adresine gidin. GitHub Pages üzerinde yayımlamak için repository ayarlarında Pages kaynağı olarak `main` dalı ve kök dizin seçilebilir.

## Prototip sınırları

Bu sürüm statik HTML/CSS/JavaScript ile çalışan bir ön yüz prototipidir. İlanlar, favoriler ve demo hesap bilgileri yalnızca aynı tarayıcıdaki `localStorage` alanında saklanır; site verisi silinirse kaybolur ve diğer kullanıcılarla senkronize olmaz. Gerçek kullanıcı kimlik doğrulaması, sunucu/veritabanı, fotoğraf yükleme servisi, satıcıya gerçek mesaj gönderimi, moderasyon, ödeme ve işlem güvencesi henüz bağlı değildir. Mesajlar sayfasındaki içerik örnektir; iletişim formu da gerçek e-posta göndermez. Yayına çıkmadan önce backend, güvenlik, kötüye kullanım önlemleri, hukuki metinler ve erişilebilirlik ayrıca tamamlanmalıdır.

## Dosyalar

- `index.html` — Türkçe sayfa iskeleti ve uygulama giriş noktası
- `styles.css` — Tasarım sistemi ve tüm ekran boyutlarına uyumlu stiller
- `app.js` — Hash tabanlı sayfa yönlendirme, örnek ilanlar, arama/filtre ve tarayıcı içi etkileşimler
