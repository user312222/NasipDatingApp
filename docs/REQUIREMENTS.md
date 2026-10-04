# Bi Nasip — MVP Gereksinimleri

**Durum:** FR-1 → FR-8 kuruldu (mock veri kaynaklarıyla; gerçek backend/sağlayıcı entegrasyonları bekliyor). Bölüm 7'de tek açık karar var.
**Kapsam:** Türkiye, Türkçe-first, evlilik-öncelikli, mahremiyet-öncelikli, medeni Müslüman bekârlar için tanışma uygulaması. Dar başlangıç: kapalı beta, davetiyeli, ilk 500 kullanıcı.

---

## 1. Ürün Özeti

Bi Nasip; Türkiye'deki mevcut seçeneklerin (küresel Müslüman uygulamaları — yerel bağlamı tanımıyor; yerel Türk uygulamaları — dini kimliği merkeze almıyor) arasında kalan boşluğu dolduran bir evlilik-niyetli tanışma uygulamasıdır. Üç temel ilke: **niyet baştan belli**, **mahremiyet kullanıcının elinde**, **aile involvement opsiyonel**.

## 2. Hedef Kullanıcı (persona özetleri)

| Persona | Yaş/Şehir | İhtiyaç |
|---|---|---|
| Ayşe | 27, İstanbul | Aile onayı ile kendi tercihi arasında denge; modesty-first foto kontrolü |
| Burak | 31, Ankara | Dini pratik sorularının zorlayıcı olmaması; mezhep opsiyonel filtre |
| Zeynep | 29, Berlin (diaspora) | Çift kimlik (Türk+Müslüman), diaspora şehir erişimi, çok dilli destek |
| Elif | 26, İzmir | Güvenilir doğrulama, net niyet, sahte profil riskinden korunma |

## 3. MVP Kapsamı

### İçinde (v1)
- Telefon numarası doğrulama (zorunlu)
- Selfie / liveness doğrulama (önerilen, MVP'de opsiyonel ama UI'da güçlü teşvik)
- Profil oluşturma: fotoğraf(lar), bio, niyet zaman çizelgesi, şehir, dini pratik seviyesi (opsiyonel/serbest metin+seçenek), mezhep (opsiyonel filtre)
- Modesty-first fotoğraf kontrolü (kimin ne zaman göreceğini kullanıcı belirler)
- Eşleştirme: filtre bazlı + basit uyum skoru (şehir, yaş aralığı, niyet zaman çizelgesi, dil)
- Karşılıklı beğeni → metin sohbeti
- Aile/veli involvement tercihi (opsiyonel toggle — zorunlu değil)
- Veli/aile hesabı türü — davet koduyla bağlanma, sadece işaretli eşleşmeleri salt-okunur görüntüleme (FR-8)
- Şikayet / engelleme
- Bekleme listesi → davetiyeli kapalı beta girişi
- KVKK'ya uygun veri ayrımı (doğrulama verisi ayrı, profil verisinden izole)

