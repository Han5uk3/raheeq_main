/// The rate the app labels VAT with when a checkout or order predates the
/// backend's per-order VAT snapshot and so carries no `vatPercentage`. Saudi
/// VAT has stood at 15% since 2020.
const double defaultVatPercentage = 15.0;
