-- Knowledge base: statements for the smaller clause blocks — acl / view / key /
-- key-store / server / controls / tls / http / dlz / dnssec-policy — plus the
-- shared values (built-in ACLs, booleans) used across scopes. Coverage follows
-- the BIND 9.20.23 grammar.
return {
  -- Statements inside `key { }` (a TSIG key).
  key = {
    algorithm = {
      summary = 'The HMAC algorithm for this TSIG key.',
      doc = 'Use `hmac-sha256` (recommended) or stronger. `hmac-md5` is legacy.',
      values = {
        ['hmac-sha256'] = 'SHA-256 HMAC (recommended).',
        ['hmac-sha512'] = 'SHA-512 HMAC.',
        ['hmac-sha384'] = 'SHA-384 HMAC.',
        ['hmac-sha224'] = 'SHA-224 HMAC.',
        ['hmac-sha1'] = 'SHA-1 HMAC (weak).',
        ['hmac-md5'] = 'MD5 HMAC (legacy, avoid).',
      },
    },
    secret = {
      summary = 'The base64-encoded shared secret for this key.',
      doc = 'Generate with `tsig-keygen` or `rndc-confgen`. Keep it out of\n'
        .. 'world-readable files; include from a 0640 file owned by named.',
    },
  },

  -- Statements inside `key-store { }` — where DNSSEC keys are stored.
  key_store = {
    directory = {
      summary = 'Directory in which DNSSEC key files for this store are kept.',
    },
    ['pkcs11-uri'] = {
      summary = 'PKCS#11 URI selecting an HSM token to hold/generate keys.',
      doc = 'Enables offline-KSK / HSM-backed signing (RFC 7512 URI).',
    },
  },

  -- Statements inside `view { }` that are not shared with options.
  view = {
    ['match-clients'] = {
      summary = 'Address-match list selecting which clients this view serves.',
      doc = 'Evaluated in order; the first view whose list matches wins.',
    },
    ['match-destinations'] = {
      summary = 'Match on the query\'s destination address as well as the source.',
    },
    ['match-recursive-only'] = {
      summary = 'Only match recursive (RD=1) queries for this view.',
      values = { yes = 'Match recursive queries only.', no = 'Match any query.' },
    },
  },

  -- Statements inside `server <prefix> { }` — per-remote-peer settings.
  server = {
    bogus = {
      summary = 'Stop sending queries to this server (it gives bad data).',
      values = { yes = 'Treat as bogus; do not query.', no = 'Normal.' },
    },
    edns = {
      summary = 'Whether to use EDNS when talking to this server.',
      values = { yes = 'Use EDNS (default).', no = 'Disable EDNS for this peer.' },
    },
    ['edns-udp-size'] = { summary = 'EDNS UDP buffer size to advertise to this peer.' },
    ['edns-version'] = { summary = 'Maximum EDNS version to send to this peer.' },
    keys = {
      summary = 'TSIG key to use when contacting this server.',
      doc = 'Syntax: `keys "key-name";` — signs transfers/notifies to it.',
    },
    ['max-udp-size'] = { summary = 'Largest EDNS UDP response to accept from this peer.' },
    ['notify-source'] = { summary = 'Local IPv4 source address/port for NOTIFY to this peer.' },
    ['notify-source-v6'] = { summary = 'Local IPv6 source address/port for NOTIFY to this peer.' },
    padding = { summary = 'Block size (bytes) for EDNS padding sent to this peer.' },
    ['provide-ixfr'] = {
      summary = 'Whether to offer incremental transfers to this peer (as primary).',
      values = { yes = 'Offer IXFR.', no = 'Only AXFR.' },
    },
    ['query-source'] = { summary = 'Local IPv4 source address/port for queries to this peer.' },
    ['query-source-v6'] = { summary = 'Local IPv6 source address/port for queries to this peer.' },
    ['request-expire'] = {
      summary = 'Whether to send the EDNS EXPIRE option to this peer.',
      values = { yes = 'Request expire timer.', no = 'Do not.' },
    },
    ['request-ixfr'] = {
      summary = 'Whether to request incremental transfers from this peer (as secondary).',
      values = { yes = 'Request IXFR.', no = 'Request full AXFR.' },
    },
    ['request-nsid'] = {
      summary = 'Whether to send the EDNS NSID option to this peer.',
      values = { yes = 'Request NSID.', no = 'Do not.' },
    },
    ['require-cookie'] = {
      summary = 'Require a valid DNS COOKIE from this peer before trusting UDP answers.',
      values = { yes = 'Force TCP if no cookie.', no = 'Do not require.' },
    },
    ['send-cookie'] = {
      summary = 'Whether to send a DNS COOKIE to this peer.',
      values = { yes = 'Send cookies.', no = 'Do not.' },
    },
    ['tcp-keepalive'] = {
      summary = 'Send the EDNS TCP-keepalive option to this peer.',
      values = { yes = 'Enable.', no = 'Disable.' },
    },
    ['tcp-only'] = {
      summary = 'Always use TCP when contacting this peer.',
      values = { yes = 'TCP only.', no = 'Use UDP then TCP (default).' },
    },
    ['transfer-format'] = {
      summary = 'Whether to pack multiple records per transfer message.',
      values = { ['many-answers'] = 'Multiple RRs per message (efficient, default).',
        ['one-answer'] = 'One RR per message (for very old peers).' },
    },
    ['transfer-source'] = { summary = 'Local IPv4 source address/port for transfers from this peer.' },
    ['transfer-source-v6'] = { summary = 'Local IPv6 source address/port for transfers from this peer.' },
    transfers = { summary = 'Maximum concurrent inbound transfers from this peer.' },
  },

  -- Statements inside `controls { }` — the rndc control channels.
  controls = {
    inet = {
      summary = 'A TCP rndc listener: address, port, allowed clients and keys.',
      doc = 'Syntax: `inet 127.0.0.1 port 953 allow { localhost; } keys { "rndc-key"; };`.\n'
        .. 'Append `read-only yes;` to forbid state-changing commands.',
    },
    unix = {
      summary = 'A Unix-domain-socket rndc control channel.',
      doc = 'Syntax: `unix "/path" perm 0640 owner <uid> group <gid> keys { ... };`.',
    },
    ['read-only'] = {
      summary = 'Restrict a control channel to read-only (status) commands.',
      values = { yes = 'Read-only.', no = 'Full control (default).' },
    },
  },

  -- Statements inside `tls { }` — a reusable TLS configuration for DoT/DoH.
  tls = {
    ['cert-file'] = { summary = 'PEM file with the server certificate (chain) for this profile.' },
    ['key-file'] = { summary = 'PEM file with the private key matching `cert-file`.' },
    ['ca-file'] = { summary = 'CA bundle used to authenticate the remote peer (for forwarding/transfers).' },
    ['dhparam-file'] = { summary = 'PEM file with Diffie-Hellman parameters for ephemeral DH.' },
    ['remote-hostname'] = { summary = 'Expected hostname to verify in a remote peer\'s certificate.' },
    protocols = {
      summary = 'Permitted TLS protocol versions, e.g. `{ TLSv1.2; TLSv1.3; }`.',
    },
    ciphers = { summary = 'OpenSSL cipher list for TLS 1.2 and below.' },
    ['cipher-suites'] = { summary = 'OpenSSL cipher suites for TLS 1.3.' },
    ['prefer-server-ciphers'] = {
      summary = 'Prefer the server\'s cipher ordering over the client\'s.',
      values = { yes = 'Server chooses.', no = 'Client chooses.' },
    },
    ['session-tickets'] = {
      summary = 'Enable TLS session-ticket resumption (RFC 5077).',
      values = { yes = 'Allow tickets.', no = 'Disable (more forward-secure).' },
    },
  },

  -- Statements inside `http { }` — a named HTTP endpoint set for DoH.
  http = {
    endpoints = {
      summary = 'HTTP path(s) on which DoH is served, e.g. `{ "/dns-query"; }`.',
    },
    ['listener-clients'] = { summary = 'Maximum concurrent DoH connections for listeners using this profile.' },
    ['streams-per-connection'] = { summary = 'Maximum HTTP/2 streams per DoH connection.' },
  },

  -- Statements inside a top-level `dlz "name" { }` block.
  dlz = {
    database = {
      summary = 'Driver name and arguments backing this DLZ, e.g. `"mysql ..."`.',
    },
    search = {
      summary = 'Whether this DLZ is consulted for normal lookups.',
      values = { yes = 'Search this DLZ (default).', no = 'Only via explicit zone.' },
    },
  },

  -- Statements inside `dnssec-policy "name" { }` (KASP).
  dnssec_policy = {
    keys = {
      summary = 'The signing keys this policy maintains (CSK/KSK/ZSK + lifetimes/algorithm).',
      doc = 'Syntax: `keys { csk lifetime unlimited algorithm 13; };` or separate\n'
        .. 'ksk/zsk entries. `key-directory`/`key-store` choose where keys live.',
    },
    ['dnskey-ttl'] = { summary = 'TTL of the zone\'s DNSKEY RRset.' },
    ['max-zone-ttl'] = { summary = 'Largest TTL allowed in the zone (bounds rollover timing).' },
    ['signatures-validity'] = { summary = 'How long generated RRSIGs remain valid.' },
    ['signatures-validity-dnskey'] = { summary = 'RRSIG validity specifically for the DNSKEY RRset.' },
    ['signatures-refresh'] = { summary = 'How long before expiry RRSIGs are regenerated.' },
    ['signatures-jitter'] = { summary = 'Random spread applied to signature expiry times.' },
    ['publish-safety'] = { summary = 'Safety margin added before a new key is used for signing.' },
    ['retire-safety'] = { summary = 'Safety margin kept before an old key is removed.' },
    ['purge-keys'] = { summary = 'How long retired key files are kept before deletion.' },
    ['zone-propagation-delay'] = { summary = 'Assumed delay for zone changes to reach all secondaries.' },
    ['parent-ds-ttl'] = { summary = 'TTL of the parent zone\'s DS records (for rollover timing).' },
    ['parent-propagation-delay'] = { summary = 'Assumed delay for DS changes to propagate at the parent.' },
    cdnskey = {
      summary = 'Publish CDNSKEY records to signal DS changes to the parent (RFC 8078).',
      values = { yes = 'Publish CDNSKEY (default).', no = 'Do not.' },
    },
    ['cds-digest-types'] = { summary = 'DS digest types to publish as CDS records, e.g. `{ "SHA-256"; }`.' },
    nsec3param = {
      summary = 'Use NSEC3 (instead of NSEC) with these iterations/opt-out/salt-length.',
      doc = 'Syntax: `nsec3param iterations 0 optout no salt-length 0;`.',
    },
    ['inline-signing'] = {
      summary = 'Default inline-signing setting for zones using this policy.',
      values = { yes = 'Maintain a signed copy from an unsigned source.', no = 'In-place signing.' },
    },
    ['manual-mode'] = {
      summary = 'Pause automated key actions until released with `rndc dnssec`.',
      values = { yes = 'Manual key transitions.', no = 'Fully automated (default).' },
    },
    ['offline-ksk'] = {
      summary = 'Operate with the KSK kept offline (in an HSM/key-store).',
      values = { yes = 'KSK offline.', no = 'KSK online (default).' },
    },
  },

  -- Shared values referenced from address-match lists and booleans.
  values = {
    any = { summary = 'Built-in ACL matching every address.' },
    none = { summary = 'Built-in ACL matching no address.' },
    localhost = { summary = 'Built-in ACL: all IP addresses of the local host.' },
    localnets = { summary = 'Built-in ACL: all networks the host is directly attached to.' },
    yes = { summary = 'Boolean true (also: `true`, `1`).' },
    no = { summary = 'Boolean false (also: `false`, `0`).' },
  },
}
