# Bi Nasip — Yazılım Gereksinimleri Belirtimi (SRS)

**Doküman türü:** Software Requirements Specification, IEEE 830 yapısına gevşek şekilde uyarlanmıştır.
**Durum:** Taslak — kapalı beta geliştirme aşaması. Bu doküman [`REQUIREMENTS.md`](REQUIREMENTS.md)'deki ürün kararlarını biçimselleştirir ve genişletir; iki doküman çelişirse **REQUIREMENTS.md güncel kabul edilir**, bu SRS ondan türetilmiştir.
**Son güncelleme bağlamı:** Kayıt sihirbazı, Keşfet, eşleşmeler, sohbet, ayarlar ve aile ekranları yeniden tasarlandıktan; telefon/OTP, profil, eşleştirme, mesajlaşma, güvenlik, hesap ve aile özellikleri Firestore'a taşındıktan; Günün Sorusu akışı (FR-9) ve bekâr kullanıcılar için alt sekme çubuğu eklendikten; "aileme göster" anahtarı kutlama ve sohbet ekranlarına, veli ekranı da niyet ve bağlı kişi bilgisine kavuştuktan sonraki durumu yansıtır. Bölüm 8 hangi parçanın gerçek, hangisinin yer tutucu (mock) olduğunu ayrıca listeler — bir gereksinimin "kuruldu" sayılması onun üretime hazır olduğu anlamına gelmez.

---

## 1. Giriş

### 1.1 Amaç

Bu doküman, Bi Nasip mobil/web uygulamasının yazılım gereksinimlerini; paydaşların (geliştirici, tasarımcı, hukuk danışmanı, ileride katılacak ekip üyeleri) ortak bir referans olarak kullanabileceği biçimde tanımlar. Kapsamı: ürünün amacı, hedef kullanıcıları, fonksiyonel ve fonksiyonel olmayan gereksinimleri, veri modeli, dış arayüzler ve bilinen açık kararlar/sınırlamalar.

### 1.2 Kapsam

**Ürün adı:** Bi Nasip ("herkesin bir nasibi var")
**Ürün türü:** Evlilik niyetli, mahremiyet öncelikli, Türkiye odaklı tanışma/eşleştirme uygulaması.
**Platform:** Flutter ile tek kod tabanından Android, iOS ve Web; proje adı `binasip`.
**Kapsam dışı (v1):** Genel App Store/Play Store herkese açık lansman — v1 yalnızca davetiye kodlu kapalı beta, ilk 500 kullanıcı hedefiyle. Sesli/görüntülü arama, async video mesaj, canlı etkinlik/hızlı tanışma özellikleri, gelişmiş AI eşleştirme, çoklu dil desteği ve namaz vakti/Ramazan takvimi entegrasyonu v2+'ya bırakılmıştır (bkz. §2.4).

Ürün üç temel ilke üzerine kuruludur:

1. **Niyet baştan belli** — her profil "Evlilik" veya "Henüz emin değilim" niyetini açıkça taşır; flört/casual seçeneği yoktur.
2. **Mahremiyet kullanıcının elinde** — fotoğraflar varsayılan olarak gizlidir, kişiler gradyan + baş harf avatarıyla gösterilir; görünürlük kullanıcının seçtiği kademeli bir ayardır.
3. **Aile katılımı opsiyonel** — bir yakın (veli) hesabı, yalnızca kullanıcının açıkça "aileme göster" işaretlediği eşleşmeleri, salt okunur ve mesaj içeriği olmadan görebilir.

### 1.3 Tanımlar, Kısaltmalar ve Terimler

| Terim | Açıklama |
|---|---|
| **KVKK** | 6698 sayılı Kişisel Verilerin Korunması Kanunu (Türkiye) |
| **FR** | Fonksiyonel Gereksinim (Functional Requirement), bu dokümanda ve `REQUIREMENTS.md`'de aynı numaralandırmayla kullanılır (FR-1…FR-9) |
| **NFR** | Fonksiyonel Olmayan Gereksinim (Non-Functional Requirement) |
| **Tekil hesap (single)** | Kendisi için eş arayan kullanıcı hesabı türü |
| **Veli/yakın hesabı (guardian)** | Kendisi eşleşmeyen, bağlı olduğu bir tekil hesabın izin verdiği eşleşmeleri salt okunur izleyen hesap türü |
| **Mock veri kaynağı** | Gerçek bir backend/sağlayıcıya bağlı olmayan, bellek içi veya sabit kodlu yer tutucu implementasyon |
| **Firestore** | Google Cloud Firestore — uygulamanın gerçek backend veritabanı |
| **Spark plan** | Firebase'in ücretsiz katmanı; Cloud Functions içermez (bkz. §2.5, §7.3) |
| **Liveness doğrulama** | Bir selfie'nin gerçek, canlı bir kişiye ait olduğunu (kimlik belgesi değil) doğrulayan kontrol |

### 1.4 Referanslar

- [`docs/REQUIREMENTS.md`](REQUIREMENTS.md) — ürün gereksinimlerinin birincil kaynağı, persona'lar, veri modeli taslağı, açık kararlar.
- [`README.md`](../README.md) — kurulum, mimari özeti, gerçek/mock durumu, test talimatları.
- [`firestore.rules`](../firestore.rules) — güvenlik kurallarının yürürlükteki kaynağı; bu SRS'teki erişim kontrolü ifadeleri onunla çelişirse kurallar dosyası esas alınır.
- 6698 sayılı KVKK ve ilgili ikincil mevzuat.

