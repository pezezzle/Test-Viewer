"""Reject obvious private artifacts before publication. This is not a complete secret scanner."""
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
result = subprocess.run(['git', 'ls-files', '-z'], cwd=ROOT, capture_output=True)
if result.returncode == 0 and result.stdout:
    files = [ROOT / name.decode('utf-8') for name in result.stdout.split(b'\0') if name]
else:
    files = [path for path in ROOT.rglob('*') if path.is_file() and not any(part in {'.git', '.dart_tool', 'build', 'Pods', '.gradle', '.symlinks', '__pycache__'} for part in path.relative_to(ROOT).parts)]
blocked = re.compile(r'(?i)(\.(?:p12|pfx|jks|keystore|pem|key|sqlite3?|db|apk|aab|ipa|zip|bundle|mobileprovision)(?:-\w+)?$|(?:^|/)(?:key\.properties|\.env)(?:$|/)|(?:^|/)signing/|PRIVAT)')
errors = []
for path in files:
    relative = path.relative_to(ROOT).as_posix()
    if blocked.search(relative):
        errors.append(relative)
        continue
    if path.suffix.lower() == '.png':
        continue
    text = path.read_text(encoding='utf-8', errors='ignore')
    if re.search(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----', text):
        errors.append(relative + ': private key contents')
    if re.search(r'\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{25,}\b', text):
        errors.append(relative + ': possible GitHub token')
if errors:
    raise SystemExit('Refusing publication:\n' + '\n'.join(errors))
print(f'Public artifact scan passed for {len(files)} source files. Manually review all commits before publishing.')
