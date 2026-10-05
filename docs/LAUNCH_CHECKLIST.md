# Lansman Öncesi Kontrol Listesi

Gerçek kullanıcıların kayıt olabilmesinden **önce** kapanması gereken kalemler.
Her madde koddaki gerçek bir yeri gösterir; bitirdikçe `[x]` işaretle.
Durum özeti için bkz. `README.md` (gerçek / mock tablosu) ve `docs/REQUIREMENTS.md` §7.

## 1. Kimlik ve kötüye kullanım koruması (engelleyici)

- [x] **reCAPTCHA yayın derlemesinde her zaman açık.** `lib/core/config/dev_flags.dart`
      içindeki `kDisableRecaptchaForTesting` artık `kDebugMode`'a bağlı: `flutter run` (debug)
      test numaralarında doğrulamayı atlar, `flutter build ...` ile alınan her derlemede
      doğrulama açıktır. Elle çevrilecek bir bayrak kalmadı. Not: yayın derlemesini
      (`node tools/serve_web.js`) test numarasıyla denerken reCAPTCHA görünür.
- [ ] **Firebase Console → Authentication → Phone → test numaralarını sil**
      (+90 555 000 00 00 … 03, kod 123456). Silinmezse bu numaralarla herkes giriş yapabilir.
- [ ] **App Check'i aç.** Kod tarafı hazır (`lib/core/config/app_check.dart`,
      `firebase_app_check` paketi); site anahtarı boş olduğu için şu an kapalı. Sırasıyla:
      1. Firebase Console → App Check → web uygulamasını **reCAPTCHA v3** ile kaydet
         (anahtarı reCAPTCHA yönetim panelinde v3 olarak, yayın alan adın için oluştur).
      2. Site anahtarını `kAppCheckWebSiteKey` sabitine yapıştır (site anahtarı gizli değildir).
      3. `flutter run` ile uygulamayı bir kez aç; tarayıcı konsoluna yazılan **debug token**'ı
         App Check → Uygulamalar → "Debug token'ları yönet" altına ekle. Bu token gizlidir,
         repoya girmez (`--dart-define=APP_CHECK_DEBUG_TOKEN=...` ile sabitlenebilir).
      4. App Check ekranındaki istek grafiğinde doğrulanan oranı izle; sorun yoksa Firestore
         (ve Authentication) için **Enforce**'u aç. Enforce açılmadan App Check hiçbir şeyi
         engellemez.
      5. Mobil yayın için Android'de Play Integrity, iOS'ta DeviceCheck kaydını ekle.
- [ ] `firebase_options.dart`'taki API anahtarını HTTP referrer ile kısıtla.
- [ ] **Davetiye kodlarını dağıt ve test kodunu kapat.** Kodlar artık Firestore'da
      (`inviteCodes/{KOD}`, `active: true`); `NASIP2026` Console'da `active: false` yapılmalı veya
      silinmeli. Kodlar yeniden kullanılabilir (geri dönen kullanıcı aynı kapıdan geçiyor); tek
      kullanımlık/sayaçlı kod ve bekleme listesinden ilk 500 kişiye otomatik dağıtım (FR-1.3)
      Cloud Functions gerektirir.
- [ ] **Bekleme listesi herkese açık yazma.** Kayıtlar artık Firestore'da (`waitlist`),
      ama giriş yapmamış biri yazabildiği için App Check olmadan spam'e açık.