### 1.5 Genel Bakış

Bölüm 2 ürünü ve kullanıcılarını genel hatlarıyla tanıtır. Bölüm 3 dış arayüzleri tanımlar. Bölüm 4 fonksiyonel gereksinimleri (FR-1…FR-9) girdi/işlem/çıktı ve kabul kriterleriyle detaylandırır. Bölüm 5 fonksiyonel olmayan gereksinimleri kapsar. Bölüm 6 veri modelini verir. Bölüm 7 bilinen mimari sınırlamaları, Bölüm 8 gerçek-vs-mock durumunu, Bölüm 9 açık kararları listeler.

---

## 2. Genel Açıklama

### 2.1 Ürün Perspektifi

Bi Nasip bağımsız, yeni geliştirilen bir mobil/web uygulamasıdır; mevcut bir sistemin parçası değildir. Backend olarak Firebase (Authentication + Cloud Firestore) kullanır; ücretsiz Spark planında çalışır, bu nedenle sunucu taraflı mantığın bir kısmı (Cloud Functions gerektiren atomik işlemler, gerçek fotoğraf moderasyonu) istemci tarafı kurallarla veya yer tutucularla karşılanır (bkz. §7).

Rakip konumlandırması: küresel Müslüman tanışma uygulamaları yerel (Türkiye) bağlamı yakalamaz; yerel Türk tanışma uygulamaları dini kimliği merkeze almaz. Bi Nasip bu ikisi arasındaki boşluğu hedefler.

### 2.2 Ürün Fonksiyonları (özet)

| # | Fonksiyon | Özet |
|---|---|---|
| FR-1 | Onboarding & Kimlik Doğrulama | Davetiye kodu, KVKK rızası, telefon+SMS OTP, selfie-liveness |
| FR-2 | Profil Oluşturma | Fotoğraf, niyet, temel bilgiler, opsiyonel dini bilgiler |
| FR-3 | Mahremiyet/Modesty Kontrolleri | Kademeli fotoğraf görünürlüğü |
| FR-4 | Eşleştirme | Filtreli keşif, karşılıklı beğeni, günlük limit |
| FR-5 | Mesajlaşma | Eşleşen kullanıcılar arası metin sohbeti, aile/buluşma nudge'ı |
| FR-6 | Güven & Güvenlik | Şikayet, engelleme, fotoğraf moderasyonu |
| FR-7 | Hesap & Veri | Hesap silme, doğrulama verisinin izolasyonu |
| FR-8 | Veli/Aile Hesabı | Ayrı hesap türü, davet koduyla bağlanma, salt okunur görünürlük |
| FR-9 | Günün Sorusu Akışı | Günde tek soru, üye başına tek kısa cevap, yalnızca beğeni |

Bu fonksiyonların her biri Bölüm 4'te girdi/işlem/çıktı/kabul kriterleriyle detaylandırılmıştır.

### 2.3 Kullanıcı Özellikleri

| Persona | Yaş/Şehir | Birincil ihtiyaç |
|---|---|---|
| Ayşe | 27, İstanbul | Aile onayı ile kendi tercihi arasında denge; modesty-first foto kontrolü |
| Burak | 31, Ankara | Dini pratik sorularının zorlayıcı olmaması; mezhep opsiyonel filtre |
| Zeynep | 29, Berlin (diaspora) | Çift kimlik (Türk + Müslüman), diaspora şehir erişimi, çok dilli destek (v2) |
| Elif | 26, İzmir | Güvenilir doğrulama, net niyet, sahte profil riskinden korunma |

İki hesap türü vardır ve her biri ürünü farklı amaçla kullanır:

- **Tekil kullanıcı** — kendisi için eş arayan, FR-2/FR-3/FR-4/FR-5/FR-9 akışlarının tamamına erişen kullanıcı.
- **Veli/yakın kullanıcı** — kendisi evli/eşleşmeyen, bir tekil hesabın izin verdiği ölçüde süreci izleyen kullanıcı; FR-2/FR-3/FR-4/FR-5/FR-9'un hiçbirine erişemez (bkz. FR-8.6, FR-9.5).

### 2.4 Kısıtlamalar

- v1 yalnızca Türkçe arayüzlüdür; çok dilli destek v2+ kapsamındadır.
- v1 kapalı betadır — genel mağaza lansmanı yoktur, erişim yalnızca davetiye kodu veya bekleme listesi üzerinden sağlanır.
- Video/sesli arama, async video mesaj, canlı etkinlik özellikleri ve gelişmiş AI eşleştirme v1 kapsamı dışındadır.
- Uygulama Firebase Spark (ücretsiz) planında çalışır; Cloud Functions yoktur (bkz. §2.5, §7.3).

### 2.5 Varsayımlar ve Bağımlılıklar

