# Window capture policy

- With background capture disabled, captures require an active switcher session.
- Focus changes, retries, and deferred captures obey the same preference.
- Queued captures re-check the current preference and session state before calling the capture API.
- With background capture enabled, idle captures remain available.
- Screen Recording permission, screen lock, and termination guards continue to apply separately.
