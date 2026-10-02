# Lansman Öncesi Kontrol Listesi

Gerçek kullanıcıların kayıt olabilmesinden **önce** kapanması gereken kalemler.
Her madde koddaki gerçek bir yeri gösterir; bitirdikçe `[x]` işaretle.
Durum özeti için bkz. `README.md` (gerçek / mock tablosu) ve `docs/REQUIREMENTS.md` §7.

## 1. Kimlik ve kötüye kullanım koruması (engelleyici)

- [ ] **reCAPTCHA'yı geri aç.** `lib/core/config/dev_flags.dart` içinde
      `kDisableRecaptchaForTesting` şu an `true` (`lib/main.dart` bunu okuyor).
      `false` yap. Bu bayrak yalnızca test numaralarında etkili ama açık kalırsa
      gerçek numaralarda sahte hesap/spam koruması devre dışı kalır.
- [ ] **Firebase Console → Authentication → Phone → test numaralarını sil**
      (+90 555 000 00 00 … 03, kod 123456). Silinmezse bu numaralarla herkes giriş yapabilir.
- [ ] **App Check** aç (web için reCAPTCHA Enterprise/v3 sağlayıcısı) ve
      `firebase_options.dart`'taki API anahtarını HTTP referrer ile kısıtla.
- [ ] **Davetiye kodu mock.** `lib/features/auth/data/datasources/auth_remote_data_source.dart`
      içinde tek sabit kod (`NASIP2026`) var, herkes biliyor. Kodlar Firestore'da tutulmalı
      ve bekleme listesinden ilk 500 kişiye verilmeli (FR-1.3).
- [ ] **Bekleme listesi kaydı kalıcı değil.** `WaitlistLocalDataSourceImpl` girdileri
      bellekte tutuyor, sayfa yenilenince kayboluyor. Firestore'a bağla.
- [ ] **Selfie doğrulaması mock** (`FirebaseAuthRemoteDataSource` selfie için
      `MockAuthRemoteDataSource`'a düşüyor). Gerçek sağlayıcı (Veriff/Yoti/Didit) seç ve bağla.

## 2. Kullanıcıya görünen hata metinleri

- [ ] **Firebase hata kodlarını kullanıcıdan gizle.** Şu an mesajlara `(${e.code})` ekleniyor
      (yaklaşık 29 yer, 9 dosya): hesap, auth, consent, family, matching, messaging, profile ve
      safety `Firestore*RemoteDataSource` sınıfları ile `FirebaseAuthRemoteDataSource._message`.
      Kodu mesajdan çıkarıp bir log/crash raporlama aracına yönlendir
      (`grep -rn "e\.code" lib` ile bul).

## 3. Hukuki (senin/avukatın işi)

- [ ] `lib/features/consent/presentation/screens/consent_screen.dart` içindeki iki yer tutucuyu
      doldur: şirket unvanı/iletişim bilgisi (satır ~218) ve başvuru kanalı (satır ~279).
- [ ] KVKK aydınlatma metnini, yurt dışına aktarım dayanağını (eur3) ve mezhep/dini not için
      ayrı açık rıza (m.6) metnini **avukata onaylat**. Kodda yalnızca arayüz ve veri akışı hazır.
- [ ] Rıza kaydının (`consents/{uid}`) saklama süresine karar ver; hesap silinince
      bilerek silinmiyor.

## 4. Blaze planı gerektirenler

Kullanıcı şu an bilerek Spark'ta; bunlar planı değiştirince ele alınacak.

- [ ] **Cloud Functions ile kapanacak kural boşlukları** (`firestore.rules` başlık notu):
      kullanıcı kendisine gelen beğenileri okuyabiliyor; eşleşmeyi istemci oluşturuyor;
      `publicProfiles` istemci tarafından yazılıyor.
- [ ] **Atomik hesap silme.** `FirestoreAccountRemoteDataSource` best-effort çalışıyor;
      `likes`, `matches` ve mesajlar silinemiyor (iki tarafa ait).
- [ ] **Fotoğraf yükleme** için Cloud Storage: `photoRefs` hâlâ yer tutucu dosya adı.
- [ ] **Fotoğraf moderasyonu (FR-6.3)** şu an dosya adı sezgisi
      (`FirestoreSafetyRemoteDataSource.moderatePhoto`); gerçek görüntü analizi gerekir.
- [ ] **Push bildirimleri** (yeni mesaj/eşleşme): FCM + sunucu tarafı tetikleyici.

## 5. Son kontroller

- [ ] `firestore.rules` son halini deploy et ve gerekli bileşik indeksleri doğrula
      (`firebase deploy --only firestore:rules --project binasip`).
- [ ] Firestore emülatörüyle kural testleri yaz (şu an tüm Firestore davranışı elle doğrulandı).
- [ ] Gizlilik sınırlarını kurallarda bir kez daha doğrula: veli mesaj içeriğini göremez
      (FR-8.5) ve `matchReads` yalnızca sahibine okunur.