- Firebase Authentication (telefon/SMS) ve Cloud Firestore'un kullanılabilir ve Türkiye'den erişilebilir olduğu varsayılır.
- Selfie-liveness doğrulaması için üçüncü taraf bir sağlayıcı (örn. Veriff/Yoti/Didit) entegrasyonu planlanmıştır ancak **henüz bağlanmamıştır** (bkz. §8); bu sağlayıcının KVKK uyumlu bir veri işleme sözleşmesi sunması varsayımına dayanır.
- Gerçek fotoğraf yükleme/depolama ve gerçek görüntü moderasyonu, Firebase Storage + Cloud Vision benzeri bir servis gerektirir; bunlar Firebase'in ücretli (Blaze) planına geçişe bağımlıdır. Bu geçiş şu an için kullanıcı tarafından bilinçli olarak ertelenmiştir.
- KVKK rıza metninin hukuken geçerli olması, bir hukuk danışmanının incelemesine bağımlıdır (bkz. §9).

---

## 3. Dış Arayüz Gereksinimleri

### 3.1 Kullanıcı Arayüzleri

- Uygulama Material 3 tabanlıdır; "Gece Moru" tasarım sistemini kullanır (canlı mor → mercan marka geçişi, logodan gelen turkuaz ve bakır ikincil renkler, sıcak krem zemin), açık ve koyu temayı destekler.
- Tipografi: Fraunces (başlıklar/display), Sora (arayüz metni).
- Görsel dil kasıtlı olarak genç ve canlı tutulmuştur: iki renkli gradyanlar, yuvarlak köşeler (kart ~30px, buton ~18px), gradyanlı ana aksiyon butonları, hafif hareket efektleri (kart sürükleme, eşleşme kutlaması). Düz yeşil ve yıldız/sekizgen-yıldız biçimli motifler kullanılmaz; logodaki turkuaz serbesttir (bkz. REQUIREMENTS.md §6 için gerekçe).
- **Gezinme:** Tekil kullanıcının ana ekranı dört sekmeli, yüzen bir alt çubuktur — Keşfet (`/discover`), Günün Sorusu (`/feed`), Eşleşmeler (`/matches`), Hesap (`/account`). Her sekme kendi gezinme yığınını ve durumunu korur; bulunulan sekmeye tekrar basmak o sekmenin başına döner. Sohbet ve aile ayarları gibi tam ekran sayfalar çubuğu örter. Okunmamış mesaj varken Eşleşmeler sekmesinin (bkz. FR-5.3), bugünün sorusu cevaplanmadıysa Günün Sorusu sekmesinin (bkz. FR-9.7) ikonunda bir nokta görünür. Veli hesabında sekme çubuğu yoktur; tek bir ana ekran ve ondan açılan ayarlar sayfası vardır.
- Mahremiyet ilkesi gereği kişiler gerçek fotoğraf yerine gradyan + baş harf avatarıyla temsil edilir.
- Paylaşılan arayüz bileşenleri (`WizardHeader`, `GradientButton`, `OptionCard`, `SectionCard`, `SummaryBand` vb.) `lib/theme/wizard_widgets.dart`'ta tanımlıdır ve uygulama içi `/design-preview` sayfasında (yalnızca debug derlemede) açık/koyu tema anahtarıyla canlı olarak incelenebilir.
- Erişilebilirlik hedefi: WCAG AA metin kontrastı, minimum 44×44pt dokunma hedefleri.

### 3.2 Donanım Arayüzleri

- Mobilde cihaz kamerası, fotoğraf seçimi (`image_picker`) ve (ileride) selfie-liveness adımı için kullanılır. v1'de selfie adımı gerçek kamera açmaz (bkz. §8).
- Özel bir donanım bağımlılığı yoktur.

### 3.3 Yazılım Arayüzleri

| Bileşen | Teknoloji |
|---|---|
| Kimlik doğrulama | Firebase Authentication — Telefon/SMS OTP |
| Veritabanı | Cloud Firestore (bölge: `eur3`) |
| Durum yönetimi | `flutter_bloc` (Cubit) |
| Bağımlılık enjeksiyonu | `get_it` |
| Yönlendirme | `go_router` |
| Planlanan, henüz bağlı değil | Üçüncü taraf selfie-liveness sağlayıcısı; Firebase Storage; görüntü moderasyon API'si |

### 3.4 İletişim Arayüzleri

- İstemci–Firebase arası iletişim HTTPS üzerinden, Firebase SDK'ları aracılığıyla yapılır.
- SMS OTP teslimatı Firebase Authentication altyapısı üzerinden sağlanır; uygulama SMS içeriğini doğrudan yönetmez.
- Uygulama şu an için harici bir REST/GraphQL API sunmaz veya tüketmez (üçüncü taraf doğrulama sağlayıcısı bağlandığında bu bölüm genişletilmelidir).

---

## 4. Fonksiyonel Gereksinimler

Her gereksinim; **girdi**, **işlem**, **çıktı/kabul kriteri** ve mevcut **uygulama durumu** ile verilmiştir. Numaralandırma `REQUIREMENTS.md` ile birebir eşleşir.

### FR-1 — Onboarding & Kimlik Doğrulama

**Amaç:** Yalnızca davetiyeli, rızası alınmış ve doğrulanmış kullanıcıların uygulamaya erişmesini sağlamak.