### Dışında (v1'de yok, v2+)
- Video/sesli arama
- Voice notes / async video mesaj
- Etkinlik/live speed-dating özellikleri
- Gelişmiş AI eşleştirme / kişiselleştirme
- Çoklu dil desteği (v1 sadece Türkçe; diaspora/çok dilli v2)
- Genel App Store / Play Store herkese açık lansman (v1 sadece davetiyeli kapalı beta)
- Namaz vakti / Ramazan takvim entegrasyonu (NEYİŞ #4 — sonraki faz)

## 4. Fonksiyonel Gereksinimler

### FR-1 — Onboarding & Kimlik Doğrulama *(kuruldu — `lib/features/auth/`; telefon + SMS OTP gerçek (Firebase Phone Auth; oturum geri yükleme ve çıkış dahil). Davetiye kodu doğrulaması Firestore'da (`inviteCodes/{KOD}`); selfie doğrulaması hâlâ mock — bkz. FR-1.2 notu)*
- FR-1.1 Kullanıcı telefon numarası ile kayıt olur, SMS OTP ile doğrular.
- FR-1.2 Kullanıcı, hesap açılışında **zorunlu** selfie-liveness doğrulamasından geçer (kimlik belgesi/T.C. kimlik istenmez — sadece "bu fotoğrafı gerçek/canlı bir insan mı çekti" kontrolü). Doğrulama 3. parti sağlayıcı (Veriff/Yoti/Didit vb.) üzerinden yapılır; ham selfie/biyometrik veri Bi Nasip'in kendi altyapısında hiçbir zaman saklanmaz — sadece sağlayıcıdan dönen `verified: true/false` + zaman damgası tutulur. Mümkünse aynı akışta sağlayıcının yaş tahmini (facial age estimation) özelliği de kullanılır, görüntü işlem sonrası saklanmaz.
- FR-1.3 Davetiye kodu olmayan kullanıcı bekleme listesine yönlendirilir (Faz 1: closed beta).
- FR-1.4 Telefon numarası istenmeden ÖNCE, kullanıcı KVKK aydınlatma metnini görür ve iki ayrı açık rızayı (veri işleme + yurt dışı aktarım) onaylamadan devam edemez *(kuruldu — `lib/features/consent/`, `/consent` ekranı, Firestore `consents/{uid}`'e kaydediliyor. **Metin taslaktır, hukuki inceleme gerekiyor** — bkz. Bölüm 7)*.

### FR-2 — Profil Oluşturma *(kuruldu — `lib/features/profile/`, Firestore'a bağlı (özel `profiles/{uid}` + asgari alanlı herkese açık `publicProfiles/{uid}`); gerçek fotoğraf seçimi `image_picker` ile canlı çalışıyor, yükleme/depolama henüz Firebase Storage'a bağlı değil)*
- FR-2.1 Kullanıcı en az 1, en fazla 6 fotoğraf ekleyebilir.
- FR-2.2 Kullanıcı niyetini seçer: "Evlilik", "Henüz emin değilim" (casual/flört seçeneği YOK — pozisyonlama gereği).
- FR-2.3 Kullanıcı şehir, yaş, eğitim, meslek, dini pratik seviyesi (opsiyonel serbest alan) girer. Mezhep alanı opsiyoneldir ve eşleştirme ekranında **opsiyonel bir filtre** olarak sunulur (varsayılan: kapalı/"farketmez"); zorunlu değildir ve boş bırakan kullanıcılar dışlanmaz. Seçenek listesi kapsayıcı tutulur (serbest metin girişi de desteklenir, kapalı bir kutuya sıkıştırılmaz).
- FR-2.4 Kullanıcı profilinde genel bir "aileme açığım" sinyali taşır (opsiyonel, varsayılan: kapalı) — bu bir niyet göstergesidir, tek başına hiçbir veriyi kimseye açmaz. Hangi eşleşmenin gerçekten aileye görüneceği eşleşme bazında ayrı ayrı belirlenir (bkz. FR-8.4).

### FR-3 — Mahremiyet / Modesty Kontrolleri *(kuruldu — `Profile.photoVisibility`, fotoğraf seçiminin hemen ardından `/profile/privacy` adımı)*
- FR-3.1 Kullanıcı (özellikle kadın kullanıcı) fotoğraf görünürlüğünü kademeli açabilir: "eşleşince otomatik", "ben açana kadar gizli", "sadece istek üzerine".
- FR-3.2 Varsayılan görünürlük seviyesi en kısıtlı seçenektir (opt-in genişletme, opt-out değil).

### FR-4 — Eşleştirme *(kuruldu — `lib/features/matching/`, Firestore'a bağlı (`likes`, `likeCounters`, `matches`; günlük 12 sınırı ve karşılıklı-beğeni koşulu `firestore.rules`'ta zorlanıyor); kart hem sürükle-bırak hem buton ile beğenilir/geçilir, eşleşme kutlaması ve alt çubukta Eşleşmeler sekmesi (`/matches`) var)*
- FR-4.1 Sistem şehir, yaş aralığı, niyet zaman çizelgesi ve dil filtrelerine göre aday listesi sunar.
- FR-4.2 Karşılıklı beğeni (mutual like) eşleşme oluşturur ve sohbeti açar.
- FR-4.3 Tek taraflı beğeni günlük **12 ile sınırlı** (spam/düşük-niyet kullanımını azaltmak için; Tinder'ın ~100/gün hacim modelinin tam tersi — "quality over quantity" pozisyonlamasını destekler).

### FR-5 — Mesajlaşma *(kuruldu — `lib/features/messaging/`, Firestore'a bağlı ve canlı (dinleyicilerle): yeni mesajlar açık sohbette anında görünür; eşleşme listesi son mesajı önizler, etkinliğe göre sıralanır ve okunmamış mesajı nokta ile işaretler (`matchReads`); aynı nokta alt çubuktaki Eşleşmeler sekmesinin ikonunda da görünür ve kullanıcı başka sekmedeyken de canlıdır, sohbet açılınca kaybolur; push bildirimi yok; FR-4'teki eşleşme diyaloğundan "Sohbete başla" ile veya alt çubuktaki Eşleşmeler sekmesinden (`/matches`) ulaşılıyor)*
- FR-5.1 Eşleşen kullanıcılar metin tabanlı sohbet edebilir.
- FR-5.2 Bir sohbette **toplam 30 mesaj değişimi VEYA 7 gün aktif yazışma** (hangisi önce gerçekleşirse) sonrasında, "aile görüşmesi" veya "buluşma" önerisi tek seferlik, nazik bir kart olarak gösterilir — zorlayıcı değil, kapatılabilir (retention/conversion nudge — Elif/araştırma bulgusu: "sohbet sonu yok" şikayeti).

### FR-6 — Güven & Güvenlik *(kuruldu — `lib/features/safety/`; şikayet (`reports`) ve engelleme (`blockedUsers`) artık Firestore'da, keşif kartında ve sohbet ekranında "⋮" menüsünde. Fotoğraf moderasyonu (FR-6.3) hâlâ mock — gerçek görüntü analizi (Cloud Vision vb.) Cloud Storage + Blaze plan gerektiriyor; mock kuralı: dosya adı "unsafe" içeriyorsa reddedilir. Kapsam notu: şikayet kullanıcı bazlı — tek tek mesaj şikayeti henüz yok)*
- FR-6.1 Kullanıcı herhangi bir profili/mesajı şikayet edebilir.
- FR-6.2 Kullanıcı engelleme yapabilir; engellenen kullanıcı bir daha görünmez.
- FR-6.3 Yüklenen fotoğraflar managed moderation API'sinden geçer (uygunsuz içerik otomatik reddedilir).

### FR-7 — Hesap & Veri *(kuruldu — `lib/features/account/`; aynı ekran bekâr kullanıcıda alt çubuktaki Hesap sekmesi (`/account`), veli hesabında ise veli ana ekranının üst çubuğundaki dişli ikonuyla açılan `/settings` sayfası. Hesap silme artık gerçek: Firestore'daki profil/publicProfile/users/aile bağlantısı belgeleri ve Firebase Auth hesabının kendisi siliniyor (son adım oturumu kalıcı olarak kapatıyor, telefon numarasını yeni kayıt için serbest bırakıyor). FR-7.2 mimari olarak zaten karşılanıyor: `AuthUser` sadece `verifiedAt` taşır, ham selfie hiçbir yerde tutulmaz. Kapsam notu: Cloud Functions (Blaze) olmadığı için `likes`/`matches`/mesajlar silinemiyor — bunlar sahiplerinin ikisine de ait, tek taraflı silinmesi karşı tarafın verisini bozabilir; kalan kayıtlar zaten eksik profille "Kullanıcı" gibi yer tutucularla gösterilecek şekilde ele alınıyor)*
- FR-7.1 Kullanıcı hesabını ve tüm verisini silebilir (KVKK "unutulma hakkı").
- FR-7.2 Doğrulama sonucu (yalnızca `verified: true/false` + zaman damgası) profil/aktivite verisinden ayrı bir veri deposunda tutulur; ham selfie/biyometrik veri Bi Nasip tarafında hiç tutulmaz, işleme tamamen 3. parti sağlayıcıda kalır.

### FR-8 — Veli/Aile Hesabı *(kuruldu — `lib/features/family/` + `AccountType` in auth + `Match.visibleToFamily` in matching, artık Firestore'a bağlı (`familyInviteCodes`, `familyInviteCodeLookup`, `guardianOf`, `familyVisible` koleksiyonları); davet kodu artık gerçek, rastgele üretilen 8 haneli bir kod. "Aileme göster" anahtarı üç yerde: eşleşme kutlama diyaloğunda (varsayılan kapalı), sohbet ekranının üst çubuğundaki aile düğmesiyle açılan sayfada ve `/family/settings` ekranında; üçü de aynı `familyVisible` kaydını yazar. Cloud Functions (Blaze) olmadığı için bazı kurallar istemci tarafından zorlanıyor — ayrıntı için `firestore.rules` ve `firestore_family_remote_data_source.dart`'taki notlara bkz.)*

Senaryo: kullanıcı zaten evli, kendisi için eş aramıyor — bir yakınının (örn. çocuğunun) sürecini, o izin verdiği ölçüde takip etmek istiyor. Bu, **ayrı bir hesap türü**; mevcut FR-2.4'teki tek başına toggle bunu karşılamıyordu.

- FR-8.1 Kullanıcı, davetiye kodu kabul edildikten hemen sonra (FR-1.3'ün ardından, telefon doğrulamadan önce) hesap tipini seçer: **"Kendim için bakıyorum"** ya da **"Bir yakınımın sürecini takip ediyorum"**. Bu seçim hesabın tüm yaşam döngüsünü belirler; sonradan değiştirilemez.
- FR-8.2 Veli/aile hesabı da FR-1'deki telefon + selfie-liveness doğrulamasından **aynı şekilde** geçer (güven/spam önleme aynı) ama FR-2 (profil), FR-3 (mahremiyet), FR-4 (eşleştirme) akışlarının **hiçbirini görmez**. Onboarding sonrası basit bir veli profili oluşturur: ad, yakınlık derecesi (anne/baba/abla/ağabey/teyze/dayı/diğer), bağlanılacak hesap için davet kodu girişi.
- FR-8.3 Bekâr kullanıcı kendi hesap ayarlarından bir **aile davet kodu** üretebilir (benzersiz, süreli — örn. 7 gün geçerli, yeniden üretilebilir). Veli bu kodu kendi onboarding'inde girerek **tek bir** bekâr hesabına bağlanır. Geçerli kod girilmeden bağlantı kurulmaz; kodsuz bir veli hesabı hiçbir bekâr kullanıcı verisine erişemez.
- FR-8.4 Bekâr kullanıcı, her eşleşme için ayrı ayrı **"aileme göster"** işaretleyebilir — hem eşleşme kutlama ekranında hem de sohbet ekranından sonradan değiştirilebilir. Varsayılan: **kapalı** (opt-in, FR-3.2'deki mahremiyet ilkesiyle tutarlı).
- FR-8.5 Bağlı veli hesabı, SADECE bağlı olduğu kullanıcının "aileme göster" işaretli eşleşmelerini **salt-okunur** görür: aday adı/yaş/şehir/niyet + sohbetin minimal bir durum etiketi (örn. "yeni eşleşme" / "aktif yazışıyorlar"). Mesaj içeriğini **birebir okuyamaz** — bu mahremiyet ilkesiyle doğrudan çelişir. *(Bu durum-etiketi kapsamı kendi kararımdır — isterseniz genişletebilir/daraltabiliriz.)*
- FR-8.6 Veli hesabı **hiçbir koşulda**: (a) başka bir kullanıcının keşif/eşleştirme akışında aday olarak önerilmez, (b) beğeni/geçme yapamaz, (c) mesaj gönderemez, (d) eşleştirme filtrelerine tabi tutulmaz. Bu, hesap tipi seviyesinde garanti altına alınır — mimari olarak veli hesapları `MatchingRepository`/`MessagingRepository`'ye hiç erişemez (sadece salt-okunur bir `FamilyViewRepository` üzerinden).

### FR-9 — Günün Sorusu Akışı *(kuruldu — `lib/features/feed/`, Firestore'a bağlı (`feedPosts`, `feedLikes`); `/feed` rotası alt çubuktaki Günün Sorusu sekmesi; adaylar bittiğinde gösterilen boş durum da buraya yönlendiriyor)*
- FR-9.1 Her gün (UTC günü) tüm üyelere aynı tek soru gösterilir; sorular istemcideki sabit bir listeden sırayla gelir.
- FR-9.2 Bir üye günde **en fazla bir** cevap paylaşır (en fazla 280 karakter). Cevap adı, yaşı ve şehriyle birlikte tüm bekâr üyelere görünür; fotoğraf gösterilmez (FR-3). Cevap düzenlenemez, sahibi silebilir.
- FR-9.3 Etkileşim yalnızca beğenidir: yorum yoktur ve akıştaki beğeni bir eşleşme beğenisi **değildir** — eşleşme oluşturmaz, sohbet açmaz. Mesajlaşma yalnızca eşleşenler arasında kalır (FR-5). Kimin beğendiği görünmez, yalnızca sayı görünür; kişi kendi cevabını beğenemez.
- FR-9.4 Her cevapta şikayet/engelle menüsü bulunur (FR-6.1/6.2); engellenen kişinin cevapları gösterilmez.
- FR-9.5 Veli hesapları akışı göremez ve cevap/beğeni veremez (FR-8.2).
- FR-9.6 Keşfet'te aday kalmadığında ana eylem kullanıcıyı akışa yönlendirir.
- Kapsam notu: Metin için otomatik moderasyon yoktur (sunucu gerektirir); güvenlik ağı karakter sınırı, günde bir cevap ve şikayet/engelle menüsüdür.

## 5. Veri Modeli (taslak)

```
User          { id, phone, accountType (single | guardian), createdAt, verifiedAt?, status }
Profile       { userId, name, birthDate, city, intent, religiousPracticeNote?, madhhab?, photos[], photoVisibility, familyInvolvementOptIn }
GuardianProfile { userId, name, relationshipToSingle, linkedSingleUserId? }        // accountType == guardian
FamilyInviteCode { code, singleUserId, createdAt, expiresAt, usedByGuardianId? }   // FR-8.3
VerificationRecord { userId, selfieCheckStatus, livenessScore, idCheckStatus? }    // ayrı, izole store
Match         { id, userAId, userBId, createdAt, status, visibleToFamily: bool }   // FR-8.4
Conversation  { matchId, messages[] }
Message       { conversationId, senderId, text, sentAt }
Report        { id, reporterId, targetUserId, reason, createdAt }
WaitlistEntry { name, contact, city?, createdAt, inviteStatus }
FeedPost      { id (authorId_dayKey), authorId, dayKey, text, createdAt, likeCount }  // FR-9.2
FeedLike      { id (postId_userId), postId, userId, dayKey, createdAt }              // FR-9.3
```

## 6. Fonksiyonel Olmayan Gereksinimler

- **Platform:** Flutter — iOS + Android (tek kod tabanı), proje adı `binasip`.
- **Dil:** v1 yalnızca Türkçe arayüz.
- **Gezinme:** Bekâr kullanıcının ana ekranı dört sekmeli bir alt çubuktur: **Keşfet** (`/discover`), **Günün Sorusu** (`/feed`), **Eşleşmeler** (`/matches`), **Hesap** (`/account`). Her sekme kendi durumunu korur (sekme değiştirip dönünce adaylar yeniden yüklenmez); bulunulan sekmeye tekrar basmak o sekmenin başına döner. Sohbet, aile ayarları gibi tam ekran sayfalar çubuğun üstünü kaplar. Okunmamış mesaj varken Eşleşmeler sekmesinde nokta görünür (FR-5). Veli hesabında sekme çubuğu yoktur; tek ana ekranı vardır (FR-8.2).
- **Yasal/Veri:** KVKK uyumu — veri minimizasyonu, doğrulama verisinin ayrı saklanması, açık rıza akışları.
- **Marka/Tasarım:** "Gece Moru" renk paleti (mor/toz gülü/altın — bkz. Figma `binasip` dosyası, `🎨 Foundations` sayfası), Fraunces (display) + Sora (UI) tipografi, Phosphor Icons (Light) + özel İslami motifler: **hilal/kemer/fener** (yıldız/sekizgen-yıldız benzeri şekiller **kullanılmaz** — başka bir dinî sembole benzeyebildiği için ürün sahibi tarafından reddedildi; Keşfet kartında hilal + küçük "pırıltı" ikonu kullanılıyor).
- **Görsel dil:** Genç ve canlı — iki renkli canlı gradyanlar (koyulaştırılmış tek renk değil), yuvarlak köşeler (kart ~30px, buton ~18px), gradyanlı ana butonlar, hafif hareket efektleri (kart sürükleme, eşleşme kutlaması, mesaj girişi). Düz yeşil kullanılmaz; logodaki turkuaz (`teal`) ve bakır (`brass`) ikincil marka renkleridir (bağlantılar, konum iğneleri, arka plan ışıması, avatar geçişleri), ana eylemler mor → mercan geçişinde kalır. Fotoğraflar mahremiyet kapılı olduğu için kişiler gradyan + baş harf avatarıyla gösterilir (FR-3).
- **Tema:** Açık ve koyu tema (sistemden). Beyaz metin taşıyan dolgular `AppColors.plumFill` kullanır (`plum` koyu temada açık pembeye döner). Ortak bileşenler `lib/theme/wizard_widgets.dart` (`WizardBackdrop/Header/Body`, `GradientButton`, `OptionCard`, `SectionCard`) ve `lib/theme/avatar_palette.dart`; hepsi `/design-preview` vitrininde (açık/koyu anahtarıyla) görülebilir.
- **Erişilebilirlik:** Metin kontrastı WCAG AA hedefi; dokunma hedefleri min. 44×44pt.

## 7. Açık Kararlar (kullanıcıdan onay bekliyor)

- [x] ~~Selfie doğrulaması MVP'de zorunlu mu, önerilen mi?~~ **Karar: zorunlu, ama 3. parti sağlayıcı üzerinden — ham veri Bi Nasip'te hiç tutulmaz (bkz. FR-1.2, FR-7.2).**
- [x] ~~Mezhep filtresi gerçekten kullanıcıya gösterilsin mi, yoksa arka planda mı tutulsun?~~ **Karar: görünsün, opsiyonel filtre olarak (varsayılan kapalı, serbest metin de desteklenir — bkz. FR-2.3).**
- [x] ~~Günlük beğeni limiti sayısı ne olsun?~~ **Karar: 12/gün (bkz. FR-4.3).**
- [x] ~~"Aile görüşmesi" nudge'ı kaç mesaj/gün sonra tetiklensin?~~ **Karar: 30 mesaj veya 7 gün, hangisi önce olursa (bkz. FR-5.2).**
- [x] ~~Veli hesabı çocuğuna nasıl bağlanır?~~ **Karar: davet kodu, çocuk üretir/veli girer (bkz. FR-8.3).**
- [x] ~~Veli tam olarak neyi görebilir?~~ **Karar: sadece eşleşme bazında "aileme göster" işaretlenenler (bkz. FR-8.4).**
- [ ] FR-8.5'teki sohbet durum-etiketi ne kadar detaylı olsun? (Şu an "yeni eşleşme"/"aktif yazışıyorlar" gibi minimal bir etiket öneriliyor — genişletilebilir.)
- [ ] **FR-1.4 KVKK rıza ekranı metni hukuki incelemeden geçmedi.** `lib/features/consent/presentation/screens/consent_screen.dart`'ta yazılı aydınlatma metni, KVKK m.10'un zorunlu unsurlarını (veri sorumlusu, amaçlar, hukuki sebep, alıcılar, yurt dışı aktarım, saklama süresi, m.11 hakları) kapsayacak şekilde yazıldı ama ben hukukçu değilim — canlıya çıkmadan önce bir hukukçu gözden geçirmeli. Şirket unvanı/iletişim bilgisi ve iletişim kanalı placeholder olarak bırakıldı. Rıza kaydı tutuluyor (`consents/{uid}`) ama tam sürüm geçmişi tutulmuyor (yalnızca en son kabul edilen sürüm) — gerçek uyumluluk için yetersiz olabilir.
