-- Knowledge base: statements specific to a `zone { }` block, plus the enum of
-- zone `type` values. Zone scope also inherits the whole `options` table
-- (see knowledge.lua), so options-level statements valid in a zone — allow-*,
-- check-*, max-*, masterfile-*, notify-*, transfer-*, dnssec-policy, etc. — need
-- not be repeated here; only zone-only statements and zone-specific phrasings
-- live below. Coverage follows the BIND 9.20.27 zone grammar (primary,
-- secondary, stub, static-stub, forward, redirect, mirror, hint, in-view).
return {
  -- The `type` statement and its values.
  type = {
    summary = 'The role this server plays for the zone.',
    doc = 'Selects how the zone is served. `primary`/`secondary` are the modern\n'
      .. 'spellings of `master`/`slave`.',
    values = {
      primary = 'Authoritative; zone data loaded from a local `file` (modern spelling of master).',
      master = 'Authoritative; zone data loaded from a local `file`.',
      secondary = 'Authoritative copy transferred from `primaries` (modern spelling of slave).',
      slave = 'Authoritative copy transferred from `masters`.',
      forward = 'Forward all queries for this zone to `forwarders`.',
      hint = 'Bootstrap list of root servers (the root zone).',
      stub = 'Like secondary but only tracks the zone\'s NS records.',
      ['static-stub'] = 'Locally configured NS/glue (server-names/server-addresses), not transferred.',
      redirect = 'Provides answers for names that would otherwise be NXDOMAIN.',
      mirror = 'A locally served, DNSSEC-validated copy (e.g. of the root zone).',
    },
  },
  keys = {
    file = {
      summary = 'Path to the zone\'s data file.',
      doc = 'For primary zones, the source of truth (relative to `directory`).\n'
        .. 'For secondary zones, where the transferred copy is written.',
    },
    primaries = {
      summary = 'Primary servers a secondary/stub/redirect/mirror zone transfers from.',
      doc = 'Syntax: `primaries { 192.0.2.1 key "k"; }` or a named `primaries`\n'
        .. '(`remote-servers`) list. Add `key`/`tls` for authenticated transfers.',
    },
    masters = {
      summary = 'Legacy spelling of `primaries`.',
      doc = 'Syntax: `masters { 192.0.2.1; }`. BIND 9.16+ prefers `primaries`.',
    },
    ['allow-transfer'] = {
      summary = 'Which clients may AXFR/IXFR this zone (overrides options).',
      doc = 'Restrict to your secondaries, e.g. `{ key "transfer-key"; 192.0.2.0/24; };`.\n'
        .. 'Optional `port`/`transport` clauses limit it further.',
    },
    ['allow-update'] = {
      summary = 'Which clients may send dynamic updates to this (primary) zone.',
      doc = 'Usually a TSIG key: `{ key "ddns-key"; };`. Mutually exclusive in\n'
        .. 'practice with `update-policy`.',
    },
    ['allow-update-forwarding'] = {
      summary = 'Which clients\' updates this secondary forwards to the primary.',
    },
    ['allow-query'] = {
      summary = 'Which clients may query this zone (overrides options).',
    },
    ['allow-notify'] = {
      summary = 'Extra hosts (beyond primaries) allowed to NOTIFY this secondary zone.',
    },
    ['update-policy'] = {
      summary = 'Fine-grained dynamic-update rules (instead of allow-update).',
      doc = 'Syntax: `update-policy { grant <id> <ruletype> <name> <rr-types>; };`.\n'
        .. 'Use `local;` for nsupdate -l only. Rule types include `name`, `subdomain`,\n'
        .. '`zonesub`, `self`, `selfsub`, `wildcard`, and the krb5-/ms- GSS forms.',
    },
    checkds = {
      summary = 'Whether named checks the parent for DS publication during a KSK rollover.',
      doc = 'Drives `dnssec-policy` rollover timing using `parental-agents`.',
      values = { yes = 'Query the parent automatically.', no = 'Disable automatic checks.',
        explicit = 'Only check via `rndc dnssec -checkds`.' },
    },
    ['parental-agents'] = {
      summary = 'Servers queried to observe this zone\'s DS state at the parent.',
      doc = 'A list (or named `parental-agents`/`remote-servers`) used with `checkds`\n'
        .. 'automation during DNSSEC key rollovers.',
    },
    database = {
      summary = 'Name (and arguments) of the database driver backing this zone.',
      doc = 'Default `rbt` (the in-memory red-black tree). Used by SDB drivers.',
    },
    dlz = {
      summary = 'Serve this zone from a named `dlz` (Dynamically Loadable Zone) driver.',
      doc = 'References a top-level `dlz "name"` block instead of a zone file.',
    },
    journal = {
      summary = 'Path to the zone\'s IXFR journal (`.jnl`) file.',
      doc = 'Defaults to the zone file name with `.jnl` appended.',
    },
    ['inline-signing'] = {
      summary = 'Keep an unsigned source file; serve a separately maintained signed copy.',
      values = { yes = 'Maintain a signed version alongside the unsigned file.',
        no = 'Do not use inline signing.' },
    },
    ['ixfr-from-differences'] = {
      summary = 'Build the IXFR journal by diffing zone versions (zone-level boolean).',
      values = { yes = 'Generate IXFR diffs for this zone.', no = 'Disabled.' },
    },
    ['server-addresses'] = {
      summary = 'Literal NS addresses for a `type static-stub` zone.',
      doc = 'Syntax: `server-addresses { 192.0.2.1; 2001:db8::1; };`.',
    },
    ['server-names'] = {
      summary = 'NS hostnames for a `type static-stub` zone (resolved normally).',
      doc = 'Syntax: `server-names { "ns1.example."; };`.',
    },
    ['in-view'] = {
      summary = 'Share an identical zone defined in another view.',
      doc = 'Syntax: `zone "x" { in-view "other-view"; };` — avoids loading the\n'
        .. 'same data twice.',
    },
    ['dnssec-policy'] = {
      summary = 'Attach a DNSSEC signing policy to automatically sign this zone.',
      doc = 'Set to a policy name, the built-in `default`, or `none`.',
    },
    ['zone-statistics'] = {
      summary = 'Collect per-zone statistics counters.',
      values = { full = 'All counters.', terse = 'Non-zero counters only.', none = 'None.',
        yes = 'Synonym for full.', no = 'Synonym for none.' },
    },
  },
}
