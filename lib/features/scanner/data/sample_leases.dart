import 'package:equatable/equatable.dart';

/// Pre-loaded realistic sample lease with fake PII for instant offline hackathon testing.
class SampleLease extends Equatable {
  const SampleLease({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.region,
    required this.tag,
    required this.rawText,
  });

  final String id;
  final String title;
  final String subtitle;
  final String region;
  final String tag;
  final String rawText;

  @override
  List<Object?> get props => [id, title, subtitle, region, tag, rawText];
}

/// 3 realistic pre-loaded sample leases populated with realistic fake PII.
abstract final class SampleLeases {
  static const List<SampleLease> all = [
    SampleLease(
      id: 'sample_student_apt',
      title: 'Predatory Student Apartment Lease',
      subtitle: 'Non-refundable deposit, entry without notice & daily late fees',
      region: 'Austin, TX',
      tag: 'High Risk • US PII',
      rawText: '''
RESIDENTIAL STUDENT LEASE AGREEMENT
Property Address: 2418 Guadalupe Street, Apt 4B, Austin, TX 78705
Landlord: Marcus Vance (Apex Campus Holdings LLC)
Landlord Email: mvance@apexcampus-example.com | Phone: (512) 555-0194
Tenant: Jordan Rivera
Tenant SSN: 123-45-6789 | Phone: (512) 555-0148 | Email: jordan.rivera@ut-example.edu
Emergency Contact: Elena Rivera | Phone: (512) 555-0182
Rent Payment Account No: 482910384721 | Routing No: 111000025

1. TERM & RENT: Lease runs from August 15, 2026 to July 31, 2027 at \$1,450/month due on the 1st.
2. SECURITY DEPOSIT: Tenant shall pay a security deposit of \$4,350 (three months rent), of which \$750 is strictly non-refundable as a "turnover fee" and the remainder may be held up to 90 days at Landlord's sole discretion.
3. LANDLORD ENTRY: Landlord and maintenance staff reserve the right to enter the premises at any time without prior notice for inspections, showings, or routine checks.
4. LATE FEES: Any rent unpaid after 5:00 PM on the 1st incurs an immediate 15% late fee plus \$35 per day compounding daily penalty until paid in full.
5. REPAIRS & LIABILITY: Premises are leased strictly as-is. Tenant waives all claims and liability against Landlord for plumbing leaks, mold, HVAC failures, or Landlord negligence, and agrees all interior repairs are at the sole expense of Tenant.
6. EARLY TERMINATION: If Tenant vacates early for any reason, Tenant forfeits the entire security deposit and immediately owes the full remaining months balance as liquidated damages.
''',
    ),
    SampleLease(
      id: 'sample_residential_lockin',
      title: 'Residential Lease with Hidden Lock-In',
      subtitle: '11-month lock-in trap, 90-day auto-renewal & unilateral rule changes',
      region: 'Bengaluru, India',
      tag: 'Lock-In Trap • IN PII',
      rawText: '''
LEAVE AND LICENSE / RESIDENTIAL RENTAL AGREEMENT
Premises: Flat No 302, Indiranagar 100 Feet Road, Bengaluru 560038
Owner: Rajesh Kulkarni | Email: rajesh.kulkarni@example.in | Phone: +91 98450 12345
Tenant: Ananya Sharma | Aadhaar No: 4512 8890 3421 | PAN: ABCDE1234F
Tenant Phone: +91 99001 54321 | Email: ananya.sharma@example.in
Bank Account No: 00451020009182 | IFSC: HDFC0000145

1. MONTHLY RENT: ₹42,000 per month payable on or before the 5th of each month.
2. SECURITY DEPOSIT: Tenant shall pay a refundable security deposit of ₹2,50,000, which Owner shall return within 90 days of vacating after deducting painting and deep-cleaning charges at Owner's sole discretion.
3. LOCK-IN PERIOD: This agreement has a mandatory 11-month lock-in period. Should Tenant vacate early during the lock-in, Tenant shall forfeit the entire security deposit plus pay remaining months rent as penalty.
4. AUTOMATIC RENEWAL: Unless Tenant provides written notice at least 90 days prior to expiration, this lease will automatically renew for another 12 months with an automatic 20% rent escalation.
5. HOUSE RULES: Owner reserves the right to modify house rules, visitor restrictions, and maintenance surcharges at any time at Owner's sole discretion without consent of Tenant.
''',
    ),
    SampleLease(
      id: 'sample_commercial_sublease',
      title: 'Commercial Studio Sublease',
      subtitle: 'As-is structural liability, unannounced audits & punitive break clause',
      region: 'San Francisco, CA',
      tag: 'Commercial • US PII',
      rawText: '''
COMMERCIAL CREATIVE STUDIO SUBLEASE AGREEMENT
Premises: 742 Howard Street, Suite 310, San Francisco, CA 94103
Sublandlord: Evelyn Chen | Email: echen@soma-studios-example.com | Phone: (415) 555-0166
Subtenant: Liam Patel | SSN: 987-65-4321 | Phone: (415) 555-0199
Subtenant Email: liam@pixelcraft-example.io
Wire Account No: 992018374650 | Routing No: 121000358

1. SUBLEASE TERM: 24 months commencing September 1, 2026 at \$3,800/month.
2. CONDITION & REPAIRS: Studio is delivered strictly as-is. Subtenant waives all rights regarding HVAC, roof leaks, or structural defects and assumes full financial responsibility for all structural and electrical repairs at sole expense of Tenant.
3. ACCESS & INSPECTIONS: Sublandlord may enter the studio unannounced without notice at any time to verify equipment compliance or show the space to prospective clients.
4. LATE CHARGES: Rent received after the 1st incurs an immediate 10% late fee plus \$75 per day overdue penalty.
5. EARLY TERMINATION: Early termination is strictly prohibited; breaking the lease triggers immediate acceleration of the full balance of all remaining months with zero duty on Sublandlord to re-let.
''',
    ),
  ];
}
