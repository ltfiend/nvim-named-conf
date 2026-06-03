-- Knowledge base: top-level clauses (statements) of a named.conf file.
-- Each entry: { summary, doc, values? }.
return {
  options = {
    summary = 'Global server configuration applied to all zones and views.',
    doc = 'A single `options { ... };` block sets server-wide defaults: working\n'
      .. 'directory, listening addresses, recursion policy, forwarding, DNSSEC\n'
      .. 'validation, and access-control defaults. Most statements here may be\n'
      .. 'overridden per-view or per-zone.',
  },
  zone = {
    summary = 'Define a DNS zone served (or forwarded) by this server.',
    doc = 'Syntax: `zone "name" [class] { type ...; ... };`. The `type` statement\n'
      .. 'selects the role: `primary`/`master`, `secondary`/`slave`, `forward`,\n'
      .. '`hint`, `stub`, `static-stub`, `redirect`, or `mirror`.\n\n'
      .. '```\nzone "example.com" IN {\n    type primary;\n    file "example.com.zone";\n};\n```',
  },
  view = {
    summary = 'A named ruleset selecting different zone data per client.',
    doc = 'Views are matched top-to-bottom by `match-clients` (an address-match\n'
      .. 'list). The first matching view serves the client. Common use:\n'
      .. 'split-horizon DNS (internal vs. external answers). Once any view is\n'
      .. 'defined, every `zone` must live inside a view.',
  },
  acl = {
    summary = 'Name an address-match list for reuse in access-control statements.',
    doc = 'Syntax: `acl "name" { address_match_element; ... };`. Reference the\n'
      .. 'name anywhere an address-match list is accepted (allow-query, etc.).\n'
      .. 'Built-in ACLs: `any`, `none`, `localhost`, `localnets`.',
  },
  key = {
    summary = 'A shared TSIG/DNS key used to authenticate requests.',
    doc = 'Syntax: `key "name" { algorithm hmac-sha256; secret "base64"; };`.\n'
      .. 'Used for `rndc`, signed zone transfers, and dynamic updates. Reference\n'
      .. 'the key by name in `allow-transfer { key "name"; };` etc.',
  },
  logging = {
    summary = 'Configure where and what the server logs.',
    doc = 'Defines `channel` blocks (output destinations) and `category` lists\n'
      .. '(which message classes go to which channels). Without it, BIND uses a\n'
      .. 'default channel.',
  },
  controls = {
    summary = 'Configure the rndc control channel(s).',
    doc = 'Declares the addresses/ports `rndc` may connect to and the keys it\n'
      .. 'must use. `controls { };` (empty) disables remote control.',
  },
  server = {
    summary = 'Per-remote-server settings, keyed by IP address or prefix.',
    doc = 'Syntax: `server <ip|prefix> { ... };`. Tune behaviour toward a\n'
      .. 'specific peer: `bogus`, `keys` (TSIG for transfers/notifies),\n'
      .. '`transfer-format`, `edns`, etc.',
  },
  include = {
    summary = 'Include another configuration file at this point.',
    doc = 'Syntax: `include "/path/to/file";`. The path is relative to the\n'
      .. 'server working directory (or chroot). Commonly used to pull in\n'
      .. '`rndc.key`, `bind.keys`, or split zone files.',
  },
  masters = {
    summary = 'Name a reusable list of primary servers (legacy spelling).',
    doc = 'Syntax: `masters "name" { 192.0.2.1; ... };`. Reference it from a\n'
      .. 'secondary zone\'s `primaries`/`masters` statement. BIND 9.16+ also\n'
      .. 'accepts the synonym `primaries`.',
  },
  primaries = {
    summary = 'Name a reusable list of primary servers (modern spelling).',
    doc = 'Synonym for `masters`. Syntax: `primaries "name" { 192.0.2.1; };`.',
  },
  ['statistics-channels'] = {
    summary = 'Expose an HTTP endpoint serving server statistics (XML/JSON).',
    doc = 'Syntax: `statistics-channels { inet <addr> port <n> allow { ... }; };`.\n'
      .. 'Requires BIND built with libxml2/json-c.',
  },
  ['trust-anchors'] = {
    summary = 'Define DNSSEC trust anchors (DS/DNSKEY) for validation.',
    doc = 'Replaces the older `trusted-keys` / `managed-keys`. Each anchor may be\n'
      .. '`static-key`, `initial-key`, `static-ds`, or `initial-ds` (RFC 5011\n'
      .. 'managed anchors use the `initial-` forms).',
  },
  ['managed-keys'] = {
    summary = 'RFC 5011 auto-updating DNSSEC trust anchors (deprecated).',
    doc = 'Superseded by `trust-anchors` with `initial-key`/`initial-ds`.',
  },
  ['trusted-keys'] = {
    summary = 'Static DNSSEC trust anchors (deprecated).',
    doc = 'Superseded by `trust-anchors` with `static-key`/`static-ds`.',
  },
  ['dnssec-policy'] = {
    summary = 'A named DNSSEC key-and-signing policy (KASP) for automated signing.',
    doc = 'Define key lifetimes, algorithms and rollover timing once, then attach\n'
      .. 'it to zones with `dnssec-policy "name";`. The built-in policy\n'
      .. '`default` enables sensible single-key CSK signing.',
  },
  ['parental-agents'] = {
    summary = 'Name a list of servers queried to check DS state at the parent.',
    doc = 'Used with `checkds` automation during DNSSEC key rollovers.',
  },
  dlz = {
    summary = 'Dynamically Loadable Zones — serve zone data from an external driver.',
    doc = 'Syntax: `dlz "name" { database "driver args"; };`. Lets BIND answer\n'
      .. 'from a database/LDAP backend instead of zone files.',
  },
  plugin = {
    summary = 'Load a query-plugin module (e.g. filter-aaaa).',
    doc = 'Syntax: `plugin query "module.so" { parameters };`.',
  },
}
