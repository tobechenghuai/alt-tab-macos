# Local CLI access

AltTab starts with its local CLI message port closed. The running app must receive `--enable-cli` to allow local window queries and commands. The flag applies to that process and requires an explicit choice on each ordinary launch. Debug and QA flags follow the same access policy.

## Enable for a session

1. Quit the running AltTab instance so LaunchServices starts a new process with the arguments.
2. Launch the installed app:

   ```sh
   open -a AltTab --args --enable-cli
   ```

3. Send a command through the app executable:

   ```sh
   /Applications/AltTab.app/Contents/MacOS/AltTab --list
   /Applications/AltTab.app/Contents/MacOS/AltTab --detailed-list
   /Applications/AltTab.app/Contents/MacOS/AltTab --focus=123
   ```

Replace `123` with a window ID returned by the list command. A development build can be launched with its app path and the same argument.

When enabled, local processes that can reach the message port can read window metadata and send supported window commands. Window titles may contain document names, webpage titles, and project names. Use the opt-in for sessions that need automation.

Quit AltTab and launch it normally to restore the closed default.

## Related privacy behavior

The background-capture preference governs focus changes, retries, and queued captures. With background capture disabled, screenshot requests require an active switcher session. Capture workers re-check the setting before calling the capture API; an OS capture already started may complete.

The app exposes its appearance, search, and shortcut features directly. This build removes update checking, the updater dependency, license activation and revalidation, hardware-fingerprint collection for licensing, activation URL handling, and purchase prompts.
