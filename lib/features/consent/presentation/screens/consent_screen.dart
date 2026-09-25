import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/wizard_widgets.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';

/// KVKK consent gate — between `/account-type` and `/phone`, i.e. before
/// any personal data (a phone number) is collected at all.
///
/// **This wording is a draft, not a reviewed legal text.** It's written to
/// be structurally complete (data controller, purposes, legal basis,
/// recipients/cross-border transfer, KVKK m.11 rights) so a lawyer has a
/// real starting point instead of a blank page — see REQUIREMENTS.md §7
/// and the `project-bi-nasip-firebase-status` memory note. Don't ship this
/// to production users without that review; nothing about *how* consent
/// is captured (two separate checkboxes, one for processing and one for
/// the cross-border transfer, both required to continue) should need to
/// change after review — only the notice text itself might.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _dataProcessingAccepted = false;
  bool _crossBorderAccepted = false;
  bool _noticeExpanded = false;

  bool get _canContinue => _dataProcessingAccepted && _crossBorderAccepted;

  void _continue() {
    context.read<AuthCubit>().acceptConsent();
    context.push('/phone');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: WizardBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const WizardHeader(
                  icon: Icons.shield_rounded,
                  title: 'Devam etmeden önce.',
                  subtitle:
                      'Bi Nasip’i kullanmak için bazı kişisel verilerini işlememiz '
                      'gerekiyor. Bunu neden ve nasıl yaptığımızı burada özetliyoruz; '
                      'tam metni istediğin zaman okuyabilirsin.',
                  step: 2,
                  totalSteps: 5,
                ),
                const SizedBox(height: 22),
                _SummaryPoint(
                  icon: Icons.badge_outlined,
                  text:
                      'Telefon numaran, profil bilgilerin ve doğrulama sonucun '
                      'yalnızca Bi Nasip’i çalıştırmak için kullanılır.',
                ),
                _SummaryPoint(
                  icon: Icons.favorite_border,
                  text:
                      'Din/mezhep gibi hassas bilgileri paylaşmak tamamen '
                      'sana kalmış — bu alanlar opsiyoneldir.',
                ),
                _SummaryPoint(
                  icon: Icons.lock_outline,
                  text:
                      'Selfie’n hiçbir zaman bizim sunucularımızda saklanmaz; '
                      'yalnızca "doğrulandı" bilgisi tutulur.',
                ),
                _SummaryPoint(
                  icon: Icons.public,
                  text:
                      'Verilerin, altyapı sağlayıcımız (Firebase/Google Cloud) '
                      'aracılığıyla Avrupa Birliği sınırları içinde işlenir.',
                ),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    initiallyExpanded: _noticeExpanded,
                    onExpansionChanged: (v) =>
                        setState(() => _noticeExpanded = v),
                    title: Text(
                      'Aydınlatma metninin tamamını oku',
                      style: textTheme.titleSmall,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: const [_FullNoticeText()],
                  ),
                ),
                const SizedBox(height: 20),
                _ConsentCheckbox(
                  value: _dataProcessingAccepted,
                  onChanged: (v) =>
                      setState(() => _dataProcessingAccepted = v ?? false),
                  label:
                      'Kişisel verilerimin, yukarıdaki aydınlatma metninde '
                      'açıklanan amaçlarla işlenmesini kabul ediyorum.',
                ),
                const SizedBox(height: 12),
                _ConsentCheckbox(
                  value: _crossBorderAccepted,
                  onChanged: (v) =>
                      setState(() => _crossBorderAccepted = v ?? false),
                  label:
                      'Verilerimin yurt dışında (Avrupa Birliği sınırları '
                      'içinde) barındırılan sunucularda işlenmesine açık rıza '
                      'veriyorum.',
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: 'Kabul ediyorum, devam et',
                  onPressed: _canContinue ? _continue : null,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bu iki onay olmadan Bi Nasip’i kullanamazsın, çünkü uygulama '
                  'temelde bu verilerin işlenmesine dayanıyor. Fikrini '
                  'değiştirirsen hesabını ve verilerini istediğin zaman '
                  'Ayarlar’dan kalıcı olarak silebilirsin.',
                  style: textTheme.bodySmall?.copyWith(color: colors.inkSoft),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryPoint extends StatelessWidget {
  const _SummaryPoint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.brass),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _ConsentCheckbox extends StatelessWidget {
  const _ConsentCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: value, onChanged: onChanged),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(label, style: textTheme.bodyMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The full notice text — structurally follows KVKK m.10's required
/// elements. See the file-level doc comment: this is a draft for legal
/// review, not final copy.
class _FullNoticeText extends StatelessWidget {
  const _FullNoticeText();

  static const _sections = [
    (
      'Veri sorumlusu',
      'Bu uygulamayı işleten Bi Nasip (kapalı beta), 6698 sayılı Kişisel '
          'Verilerin Korunması Kanunu ("KVKK") kapsamında veri sorumlusudur. '
          '[Şirket unvanı ve iletişim bilgileri, ticari kuruluş '
          'tamamlandığında buraya eklenecek.]',
    ),
    (
      'Hangi verileri topluyoruz',
      'Telefon numaran (kimlik doğrulama için), profilinde paylaştığın '
          'bilgiler (ad, doğum tarihi, şehir, fotoğrafların, evlilik niyetin '
          've paylaşmayı tercih edersen eğitim/meslek/dini pratik/mezhep '
          'bilgin), selfie doğrulamasının SONUCU (bir görsel değil, sadece '
          '"doğrulandı" bilgisi ve zamanı), eşleşme ve mesajlaşma '
          'etkileşimlerin, ve varsa bağlı bir aile hesabının bu verilere '
          'erişim kaydı.',
    ),
    (
      'Neden topluyoruz',
      'Hesabını oluşturmak ve doğrulamak, sana uygun adayları göstermek, '
          'eşleştiğin kişilerle mesajlaşmanı sağlamak, hesabının '
          'güvenliğini korumak (sahte hesap/kötüye kullanım tespiti), '
          'tercih ettiysen aile bağlantısı özelliğini çalıştırmak ve yasal '
          'yükümlülüklerimizi yerine getirmek.',
    ),
    (
      'Hukuki sebep',
      'Verilerin işlenmesi, aramızdaki sözleşmenin (Bi Nasip\'i kullanım '
          'şartların) kurulması ve ifası için gereklidir (KVKK m.5/2-c). '
          'Din/mezhep gibi özel nitelikli verilerin işlenmesi ise açık '
          'rızana dayanır (KVKK m.6) — bu alanlar tamamen opsiyoneldir, '
          'doldurmayabilirsin.',
    ),
    (
      'Kimlerle paylaşıyoruz',
      'Verilerin, hizmeti çalıştırmamıza yardımcı olan altyapı '
          'sağlayıcımız (Google Firebase/Google Cloud) ile ve yalnızca '
          'kimlik doğrulama amacıyla bağımsız bir doğrulama sağlayıcısıyla '
          'paylaşılır. Başka hiçbir üçüncü tarafla, izin verdiğin '
          'durumlar (ör. aile bağlantısı) dışında paylaşılmaz; hiçbir '
          'zaman satılmaz.',
    ),
    (
      'Yurt dışı aktarım',
      'Verilerin, altyapı sağlayıcımızın Avrupa Birliği sınırları '
          'içindeki sunucularında (Google Cloud, eur3 bölgesi) işlenir. Bu, '
          'KVKK kapsamında yurt dışına aktarım sayılır ve ayrı bir açık '
          'rızana dayanır.',
    ),
    (
      'Ne kadar süre saklıyoruz',
      'Hesabın aktif olduğu sürece saklanır. Hesabını sildiğinde, '
          'profilin ve ilişkili verilerin (yasal saklama yükümlülüklerimiz '
          'dışında kalanlar) kalıcı olarak silinir.',
    ),
    (
      'Haklarınız (KVKK m.11)',
      'Verilerinin işlenip işlenmediğini öğrenme, işlenmişse bilgi talep '
          'etme, işlenme amacını ve amacına uygun kullanılıp '
          'kullanılmadığını öğrenme, yurt içinde/dışında aktarıldığı '
          'üçüncü kişileri bilme, eksik/yanlış işlenmişse düzeltilmesini '
          'isteme, KVKK\'nın öngördüğü şartlarda silinmesini/yok '
          'edilmesini isteme, ve bu işlemlerin aktarıldığı üçüncü '
          'kişilere bildirilmesini isteme haklarına sahipsin. Bu '
          'haklarını Ayarlar ekranından hesabını silerek, ya da '
          '[iletişim kanalı eklenecek] üzerinden bize ulaşarak '
          'kullanabilirsin.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (title, body) in _sections)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
