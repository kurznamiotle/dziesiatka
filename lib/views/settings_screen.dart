import 'package:dziesiatka/models/app_accent.dart';
import 'package:dziesiatka/services/app_info_service.dart';
import 'package:dziesiatka/services/app_links.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/link_service.dart';
import 'package:dziesiatka/services/purchase_service.dart';
import 'package:dziesiatka/services/reminder_service.dart';
import 'package:dziesiatka/services/theme_service.dart';
import 'package:dziesiatka/services/usage_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/categories_screen.dart';
import 'package:dziesiatka/views/plus_screen.dart';
import 'package:dziesiatka/views/welcome_screen.dart';
import 'package:flutter/material.dart';

const _appName = 'Dziesiątka';
const _aboutText =
    'Dziesiątka to codzienna talia dziesięciu ciekawostek z krótkim quizem. '
    'Kilka minut dziennie, bez konta.';
const _privacyText =
    'Dziesiątka nie ma kont użytkowników.\n\n'
    'Postęp, ulubione, odpowiedzi z quizu, seria dni i wybrany motyw są '
    'zapisywane wyłącznie na tym urządzeniu lub w tej przeglądarce. '
    'Usunięcie aplikacji albo danych strony kasuje je bezpowrotnie.\n\n'
    'Nowe ciekawostki są pobierane z serwerów usługi Supabase, która przy '
    'połączeniu widzi adres IP urządzenia. Aplikacja nie wysyła tam Twojego '
    'postępu.\n\n'
    'Aby rozwijać aplikację, wysyłamy anonimowe statystyki: losowy '
    'identyfikator instalacji, wersję aplikacji, rodzaj systemu oraz dzienne '
    'podsumowanie, czyli liczbę kart, wynik quizu, przedział serii dni, '
    'użycie dodatkowych kart i wybory z pierwszego uruchomienia. W wersji '
    'internetowej robimy to dopiero po Twojej zgodzie.\n\n'
    'Osobno sumujemy, jak często każda ciekawostka była pokazana, polubiona, '
    'rozwinięta i udostępniona oraz jak często odpowiedź na jej pytanie była '
    'poprawna. Te sumy nie mają identyfikatora, więc nie pokazują, kto co '
    'czytał.\n\n'
    'Nie zbieramy imienia, adresu e-mail, lokalizacji ani modelu telefonu. '
    'Możesz to wyłączyć w ustawieniach opcją „Anonimowe statystyki”. '
    'Wyłączenie kasuje identyfikator i niewysłane dane.\n\n'
    'Gdy zgłosisz błąd w ciekawostce, na serwery usługi Supabase trafia, '
    'której ciekawostki dotyczy, wybrany powód i Twój komentarz. Zgłoszenie '
    'nie ma identyfikatora, więc nie wpisuj w komentarzu danych o sobie.\n\n'
    'Przypomnienia są planowane na tym urządzeniu i nie przechodzą przez '
    'żaden serwer.\n\n'
    'Pod niektórymi ciekawostkami jest link partnerski do produktu '
    'związanego z tematem. Otwiera się w przeglądarce, poza aplikacją, a '
    'sklep i sieć afiliacyjna (TradeTracker) mogą wtedy zapisać plik cookie, '
    'żeby przypisać ewentualny zakup. Aplikacja nie przekazuje im żadnych '
    'Twoich danych. Za zgodą na anonimowe statystyki liczymy tylko, przy '
    'której ciekawostce link został otwarty.\n\n'
    'Zakupy w aplikacji, czyli Dziesiątkę+ i napiwki, obsługuje Google Play. '
    'Dane płatności widzi tylko Google, a aplikacja zapisuje na urządzeniu '
    'jedynie, czy masz Dziesiątkę+.\n\n'
    'Grafika trafia do innych aplikacji tylko wtedy, gdy sam ją '
    'udostępnisz.\n\n'
    'Linki otwierają się poza aplikacją, na stronach z własnymi zasadami '
    'prywatności. Wersja internetowa pobiera czcionki z serwerów Google, '
    'które mogą przy tym zobaczyć adres IP.';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.themeService,
    this.purchaseService,
    this.factsService,
    this.reminderService,
    this.usageService,
    this.linkService = const LinkService(),
    this.appInfoService = const AppInfoService(),
    this.supportUrl = AppLinks.supportInApp,
  });

  final ThemeService themeService;
  final PurchaseService? purchaseService;
  final FactsService? factsService;
  final ReminderService? reminderService;
  final UsageService? usageService;
  final LinkService linkService;
  final AppInfoService appInfoService;

  /// Without an address the support section is hidden.
  final String? supportUrl;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _version;
  bool? _remindersEnabled;
  bool? _usageEnabled;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadSwitches();
  }

  Future<void> _loadSwitches() async {
    final reminders = widget.reminderService;
    final remindersEnabled = reminders == null || !reminders.isSupported
        ? null
        : await reminders.isEnabled();
    final usageEnabled = await widget.usageService?.isEnabled();
    if (!mounted) return;
    setState(() {
      _remindersEnabled = remindersEnabled;
      _usageEnabled = usageEnabled;
    });
  }

  Future<void> _setRemindersEnabled(bool isEnabled) async {
    final result = await widget.reminderService!.setEnabled(isEnabled);
    if (!mounted) return;
    setState(() => _remindersEnabled = result);
    if (isEnabled && !result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Włącz powiadomienia w ustawieniach telefonu.'),
        ),
      );
    }
  }

  Future<void> _setUsageEnabled(bool isEnabled) async {
    setState(() => _usageEnabled = isEnabled);
    await widget.usageService!.setEnabled(isEnabled);
  }

  Future<void> _loadVersion() async {
    try {
      final version = await widget.appInfoService.getVersion();
      if (mounted) setState(() => _version = version);
    } catch (_) {
      // The tile keeps its placeholder, which is enough for a detail like this.
    }
  }

  Future<void> _openLink(String url) async {
    final opened = await widget.linkService.open(url);
    if (opened || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nie udało się otworzyć linku.')),
    );
  }

  void _openCategories() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoriesScreen(
          factsService: widget.factsService ?? FactsService(),
          onChanged: widget.usageService?.categoriesChanged,
        ),
      ),
    );
  }

  void _openPlus(PurchaseService purchases) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlusScreen(purchaseService: purchases),
      ),
    );
  }

  void _openInstructions() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            WelcomeScreen(onFinished: () => Navigator.of(context).pop()),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Polityka prywatności'),
        content: const SingleChildScrollView(child: Text(_privacyText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: _appName,
      applicationVersion: _version,
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchases = widget.purchaseService;
    if (purchases == null) return _buildScreen(context, null);
    return ListenableBuilder(
      listenable: purchases,
      builder: (context, _) => _buildScreen(context, purchases),
    );
  }

  Widget _buildScreen(BuildContext context, PurchaseService? purchases) {
    final hasPlus = purchases?.hasPlus ?? false;
    final remindersEnabled = _remindersEnabled;
    final usageEnabled = _usageEnabled;
    final supportUrl = widget.supportUrl;
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            const _SectionHeader('Wygląd'),
            _ThemeOptions(themeService: widget.themeService),
            if (hasPlus) _AccentOptions(themeService: widget.themeService),
            if (purchases != null && purchases.showsPlus) ...[
              const _SectionHeader('Dziesiątka+'),
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: const Text('Dziesiątka+'),
                subtitle: Text(
                  hasPlus
                      ? 'Aktywna. Dziękujemy za wsparcie!'
                      : 'Bez poleceń partnerskich, więcej kolorów',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openPlus(purchases),
              ),
            ],
            const _SectionHeader('Ciekawostki'),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Kategorie'),
              onTap: _openCategories,
            ),
            if (remindersEnabled != null)
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Przypomnienie o 18:00'),
                subtitle: const Text('Tylko gdy talia nie jest ukończona'),
                value: remindersEnabled,
                onChanged: _setRemindersEnabled,
              ),
            if (supportUrl != null) ...[
              const _SectionHeader('Wsparcie i rozwój'),
              _LinkTile(
                icon: Icons.local_cafe_outlined,
                title: 'Postaw kawę twórcy ☕',
                url: supportUrl,
                onOpen: _openLink,
              ),
            ],
            const _SectionHeader('O aplikacji'),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded),
              title: const Text('Instrukcja'),
              onTap: _openInstructions,
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Wersja'),
              trailing: Text(_version ?? '–'),
            ),
            const ListTile(
              leading: Icon(Icons.auto_awesome_outlined),
              title: Text(_appName),
              subtitle: Text(_aboutText),
            ),
            if (usageEnabled != null)
              SwitchListTile(
                secondary: const Icon(Icons.query_stats_rounded),
                title: const Text('Anonimowe statystyki'),
                subtitle: const Text(
                  'Pomagają ulepszać aplikację i ciekawostki',
                ),
                value: usageEnabled,
                onChanged: _setUsageEnabled,
              ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Polityka prywatności'),
              onTap: _showPrivacyPolicy,
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Licencje'),
              onTap: _showLicenses,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ThemeOptions extends StatelessWidget {
  const _ThemeOptions({required this.themeService});

  final ThemeService themeService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) => Column(
        children: [
          _buildOption(
            ThemeMode.light,
            icon: Icons.light_mode_outlined,
            title: 'Jasny',
          ),
          _buildOption(
            ThemeMode.dark,
            icon: Icons.dark_mode_outlined,
            title: 'Ciemny',
          ),
          _buildOption(
            ThemeMode.system,
            icon: Icons.brightness_auto_outlined,
            title: 'Zgodny z systemem',
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    ThemeMode mode, {
    required IconData icon,
    required String title,
  }) {
    final isSelected = themeService.themeMode == mode;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: isSelected,
      trailing: isSelected ? const Icon(Icons.check_rounded) : null,
      onTap: () => themeService.setThemeMode(mode),
    );
  }
}

class _AccentOptions extends StatelessWidget {
  const _AccentOptions({required this.themeService});

  final ThemeService themeService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) => ListTile(
        leading: const Icon(Icons.palette_outlined),
        title: const Text('Kolor akcentu'),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final accent in AppAccent.values)
                _buildChip(context, accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, AppAccent accent) {
    final brightness = Theme.of(context).brightness;
    final color = AppTheme.of(accent, brightness).colorScheme.primary;
    return ChoiceChip(
      avatar: CircleAvatar(backgroundColor: color, radius: 8),
      label: Text(accent.label),
      selected: themeService.accent == accent,
      onSelected: (_) => themeService.setAccent(accent),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.url,
    required this.onOpen,
  });

  final IconData icon;
  final String title;
  final String url;
  final void Function(String url) onOpen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.open_in_new_rounded),
      onTap: () => onOpen(url),
    );
  }
}
