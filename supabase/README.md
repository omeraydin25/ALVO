# Supabase altyapısı — ALVO

Bu klasörde Supabase’e uygulamaya hazır veritabanı migrasyonu bulunur. Bu değişiklik hiçbir Supabase projesine bağlanmaz ve veritabanında kendiliğinden SQL çalıştırmaz.

## Migration dosyası

`migrations/20261107000000_initial_schema.sql` temiz projede ve ALVO’nun eski `public.listings` şeması bulunan projede kullanılacak biçimde hazırlanmıştır. Eski tabloda `user_id`, `image_url` gibi alanlar olup `seller_id` yoksa migration tabloyu **silmeden** `listings_legacy_backup_20261108` adına yeniden adlandırır. Tüm kayıt ve sütunlar korunur; eski politikalar/grant’ler kaldırılır, RLS etkinleştirilip zorlanır. Sonrasında yeni `public.listings` oluşturulur.

Yedek adı zaten kullanılıyorsa veya tablo tanınmayan bir şemadaysa migration güvenli şekilde hata verip durur; mevcut tabloya müdahale ederek üzerine yazmaz. Eski ilan verisi otomatik olarak yeni tabloya taşınmaz; yedek tablo korunur ve ayrı bir veri eşleme/aktarım işi gerekir. `image_url`, `condition`, `negotiable` ve `images` değerleri yedek tablodan silinmez.

> Tabloyu yeniden adlandırmak veriyi aynı veritabanında saklayan mantıksal korumadır, bağımsız fiziksel yedek değildir. Üretim uygulamasından önce Supabase yedeği/PITR veya `pg_dump` alın ve kurtarma adımını doğrulayın.

## Tablolar ve erişim

`profiles`, `listings`, `listing_images`, `favorites`, `conversations`, `conversation_members`, `messages`, `reports` tabloları oluşturulur. Hepsinde RLS etkinleştirilir. İlan sahibi dışında kullanıcı ilanı değiştiremez; kullanıcılar favorilerini ve şikâyetlerini başkalarından gizli tutar. Konuşma ve mesaj okuması üyelikle sınırlandırılır. Direkt konuşma `start_listing_conversation(listing_id)` güvenli RPC’siyle, aktif ilanın alıcısı/satıcısı için atomik olarak başlatılır; istemciler doğrudan katılımcı ekleyemez. İstemciye yönetici rolü veren bir profil alanı yoktur.

`listing-images` private bucket olarak oluşturulur veya var olan aynı adlı bucket private ve izin verilen görsel türleriyle sınırlandırılır. Nesne yolu `<auth.uid()>/<listing_uuid>/<filename>` olmalıdır; yazma/silme kullanıcı sahipliği ve yüklemede ilan sahipliğiyle denetlenir. Anonim okuma yalnızca aktif ilana bağlı fotoğraflara izin verir.

Yönetici/Service Role anahtarı RLS’i aşabileceğinden asla HTML, JavaScript, Git geçmişi veya mobil uygulama paketine konulmamalıdır. Tarayıcıda yalnızca publishable/anon anahtarı kullanılabilir; erişim kontrolünün temeli RLS’dir.

## SQL’i güvenli uygulama

1. Önce **hedef Supabase projesinde** yedek alın ve eski `public.listings` şemasını doğrulayın. Bu migration dışındaki ilişkili tablolar eski `listings` tablosuna FK ile bağlıysa, rename sonrasında eski yedek tabloya bağlı kalabilir; bu ilişkileri de inceleyin.
2. Önce geliştirme projesinde deneyin. Supabase Dashboard → **SQL Editor** → **New query** bölümünde yukarıdaki migration dosyasının tamamını çalıştırın. SQL Editor tek seferde çalıştırılabilir.
3. CLI kullanıyorsanız depo kökünde Supabase CLI kurup `supabase login` ve `supabase link --project-ref <proje-ref>` adımlarını tamamlayın; migrasyon geçmişinizin mevcut durumunu kontrol edin. `supabase db push` yalnızca doğru, yedeklenmiş hedef projeye yöneldiğinizden emin olduktan sonra uygulanmalıdır. Bu depo aşamasında CLI’a bağlanılmamış veya komut çalıştırılmamıştır.
4. Başarıdan sonra Table Editor’da `listings_legacy_backup_20261108` satır adedi/eski alanları, yeni `listings` şemasını ve sekiz tablonun RLS durumunu kontrol edin. Storage’da bucket’ın private olduğunu doğrulayın.
5. İki gerçek test kullanıcısının JWT’siyle denetleyin: A taslak ilanını görebilir/değiştirebilir, B değiştiremez; B aktif ilanı okuyabilir; B A’nın favorilerini veya özel mesajlarını okuyamaz; kullanıcı başka birinin fotoğraf yoluna yükleme yapamaz. SQL Editor’da yönetici sorgusu tek başına RLS testi değildir.

## Sonraki entegrasyon

Ön yüz henüz Supabase istemcisine bağlanmamıştır; mevcut demo akışı `localStorage` kullanır. Eski ilan yedeğini yeni şemaya aktarmak için kullanıcı eşlemesi, kategori/durum dönüşümü, `image_url`/`images` fotoğraf aktarımı ve kayıp veriye dair kararlar içeren ayrıca incelenebilir bir data migration hazırlanmalıdır.
