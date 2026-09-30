/// Public legal pages, served by GitHub Pages from `site/`
/// (deployed by `.github/workflows/pages.yml`).
///
/// Both stores require the privacy policy to be reachable from inside the
/// app, and Play requires the account-deletion page to work without it. The
/// same URLs go into App Store Connect and Play Console, so change them here
/// and there together.
class LegalLinks {
  LegalLinks._();

  static const _base =
      'https://liosdali.github.io/exercise-tracker-mobile-application';

  static final privacyPolicy = Uri.parse('$_base/privacy.html');
  static final termsOfUse = Uri.parse('$_base/terms.html');
  static final deleteAccount = Uri.parse('$_base/delete-account.html');

  /// Bump when the terms change materially, so everyone is asked again.
  static const communityTermsVersion = 1;
}