| # | Gereksinim | Girdi | İşlem | Çıktı / Kabul Kriteri |
|---|---|---|---|---|
| FR-1.1 | Telefon + SMS OTP ile kayıt | Telefon numarası, SMS ile gelen kod | Firebase Phone Auth ile doğrulama | Geçerli kodla oturum açılır; hatalı/süresi dolmuş kodda anlaşılır hata mesajı gösterilir |
| FR-1.2 | Zorunlu selfie-liveness doğrulaması | Kullanıcının selfie'si | Üçüncü taraf sağlayıcıya gönderim, yalnızca `verified: true/false` + zaman damgası geri alınır | Ham selfie/biyometrik veri Bi Nasip altyapısında hiçbir zaman saklanmaz; mümkünse sağlayıcının yaş tahmini özelliği kullanılır, görüntü işlem sonrası saklanmaz |
| FR-1.3 | Davetiye kodu kontrolü | Davetiye kodu | Kod geçerliliği kontrolü | Geçersiz/eksik kodda kullanıcı bekleme listesi akışına yönlendirilir |
| FR-1.5 | İki kapılı giriş | "Davetiye kodum var" (yeni kayıt) ya da "Hesabım var" (giriş) | Yeni kayıt mevcut sırayı izler; giriş yalnızca telefon + SMS kodu ister ve kayıtlı hesabı arar | Kayıtlı kullanıcı davetiye kodu, hesap türü ve rıza adımlarını yeniden doldurmadan, kayıtlı hesap türüyle içeri alınır; numaranın hesabı yoksa kullanıcı giriş ekranına döner, kayda yönlendirilir ve denemeden geriye hesap kalmaz |
| FR-1.4 | KVKK rızası, telefon istenmeden önce | — | Aydınlatma metni gösterimi, iki ayrı açık rıza (veri işleme + yurt dışı aktarım) | İki rıza da onaylanmadan akış ilerlemez; rıza Firestore'da `consents/{uid}` altında kayıt altına alınır |

**Kabul kriteri (uçtan uca):** Yeni bir kullanıcı davetiye kodu → hesap türü seçimi → KVKK rızası → telefon → OTP → selfie adımını tamamlamadan profil oluşturma veya keşif ekranına erişemez. Kayıtlı bir kullanıcı "Hesabım var" kapısından telefon → OTP ile, başka hiçbir adım doldurmadan uygulamaya girer; aynı kapı kayıtsız bir numarayı içeri almaz.

### FR-2 — Profil Oluşturma

| # | Gereksinim | Girdi | İşlem | Çıktı / Kabul Kriteri |
|---|---|---|---|---|
| FR-2.1 | Fotoğraf ekleme | 1–6 fotoğraf | Seçim ve önizleme | En az 1 fotoğraf olmadan sonraki adıma geçilemez |
| FR-2.2 | Niyet seçimi | "Evlilik" veya "Henüz emin değilim" | Seçim kaydı | Casual/flört seçeneği sunulmaz (pozisyonlama gereği) |
| FR-2.3 | Temel bilgiler | Ad, doğum tarihi, şehir, eğitim/meslek (opsiyonel), dini pratik notu (opsiyonel), mezhep (opsiyonel) | Form doğrulama ve kayıt | Ad/doğum tarihi/şehir zorunlu; mezhep eşleştirmede opsiyonel bir filtre olarak sunulur (varsayılan "farketmez"), serbest metin de desteklenir |
| FR-2.4 | "Aileme açığım" genel sinyali | Açık/kapalı toggle | Profil alanına kayıt | Varsayılan kapalı; tek başına hiçbir eşleşme verisini açığa çıkarmaz — eşleşme bazlı görünürlük ayrıca FR-8.4 ile belirlenir |

**Hassas veri notu (KVKK m.6):** Dini pratik notu veya mezhep alanı doldurulduğunda (ve mezhep değeri salt "Belirtmek istemiyorum" değilse), kullanıcıdan bu özel nitelikli verinin işlenmesi için ayrı bir açık rıza istenir; onay verilmeden forma devam edilemez.

### FR-3 — Mahremiyet / Modesty Kontrolleri

| # | Gereksinim | Girdi | İşlem | Çıktı / Kabul Kriteri |
|---|---|---|---|---|
| FR-3.1 | Kademeli fotoğraf görünürlüğü | Görünürlük seviyesi seçimi | Profile kayıt | Üç seviye: "eşleşince otomatik", "ben açana kadar gizli", "sadece istek üzerine" |
| FR-3.2 | Varsayılan en kısıtlı seviye | — | Yeni profil oluşturulurken varsayılan atama | Kullanıcı opt-in ile genişletir; opt-out mekanizması yoktur |

### FR-4 — Eşleştirme

| # | Gereksinim | Girdi | İşlem | Çıktı / Kabul Kriteri |
|---|---|---|---|---|
| FR-4.1 | Filtreli aday listesi | Şehir, yaş aralığı, niyet filtreleri | Aday sorgusu | Filtrelere uyan, daha önce beğenilmemiş/geçilmemiş ve engellenmemiş adaylar listelenir |
| FR-4.2 | Karşılıklı beğeni → eşleşme | İki taraflı "beğen" aksiyonu | Eşleşme kaydı oluşturma | Eşleşme oluşunca kutlama ekranı gösterilir ve sohbete giriş sağlanır |
| FR-4.3 | Günlük beğeni limiti | — | Günlük beğeni sayacı | Bir kullanıcı günde en fazla **12** tek taraflı beğeni yapabilir; limit aşıldığında işlem reddedilir |

**Kabul kriteri:** Aday kartı hem sürükleyerek (sola geç/sağa beğen) hem de buton ile işlenebilir; 13. beğeni denemesi aynı gün içinde reddedilir.

