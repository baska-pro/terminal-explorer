# Security Policy

Do not publish passwords, tokens, private keys, or sensitive local file contents in public issues.

A report is security-relevant when Terminal Explorer:

- deletes outside the path explicitly selected by the user;
- follows an unsafe archive path traversal;
- unexpectedly operates on a protected system root;
- executes a different file than the one selected.

When reporting, include:

- Terminal Explorer version;
- `terminal-explorer --doctor` output with private paths redacted;
- Linux distribution or Termux version;
- exact action taken;
- minimal reproduction steps.

Do not include secrets or personal files.
