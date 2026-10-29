# Sidebar list rows

`SidebarListRow` displays a shortcut title, summary, and selection state. ControlsTab reuses rows when shortcuts change.

- Rebinding a row updates its text and tooltip while preserving its view count.
- An empty summary produces a tooltip containing the current title alone.

`SidebarListTests.swift` covers repeated reuse and clearing a previous summary.