### FR-5 — Mesajlaşma

| # | Gereksinim | Girdi | İşlem | Çıktı / Kabul Kriteri |
|---|---|---|---|---|
| FR-5.1 | Eşleşenler arası metin sohbeti | Mesaj metni | Gönderim ve kayıt | Yalnızca karşılıklı eşleşmiş kullanıcılar birbirine mesaj gönderebilir |
| FR-5.2 | Aile/buluşma önerisi nudge'ı | Mesaj sayısı/süre | Eşik kontrolü (30 mesaj VEYA 7 gün, hangisi önce gerçekleşirse) | Tek seferlik, kapatılabilir, zorlayıcı olmayan bir öneri kartı gösterilir; aynı sohbette tekrar gösterilmez |
| FR-5.3 | Okunmamış işareti | Karşı taraftan gelen son mesaj, kullanıcının sohbeti son açma zamanı | Karşılaştırma (canlı dinleyici) | Okunmamış sohbet eşleşme listesinde nokta ile işaretlenir; en az bir okunmamış sohbet varken alt çubuktaki Eşleşmeler sekmesinde de nokta görünür (kullanıcı başka sekmedeyken de). Sohbet açılınca ikisi de kaybolur; kullanıcının kendi son mesajı okunmamış sayılmaz |

### FR-6 — Güven & Güvenlik

| # | Gereksinim | Girdi | İşlem | Çıktı / Kabul Kriteri |
|---|---|---|---|---|
| FR-6.1 | Şikayet | Hedef kullanıcı, sebep, opsiyonel not | Şikayet kaydı oluşturma | Şikayet hiçbir istemci tarafından (şikayet eden dahil) geri okunamaz; yalnızca yönetici erişimiyle incelenir |
| FR-6.2 | Engelleme | Hedef kullanıcı | Engel kaydı oluşturma | Engellenen kullanıcı, engelleyenin keşif/eşleşme listelerinden anında kaldırılır |
| FR-6.3 | Fotoğraf moderasyonu | Yüklenen fotoğraf | Otomatik içerik kontrolü | Uygunsuz içerik otomatik reddedilir (bkz. §8 — şu an yer tutucu kuralla çalışır) |

### FR-7 — Hesap & Veri

| # | Gereksinim | Girdi | İşlem | Çıktı / Kabul Kriteri |
|---|---|---|---|---|
| FR-7.1 | Hesap ve veri silme | Kullanıcı onayı | Profil, herkese açık profil, kullanıcı belgesi, aile bağlantısı kayıtlarının ve kimlik doğrulama hesabının silinmesi | Silme sonrası aynı telefon numarasıyla tekrar kayıt, tamamen yeni bir hesap olarak başlar |
| FR-7.2 | Doğrulama verisinin izolasyonu | — | Mimari ayrım | Yalnızca `verified`/zaman damgası saklanır; ham selfie/biyometrik veri hiçbir zaman Bi Nasip altyapısında tutulmaz |

**Not:** FR-7.1 kapsamında beğeniler, eşleşmeler ve mesajlar — her iki tarafa da ait olmaları ve Cloud Functions olmadan atomik/çift taraflı silme yapılamaması nedeniyle — silinmez; karşı taraf bu kayıtları silinmiş kullanıcı için yer tutucu bir etiketle ("Kullanıcı") görmeye devam edebilir (bkz. §7.3).

### FR-8 — Veli/Aile Hesabı

**Senaryo:** Kullanıcı zaten evlidir, kendisi için eş aramaz; bir yakınının (örn. çocuğunun) sürecini, o izin verdiği ölçüde takip etmek ister.

| # | Gereksinim | Girdi | İşlem | Çıktı / Kabul Kriteri |
|---|---|---|---|---|
| FR-8.1 | Hesap türü seçimi | "Kendim için bakıyorum" / "Bir yakınımın sürecini takip ediyorum" | Onboarding'in ilk adımında seçim | Seçim kalıcıdır, sonradan değiştirilemez |
| FR-8.2 | Veli hesabının doğrulaması ve kapsamı | Telefon + selfie (FR-1 ile aynı) | Aynı doğrulama akışı; FR-2/3/4'e erişim verilmez | Onboarding sonrası ad, yakınlık derecesi ve davet kodu istenir |
| FR-8.3 | Aile davet kodu | Tekil kullanıcının ürettiği kod | Kod doğrulama ve bağlama | Geçerli kod girilmeden bağlantı kurulamaz; kodsuz veli hesabı hiçbir veriye erişemez |
| FR-8.4 | Eşleşme bazlı "aileme göster" | Açık/kapalı toggle, eşleşme başına | Görünürlük kaydı | Varsayılan kapalı; anahtar eşleşme kutlama diyaloğunda, sohbet ekranında (üst çubuktaki aile düğmesi) ve aile ayarları ekranında bulunur, kullanıcı istediği zaman açıp kapatabilir |
| FR-8.5 | Veli görünümü (salt okunur) | — | Yalnızca "aileme göster" işaretli eşleşmelerin minimal görünümü | Aday adı/yaş/şehir/niyet + kaba bir durum etiketi ("yeni eşleşme"/"aktif yazışıyorlar") gösterilir; ekranın başında kimin eşleşmelerinin görüldüğü (bağlı kişinin adı) ve kaç eşleşmenin paylaşıldığı yazar; mesaj içeriği asla gösterilmez |
| FR-8.6 | Veli hesabının kısıtları | — | Mimari erişim kısıtı | Veli hesabı keşif/eşleştirme adayı olamaz, beğeni/geçme yapamaz, mesaj gönderemez, eşleştirme filtrelerine tabi olmaz |

