-- Knowledge base: statements inside `logging { }`, `channel { }` and `category`.
return {
  keys = {
    channel = {
      summary = 'Define a log output destination.',
      doc = 'Syntax: `channel "name" { file|syslog|stderr|null; severity ...; };`.\n'
        .. 'Built-in channels: `default_syslog`, `default_debug`, `default_stderr`,\n'
        .. '`null`.',
    },
    category = {
      summary = 'Route a class of log messages to one or more channels.',
      doc = 'Syntax: `category <name> { channel1; channel2; };`. Common categories:\n'
        .. '`default`, `general`, `queries`, `security`, `xfer-in`, `xfer-out`,\n'
        .. '`notify`, `lame-servers`, `dnssec`, `resolver`.',
    },
    file = {
      summary = 'Write this channel to a file, with optional rotation/size limits.',
      doc = 'Syntax: `file "path" [versions <n>|unlimited] [size <limit>]\n'
        .. '[suffix increment|timestamp]`. `suffix timestamp` names rolled files\n'
        .. 'by time instead of a counter. Example: `file "named.log" versions 3 size 20m;`.',
    },
    syslog = {
      summary = 'Send this channel to syslog at the given facility.',
      doc = 'Syntax: `syslog <facility>;` e.g. `syslog daemon;` (default `daemon`).',
    },
    severity = {
      summary = 'Minimum message severity this channel emits.',
      doc = 'Messages below this level are dropped.',
      values = {
        critical = 'Only critical errors.',
        error = 'Errors and above.',
        warning = 'Warnings and above.',
        notice = 'Notices and above.',
        info = 'Informational and above.',
        debug = 'Debug messages (optionally `debug <level>`).',
        dynamic = 'Follow the server-wide debug level (set via `rndc trace`).',
      },
    },
    ['print-time'] = {
      summary = 'Prefix each message with a timestamp.',
      values = { yes = 'Include a local timestamp.', no = 'No timestamp.',
        ['iso8601'] = 'ISO 8601 local time.', ['iso8601-utc'] = 'ISO 8601 UTC.' },
    },
    ['print-severity'] = {
      summary = 'Prefix each message with its severity level.',
      values = { yes = 'Include severity.', no = 'Omit severity.' },
    },
    ['print-category'] = {
      summary = 'Prefix each message with its category.',
      values = { yes = 'Include category.', no = 'Omit category.' },
    },
    stderr = { summary = 'Send this channel to standard error.' },
    ['null'] = { summary = 'Discard all messages sent to this channel.' },
    buffered = {
      summary = 'Buffer file writes instead of flushing each line.',
      values = { yes = 'Buffer (faster, may lose tail on crash).', no = 'Flush each message.' },
    },
  },
}