- [ ] **Selfie doğrulaması mock** (`FirebaseAuthRemoteDataSource` selfie için
      `MockAuthRemoteDataSource`'a düşüyor). Gerçek sağlayıcı (Veriff/Yoti/Didit) seç ve bağla.
      **Sunucu şart:** oturum açmak ve sonucu (webhook) almak için gizli API anahtarı gerekir,
      istemcide tutulamaz; yani Cloud Functions/Blaze olmadan güvenli entegrasyon yok. Bugün
      `users/{uid}.verifiedAt` istemci tarafından yazılabiliyor, yani doğrulama atlanabilir;
      gerçek sağlayıcıyla `verifiedAt` yalnızca sunucudan yazılmalı (kural `write: false`).
      Selfie/yüz verisi KVKK m.6 kapsamında özel nitelikli veridir: ayrı açık rıza + avukat onayı.

## 2. Kullanıcıya görünen hata metinleri

- [x] **Firebase hata kodları kullanıcıdan gizlendi.** Kullanıcı sade Türkçe mesaj görüyor,
      teknik ayrıntı `logFailure` ile (`lib/core/error/error_log.dart`) yalnızca geliştirici
      konsoluna yazılıyor.
- [ ] **`logFailure` içini crash raporlamaya bağla** (Crashlytics/Sentry). Şu an sadece
      `debugPrint`; yayında hataları görmenin tek yolu bu.
- [x] **Oturum kapanışı gürültüsü log'dan ayıklandı.** Çıkışta ya da hesap silmede hâlâ
      açık olan Firestore dinleyicilerinin aldığı `permission-denied` artık raporlanmıyor
      (`isSessionEndNoise`); oturum açıkken gelen aynı hata ve oturumsuz çağrılar (davetiye
      kodu, bekleme listesi, giriş) raporlanmaya devam ediyor.

## 3. Hukuki (senin/avukatın işi)

- [ ] `lib/features/consent/presentation/screens/consent_screen.dart` içindeki iki yer tutucuyu
      doldur: şirket unvanı/iletişim bilgisi (satır ~218) ve başvuru kanalı (satır ~279).
- [ ] KVKK aydınlatma metnini, yurt dışına aktarım dayanağını (eur3) ve mezhep/dini not için
      ayrı açık rıza (m.6) metnini **avukata onaylat**. Kodda yalnızca arayüz ve veri akışı hazır.
- [ ] **"Hesabım var" kapısını avukata sor.** Bu kapıda telefon numarası rıza ekranı
      görülmeden girilir. Kayıtlı kullanıcının rızası zaten var; ama yeni biri yanlışlıkla bu
      kapıyı seçerse numarası bir SMS göndermek için işlenmiş olur (hesabı olmadığı anlaşılınca
      deneme iz bırakmadan kapatılıyor). Giriş ekranına kısa bir aydınlatma notu/bağlantısı
      gerekip gerekmediğini sor.
- [ ] Rıza kaydının (`consents/{uid}`) saklama süresine karar ver; hesap silinince
      bilerek silinmiyor.

## 4. Blaze planı gerektirenler

Kullanıcı şu an bilerek Spark'ta; bunlar planı değiştirince ele alınacak.

- [ ] **Cloud Functions ile kapanacak kural boşlukları** (`firestore.rules` başlık notu):
      kullanıcı kendisine gelen beğenileri okuyabiliyor; eşleşmeyi istemci oluşturuyor;
      `publicProfiles` istemci tarafından yazılıyor; doğum tarihi güncellemede kilitli
      (FR-2.5) ama profil belgelerini silip yeniden oluşturan biri onu değiştirebiliyor.
- [ ] **Atomik hesap silme.** `FirestoreAccountRemoteDataSource` best-effort çalışıyor;
      `likes`, `matches` ve mesajlar silinemiyor (iki tarafa ait).
- [ ] **Fotoğraf yükleme** için Cloud Storage: `photoRefs` hâlâ yer tutucu dosya adı.
- [ ] **Fotoğraf moderasyonu (FR-6.3)** şu an dosya adı sezgisi
      (`FirestoreSafetyRemoteDataSource.moderatePhoto`); gerçek görüntü analizi gerekir.
- [ ] **Push bildirimleri** (yeni mesaj/eşleşme): FCM + sunucu tarafı tetikleyici.

- [ ] **Akış (günün sorusu) metin moderasyonu.** Cevaplar otomatik denetlenmiyor; uygunsuz
      içerik yalnızca şikayetle fark edilir ve şikayetleri okuyan bir panel yok (`reports`
      istemciden okunamıyor). Lansmandan önce şikayetleri inceleyecek bir süreç ve tercihen
      sunucu tarafı metin filtresi gerekir.

## 5. Son kontroller

- [ ] `firestore.rules` son halini deploy et. Son deploy 2026-10-05 (doğum tarihi kilidi:
      profil güncellemesinde doğum tarihi değişemez, FR-2.5) - canlıda doğrulandı. Sonraki
      her kural değişikliğinde yinele.
      **Dikkat:** davetiye kapısı ve veli bağlantısı kuralları (aynı gün, daha önce)
      uygulamanın aynı sürümüyle birlikte yayınlanmalı - o değişiklikten önceki bir derleme
      yeni hesap açamaz ve veli bağlayamaz (mevcut hesapların girişi etkilenmez). Yayındaki
      derlemeyi kurallarla aynı anda güncelle. Doğum tarihi kilidi böyle bir bağ kurmuyor:
      tarihi değiştirmeyen her kayıt eski derlemede de geçer.
      (`firebase deploy --only firestore:rules --project binasip`).
- [x] **Bileşik indeks gerekmiyor.** Uygulamadaki tüm sorgular ya yalnızca eşitlik filtresi
      kullanıyor ya da tek alanda sıralıyor (`messages` → `sentAt`); bunları Firestore'un
      otomatik tek-alan indeksleri karşılıyor, `firestore.indexes.json` yok ve gerekmiyor.
      Yeni bir sorguya eşitsizlik filtresi ya da farklı alanda `orderBy` eklenirse yeniden bak.
- [x] Firestore kural testleri hazır (`rules_test/`, `npm test`; Java gerekir). Kuralları her
      değiştirdiğinde deploy etmeden önce çalıştır. Uygulama katmanı (veri kaynakları) hâlâ elle doğrulanıyor.
- [x] **Gizlilik sınırları kural testleriyle sabitlendi.** Bağlı bir veli, kendisiyle
      paylaşılan eşleşmenin mesajlarını okuyamaz/yazamaz, eşleşme belgesini, okunma
      işaretlerini ve bekârın özel profilini okuyamaz, paylaşımı kendisi açıp kapatamaz
      (`rules_test/` → "guardian privacy (FR-8.5)"); `matchReads` yalnızca sahibine okunur
      ("matchReads (unread markers)").
- [x] **`/design-preview` yalnızca debug derlemede.** Geliştirici vitrininin rotası
      `kDebugMode` arkasında (`lib/core/router/app_router.dart`); yayın derlemesinde yok,
      o adresle açılan uygulama giriş ekranına yönlenir.
