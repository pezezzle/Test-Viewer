"""Compile and run the native Android database-path policy tests."""

import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def run(*arguments: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(arguments, check=True, capture_output=True, text=True)


def main() -> None:
    for command in ('java', 'javac'):
        if not shutil.which(command):
            raise SystemExit(f'Missing {command}; install JDK 17. These native tests do not require Flutter.')

    with tempfile.TemporaryDirectory(prefix='testmaster-native-') as directory:
        classes = Path(directory) / 'classes'
        classes.mkdir()
        run(
            'javac',
            '-encoding',
            'UTF-8',
            '-d',
            str(classes),
            str(ROOT / 'android/app/src/main/java/com/pezezzle/testmasterviewer/PathPolicy.java'),
            str(ROOT / 'tool/native_tests/PathPolicyTest.java'),
        )
        print(run('java', '-cp', str(classes), 'PathPolicyTest').stdout.strip())


if __name__ == '__main__':
    main()