**Kabul kriteri:** Bir veli hesabının `MatchingRepository`/`MessagingRepository` katmanlarına hiçbir kod yolundan erişimi olmamalıdır; yalnızca salt okunur bir aile görünümü üzerinden veri alır.

### FR-9 — Günün Sorusu Akışı

| # | Gereksinim | Girdi | İşlem | Çıktı / Kabul Kriteri |
|---|---|---|---|---|
| FR-9.1 | Günün sorusu | Tarih (UTC günü) | İstemcideki sabit listeden sırayla seçim | Aynı gün tüm üyeler aynı tek soruyu görür; gün değişirken açık olan uygulama kendiliğinden yeni soruya geçer |
| FR-9.2 | Günde tek cevap | En fazla 280 karakterlik metin | Cevap kaydı oluşturma | Üye günde en fazla bir cevap paylaşır; cevap ad, yaş ve şehirle tüm tekil üyelere görünür, fotoğraf gösterilmez; düzenlenemez, sahibi silebilir |
| FR-9.3 | Yalnızca beğeni | Beğen / beğeniyi geri al | Beğeni kaydı ve sayaç güncelleme | Yorum yoktur; akış beğenisi eşleşme oluşturmaz ve sohbet açmaz; kimin beğendiği görünmez, yalnızca sayı görünür; kişi kendi cevabını beğenemez |
| FR-9.4 | Şikayet / engelleme | Hedef cevap sahibi | FR-6.1 / FR-6.2 ile aynı | Her cevapta menü bulunur; engellenen kişinin cevapları gösterilmez |
| FR-9.5 | Veli hesabı kapsam dışı | — | Hesap türü kontrolü (kurallarda) | Veli hesabı akışı okuyamaz, cevap veya beğeni veremez |
| FR-9.6 | Keşfet'ten yönlendirme | Aday listesinin bitmesi | Boş durum ekranı | Aday kalmadığında ana eylem kullanıcıyı akışa götürür |
| FR-9.7 | Cevaplanmamış soru işareti | Kullanıcının bugünkü cevabının varlığı | Tek belgelik canlı dinleyici | Bugünün sorusu cevaplanmadıysa alt çubuktaki Günün Sorusu sekmesinde nokta görünür; cevap paylaşılınca kaybolur, cevap silinince veya yeni gün (UTC) başlayınca geri gelir |

**Not:** Metin için otomatik moderasyon yoktur (sunucu gerektirir, bkz. §7.1); güvenlik ağı karakter sınırı, günde tek cevap ve şikayet/engelle menüsüdür.

---

## 5. Fonksiyonel Olmayan Gereksinimler

### 5.1 Performans

Şu an için resmi bir gecikme/throughput hedefi (SLA) **tanımlanmamıştır**. Uygulama tekil kullanıcı etkileşimlerine (bir seferde bir kullanıcının işlemi) göre tasarlanmıştır; yüksek eşzamanlılık/ölçek testleri yapılmamıştır. Mesajlaşma ve eşleşme listesi Firestore dinleyicileriyle canlıdır (sohbet mesajları, son mesaj önizlemesi, sıralama ve okunmamış işareti); bu yalnızca uygulama açıkken geçerlidir (bkz. §7.2).

### 5.2 Güvenlik

- Firestore güvenlik kuralları varsayılan-reddet ilkesiyle yazılmıştır (`firestore.rules`); bir koleksiyona açık `allow` kuralı olmadan erişilemez.
- Günlük beğeni limiti (FR-4.3) ve karşılıklı-eşleşme koşulu (FR-4.2) yalnızca istemci mantığıyla değil, Firestore kurallarıyla da zorlanır.
- Şikayet kayıtları (FR-6.1) hiçbir istemciden (şikayet eden dahil) okunamaz.
- **Bilinen sınırlama:** Cloud Functions (Blaze plan) olmadığı için bazı kurallar tamamen istemci tarafında zorlanır; örneğin bir kullanıcının kendisini kimin beğendiğini teknik olarak okuyabilmesi gibi uçlar, ilgili veri kaynağı dosyalarında ve `firestore.rules`'ta yorum olarak işaretlenmiştir. Üretim öncesi bu uçların Cloud Functions ile kapatılması önerilir.

### 5.3 Gizlilik / Yasal Uygunluk (KVKK)

- Veri minimizasyonu ilkesi: doğrulama verisi (yalnızca `verified`/zaman damgası) profil ve aktivite verisinden ayrı tutulur.
- Özel nitelikli veri (din/mezhep) için ayrı, açık rıza mekanizması vardır (bkz. FR-2.3 notu).
- Kullanıcı, hesabını ve verisini istediği an silebilir ("unutulma hakkı", FR-7.1).
- **Açık risk:** KVKK aydınlatma/rıza metni bir hukuk danışmanı tarafından incelenmemiştir; şirket unvanı ve iletişim bilgileri yer tutucudur. Bu madde gerçek kullanıcılara açılmadan önce kapatılmalıdır (bkz. §9).

### 5.4 Kullanılabilirlik

