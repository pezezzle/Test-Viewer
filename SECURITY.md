# Security

Never include original databases, real device inventories, private signing keys, passwords, or personal screenshots in issues, commits, or Actions logs. Use only synthetic sample data and sanitized logs in bug reports.

The viewer does not assess device safety and never writes to the source database. Due-date status and inspection result are separate: a device with a future due date can still have a failed inspection code.

The repository does not contain a private release key. Keep signing files outside version control or in dedicated CI secrets. A `.gitignore` rule cannot remove a secret from existing Git history, so always inspect the history before publication.

Report potential security issues privately to the publisher first. Never publish real inspection data to reproduce a problem.
