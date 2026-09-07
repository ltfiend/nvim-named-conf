-- Knowledge base for zone data ("master") files, RFC 1035 §5 syntax: the
-- $-directives, record classes, resource-record types, and special names.
-- Feeds hover and completion for buffers attached with the 'zone' dialect
-- (see zonefile.lua). Entries use the same shape as the named.conf kb
-- (summary / doc / values) so knowledge.render() works unchanged.
return {
  directives = {
    ['$TTL'] = {
      summary = 'Default TTL for records that do not specify one (RFC 2308).',
      doc = 'Syntax: `$TTL 3600` (seconds, or `1h`/`1d`/`2w` style units).\n'
        .. 'Required by BIND at the top of the file unless every record has an\n'
        .. 'explicit TTL; without it named-checkzone fails with\n'
        .. '`no TTL specified`.',
    },
    ['$ORIGIN'] = {
      summary = 'Sets the origin appended to unqualified names that follow.',
      doc = 'Syntax: `$ORIGIN example.com.` — note the **trailing dot**.\n'
        .. 'Relative owner names (`www`) become `www.example.com.`, and `@`\n'
        .. 'stands for the origin itself. Defaults to the zone name given to\n'
        .. 'named/named-checkzone.',
    },
    ['$INCLUDE'] = {
      summary = 'Reads records from another file at this point.',
      doc = 'Syntax: `$INCLUDE filename [origin]`. The optional origin applies\n'
        .. 'only inside the included file; the current origin is restored\n'
        .. 'afterwards.',
    },
    ['$GENERATE'] = {
      summary = 'BIND extension: generates a series of records from a template.',
      doc = 'Syntax: `$GENERATE 1-100 dhcp-$ A 192.0.2.$` — `$` in the\n'
        .. 'template is replaced with each value in the range. Handy for\n'
        .. 'reverse zones: `$GENERATE 1-100 $ PTR dhcp-$.example.com.`',
    },
  },

  classes = {
    IN = { summary = 'Internet class — the class for effectively all DNS data.' },
    CH = { summary = 'Chaosnet class. Survives for server metadata queries like `version.bind CH TXT`.' },
    HS = { summary = 'Hesiod class (historic directory service).' },
  },

  specials = {
    ['@'] = {
      summary = 'The current origin (the zone apex, unless $ORIGIN changed it).',
      doc = 'Records at the apex — SOA, NS, apex A/AAAA/MX — use `@` as the\n'
        .. 'owner name. A blank owner field instead repeats the previous\n'
        .. 'record\'s owner.',
    },
  },

  types = {
    SOA = {
      summary = 'Start of Authority — one per zone, first record at the apex.',
      doc = 'Fields: `MNAME RNAME (serial refresh retry expire minimum)`.\n'
        .. '- **MNAME** — primary server name.\n'
        .. '- **RNAME** — admin mailbox, `.` for `@` (hostmaster.example.com. = hostmaster@example.com).\n'
        .. '- **serial** — bump on every change; secondaries transfer only when it grows.\n'
        .. '- **refresh/retry** — how often secondaries poll / retry after failure.\n'
        .. '- **expire** — secondaries stop serving after this long without contact.\n'
        .. '- **minimum** — negative-caching TTL (RFC 2308).',
    },
    NS = {
      summary = 'Delegates the zone (or a subzone) to an authoritative name server.',
      doc = 'Every zone needs NS records at the apex naming its servers. NS at\n'
        .. 'a child name creates a delegation; add in-zone glue A/AAAA when the\n'
        .. 'server name lives inside the delegated zone.',
    },
    A = { summary = 'IPv4 address, e.g. `www  A  192.0.2.10`.' },
    AAAA = { summary = 'IPv6 address, e.g. `www  AAAA  2001:db8::10`.' },
    CNAME = {
      summary = 'Canonical-name alias to another domain name.',
      doc = 'A CNAME owner may have **no other record types** (so never at the\n'
        .. 'zone apex, which has SOA/NS). Use ANAME-style A records or HTTPS\n'
        .. 'records for apex aliasing.',
    },
    DNAME = { summary = 'Redirects an entire subtree of names (CNAME for descendants).' },
    MX = {
      summary = 'Mail exchanger: `MX 10 mail.example.com.` (preference, then host).',
      doc = 'Lower preference wins. The target must be a hostname with A/AAAA —\n'
        .. 'not a CNAME, not an IP address.',
    },
    TXT = {
      summary = 'Free-form text; carries SPF, DKIM, DMARC, and verification tokens.',
      doc = 'Quote each string; strings over 255 bytes must be split:\n'
        .. '`"v=DKIM1; k=rsa; p=MIIB..." "...rest"` — adjacent strings concatenate.',
    },
    SRV = {
      summary = 'Service locator: `_service._proto  SRV  prio weight port target.`',
      doc = 'e.g. `_ldap._tcp SRV 0 5 389 ldap.example.com.` Lower priority\n'
        .. 'wins; weight load-balances within a priority; target `.`\n'
        .. 'means "service not available".',
    },
    PTR = {
      summary = 'Reverse mapping (address → name) in in-addr.arpa / ip6.arpa zones.',
      doc = 'e.g. `10.2.0.192.in-addr.arpa.  PTR  www.example.com.`',
    },
    CAA = {
      summary = 'Which certificate authorities may issue certs for this name (RFC 8659).',
      doc = 'Syntax: `CAA flags tag "value"`.\n'
        .. '- `0 issue "letsencrypt.org"` — allow this CA.\n'
        .. '- `0 issuewild ";"` — forbid wildcard issuance.\n'
        .. '- `0 iodef "mailto:sec@example.com"` — violation reports.\n'
        .. 'Flag `128` marks the tag critical.',
    },
    DS = {
      summary = 'Delegation Signer — hash of a child zone\'s KSK, placed in the **parent**.',
      doc = 'Syntax: `DS keytag algorithm digest-type digest`. Publish in the\n'
        .. 'parent zone (via the registrar) to complete the DNSSEC chain of\n'
        .. 'trust to a signed child.',
    },
    DNSKEY = {
      summary = 'Public key used to validate the zone\'s RRSIGs (DNSSEC).',
      doc = 'Flags 257 = KSK (key-signing key), 256 = ZSK (zone-signing key).\n'
        .. 'With `dnssec-policy`, named manages these — do not hand-edit them\n'
        .. 'in the zone file.',
    },
    CDS = { summary = 'Child copy of the DS the parent should publish (automated DS updates, RFC 7344).' },
    CDNSKEY = { summary = 'Child copy of the DNSKEY the parent should build a DS from (RFC 7344).' },
    RRSIG = {
      summary = 'DNSSEC signature over an RRset. Generated by signing — never hand-written.',
    },
    NSEC = { summary = 'Authenticated denial of existence: links to the next name in the signed zone.' },
    NSEC3 = { summary = 'Hashed authenticated denial of existence (harder zone walking than NSEC).' },
    NSEC3PARAM = { summary = 'NSEC3 parameters (hash, iterations, salt) at the zone apex.' },
    ZONEMD = { summary = 'Message digest over the whole zone for verifying transfers (RFC 8976).' },
    TLSA = {
      summary = 'DANE: pins a TLS certificate/key for a service (RFC 6698).',
      doc = 'Owner encodes port/proto: `_25._tcp.mail  TLSA  3 1 1 <hash>`.\n'
        .. 'Fields: usage selector matching-type digest — `3 1 1` (DANE-EE,\n'
        .. 'SPKI, SHA-256) is the common choice for SMTP.',
    },
    SSHFP = {
      summary = 'SSH host key fingerprint: `SSHFP algorithm fp-type fingerprint`.',
      doc = 'Verified by ssh with `VerifyHostKeyDNS yes`. Algorithms: 1 RSA,\n'
        .. '3 ECDSA, 4 Ed25519; fp-type 2 = SHA-256.',
    },
    NAPTR = { summary = 'Regex-based rewriting for ENUM/SIP: `NAPTR order pref "flags" "service" "regexp" replacement`.' },
    SVCB = {
      summary = 'General service binding: priority, target, and parameters (RFC 9460).',
      doc = '`SVCB 1 target. alpn=h2 port=8443 ...` — priority 0 is an alias\n'
        .. 'form. HTTPS is the HTTP-specific variant of this type.',
    },
    HTTPS = {
      summary = 'Service binding for HTTP(S) — enables apex "aliasing" and ALPN/ECH hints.',
      doc = '`@  HTTPS  1 .  alpn=h2,h3` — target `.` means "this owner name".\n'
        .. 'The one standards-blessed way to point a zone apex at a CDN.',
    },
    LOC = { summary = 'Geographic location of a host (latitude/longitude/altitude, RFC 1876).' },
    HINFO = { summary = 'Host CPU/OS info. Also synthesized by some servers to refuse ANY queries.' },
    OPENPGPKEY = { summary = 'OpenPGP public key for an email address (DANE for e-mail, RFC 7929).' },
    SMIMEA = { summary = 'S/MIME certificate association for an email address (RFC 8162).' },
    CSYNC = { summary = 'Lets a child signal the parent to copy NS/glue automatically (RFC 7477).' },
    URI = { summary = 'Maps a name to a URI: `URI priority weight "https://..."` (RFC 7553).' },
    APL = { summary = 'Address prefix list (RFC 3123, rarely used).' },
    DHCID = { summary = 'DHCP client identifier — pairs with dynamic DNS updates from DHCP servers.' },
    KX = { summary = 'Key exchanger (RFC 2230, rarely used).' },
    SPF = {
      summary = 'Deprecated SPF type (RFC 7208 §3.1) — publish SPF in a TXT record instead.',
    },
  },
}