- Arayüz dili v1'de yalnızca Türkçe'dir.
- Tasarım dili tutarlı, paylaşılan bileşenler üzerinden uygulanır (bkz. §3.1); açık ve koyu tema desteklenir.
- Erişilebilirlik hedefi: WCAG AA metin kontrastı, ≥44×44pt dokunma hedefleri (resmi olarak otomatik test edilmemiştir, tasarım ilkesi olarak izlenir).

### 5.5 Güvenilirlik ve Hata Toleransı

- Başarısız olabilecek tüm repository/use-case çağrıları, istisna fırlatmak yerine tipli bir `Result<T>` (`Ok`/`Err`) döndürür; sunum katmanı hatayı açıkça ele almak zorundadır.
- Hesap silme gibi çok adımlı, atomik olmayan işlemler "best-effort" prensibiyle çalışır: bir adım başarısız olursa işlem, kullanıcıya gerçek durumu yansıtacak şekilde (örn. en azından oturumu kapatarak) geri döner; sessizce "başarılı" göstermez.
- Teknik hata ayrıntıları kullanıcıya gösterilmez, `logFailure` ile kaydedilir. Oturum kapanırken hâlâ açık olan dinleyicilerin aldığı `permission-denied` bir arıza sayılmaz ve kaydedilmez; oturum açıkken gelen aynı hata ile oturumsuz çağrılardaki (davetiye kodu, bekleme listesi, giriş) retler kaydedilir.
- Tanınmayan bir adres (yanlış yazılmış bağlantı) hata sayfası yerine giriş ekranına yönlendirilir; oturum varsa oradan uygulamaya geçilir.

### 5.6 Bakım Yapılabilirlik

- Özellik-öncelikli (feature-first) temiz mimari: her özellik `data/domain/presentation` katmanlarına ayrılmıştır; domain katmanı Flutter/Firebase'den bağımsızdır.
- Yer tutucu (`Mock*`) ve gerçek (`Firestore*`) veri kaynakları aynı arayüzü uygular ve yalnızca `lib/core/di/injection_container.dart`'ta değiştirilir — bu, bir özelliğin backend'ini mimariyi bozmadan değiştirmeyi sağlar.
- Paylaşılan tasarım bileşenleri tek bir yerde (`lib/theme/`) tutulur ve `/design-preview` üzerinden görsel olarak doğrulanabilir.

### 5.7 Taşınabilirlik

Flutter tek kod tabanından Android, iOS ve Web hedeflenir. Web hedefi şu an öncelikli geliştirme/test platformudur; mobil platformlara özgü akışlar (örn. gerçek kamera ile selfie) henüz tam olarak doğrulanmamıştır.

### 5.8 Marka ve Görsel Kimlik

Bkz. §3.1. Özetle: "Gece Moru" renk paleti, Fraunces + Sora tipografi, yıldız/sekizgen-yıldız motifleri kullanılmaz (hilal/kemer/fener tercih edilir), düz yeşil kullanılmaz (logodaki turkuaz ve bakır ikincil marka renkleridir), kişiler gerçek fotoğraf yerine gradyan + baş harf avatarıyla gösterilir.

---

## 6. Veri Modeli (taslak)

Aşağıdaki model, kavramsal varlıkları özetler; gerçek Firestore koleksiyon/alan adları için ilgili `Firestore*RemoteDataSource` sınıflarındaki doc yorumları esas alınmalıdır.

```
User              { id, phone, accountType (single | guardian), createdAt, verifiedAt?, status }
Profile           { userId, name, birthDate, city, intent, religiousPracticeNote?, madhhab?,
                    photos[], photoVisibility, familyInvolvementOptIn }
GuardianProfile   { userId, name, relationshipToSingle, linkedSingleUserId? }   // accountType == guardian
FamilyInviteCode  { code, singleUserId, createdAt, expiresAt, usedByGuardianId? }
VerificationRecord{ userId, selfieCheckStatus, livenessScore, idCheckStatus? }  // ayrı, izole saklanır
Match             { id, userAId, userBId, createdAt, status, visibleToFamily: bool }
Conversation      { matchId, messages[] }
Message           { conversationId, senderId, text, sentAt }
Report            { id, reporterId, targetUserId, reason, createdAt }
WaitlistEntry     { name, contact, city?, createdAt, inviteStatus }
Consent           { userId, consentVersion, acceptedAt, lastAcceptedAt }
FeedPost          { id (authorId_dayKey), authorId, dayKey, text, createdAt, likeCount }
FeedLike          { id (postId_userId), postId, userId, dayKey, createdAt }
```

---

## 7. Bilinen Mimari Sınırlamalar

1. **Cloud Functions yok (Spark plan).** Atomik, çok taraflı işlemler (örn. iki tarafa da ait bir eşleşmenin tamamen silinmesi) istemci tarafından güvenle yapılamaz; bu işlemler ya yapılmaz ya da en iyi çaba (best-effort) prensibiyle kısmi olarak yapılır.
2. **Push bildirimi yok.** Sohbet ve eşleşme listesi Firestore dinleyicileriyle canlıdır, ama yalnızca uygulama açıkken; kapalı bir uygulamaya bildirim gitmez (Cloud Functions + FCM gerekir).
3. **İstemci tarafında zorlanan kurallar.** Günlük beğeni limiti ve bazı erişim kısıtları Firestore kurallarıyla desteklense de, bazı uç durumlar (örn. "kim beni beğendi" bilgisinin teoride okunabilmesi) yalnızca Cloud Functions ile tam olarak kapatılabilir; bu, Blaze plana geçişe bağlıdır.
4. **Silinen hesapların kalıntıları.** FR-7.1 kapsamında silinemeyen paylaşımlı kayıtlar (beğeniler, eşleşmeler, mesajlar), karşı taraf arayüzünde eksik profille yer tutucu olarak gösterilecek şekilde ele alınmıştır.

