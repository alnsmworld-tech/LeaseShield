/// Central configuration constants and Firebase Remote Config defaults for LeaseShield.
abstract final class AppConfig {
  static const String appName = 'LeaseShield';
  static const String hybridAiChannelName = 'com.leaseshield/hybrid_ai';

  // Remote Config parameter keys
  static const String rcRedFlagPromptKey = 'red_flag_prompt_template';
  static const String rcNegotiationPromptKey = 'negotiation_prompt_template';
  static const String rcDefaultTriageModeKey = 'default_triage_mode';

  // Default cloud Gemini model for Firebase AI Logic
  static const String defaultCloudModel = 'gemini-2.5-flash';

  // Default Remote Config values
  static const String defaultTriageMode = 'ONLY_ON_DEVICE';

  static const String defaultRedFlagPromptTemplate = '''
You are LeaseShield, an on-device privacy-first rental agreement analyst.
Analyze the following rental lease text.
1. Redact ALL personally identifiable information (PII) using placeholders: [REDACTED_NAME], [REDACTED_PHONE], [REDACTED_EMAIL], [REDACTED_ID], [REDACTED_BANK], [REDACTED_ADDRESS].
2. Identify predatory, unfair, or risky clauses (e.g., excessive security deposit, non-refundable fees, unilateral entry without notice, automatic renewal traps, hidden lock-in penalties, waiving habitability or legal rights, unreasonable late fees).
3. Return ONLY valid JSON matching this exact schema (no markdown fences):
{
  "redactedText": "<full lease text with all PII replaced>",
  "overallRiskScore": <integer 0-100>,
  "summary": "<2-sentence neutral summary with zero PII>",
  "clauses": [
    {
      "id": "<short_id>",
      "title": "<short clause title>",
      "severity": "HIGH" | "MEDIUM" | "LOW",
      "category": "<Deposit | Entry | Lock-In | Fees | Liability | Renewal | Termination | Other>",
      "excerpt": "<redacted excerpt from lease>",
      "explanation": "<why this is risky for the tenant>",
      "recommendation": "<concrete change to request>"
    }
  ]
}

LEASE TEXT:
{{LEASE_TEXT}}
''';

  static const String defaultNegotiationPromptTemplate = '''
You are an expert tenant-rights negotiation assistant.
Using ONLY the anonymized, redacted lease clauses below and the tenant's city/region, draft a polite, firm, and legally informed counter-offer email to the landlord.
Never invent personal names, phone numbers, or addresses—use bracketed placeholders like [Landlord Name] and [Tenant Name].
Ground your requested revisions in typical regional tenant-protection norms for {{REGION}} while adding a brief disclaimer that this is informational and not formal legal advice.

Return ONLY valid JSON matching this exact schema (no markdown fences):
{
  "subject": "<concise professional email subject>",
  "body": "<full email body with clear bullet points for each requested revision>",
  "regionalNorms": ["<relevant tenant protection norm 1>", "<relevant tenant protection norm 2>"],
  "toneSummary": "<1-sentence description of negotiation strategy>"
}

CITY / REGION: {{REGION}}
TONE: {{TONE}}
REDACTED CLAUSES TO NEGOTIATE:
{{REDACTED_CLAUSES}}
''';

  static Map<String, Object> get remoteConfigDefaults => {
        rcRedFlagPromptKey: defaultRedFlagPromptTemplate,
        rcNegotiationPromptKey: defaultNegotiationPromptTemplate,
        rcDefaultTriageModeKey: defaultTriageMode,
      };
}
