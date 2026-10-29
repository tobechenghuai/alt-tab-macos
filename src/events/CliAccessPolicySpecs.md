# Local CLI access

- Ordinary launches keep the local message port closed in Debug and Release builds.
- The running app must receive the exact `--enable-cli` argument to expose its CLI port.
- Diagnostic flags and QA lifecycle mode keep the default access policy.
- The opt-in applies to the current process. An ordinary relaunch restores the closed default.
- Enabling the CLI permits local processes that can reach its message port to query window metadata and issue the supported window commands.