---

## 8. Uygulama Durumu — Gerçek vs Yer Tutucu (Mock)

| Bileşen | Durum |
|---|---|
| Telefon + SMS OTP ile giriş, oturum geri yükleme, çıkış | **Gerçek** (Firebase Auth) |
| Profiller, beğeniler, eşleşmeler, mesajlar, şikayetler, engellemeler, aile bağlantıları, rıza kayıtları, hesap silme | **Gerçek** (Cloud Firestore, kurallar `firestore.rules`'ta) |
| Davetiye kodu kontrolü | **Firestore** — Console'da elle oluşturulan `inviteCodes/{KOD}` dokümanları (`active: true`); kodlar yeniden kullanılabilir, sayaç/tek kullanımlık takip yok |
| Selfie / liveness doğrulaması | **Mock** — her zaman başarılı sayılır, kamera açılmaz; üçüncü taraf sağlayıcı entegrasyonu planlı |
| Fotoğraf yükleme/depolama | **Yok** — fotoğraflar yerel olarak seçilip gösterilir ama saklanmaz; kişiler baş harf avatarıyla temsil edilir |
| Fotoğraf moderasyonu | **Mock** — yalnızca dosya adı sezgisel kontrolü |
| Bekleme listesi kayıtları | **Firestore** — yalnızca oluşturulabilir `waitlist` koleksiyonu; istemci okuyamaz, Console'dan incelenir |
| Gerçek zamanlı sohbet ve okunmamış işareti (liste + Eşleşmeler sekmesi) | **Firestore dinleyicileri** — uygulama açıkken canlı; arka plan bildirimi yok (bkz. §7.2) |
| Günün Sorusu akışı | **Gerçek** (Firestore `feedPosts` / `feedLikes`); metin otomatik denetlenmez — yalnızca şikayet/engelleme |
| Push bildirimleri | **Yok** |
| KVKK rıza metni | **Taslak** — hukuki incelemeden geçmedi (bkz. §9) |

Bir gereksinimin Bölüm 4'te "kuruldu" olarak işaretlenmesi, kullanıcı arayüzü ve veri akışının tamamlandığı; yukarıdaki tabloda "mock/yok" olarak işaretlenen parçaların ise henüz üretime hazır olmadığı anlamına gelir.

---

## 9. Açık Kararlar ve Riskler

- [x] Selfie doğrulaması zorunlu, üçüncü taraf sağlayıcı üzerinden yapılacak — **karar verildi**, entegrasyon bekliyor (bkz. §8).
- [x] Mezhep alanı opsiyonel filtre olarak gösterilecek, varsayılan kapalı — **karar verildi** (FR-2.3).
- [x] Günlük beğeni limiti: 12/gün — **karar verildi** (FR-4.3).
- [x] Aile görüşmesi nudge'ı eşiği: 30 mesaj veya 7 gün — **karar verildi** (FR-5.2).
- [x] Veli bağlantısı: davet kodu, tekil kullanıcı üretir — **karar verildi** (FR-8.3).
- [x] Veli görünürlüğü: yalnızca "aileme göster" işaretli eşleşmeler — **karar verildi** (FR-8.4).
- [ ] **FR-8.5'teki sohbet durum etiketinin detay seviyesi** henüz netleşmedi ("yeni eşleşme"/"aktif yazışıyorlar" gibi minimal bir öneri var, genişletilebilir).
- [ ] **KVKK rıza metni hukuki incelemeden geçmedi.** `lib/features/consent/presentation/screens/consent_screen.dart`'taki aydınlatma metni KVKK m.10'un zorunlu unsurlarını (veri sorumlusu, amaçlar, hukuki sebep, alıcılar, yurt dışı aktarım, saklama süresi, m.11 hakları) yapısal olarak kapsayacak şekilde yazılmıştır ancak bir hukuk danışmanı tarafından onaylanmamıştır. Şirket unvanı/iletişim bilgisi yer tutucudur. Bu madde **üretime çıkmadan önce kapatılmalıdır**.
- [ ] **Firebase Blaze plana geçiş zamanlaması** kullanıcı tarafından bilinçli olarak ertelenmiştir; gerçek fotoğraf depolama, görüntü moderasyonu ve Cloud Functions ile kapatılacak güvenlik uçları bu karara bağlıdır.

---

## Ek A — Doküman Sahipliği ve Güncelleme

Bu SRS, kod tabanındaki gerçek duruma göre elle güncellenir; otomatik üretilmez. Bir FR'nin durumu (kuruldu/mock/yok) değiştiğinde hem bu dosyanın hem [`REQUIREMENTS.md`](REQUIREMENTS.md)'nin ilgili bölümünün güncellenmesi beklenir. Çelişki durumunda `REQUIREMENTS.md` esas alınır (bkz. doküman başlığı).
