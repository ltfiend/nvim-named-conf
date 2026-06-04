-- Knowledge base: the `rndc.conf` schema (BIND 9.20.23 `rndc.grammar`).
--
-- rndc.conf reuses the clause keywords `options`, `server` and `key`, but with a
-- completely different and much smaller statement set than named.conf — so this
-- table is selected only for buffers detected as the rndc dialect (see
-- detect.lua / context.lua). The `key` block is identical to named.conf's
-- (algorithm + secret) and is reused from kb/misc.lua by knowledge.lua.
return {
  -- Top-level clauses of an rndc.conf file.
  top = {
    options = {
      summary = 'Default control-channel settings used when no `-s`/`-k` is given.',
      doc = 'Sets `default-server`, `default-key`, `default-port` and the source\n'
        .. 'address rndc uses unless overridden on the command line.',
    },
    server = {
      summary = 'Per-server overrides keyed by name (matches `rndc -s <name>`).',
      doc = 'Syntax: `server "name" { key "k"; addresses { ... }; };`. Lets one\n'
        .. 'rndc.conf control several named instances.',
    },
    key = {
      summary = 'A shared TSIG key used to authenticate to the rndc control channel.',
      doc = 'Syntax: `key "name" { algorithm hmac-sha256; secret "base64"; };`.\n'
        .. 'Must match a key named to named\'s `controls { inet ... keys { ... }; }`.',
    },
    include = {
      summary = 'Include another file at this point (e.g. the generated `rndc.key`).',
      doc = 'Syntax: `include "/etc/rndc.key";`.',
    },
  },

  -- Statements inside the rndc `options { }` block.
  options = {
    ['default-server'] = {
      summary = 'Host rndc connects to when `-s` is not given (default `127.0.0.1`).',
    },
    ['default-key'] = {
      summary = 'Name of the `key` used when none is given with `-k`/`-y`.',
    },
    ['default-port'] = {
      summary = 'TCP port rndc connects to when none is given (default 953).',
    },
    ['default-source-address'] = {
      summary = 'Local IPv4 source address rndc binds to (`*` for any).',
    },
    ['default-source-address-v6'] = {
      summary = 'Local IPv6 source address rndc binds to (`*` for any).',
    },
  },

  -- Statements inside an rndc `server "name" { }` block.
  server = {
    addresses = {
      summary = 'Addresses (and optional ports) of this named instance\'s control channel.',
      doc = 'Syntax: `addresses { 127.0.0.1 port 953; ::1; };`.',
    },
    key = {
      summary = 'Name of the `key` used to authenticate to this server.',
      doc = 'Syntax: `key "rndc-key";` — must match the server\'s `controls` key.',
    },
    port = {
      summary = 'Control-channel port for this server (overrides `default-port`).',
    },
    ['source-address'] = {
      summary = 'Local IPv4 source address used when contacting this server.',
    },
    ['source-address-v6'] = {
      summary = 'Local IPv6 source address used when contacting this server.',
    },
  },
}
