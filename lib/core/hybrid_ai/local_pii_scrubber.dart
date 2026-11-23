import 'package:equatable/equatable.dart';

/// Result of deterministic on-device regex PII redaction.
class PiiScrubResult extends Equatable {
  const PiiScrubResult({
    required this.redactedText,
    required this.redactionCounts,
  });

  final String redactedText;
  final Map<String, int> redactionCounts;

  int get totalRedactions =>
      redactionCounts.values.fold(0, (sum, count) => sum + count);

  @override
  List<Object?> get props => [redactedText, redactionCounts];
}

/// Deterministic, offline-safe regex PII scrubber.
///
/// Always runs locally before any cloud fallback or Firestore persistence to
/// mathematically guarantee zero raw PII leaves the device.
class LocalPiiScrubber {
  static final RegExp _ssnRegex = RegExp(
    r'\b\d{3}[-\s]?\d{2}[-\s]?\d{4}\b',
  );

  static final RegExp _aadhaarRegex = RegExp(
    r'\b[2-9]\d{3}[\s-]?\d{4}[\s-]?\d{4}\b',
  );

  static final RegExp _panRegex = RegExp(
    r'\b[A-Z]{5}\d{4}[A-Z]\b',
  );

  static final RegExp _labeledIdRegex = RegExp(
    r'(?:SSN|Social\s*Security|Aadhaar|PAN|Passport|Driver(?:\x27s)?\s*License|Govt\.?\s*ID|National\s*ID)\s*(?:No\.?|Number|#|:)?\s*[:#-]?\s*[A-Z0-9-]{6,20}',
    caseSensitive: false,
  );

  static final RegExp _bankAccountRegex = RegExp(
    r'(?:Account\s*(?:No\.?|Number|#)|A/C\s*(?:No\.?)?|Routing\s*(?:No\.?|Number|#)|IFSC|IBAN|SWIFT)\s*[:#-]?\s*[A-Z0-9-]{6,24}',
    caseSensitive: false,
  );

  static final RegExp _emailRegex = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
  );

  static final RegExp _phoneRegex = RegExp(
    r'(?:(?:\+?\d{1,3}[\s.-]?)?(?:\(\d{3}\)|\d{3})[\s.-]?\d{3}[\s.-]?\d{4}|\+91[\s-]?\d{5}[\s-]?\d{5})',
  );

  static final RegExp _streetAddressRegex = RegExp(
    r'\b\d{1,5}\s+[A-Z][A-Za-z0-9.\s]{2,32}\s+(?:Street|St\.?|Avenue|Ave\.?|Road|Rd\.?|Boulevard|Blvd\.?|Drive|Dr\.?|Lane|Ln\.?|Way|Court|Ct\.?|Circle|Cir\.?|Terrace|Place|Pl\.?)(?:,\s*(?:Apt\.?|Unit|Suite|Ste\.?|Flat|#)\s*[A-Za-z0-9-]+)?(?:,\s*[A-Za-z\s]+,\s*[A-Z]{2}\s*\d{5}(?:-\d{4})?)?',
  );

  static final RegExp _indianFlatAddressRegex = RegExp(
    r'\b(?:Flat|House|Plot|Door|No\.?)\s*(?:No\.?\s*)?[A-Z0-9/-]{1,8},\s*[A-Za-z0-9\s.-]{3,40}(?:Road|Nagar|Layout|Colony|Enclave|Avenue|Cross|Main|Sector\s*\d+)(?:,\s*[A-Za-z\s]+)?(?:[-\s]*\d{6})?',
    caseSensitive: false,
  );

  static final RegExp _labeledPartyNameRegex = RegExp(
    r'(Landlord|Lessor|Owner|Tenant|Lessee|Occupant|Co-Signer|Guarantor|Emergency[ \t]+Contact|Property[ \t]+Manager|Sublandlord|Subtenant)([ \t]*(?:Name)?[ \t]*:[ \t]*)([A-Z][a-z]+(?:[ \t]+[A-Z]\.?)?(?:[ \t]+[A-Z][a-z]+){1,2})',
  );

  static final RegExp _honorificNameRegex = RegExp(
    r'\b(?:Mr\.|Mrs\.|Ms\.|Dr\.)[ \t]+[A-Z][a-z]+(?:[ \t]+[A-Z][a-z]+){1,2}\b',
  );

  /// Redacts all detected PII categories and returns both redacted text and counts.
  PiiScrubResult scrub(String rawText) {
    final counts = <String, int>{};
    var output = rawText;

    output = _replaceAndCount(
      output,
      _emailRegex,
      '[REDACTED_EMAIL]',
      'Emails',
      counts,
    );
    output = _replaceAndCount(
      output,
      _bankAccountRegex,
      '[REDACTED_BANK]',
      'Bank Accounts',
      counts,
    );
    output = _replaceAndCount(
      output,
      _labeledIdRegex,
      '[REDACTED_ID]',
      'Gov IDs',
      counts,
    );
    output = _replaceAndCount(
      output,
      _aadhaarRegex,
      '[REDACTED_ID]',
      'Gov IDs',
      counts,
    );
    output = _replaceAndCount(
      output,
      _ssnRegex,
      '[REDACTED_ID]',
      'Gov IDs',
      counts,
    );
    output = _replaceAndCount(
      output,
      _panRegex,
      '[REDACTED_ID]',
      'Gov IDs',
      counts,
    );
    output = _replaceAndCount(
      output,
      _phoneRegex,
      '[REDACTED_PHONE]',
      'Phone Numbers',
      counts,
    );
    output = _replaceAndCount(
      output,
      _streetAddressRegex,
      '[REDACTED_ADDRESS]',
      'Addresses',
      counts,
    );
    output = _replaceAndCount(
      output,
      _indianFlatAddressRegex,
      '[REDACTED_ADDRESS]',
      'Addresses',
      counts,
    );

    // Labeled names preserve the role label ("Tenant: [REDACTED_NAME]")
    output = output.replaceAllMapped(_labeledPartyNameRegex, (match) {
      counts['Names'] = (counts['Names'] ?? 0) + 1;
      return '${match.group(1)}${match.group(2)}[REDACTED_NAME]';
    });

    output = _replaceAndCount(
      output,
      _honorificNameRegex,
      '[REDACTED_NAME]',
      'Names',
      counts,
    );

    return PiiScrubResult(
      redactedText: output,
      redactionCounts: Map.unmodifiable(counts),
    );
  }

  /// Quick verification check used by the Glass Box outbound payload inspector.
  bool containsPotentialPii(String text) {
    return _emailRegex.hasMatch(text) ||
        _ssnRegex.hasMatch(text) ||
        _aadhaarRegex.hasMatch(text) ||
        _panRegex.hasMatch(text) ||
        _phoneRegex.hasMatch(text) ||
        _bankAccountRegex.hasMatch(text) ||
        _streetAddressRegex.hasMatch(text);
  }

  String _replaceAndCount(
    String input,
    RegExp regex,
    String placeholder,
    String category,
    Map<String, int> counts,
  ) {
    return input.replaceAllMapped(regex, (_) {
      counts[category] = (counts[category] ?? 0) + 1;
      return placeholder;
    });
  }
}
