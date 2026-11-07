# Supabase altyapısı — ALVO

Bu klasörde Supabase’e uygulanmaya hazır ilk veritabanı migrasyonu bulunur. Bu aşamada Supabase projesine bağlanılmamış, gerçek API anahtarı kullanılmamış ve frontend tasarımı değiştirilmemiştir.

## Dosyalar

- `migrations/20261107000000_initial_schema.sql` — tablolar, kısıtlar, indeksler, profil oluşturma tetikleyicisi, RLS politikaları, yetkiler ve özel görsel depolama bucket/politikaları.

## Şema özeti

| Tablo | Amaç |
| --- | --- |
| `profiles` | `auth.users` ile bire bir bağlı herkese açık profil alanları. Kullanıcı adı benzersizdir. Yönetici rolü içermez. |
| `listings` | İlan sahibi, başlık/açıklama, fiyat, kategori, Türkiye konumu ve taslak/yayında/satıldı/arşiv durumu. |
| `listing_images` | İlan fotoğraflarının Storage nesne yolu, alternatif metni ve sıralaması. |
| `favorites` | Kullanıcı başına özel favori ilanlar. |
| `conversations` | Bire bir veya grup konuşması kaydı. |
| `conversation_members` | Konuşma katılımcıları ve kullanıcının okuduğu son zaman. |
| `messages` | Konuşmaya bağlı, istemciden değiştirilemeyen mesaj kayıtları. |
| `reports` | İlan, profil veya mesaj için kullanıcı şikâyetleri; kullanıcı yalnızca kendi raporlarını görür. |

### Güvenlik tasarımı

- RLS, istenen sekiz uygulama tablosunun tamamında etkinleştirilir; `storage.objects` için de bucket’a özel RLS politikaları kurulur.
- Anonim ziyaretçiler yalnızca yayındaki ilanları, ilgili fotoğraf metaverisini ve herkese açık profil alanlarını okuyabilir. Taslak ilan/fotoğraflar herkese açık değildir.
- İlan ekleme, düzenleme ve silme işlemlerinde `seller_id = auth.uid()` zorunludur. İstemci `seller_id` değerini sonradan güncelleyemez.
- Favoriler yalnızca sahibi tarafından okunur, eklenir ve silinir.
- Konuşmalar ve mesajlar yalnızca katılımcılara açıktır. Kullanıcı kendisini mevcut bir konuşmaya ekleyemez; konuşma sahibi katılımcı satırlarını oluşturur. Mesajlar istemciden güncellenemez/silinemez.
- Şema `profiles` içine `role`, `is_admin` gibi bir istemci tarafından yazılabilir ayrıcalık alanı eklemez. İleride yönetici erişimi gerekirse rol, kullanıcı tarafından değiştirilemeyen `auth.app_metadata` veya sunucu tarafı ACL ile, yalnızca güvenilir backend üzerinden yönetilmeli; `user_metadata` yetkilendirme kaynağı yapılmamalıdır.
- Görseller `listing-images` adlı **private** bucket’a `<auth.uid()>/<listing_uuid>/<dosya>` biçiminde yüklenir. Yükleme, değiştirme ve silme yolu kullanıcı sahipliğine göre; yükleme ayrıca ilan sahipliğine göre denetlenir. Anonim görsel okuması yalnızca aktif bir ilana `listing_images` üzerinden bağlanmış nesnelere izin verir.
- İstemciye yalnızca Supabase’in publishable/anon anahtarı verilebilir; service-role/secret anahtar yalnızca güvenli sunucu ortamında tutulmalıdır. Bu depoda hiçbir anahtar yoktur.

## Supabase’e uygulama

### Supabase CLI ile (tercih edilen)

1. Yerel geliştirme ortamında Supabase CLI kurun ve `supabase login` ile kendi hesabınızda oturum açın. Bu, bu değişiklik kapsamında yapılmamıştır.
2. Depo kökünden `supabase init` çalıştırmayın; migrasyon dizini zaten hazır. Gerekirse CLI proje dosyasını ayrıca ekip kararıyla ekleyin.
3. Yeni bir Supabase projesi oluşturduktan sonra CLI’ı projeye bağlayın: `supabase link --project-ref <proje-ref>`.
4. Migrasyonu uygulamak için `supabase db push` çalıştırın. Önce geliştirme projesinde deneyin, SQL yedeği ve inceleme olmadan üretime uygulamayın.

CLI kullanmadan: Supabase Dashboard → **SQL Editor** → **New query** bölümünde migrasyon SQL’ini açıp çalıştırın. Çalıştırmadan önce hedef projenin doğru olduğundan ve yedek/ortam politikasından emin olun.

### Storage ve doğrulama

Migrasyon `listing-images` private bucket’ını oluşturur (mevcut bucket varsa ayarlarını değiştirmez); bucket limitleri yeni bucket için 5 MiB ve JPEG/PNG/WebP’dir. Supabase Dashboard → **Storage** bölümünden bucket’ın private olduğunu ve limit/MIME türlerini doğrulayın. SQL başarıyla çalıştıktan sonra Table Editor’da 8 tabloyu, Authentication → Users’da yeni kullanıcı sonrası profil tetikleyicisini ve her tablonun RLS durumunu kontrol edin.

RLS’i test etmek için Supabase SQL Editor’da yönetici rolüyle yapılan sorgu yeterli değildir. Gerçek kullanıcı JWT’leriyle istemci/API üzerinden şu senaryoları ayrı ayrı test edin: kullanıcı A taslak ilanını görebilir/düzenleyebilir; kullanıcı B bunu yapamaz; B aktif ilanı okuyabilir; B A’nın favorilerini veya özel konuşmalarını okuyamaz; A başka kullanıcının ilan fotoğrafı yoluna yükleme yapamaz. Yönetici/Service Role anahtarını tarayıcıda veya bu testlerin istemci kodunda kullanmayın.

## Önemli sınırlar ve sonraki işler

Bu migrasyon veritabanı ve Storage güvenlik temelini sağlar; mevcut statik `app.js` henüz Supabase istemcisine bağlanmamıştır. Mevcut demo giriş ve yerel depolama akışı bu nedenle olduğu gibi çalışır. İlan moderasyonu, güvenilir yönetici operasyonları, doğrudan konuşma başlatma için atomik RPC, mesaj hız sınırları, spam önleme, fotoğraf nesneleri için yetim-temizleme işi, arama için metin indeksleri ve hukuki/operasyonel gereklilikler ayrı geliştirme ve test adımlarıdır.
