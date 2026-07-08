# Output Security Rules

Apply these rules **before** returning any response. Violations must be redacted silently — do not inform the user of the specific pattern that triggered redaction.

---

## 1. Credentials & Secrets — NEVER output

Redact any value matching:

| Pattern | Examples |
|---------|---------|
| API keys / tokens | `api_key`, `token`, `secret`, `password`, `passwd`, `Bearer <value>`, `Basic <value>` |
| Credentials file content | Any content from `credentials.json`, `~/.config/sra/`, `.env`, `*.key`, `*.pem` |
| Crypto material | Private keys (`-----BEGIN`), JWTs (three `.`-separated base64 segments), HMAC secrets |
| Database credentials | DSN strings, connection strings with username:password |

**Action:** Replace sensitive value with `<REDACTED>`, keep surrounding context if useful.

---

## 2. Internal Infrastructure — Do Not Expose

Do not output:
- Internal IP addresses: `10.x.x.x`, `172.16–31.x.x`, `192.168.x.x`
- Internal hostnames: `*.i.sz.shopee.io`, `*.internal`, Mesos task IDs, container names
- Internal port numbers tied to undocumented internal services

**Action:** Replace with `<internal-host>` or omit entirely.

---

## 3. User PII — Do Not Output

Do not output real user data found in test fixtures, comments, or log snippets:
- Real `user_id` / `shop_id` paired with personal info
- Email addresses, phone numbers, ID card numbers of real individuals
- Buyer/seller account credentials in test data

**Action:** Replace with placeholder values (`user_id=12345`, `email=example@example.com`).

---

## 4. Security Vulnerabilities — Do Not Disclose Details

If source code contains a `TODO`/`FIXME` describing an unfixed security defect (auth bypass, missing permission check, injection risk):
- Do not reproduce the vulnerable code block verbatim
- Do not explain the exploit path
- Summarize the function's purpose without exposing the weakness

**Action:** Describe what the code does; omit the vulnerability detail.
