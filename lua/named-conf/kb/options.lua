-- Knowledge base: statements valid inside `options { }`. Because of the scope
-- inheritance in knowledge.lua, these also serve `view { }` and `zone { }`
-- (the more-specific clause table wins when a name collides).
--
-- Coverage target: the complete `options` grammar of BIND 9.20.23
-- (https://bind9.readthedocs.io/en/v9.20.23/reference.html). Statuses BIND
-- itself flags — deprecated / obsolete / experimental / test-only / not built
-- by default — are noted inline so hover/completion warns the user.
--
-- `keys` are the statements; `values` documents shared enum-style answers.
return {
  keys = {
    -- ── Access control / address-match lists ─────────────────────────────
    ['allow-query'] = {
      summary = 'Which clients may query this server/zone at all.',
      doc = 'An address-match list. Defaults to `{ any; }`. Override per-zone for\n'
        .. 'finer control.',
    },
    ['allow-query-on'] = {
      summary = 'Like `allow-query`, but matched on the local interface address.',
      doc = 'Restrict which of *this* server\'s interfaces will answer queries.',
    },
    ['allow-query-cache'] = {
      summary = 'Which clients may receive answers from the cache.',
      doc = 'Defaults to `allow-recursion`, then `allow-query`, then localnets.',
    },
    ['allow-query-cache-on'] = {
      summary = 'Like `allow-query-cache`, matched on the local interface address.',
    },
    ['allow-recursion'] = {
      summary = 'Which clients may request recursive resolution.',
      doc = 'An address-match list. Keep this tight — an open resolver can be\n'
        .. 'abused for amplification attacks.',
    },
    ['allow-recursion-on'] = {
      summary = 'Like `allow-recursion`, matched on the local interface address.',
    },
    ['allow-transfer'] = {
      summary = 'Which clients may request a full zone transfer (AXFR/IXFR).',
      doc = 'An address-match list. Default allows transfers to anyone, so restrict\n'
        .. 'it (e.g. to your secondaries). Optional `port`/`transport` clauses\n'
        .. 'limit transfers to a specific port or transport (e.g. `transport "tls"`).',
    },
    ['allow-update'] = {
      summary = 'Which clients may submit dynamic DNS updates (RFC 2136).',
      doc = 'An address-match list; usually `key "name";` for TSIG-signed updates.\n'
        .. 'Set at the zone level for primary zones.',
    },
    ['allow-update-forwarding'] = {
      summary = 'Which clients\' dynamic updates a secondary forwards to the primary.',
      doc = 'Default `{ none; }`. Enabling forwarding from untrusted clients is\n'
        .. 'risky — restrict tightly.',
    },
    ['allow-notify'] = {
      summary = 'Extra hosts (beyond the primaries) allowed to send NOTIFY to a secondary.',
      doc = 'An address-match list, applied to secondary zones.',
    },
    ['allow-new-zones'] = {
      summary = 'Permit zones to be added/removed at runtime via `rndc addzone`/`delzone`.',
      values = { yes = 'Allow runtime zone management.', no = 'Disallow (default).' },
    },
    ['allow-proxy'] = {
      summary = 'Which clients may use PROXYv2-encapsulated queries. (experimental)',
    },
    ['allow-proxy-on'] = {
      summary = 'Local interfaces on which PROXYv2 queries are accepted. (experimental)',
    },
    blackhole = {
      summary = 'Addresses to ignore entirely — no queries answered, none sent.',
      doc = 'An address-match list of misbehaving clients/servers.',
    },
    ['no-case-compress'] = {
      summary = 'Clients to which case-insensitive name compression is disabled.',
      doc = 'For peers that mishandle BIND\'s case-preserving compression.',
    },
    ['deny-answer-addresses'] = {
      summary = 'Drop A/AAAA answers pointing into these address ranges (anti-rebinding).',
      doc = 'Optional `except-from { "domain"; }` exempts trusted zones.',
    },
    ['deny-answer-aliases'] = {
      summary = 'Drop CNAME/DNAME answers that point into these domains (anti-rebinding).',
      doc = 'Optional `except-from { "domain"; }` exempts trusted zones.',
    },
    sortlist = {
      summary = 'Order multi-address answers by client locality. (deprecated)',
    },
    ['rrset-order'] = {
      summary = 'Control the order records of an RRset are returned (fixed/random/cyclic).',
      doc = 'Syntax: `rrset-order { [class C] [type T] [name "n"] order <order>; };`.',
    },

    -- ── Recursion & resolver behaviour ───────────────────────────────────
    recursion = {
      summary = 'Whether the server performs recursive resolution for clients.',
      doc = 'Set `no` for an authoritative-only server. When `yes`, restrict who\n'
        .. 'may recurse with `allow-recursion` to avoid being an open resolver.',
      values = { yes = 'Resolve recursively (a caching resolver).',
        no = 'Authoritative only; refuse/refer recursive queries.' },
    },
    ['recursive-clients'] = {
      summary = 'Maximum simultaneous recursive client queries (default 1000).',
    },
    ['clients-per-query'] = {
      summary = 'Initial limit of concurrent recursions for the same name/type.',
    },
    ['max-clients-per-query'] = {
      summary = 'Upper bound the adaptive clients-per-query limit may grow to.',
    },
    ['fetches-per-server'] = {
      summary = 'Cap on outstanding recursive fetches sent to one upstream server.',
      doc = 'Optional `drop`|`fail` action when the quota is exceeded. Mitigates\n'
        .. 'damage from unresponsive servers.',
    },
    ['fetches-per-zone'] = {
      summary = 'Cap on outstanding recursive fetches for names in one zone.',
      doc = 'Optional `drop`|`fail` action. Throttles spoofed-query attacks.',
    },
    ['fetch-quota-params'] = {
      summary = 'Tuning constants for the adaptive `fetches-per-server` quota.',
    },
    ['max-recursion-depth'] = {
      summary = 'Maximum delegation depth followed during one recursion.',
    },
    ['max-recursion-queries'] = {
      summary = 'Maximum outgoing queries allowed while resolving one client query.',
    },
    ['max-query-count'] = {
      summary = 'Maximum iterative queries for a single client request (hard cap).',
    },
    ['max-query-restarts'] = {
      summary = 'Maximum CNAME/DNAME chain restarts when resolving a query.',
    },
    ['resolver-query-timeout'] = {
      summary = 'How long (ms) the resolver works on a client query before giving up.',
    },
    ['qname-minimization'] = {
      summary = 'Send the minimum query name to each server (RFC 9156 privacy).',
      values = {
        strict = 'Always minimise; fail rather than fall back.',
        relaxed = 'Minimise but fall back to the full name on error (default).',
        disabled = 'Send the full QNAME at every step.',
        off = 'Synonym for `disabled`.',
      },
    },
    ['nxdomain-redirect'] = {
      summary = 'Suffix used to redirect NXDOMAIN results to a redirect zone.',
    },
    ['root-key-sentinel'] = {
      summary = 'Answer RFC 8509 root-key-sentinel probes about trust-anchor state.',
      values = { yes = 'Honour sentinel probes (default).', no = 'Disable.' },
    },
    ['resolver-use-dns64'] = {
      summary = 'Apply `dns64` mappings to addresses the resolver itself queries.',
      values = { yes = 'Use DNS64 for resolver fetches.', no = 'Do not (default).' },
    },

    -- ── Forwarding ───────────────────────────────────────────────────────
    forwarders = {
      summary = 'Upstream resolvers to forward recursive queries to.',
      doc = 'Syntax: `forwarders { 8.8.8.8; 1.1.1.1 port 53; };`. A per-server\n'
        .. '`tls "name"` enables DNS-over-TLS forwarding. Combine with `forward`.',
    },
    forward = {
      summary = 'How forwarding interacts with normal recursion.',
      doc = 'Only meaningful with `forwarders`.',
      values = {
        first = 'Query forwarders first; if they fail, recurse normally.',
        only = 'Only use forwarders; never recurse directly.',
      },
    },
    ['dual-stack-servers'] = {
      summary = 'Servers to relay through when only one IP family is reachable.',
    },

    -- ── DNSSEC validation & signing ──────────────────────────────────────
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
      doc = 'Set to a `dnssec-policy` name, the built-in `default`, or `none`. Can\n'
        .. 'be set in options/view/zone scope.',
    },
    ['dnssec-accept-expired'] = {
      summary = 'Accept expired RRSIGs during validation (testing only — dangerous).',
      values = { yes = 'Ignore signature expiry.', no = 'Reject expired sigs (default).' },
    },
    ['dnssec-loadkeys-interval'] = {
      summary = 'How often (minutes) to scan the key directory for new signing keys.',
    },
    ['dnssec-must-be-secure'] = {
      summary = 'Require a name to be securely resolved (or fail). (deprecated)',
    },
    ['validate-except'] = {
      summary = 'Domains for which DNSSEC validation is skipped (e.g. internal TLDs).',
    },
    ['disable-algorithms'] = {
      summary = 'DNSSEC algorithms to treat as insecure at/below a domain name.',
    },
    ['disable-ds-digests'] = {
      summary = 'DS digest types to treat as insecure at/below a domain name.',
    },
    ['max-rsa-exponent-size'] = {
      summary = 'Largest RSA public exponent (bits) accepted in DNSKEYs (0 = default).',
    },
    ['max-validations-per-fetch'] = {
      summary = 'Cap on signature validations per fetch (anti-DoS). (experimental)',
    },
    ['max-validation-failures-per-fetch'] = {
      summary = 'Cap on failed validations per fetch before bailing. (experimental)',
    },
    ['nta-lifetime'] = {
      summary = 'Default lifetime of a negative trust anchor (`rndc nta`).',
    },
    ['nta-recheck'] = {
      summary = 'How often to re-test whether an NTA can be lifted early.',
    },
    ['trust-anchor-telemetry'] = {
      summary = 'Send RFC 8145 trust-anchor signalling queries to parent zones.',
      values = { yes = 'Send telemetry (default).', no = 'Disable.' },
    },
    ['synth-from-dnssec'] = {
      summary = 'Synthesise NXDOMAIN/wildcard answers from cached NSEC (RFC 8198).',
      values = { yes = 'Enable aggressive NSEC use (default).', no = 'Disable.' },
    },
    ['dnskey-sig-validity'] = { summary = 'DNSKEY signature validity. (obsolete — use dnssec-policy)' },
    ['dnssec-dnskey-kskonly'] = { summary = 'Sign DNSKEY RRset with KSK only. (obsolete)' },
    ['dnssec-secure-to-insecure'] = { summary = 'Allow a zone to go from signed to unsigned. (obsolete)' },
    ['dnssec-update-mode'] = { summary = 'Automatic resigning mode. (obsolete — use dnssec-policy)' },
    ['sig-validity-interval'] = { summary = 'RRSIG validity window. (obsolete — use dnssec-policy)' },
    ['sig-signing-nodes'] = { summary = 'Nodes signed per quantum during incremental signing.' },
    ['sig-signing-signatures'] = { summary = 'Signatures generated per quantum during incremental signing.' },
    ['sig-signing-type'] = { summary = 'Private RR type used to track incremental signing state.' },
    ['key-directory'] = {
      summary = 'Directory holding the zones\' DNSSEC key files.',
    },
    ['managed-keys-directory'] = {
      summary = 'Directory where RFC 5011 managed-key state files are written.',
    },
    ['update-check-ksk'] = { summary = 'Use only KSKs to sign the DNSKEY RRset. (obsolete)' },

    -- ── Cache ────────────────────────────────────────────────────────────
    ['max-cache-size'] = {
      summary = 'Maximum memory the resolver cache may use.',
      doc = 'Accepts a size (`512m`), a percentage of RAM (`90%`), `unlimited`, or\n'
        .. '`default`. Default is `90%`.',
    },
    ['max-cache-ttl'] = {
      summary = 'Cap on how long positive answers are cached (seconds).',
    },
    ['max-ncache-ttl'] = {
      summary = 'Cap on how long negative answers (NXDOMAIN/NODATA) are cached.',
    },
    ['min-cache-ttl'] = {
      summary = 'Floor applied to positive-answer TTLs before caching.',
    },
    ['min-ncache-ttl'] = {
      summary = 'Floor applied to negative-answer TTLs before caching.',
    },
    ['attach-cache'] = {
      summary = 'Share a single cache database between views, by cache name.',
    },
    ['servfail-ttl'] = {
      summary = 'How long SERVFAIL results are cached (0–30s).',
    },
    ['stale-answer-enable'] = {
      summary = 'Serve stale (expired) cached answers when upstream is unreachable.',
      values = { yes = 'Serve stale on failure.', no = 'Disable (default).' },
    },
    ['stale-answer-ttl'] = {
      summary = 'TTL returned with a served-stale answer.',
    },
    ['stale-answer-client-timeout'] = {
      summary = 'How long (ms) to wait for fresh data before serving a stale answer.',
      values = { disabled = 'Never answer early with stale data.', off = 'Synonym for disabled.' },
    },
    ['stale-cache-enable'] = {
      summary = 'Keep expired records in cache so they can be served stale.',
      values = { yes = 'Retain expired records (default for serve-stale).', no = 'Drop on expiry.' },
    },
    ['stale-refresh-time'] = {
      summary = 'After a failed refresh, how long to keep serving stale before retrying.',
    },
    ['max-stale-ttl'] = {
      summary = 'Longest a record may be retained past expiry for serve-stale.',
    },
    prefetch = {
      summary = 'Refresh popular records before they expire (eligibility TTL + trigger).',
      doc = 'Syntax: `prefetch <trigger> [<eligibility>];`. Set `0` to disable.',
    },
    ['lame-ttl'] = { summary = 'How long lame-server indications are cached (legacy; default 0).' },

    -- ── Zone transfer (NOTIFY / AXFR / IXFR) ─────────────────────────────
    ['also-notify'] = {
      summary = 'Extra servers to send NOTIFY to beyond the NS records.',
      doc = 'An address list, e.g. hidden secondaries. Works with `notify yes`.',
    },
    notify = {
      summary = 'Whether to send NOTIFY messages when a zone changes.',
      values = {
        yes = 'Notify servers in NS records (and also-notify).',
        no = 'Send no NOTIFY messages.',
        explicit = 'Notify only the servers in `also-notify`.',
        ['primary-only'] = 'Notify only for zones for which this is the primary.',
        ['master-only'] = 'Legacy spelling of `primary-only`.',
      },
    },
    ['notify-source'] = { summary = 'Local IPv4 address/port used to send NOTIFY messages.' },
    ['notify-source-v6'] = { summary = 'Local IPv6 address/port used to send NOTIFY messages.' },
    ['notify-delay'] = { summary = 'Seconds to wait between sending sets of NOTIFY messages.' },
    ['notify-defer'] = { summary = 'Seconds to coalesce rapid zone changes before notifying.' },
    ['notify-rate'] = { summary = 'NOTIFY messages per second sent for regular zone changes.' },
    ['startup-notify-rate'] = { summary = 'NOTIFY messages per second sent at server startup.' },
    ['serial-query-rate'] = { summary = 'SOA refresh queries per second a secondary may send.' },
    ['notify-to-soa'] = {
      summary = 'Skip the check that NOTIFY targets appear as NS records.',
      values = { yes = 'Do not compare against the SOA/NS set.', no = 'Compare (default).' },
    },
    ['multi-master'] = {
      summary = 'Suppress mismatched-serial warnings when a zone has several primaries.',
      values = { yes = 'Multiple primaries expected.', no = 'Single primary (default).' },
    },
    ['transfer-format'] = {
      summary = 'Whether to pack multiple records per transfer message.',
      values = { ['many-answers'] = 'Multiple RRs per message (efficient, default).',
        ['one-answer'] = 'One RR per message (for very old peers).' },
    },
    ['transfer-message-size'] = { summary = 'Target uncompressed size (bytes) of each AXFR/IXFR message.' },
    ['transfer-source'] = { summary = 'Local IPv4 address/port used as the source for outgoing transfers.' },
    ['transfer-source-v6'] = { summary = 'Local IPv6 address/port used as the source for outgoing transfers.' },
    ['transfers-in'] = { summary = 'Maximum concurrent inbound zone transfers (default 10).' },
    ['transfers-out'] = { summary = 'Maximum concurrent outbound zone transfers (default 10).' },
    ['transfers-per-ns'] = { summary = 'Maximum concurrent inbound transfers from one remote server.' },
    ['max-transfer-time-in'] = { summary = 'Minutes an inbound transfer may run before being aborted.' },
    ['max-transfer-time-out'] = { summary = 'Minutes an outbound transfer may run before being aborted.' },
    ['max-transfer-idle-in'] = { summary = 'Minutes an inbound transfer may stall before being aborted.' },
    ['max-transfer-idle-out'] = { summary = 'Minutes an outbound transfer may stall before being aborted.' },
    ['min-transfer-rate-in'] = { summary = 'Minimum inbound transfer rate (bytes / minutes) before aborting.' },
    ['provide-ixfr'] = {
      summary = 'Offer incremental transfers (IXFR) to secondaries, as a primary.',
      values = { yes = 'Offer IXFR (default).', no = 'Only AXFR.' },
    },
    ['request-ixfr'] = {
      summary = 'Request incremental transfers (IXFR) from primaries, as a secondary.',
      values = { yes = 'Request IXFR (default).', no = 'Request full AXFR.' },
    },
    ['request-expire'] = {
      summary = 'Send the EDNS EXPIRE option when requesting transfers.',
      values = { yes = 'Request expire timer (default).', no = 'Do not.' },
    },
    ['max-ixfr-ratio'] = {
      summary = 'If an IXFR would exceed this fraction of the zone, fall back to AXFR.',
    },
    ['max-journal-size'] = {
      summary = 'Maximum size of a zone\'s IXFR journal (`.jnl`) file.',
      doc = 'Accepts a size, `unlimited`, or `default`.',
    },
    ['try-tcp-refresh'] = {
      summary = 'Retry SOA refresh over TCP when the UDP query fails.',
      values = { yes = 'Fall back to TCP (default).', no = 'UDP only.' },
    },
    ['ixfr-from-differences'] = {
      summary = 'Build an IXFR journal by diffing reloaded/transferred zone versions.',
      values = { primary = 'For primary zones.', master = 'Legacy spelling of primary.',
        secondary = 'For secondary zones.', slave = 'Legacy spelling of secondary.',
        yes = 'For all zones.', no = 'Disabled (default).' },
    },
    ['max-refresh-time'] = { summary = 'Upper bound applied to a zone\'s SOA refresh interval.' },
    ['min-refresh-time'] = { summary = 'Lower bound applied to a zone\'s SOA refresh interval.' },
    ['max-retry-time'] = { summary = 'Upper bound applied to a zone\'s SOA retry interval.' },
    ['min-retry-time'] = { summary = 'Lower bound applied to a zone\'s SOA retry interval.' },

    -- ── Dynamic update ───────────────────────────────────────────────────
    ['serial-update-method'] = {
      summary = 'How the SOA serial is bumped on dynamic update.',
      values = { date = 'YYYYMMDDnn date form.', increment = 'Add 1.',
        unixtime = 'Unix epoch seconds.' },
    },
    ['update-quota'] = { summary = 'Maximum simultaneous forwarded dynamic-update requests.' },
    ['session-keyfile'] = { summary = 'Path to the TSIG key used for local dynamic updates (`nsupdate -l`).' },
    ['session-keyname'] = { summary = 'Name of the auto-generated local session TSIG key.' },
    ['session-keyalg'] = { summary = 'Algorithm of the auto-generated local session TSIG key.' },

    -- ── Interfaces / network / ports ─────────────────────────────────────
    ['listen-on'] = {
      summary = 'IPv4 addresses/interfaces (and port) to answer queries on.',
      doc = 'Syntax: `listen-on [port <n>] [tls <name>] [http <name>] { aml };`.\n'
        .. 'Default is port 53 on all IPv4 interfaces. Repeat for multiple ports.\n'
        .. 'The `tls`/`http` clauses enable DoT/DoH on the listener.',
    },
    ['listen-on-v6'] = {
      summary = 'IPv6 addresses/interfaces (and port) to answer queries on.',
      doc = 'Like `listen-on` but for IPv6. Use `{ any; }` for all interfaces or\n'
        .. '`{ none; }` to disable IPv6.',
    },
    port = { summary = 'Default UDP/TCP port for listening and querying (default 53).' },
    ['tls-port'] = { summary = 'Default port for DNS-over-TLS (DoT) listeners (default 853).' },
    ['http-port'] = { summary = 'Default port for cleartext DoH listeners (default 80).' },
    ['https-port'] = { summary = 'Default port for DNS-over-HTTPS (DoH) listeners (default 443).' },
    ['http-listener-clients'] = { summary = 'Default per-listener cap on concurrent DoH connections.' },
    ['http-streams-per-connection'] = { summary = 'Default cap on HTTP/2 streams per DoH connection.' },
    ['interface-interval'] = { summary = 'How often to rescan network interfaces for `listen-on` changes.' },
    ['automatic-interface-scan'] = {
      summary = 'Rescan interfaces automatically when the OS reports a change.',
      values = { yes = 'Auto-rescan (default).', no = 'Only on interface-interval/rndc.' },
    },
    ['query-source'] = { summary = 'Local IPv4 address/port used as the source of outgoing queries.' },
    ['query-source-v6'] = { summary = 'Local IPv6 address/port used as the source of outgoing queries.' },
    ['parental-source'] = { summary = 'Local IPv4 address/port used for parent DS checks (`checkds`).' },
    ['parental-source-v6'] = { summary = 'Local IPv6 address/port used for parent DS checks (`checkds`).' },
    reuseport = {
      summary = 'Use SO_REUSEPORT load balancing across listener threads.',
      values = { yes = 'Enable per-thread sockets (default).', no = 'Single shared socket.' },
    },
    ['match-mapped-addresses'] = {
      summary = 'Treat IPv4-mapped IPv6 client addresses as their IPv4 form in ACLs.',
      values = { yes = 'Map before matching.', no = 'Match literally (default).' },
    },

    -- ── EDNS / COOKIE / UDP sizing ───────────────────────────────────────
    ['edns-udp-size'] = { summary = 'EDNS buffer size advertised on outgoing queries (512–4096).' },
    ['max-udp-size'] = { summary = 'Largest EDNS UDP response this server will send.' },
    ['nocookie-udp-size'] = { summary = 'Max UDP response size sent to clients without a valid COOKIE.' },
    ['message-compression'] = {
      summary = 'Use DNS name compression in responses.',
      values = { yes = 'Compress (default).', no = 'Disable (debugging).' },
    },
    ['answer-cookie'] = {
      summary = 'Whether to return a DNS COOKIE option to clients that send one.',
      values = { yes = 'Echo cookies (default).', no = 'Never send cookies.' },
    },
    ['send-cookie'] = {
      summary = 'Send a DNS COOKIE option on outgoing queries.',
      values = { yes = 'Send cookies (default).', no = 'Do not.' },
    },
    ['require-server-cookie'] = {
      summary = 'Require a valid server COOKIE before answering over UDP (anti-spoof).',
      values = { yes = 'Force TCP/cookie for unverified clients.', no = 'Do not require (default).' },
    },
    ['cookie-algorithm'] = {
      summary = 'Algorithm used to compute DNS server COOKIEs.',
      values = { siphash24 = 'SipHash-2-4 (the only supported algorithm).' },
    },
    ['cookie-secret'] = { summary = 'Shared secret(s) used to generate/verify DNS COOKIEs.' },
    ['request-nsid'] = {
      summary = 'Send the EDNS NSID option on outgoing queries.',
      values = { yes = 'Request NSID.', no = 'Do not (default).' },
    },
    ['response-padding'] = {
      summary = 'Pad responses to a block size for listed clients (privacy, RFC 8467).',
      doc = 'Syntax: `response-padding { aml } block-size <n>;`.',
    },

    -- ── Response shaping ─────────────────────────────────────────────────
    ['minimal-responses'] = {
      summary = 'Omit non-essential authority/additional records to shrink responses.',
      values = { yes = 'Always minimal.', no = 'Full responses.',
        ['no-auth'] = 'Omit the authority section.', ['no-auth-recursive'] = 'Omit authority for recursive answers.' },
    },
    ['minimal-any'] = {
      summary = 'Return a single RRset for ANY queries over UDP (anti-amplification).',
      values = { yes = 'Minimise ANY answers.', no = 'Full ANY answers (default).' },
    },
    ['preferred-glue'] = {
      summary = 'Address family to list first in the additional section (`A` or `AAAA`).',
    },
    ['auth-nxdomain'] = {
      summary = 'Set the AA bit on NXDOMAIN responses (legacy behaviour).',
      values = { yes = 'Claim authority on NXDOMAIN.', no = 'Standard (default).' },
    },
    ['v6-bias'] = { summary = 'Milliseconds of preference given to IPv6 server addresses when choosing.' },

    -- ── Name/zone checking ───────────────────────────────────────────────
    ['check-names'] = {
      summary = 'Check owner/host names against the RFC hostname rules.',
      doc = 'Syntax: `check-names ( primary | secondary | response ) ( fail | warn | ignore );`.',
      values = { fail = 'Reject the offending name.', warn = 'Log but accept.',
        ignore = 'No checking.' },
    },
    ['check-dup-records'] = {
      summary = 'How to handle duplicate records that differ only in rdata text.',
      values = { fail = 'Reject the zone.', warn = 'Log (default).', ignore = 'Silent.' },
    },
    ['check-mx'] = {
      summary = 'Check that MX targets are hostnames, not addresses.',
      values = { fail = 'Reject.', warn = 'Log (default).', ignore = 'Silent.' },
    },
    ['check-mx-cname'] = {
      summary = 'How to handle MX records that point at a CNAME.',
      values = { fail = 'Reject.', warn = 'Log (default).', ignore = 'Silent.' },
    },
    ['check-srv-cname'] = {
      summary = 'How to handle SRV records that point at a CNAME.',
      values = { fail = 'Reject.', warn = 'Log (default).', ignore = 'Silent.' },
    },
    ['check-sibling'] = {
      summary = 'Warn about sibling glue (delegation NS records) missing addresses.',
      values = { yes = 'Check sibling glue (default).', no = 'Skip.' },
    },
    ['check-integrity'] = {
      summary = 'Run post-load consistency checks (MX/SRV/NS targets exist, etc.).',
      values = { yes = 'Enable (default).', no = 'Disable.' },
    },
    ['check-wildcard'] = {
      summary = 'Warn about non-terminal wildcard records.',
      values = { yes = 'Warn (default).', no = 'Skip.' },
    },
    ['check-spf'] = {
      summary = 'Warn about deprecated SPF (type 99) records.',
      values = { warn = 'Log (default).', ignore = 'Silent.' },
    },
    ['check-svcb'] = {
      summary = 'Check SVCB/HTTPS record consistency.',
      values = { yes = 'Enable (default).', no = 'Disable.' },
    },

    -- ── Catalog zones / RPZ / DNS64 ──────────────────────────────────────
    ['catalog-zones'] = {
      summary = 'Auto-provision member zones from a catalog zone (RFC 9432).',
      doc = 'Lists catalog zones plus default primaries/options for their members.',
    },
    ['response-policy'] = {
      summary = 'Response Policy Zones (RPZ) — rewrite answers from policy zones.',
      doc = 'Syntax: `response-policy { zone "rpz1"; ... } [options];`. Used for\n'
        .. 'DNS firewalling / threat blocking.',
    },
    dns64 = {
      summary = 'Synthesise AAAA from A records for an IPv6-only client prefix (RFC 6147).',
      doc = 'Syntax: `dns64 <prefix> { clients { aml }; exclude { aml }; ... };`.',
    },
    ['dns64-server'] = { summary = 'Name of the DNS64 server placed in synthesised SOA/NS records.' },
    ['dns64-contact'] = { summary = 'Contact name placed in synthesised DNS64 SOA records.' },
    ['ipv4only-enable'] = {
      summary = 'Serve the synthetic `ipv4only.arpa` zone used by DNS64 clients.',
      values = { yes = 'Enable.', no = 'Disable.' },
    },
    ['ipv4only-server'] = { summary = 'SOA MNAME used in the synthetic `ipv4only.arpa` zone.' },
    ['ipv4only-contact'] = { summary = 'SOA RNAME used in the synthetic `ipv4only.arpa` zone.' },

    -- ── Rate limiting (RRL) ──────────────────────────────────────────────
    ['rate-limit'] = {
      summary = 'Response Rate Limiting (RRL) to blunt amplification/DoS.',
      doc = 'Syntax: `rate-limit { responses-per-second 5; ... };`. Limits identical\n'
        .. 'responses per client subnet.',
    },
    ['sig0checks-quota'] = { summary = 'Limit concurrent SIG(0) signature checks. (experimental)' },
    ['sig0checks-quota-exempt'] = { summary = 'Clients exempt from the SIG(0) check quota. (experimental)' },
    ['sig0key-checks-limit'] = { summary = 'Maximum SIG(0) key lookups per dynamic-update message.' },
    ['sig0message-checks-limit'] = { summary = 'Maximum SIG(0) signature checks per dynamic-update message.' },

    -- ── Empty zones ──────────────────────────────────────────────────────
    ['empty-zones-enable'] = {
      summary = 'Serve RFC 6303 empty zones for private/reverse namespaces.',
      values = { yes = 'Enable (default for recursive).', no = 'Disable all empty zones.' },
    },
    ['disable-empty-zone'] = { summary = 'Disable one specific built-in empty zone by name.' },
    ['empty-server'] = { summary = 'SOA MNAME used in automatically generated empty zones.' },
    ['empty-contact'] = { summary = 'SOA RNAME used in automatically generated empty zones.' },

    -- ── Files & paths ────────────────────────────────────────────────────
    directory = {
      summary = 'The server working directory.',
      doc = 'Relative paths in the config (zone files, dump files) resolve against\n'
        .. 'this directory. Must be an absolute path and writable by named.',
    },
    ['pid-file'] = { summary = 'Path to the file storing the named process id (`none` to disable).' },
    ['dump-file'] = { summary = 'Path for `rndc dumpdb` cache dumps.' },
    ['statistics-file'] = { summary = 'Path for `rndc stats` output.' },
    ['memstatistics-file'] = { summary = 'Path for memory-usage statistics written at exit.' },
    ['recursing-file'] = { summary = 'Path for `rndc recursing` dumps of in-progress recursions.' },
    ['secroots-file'] = { summary = 'Path for `rndc secroots` security-root dumps.' },
    ['new-zones-directory'] = { summary = 'Directory holding state for `rndc addzone`-created zones.' },
    ['lmdb-mapsize'] = { summary = 'Size of the LMDB map backing the new-zone (addzone) database.' },
    ['masterfile-format'] = {
      summary = 'On-disk format for zone files written by named.',
      values = { raw = 'Binary (fast to load).', text = 'Human-readable (default).' },
    },
    ['masterfile-style'] = {
      summary = 'Layout of text-format zone files dumped by named.',
      values = { full = 'One record per line, fully qualified.',
        relative = 'Compact, using $ORIGIN-relative names (default).' },
    },
    ['max-records'] = { summary = 'Maximum records allowed in a single zone (0 = unlimited).' },
    ['max-records-per-type'] = { summary = 'Maximum records of one type at one name (anti-abuse).' },
    ['max-types-per-name'] = { summary = 'Maximum distinct RR types at a single name (anti-abuse).' },
    ['max-zone-ttl'] = { summary = 'Cap on any TTL in a signed zone. (deprecated — set in dnssec-policy)' },
    ['memstatistics'] = {
      summary = 'Write memory-usage statistics to the memstatistics-file at exit.',
      values = { yes = 'Write stats.', no = 'Do not (default).' },
    },
    ['geoip-directory'] = { summary = 'Directory of MaxMind GeoIP2 databases for `geoip` ACLs.' },
    ['flush-zones-on-shutdown'] = {
      summary = 'Flush pending zone writes to disk on shutdown.',
      values = { yes = 'Flush (slower shutdown).', no = 'Skip (default).' },
    },
    ['bindkeys-file'] = { summary = 'Path to the bind.keys trust-anchor file. (test only)' },

    -- ── Logging-ish toggles ──────────────────────────────────────────────
    querylog = {
      summary = 'Enable query logging at startup.',
      values = { yes = 'Log every query.', no = 'Do not log queries (default).' },
    },
    responselog = {
      summary = 'Enable response logging at startup.',
      values = { yes = 'Log every response.', no = 'Do not (default).' },
    },

    -- ── Server identity ──────────────────────────────────────────────────
    version = {
      summary = 'String returned for version.bind/CH TXT queries.',
      doc = 'Set to `none` to refuse, or a custom string to hide the real version.',
    },
    hostname = { summary = 'String returned for hostname.bind queries (`none` to refuse).' },
    ['server-id'] = {
      summary = 'Identifier returned for ID.SERVER / EDNS NSID queries.',
      values = { none = 'Refuse to answer.', hostname = 'Use the system hostname.' },
    },

    -- ── TCP / UDP buffers & timeouts ─────────────────────────────────────
    ['tcp-clients'] = { summary = 'Maximum simultaneous TCP client connections (default 150).' },
    ['tcp-listen-queue'] = { summary = 'Listen backlog (accept queue depth) for TCP sockets.' },
    ['tcp-initial-timeout'] = { summary = 'Deciseconds to wait for the first message on a new TCP connection.' },
    ['tcp-idle-timeout'] = { summary = 'Deciseconds an idle TCP connection is kept open.' },
    ['tcp-keepalive-timeout'] = { summary = 'EDNS TCP-keepalive value (deciseconds) advertised to clients.' },
    ['tcp-advertised-timeout'] = { summary = 'EDNS TCP-keepalive timeout advertised to clients (deciseconds).' },
    ['tcp-receive-buffer'] = { summary = 'Socket receive buffer size (bytes) for TCP (0 = OS default).' },
    ['tcp-send-buffer'] = { summary = 'Socket send buffer size (bytes) for TCP (0 = OS default).' },
    ['udp-receive-buffer'] = { summary = 'Socket receive buffer size (bytes) for UDP (0 = OS default).' },
    ['udp-send-buffer'] = { summary = 'Socket send buffer size (bytes) for UDP (0 = OS default).' },

    -- ── TKEY / GSS-TSIG ──────────────────────────────────────────────────
    ['tkey-gssapi-keytab'] = { summary = 'Kerberos keytab used for GSS-TSIG (TKEY) negotiation.' },
    ['tkey-gssapi-credential'] = { summary = 'GSS-API principal for TKEY. (deprecated — use tkey-gssapi-keytab)' },
    ['tkey-domain'] = { summary = 'Domain appended to TKEY-negotiated key names. (obsolete)' },

    -- ── Miscellaneous tuning ─────────────────────────────────────────────
    ['zero-no-soa-ttl'] = {
      summary = 'Set the SOA TTL to zero in authoritative negative responses.',
      values = { yes = 'Zero the SOA TTL (default).', no = 'Keep the SOA TTL.' },
    },
    ['zero-no-soa-ttl-cache'] = {
      summary = 'Treat a cached negative SOA TTL as zero.',
      values = { yes = 'Zero it.', no = 'Honour the TTL (default).' },
    },
    ['zone-statistics'] = {
      summary = 'Collect per-zone statistics counters.',
      values = { full = 'All counters.', terse = 'Non-zero counters only.', none = 'None.',
        yes = 'Synonym for full.', no = 'Synonym for none.' },
    },
    ['nsec3-test-zone'] = { summary = 'Allow signing with a deliberately broken NSEC3 chain. (test only)' },
    dialup = { summary = 'Demand-dial heartbeat behaviour for transfers/notify. (deprecated)' },
    ['heartbeat-interval'] = { summary = 'Interval for dialup heartbeat zone maintenance. (deprecated)' },
    ['keep-response-order'] = { summary = 'Preserve TCP response order for listed clients. (obsolete)' },
    ['avoid-v4-udp-ports'] = { summary = 'UDP source ports to avoid for IPv4 queries. (deprecated)' },
    ['avoid-v6-udp-ports'] = { summary = 'UDP source ports to avoid for IPv6 queries. (deprecated)' },
    ['use-v4-udp-ports'] = { summary = 'UDP source-port range allowed for IPv4 queries. (deprecated)' },
    ['use-v6-udp-ports'] = { summary = 'UDP source-port range allowed for IPv6 queries. (deprecated)' },

    -- ── Compiled-out features (present in grammar, "not configured") ─────
    ['dnstap'] = { summary = 'dnstap binary query/response logging. (not built unless --enable-dnstap)' },
    ['dnstap-identity'] = { summary = 'Identity field in dnstap frames. (not built by default)' },
    ['dnstap-output'] = { summary = 'dnstap output file or socket. (not built by default)' },
    ['dnstap-version'] = { summary = 'Version string in dnstap frames. (not built by default)' },
    ['dnsrps-enable'] = { summary = 'Use the DNSRPS (RPZ) library API. (not built by default)' },
    ['dnsrps-library'] = { summary = 'Path to the DNSRPS library. (not built by default)' },
    ['dnsrps-options'] = { summary = 'Options passed to the DNSRPS library. (not built by default)' },
    ['fstrm-set-buffer-hint'] = { summary = 'libfstrm buffer hint for dnstap. (not built by default)' },
    ['fstrm-set-flush-timeout'] = { summary = 'libfstrm flush timeout for dnstap. (not built by default)' },
    ['fstrm-set-input-queue-size'] = { summary = 'libfstrm input queue size for dnstap. (not built by default)' },
    ['fstrm-set-output-notify-threshold'] = { summary = 'libfstrm output notify threshold. (not built by default)' },
    ['fstrm-set-output-queue-model'] = { summary = 'libfstrm queue model (mpsc/spsc). (not built by default)' },
    ['fstrm-set-output-queue-size'] = { summary = 'libfstrm output queue size. (not built by default)' },
    ['fstrm-set-reopen-interval'] = { summary = 'libfstrm reopen interval. (not built by default)' },
  },
}
