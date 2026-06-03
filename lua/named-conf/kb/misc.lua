-- Knowledge base: statements for acl / view / key / server / controls, plus
-- shared values (built-in ACLs, TSIG algorithms, yes/no) used across scopes.
return {
  -- Statements inside `key { }`.
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

  -- Statements inside `view { }`.
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
    recursion = {
      summary = 'Per-view recursion policy (overrides options).',
      values = { yes = 'Recurse for this view.', no = 'Authoritative only.' },
    },
  },

  -- Statements inside `server { }`.
  server = {
    bogus = {
      summary = 'Stop sending queries to this server (it gives bad data).',
      values = { yes = 'Treat as bogus; do not query.', no = 'Normal.' },
    },
    ['provide-ixfr'] = {
      summary = 'Whether to offer incremental transfers to this peer (as primary).',
      values = { yes = 'Offer IXFR.', no = 'Only AXFR.' },
    },
    ['request-ixfr'] = {
      summary = 'Whether to request incremental transfers from this peer (as secondary).',
      values = { yes = 'Request IXFR.', no = 'Request full AXFR.' },
    },
    keys = {
      summary = 'TSIG key to use when contacting this server.',
      doc = 'Syntax: `keys { "key-name"; };` — signs transfers/notifies to it.',
    },
    ['transfer-format'] = {
      summary = 'Whether to pack multiple records per transfer message.',
      values = { ['many-answers'] = 'Multiple RRs per message (efficient, default).',
        ['one-answer'] = 'One RR per message (for very old peers).' },
    },
    edns = {
      summary = 'Whether to use EDNS when talking to this server.',
      values = { yes = 'Use EDNS.', no = 'Disable EDNS for this peer.' },
    },
  },

  -- Statements inside `controls { }`.
  controls = {
    inet = {
      summary = 'An rndc listener: address, port, and allowed clients/keys.',
      doc = 'Syntax: `inet 127.0.0.1 port 953 allow { localhost; } keys { "rndc-key"; };`.',
    },
    unix = {
      summary = 'A Unix-domain-socket rndc control channel.',
    },
  },

  -- Shared values referenced from address-match lists and `keys`/`secret`.
  values = {
    any = { summary = 'Built-in ACL matching every address.' },
    none = { summary = 'Built-in ACL matching no address.' },
    localhost = { summary = 'Built-in ACL: all IP addresses of the local host.' },
    localnets = { summary = 'Built-in ACL: all networks the host is directly attached to.' },
    yes = { summary = 'Boolean true (also: `true`, `1`).' },
    no = { summary = 'Boolean false (also: `false`, `0`).' },
  },
}
