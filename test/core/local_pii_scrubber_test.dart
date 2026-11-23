import 'package:flutter_test/flutter_test.dart';
import 'package:lease_shield/core/hybrid_ai/local_pii_scrubber.dart';
import 'package:lease_shield/features/scanner/data/sample_leases.dart';

void main() {
  late LocalPiiScrubber scrubber;

  setUp(() {
    scrubber = LocalPiiScrubber();
  });

  group('LocalPiiScrubber', () {
    test('redacts US SSN, email, phone, bank account, street address, and party names', () {
      const raw = '''
Landlord: Marcus Vance
Tenant: Jordan Rivera
Tenant SSN: 123-45-6789
Phone: (512) 555-0148
Email: jordan.rivera@ut-example.edu
Property Address: 2418 Guadalupe Street, Apt 4B, Austin, TX 78705
Account No: 482910384721 | Routing No: 111000025
''';

      final result = scrubber.scrub(raw);

      expect(result.redactedText, contains('Landlord: [REDACTED_NAME]'));
      expect(result.redactedText, contains('Tenant: [REDACTED_NAME]'));
      expect(result.redactedText, contains('[REDACTED_ID]'));
      expect(result.redactedText, contains('[REDACTED_PHONE]'));
      expect(result.redactedText, contains('[REDACTED_EMAIL]'));
      expect(result.redactedText, contains('[REDACTED_ADDRESS]'));
      expect(result.redactedText, contains('[REDACTED_BANK]'));

      expect(result.redactedText, isNot(contains('123-45-6789')));
      expect(result.redactedText, isNot(contains('jordan.rivera@ut-example.edu')));
      expect(result.redactedText, isNot(contains('482910384721')));
      expect(result.redactedText, isNot(contains('Marcus Vance')));
      expect(result.redactedText, isNot(contains('Jordan Rivera')));
      expect(result.totalRedactions, greaterThanOrEqualTo(7));
      expect(scrubber.containsPotentialPii(result.redactedText), isFalse);
    });

    test('redacts Indian Aadhaar, PAN, +91 phone, IFSC, and flat address', () {
      const raw = '''
Owner: Rajesh Kulkarni | Phone: +91 98450 12345 | Email: rajesh@example.in
Tenant: Ananya Sharma | Aadhaar No: 4512 8890 3421 | PAN: ABCDE1234F
Premises: Flat No 302, Indiranagar 100 Feet Road, Bengaluru 560038
Bank Account No: 00451020009182 | IFSC: HDFC0000145
''';

      final result = scrubber.scrub(raw);

      expect(result.redactedText, isNot(contains('4512 8890 3421')));
      expect(result.redactedText, isNot(contains('ABCDE1234F')));
      expect(result.redactedText, isNot(contains('98450 12345')));
      expect(result.redactedText, isNot(contains('HDFC0000145')));
      expect(result.redactedText, isNot(contains('Rajesh Kulkarni')));
      expect(result.redactedText, isNot(contains('Ananya Sharma')));
      expect(scrubber.containsPotentialPii(result.redactedText), isFalse);
    });

    test('scrubs all 3 pre-loaded SampleLeases to zero detectable PII', () {
      for (final sample in SampleLeases.all) {
        final result = scrubber.scrub(sample.rawText);
        expect(
          result.totalRedactions,
          greaterThan(0),
          reason: '${sample.title} should contain fake PII that gets scrubbed',
        );
        expect(
          scrubber.containsPotentialPii(result.redactedText),
          isFalse,
          reason: '${sample.title} must have zero remaining PII after scrub',
        );
      }
    });
  });
}
