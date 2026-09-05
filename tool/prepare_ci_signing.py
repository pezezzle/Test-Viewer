"""Write signing configuration without logging any secret value."""
import base64
import os
from pathlib import Path

required = ('KEYSTORE_BASE64', 'KEYSTORE_PASSWORD', 'KEY_ALIAS', 'KEY_PASSWORD', 'RUNNER_TEMP')
if any(not os.environ.get(name) for name in required):
    raise SystemExit('Configure the required Android signing secrets and runner environment first.')
key = Path(os.environ['RUNNER_TEMP']) / 'testmaster-release.p12'
key.write_bytes(base64.b64decode(os.environ['KEYSTORE_BASE64'], validate=True))
key.chmod(0o600)
# Java Properties requires escaped backslashes and leading whitespace.
def escape(value: str) -> str:
    return ''.join(''.join('\\u%04x' % int.from_bytes(c.encode('utf-16-be')[i:i + 2], 'big') for i in range(0, len(c.encode('utf-16-be')), 2)) if ord(c) < 32 or ord(c) > 126 else '\\' + c if c in '\\:=#! ' else c for c in value)
values = {'storeFile': str(key.resolve()), 'storeType': 'PKCS12', 'storePassword': os.environ['KEYSTORE_PASSWORD'], 'keyAlias': os.environ['KEY_ALIAS'], 'keyPassword': os.environ['KEY_PASSWORD']}
target = Path(__file__).resolve().parents[1] / 'android' / 'key.properties'
target.write_text('\n'.join(f'{name}={escape(value)}' for name, value in values.items()) + '\n', encoding='ascii')
target.chmod(0o600)
print('Signing material configured in private runner storage.')
