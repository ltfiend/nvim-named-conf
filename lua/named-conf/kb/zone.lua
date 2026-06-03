-- Knowledge base: statements valid inside a `zone { }` block, plus the enum of
-- zone `type` values.
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
      ['static-stub'] = 'Locally configured NS/glue, not transferred.',
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
    masters = {
      summary = 'Primary servers a secondary/stub zone transfers from (legacy spelling).',
      doc = 'Syntax: `masters { 192.0.2.1; }` or a named `masters`/`primaries`\n'
        .. 'list. Add `key "name";` for TSIG-authenticated transfers.',
    },
    primaries = {
      summary = 'Primary servers a secondary/stub zone transfers from (modern spelling).',
      doc = 'Synonym for `masters`.',
    },
    ['allow-transfer'] = {
      summary = 'Which clients may AXFR/IXFR this zone.',
      doc = 'Overrides the options-level default for this zone. Restrict to your\n'
        .. 'secondaries, e.g. `{ key "transfer-key"; 192.0.2.0/24; };`.',
    },
    ['allow-update'] = {
      summary = 'Which clients may send dynamic updates to this (primary) zone.',
      doc = 'Usually a TSIG key: `{ key "ddns-key"; };`. Mutually exclusive in\n'
        .. 'practice with `update-policy`.',
    },
    ['update-policy'] = {
      summary = 'Fine-grained dynamic-update rules (instead of allow-update).',
      doc = 'Syntax: `update-policy { grant <key> <type> <name> <rr-types>; };`.\n'
        .. 'Use `local;` for nsupdate -l only.',
    },
    ['allow-query'] = {
      summary = 'Which clients may query this zone.',
      doc = 'Overrides the options-level default for this zone.',
    },
    ['also-notify'] = {
      summary = 'Extra NOTIFY targets for this zone beyond its NS records.',
    },
    notify = {
      summary = 'NOTIFY behaviour for this zone (overrides options).',
      values = { yes = 'Notify NS + also-notify.', no = 'No NOTIFY.',
        explicit = 'Notify only also-notify targets.' },
    },
    forwarders = {
      summary = 'Upstream resolvers for a `type forward` zone.',
      doc = 'Syntax: `forwarders { 192.0.2.53; };`.',
    },
    forward = {
      summary = 'Forwarding mode for a forward zone.',
      values = { first = 'Try forwarders, then recurse.', only = 'Forwarders only.' },
    },
    ['in-view'] = {
      summary = 'Share an identical zone defined in another view.',
      doc = 'Syntax: `zone "x" { in-view "other-view"; };` — avoids loading the\n'
        .. 'same data twice.',
    },
    ['dnssec-policy'] = {
      summary = 'Attach a DNSSEC signing policy to automatically sign this zone.',
    },
    ['inline-signing'] = {
      summary = 'Keep an unsigned source file; serve a separately maintained signed copy.',
      values = { yes = 'Maintain a signed version alongside the unsigned file.',
        no = 'Do not use inline signing.' },
    },
    ['auto-dnssec'] = {
      summary = 'Legacy DNSSEC key maintenance mode (superseded by dnssec-policy).',
      values = { allow = 'Sign only on rndc command.',
        maintain = 'Automatically sign and roll keys.', off = 'Disabled.' },
    },
    ['zone-statistics'] = {
      summary = 'Collect per-zone statistics counters.',
      values = { full = 'All counters.', terse = 'Non-zero counters only.', none = 'None.' },
    },
    serial = {
      summary = 'Used by `type redirect`/`mirror` in some contexts.',
    },
  },
}
