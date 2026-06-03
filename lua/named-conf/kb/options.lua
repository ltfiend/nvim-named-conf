-- Knowledge base: statements valid inside `options { }` (and, for many of them,
-- inside `view { }` and even `zone { }`). Keyed by statement keyword.
-- `keys` are the statements; `values` documents shared enum-style answers.
return {
  keys = {
    directory = {
      summary = 'The server working directory.',
      doc = 'Relative paths in the config (zone files, dump files) resolve against\n'
        .. 'this directory. Must be an absolute path and writable by named.',
    },
    ['listen-on'] = {
      summary = 'IPv4 addresses/interfaces (and port) to answer queries on.',
      doc = 'Syntax: `listen-on [port <n>] { address_match_list };`. Default is\n'
        .. 'port 53 on all IPv4 interfaces. Repeat for multiple ports.',
    },
    ['listen-on-v6'] = {
      summary = 'IPv6 addresses/interfaces (and port) to answer queries on.',
      doc = 'Like `listen-on` but for IPv6. Use `{ any; }` for all interfaces or\n'
        .. '`{ none; }` to disable IPv6.',
    },
    recursion = {
      summary = 'Whether the server performs recursive resolution for clients.',
      doc = 'Set `no` for an authoritative-only server. When `yes`, restrict who\n'
        .. 'may recurse with `allow-recursion` to avoid being an open resolver.',
      values = { yes = 'Resolve recursively (a caching resolver).',
        no = 'Authoritative only; refuse/refer recursive queries.' },
    },
    ['allow-query'] = {
      summary = 'Which clients may query this server/zone at all.',
      doc = 'An address-match list. Defaults to `{ any; }`. Override per-zone for\n'
        .. 'finer control.',
    },
    ['allow-query-cache'] = {
      summary = 'Which clients may receive answers from the cache.',
      doc = 'Defaults to `allow-recursion`, then `allow-query`, then localnets.',
    },
    ['allow-recursion'] = {
      summary = 'Which clients may request recursive resolution.',
      doc = 'An address-match list. Keep this tight — an open resolver can be\n'
        .. 'abused for amplification attacks.',
    },
    ['allow-transfer'] = {
      summary = 'Which clients may request a full zone transfer (AXFR/IXFR).',
      doc = 'An address-match list. Default allows transfers to anyone, so restrict\n'
        .. 'it (e.g. to your secondaries, optionally `key "name";`).',
    },
    ['allow-update'] = {
      summary = 'Which clients may submit dynamic DNS updates (RFC 2136).',
      doc = 'An address-match list; usually `key "name";` for TSIG-signed updates.\n'
        .. 'Set at the zone level for primary zones.',
    },
    blackhole = {
      summary = 'Addresses to ignore entirely — no queries answered, none sent.',
      doc = 'An address-match list of misbehaving clients/servers.',
    },
    forwarders = {
      summary = 'Upstream resolvers to forward recursive queries to.',
      doc = 'Syntax: `forwarders { 8.8.8.8; 1.1.1.1 port 53; };`. Combine with\n'
        .. '`forward` to control whether to fall back to full recursion.',
    },
    forward = {
      summary = 'How forwarding interacts with normal recursion.',
      doc = 'Only meaningful with `forwarders`.',
      values = {
        first = 'Query forwarders first; if they fail, recurse normally.',
        only = 'Only use forwarders; never recurse directly.',
      },
    },
    ['dnssec-validation'] = {
      summary = 'Whether the resolver validates DNSSEC signatures.',
      doc = 'Recommended: `auto` (use the built-in ICANN root trust anchor and\n'
        .. 'maintain it via RFC 5011).',
      values = {
        auto = 'Validate using the managed root trust anchor (recommended).',
        yes = 'Validate using explicitly configured trust anchors.',
        no = 'Do not validate (clients lose DNSSEC protection).',
      },
    },
    ['dnssec-policy'] = {
      summary = 'Attach a DNSSEC signing policy (KASP) to sign zones automatically.',
      doc = 'Set to a `dnssec-policy` name or the built-in `default`. Can be set in\n'
        .. 'options/view/zone scope.',
    },
    ['max-cache-size'] = {
      summary = 'Maximum memory the resolver cache may use.',
      doc = 'Accepts a size (`512m`), a percentage of RAM (`90%`), or `unlimited`.\n'
        .. 'Default is `90%`.',
    },
    ['max-cache-ttl'] = {
      summary = 'Cap on how long positive answers are cached (seconds).',
    },
    ['max-ncache-ttl'] = {
      summary = 'Cap on how long negative answers (NXDOMAIN/NODATA) are cached.',
    },
    version = {
      summary = 'String returned for version.bind/CH TXT queries.',
      doc = 'Set to `none` to refuse, or a custom string to hide the real version.',
    },
    ['querylog'] = {
      summary = 'Enable query logging at startup.',
      values = { yes = 'Log every query.', no = 'Do not log queries (default).' },
    },
    ['also-notify'] = {
      summary = 'Extra servers to send NOTIFY to beyond the NS records.',
      doc = 'An address list, e.g. hidden secondaries. Works with `notify yes`.',
    },
    notify = {
      summary = 'Whether to send NOTIFY messages when a zone changes.',
      values = {
        yes = 'Notify servers listed in NS records (and also-notify).',
        no = 'Send no NOTIFY messages.',
        explicit = 'Notify only the servers in `also-notify`.',
        ['master-only'] = 'Notify only for zones for which this is the primary.',
      },
    },
    ['pid-file'] = { summary = 'Path to the file storing the named process id.' },
    ['dump-file'] = { summary = 'Path for `rndc dumpdb` cache dumps.' },
    ['statistics-file'] = { summary = 'Path for `rndc stats` output.' },
    ['session-keyfile'] = { summary = 'Path to the TSIG key used for local dynamic updates (nsupdate -l).' },
    ['minimal-responses'] = {
      summary = 'Omit non-essential authority/additional records to shrink responses.',
      values = { yes = 'Always minimal.', no = 'Full responses.',
        ['no-auth'] = 'Minimise authority section.', ['no-auth-recursive'] = 'Minimise for recursive answers.' },
    },
    ['rate-limit'] = {
      summary = 'Response Rate Limiting (RRL) to blunt amplification/DoS.',
      doc = 'Syntax: `rate-limit { responses-per-second 5; ... };`. Limits identical\n'
        .. 'responses per client subnet.',
    },
  },
}
