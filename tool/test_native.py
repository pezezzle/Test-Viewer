"""Run actual Java path tests and the portable Swift SQLite reader. Not a mobile UI test."""
import argparse
import hashlib
import json
import platform
import shutil
import sqlite3
import subprocess
import tempfile
from pathlib import Path
from create_demo_database import create_database
import datetime as dt

ROOT = Path(__file__).resolve().parents[1]
COLUMNS = ['CustomerNumber', 'IDNumber', 'Location', 'DeviceDescription', 'Manufacturer', 'Type', 'Class', 'Standard', 'FactoryNumber', 'LastTest', 'NextTest', 'TestInterval', 'TestResult', 'Remark', 'Status', 'User1', 'User2', 'User3', 'SubStandard']


def run(*arguments: str) -> subprocess.CompletedProcess:
    return subprocess.run(arguments, check=True, capture_output=True, text=True)


def compare_database(executable: Path, source: Path) -> int:
    before = hashlib.sha256(source.read_bytes()).hexdigest()
    actual = json.loads(run(str(executable), str(source)).stdout)
    with sqlite3.connect(source.resolve().as_uri() + '?mode=ro', uri=True) as connection:
        available = {row[1] for row in connection.execute('PRAGMA table_info(tblIDNumbers)')}
        projection = ','.join(f'"{name}"' if name in available else f'NULL AS "{name}"' for name in COLUMNS)
        expected = [{name: None if value is None else str(value) for name, value in zip(COLUMNS, row)} for row in connection.execute('SELECT ' + projection + ' FROM tblIDNumbers')]
        customer_schema = {row[1] for row in connection.execute('PRAGMA table_info(tblCustomer)')}
        customers = []
        if 'CustomerNumber' in customer_schema:
            name_column = '"Name"' if 'Name' in customer_schema else 'NULL'
            customers = [{'CustomerNumber': None if number is None else str(number), 'Name': None if name is None else str(name)} for number, name in connection.execute('SELECT "CustomerNumber", ' + name_column + ' FROM tblCustomer')]
    assert actual['devices'] == expected, 'The native reader differs from the original SQL rows.'
    assert actual['customers'] == customers, 'The native reader differs from the customer table.'
    assert before == hashlib.sha256(source.read_bytes()).hexdigest(), 'The source hash changed.'
    return len(expected)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--database', type=Path, help='Optional local database for an additional read-only comparison. Its data is not printed.')
    args = parser.parse_args()
    for command in ('swiftc', 'java', 'javac'):
        if not shutil.which(command):
            raise SystemExit(f'Missing {command}; install a Swift toolchain and JDK 17. These native tests do not require Flutter.')
    with tempfile.TemporaryDirectory(prefix='testmaster-native-') as directory:
        work = Path(directory)
        modules = []
        if platform.system() == 'Linux':
            module = work / 'modules' / 'SQLite3'
            module.mkdir(parents=True)
            header = Path('/usr/include/sqlite3.h')
            if not header.exists():
                raise SystemExit('Install SQLite development headers first.')
            (module / 'module.modulemap').write_text(f'module SQLite3 [system] {{ header "{header}"\n link "sqlite3"\n export * }}\n')
            modules = ['-I', str(module.parent)]
        executable = work / 'sqlite-reader'
        run('swiftc', *modules, str(ROOT / 'ios/Runner/DeviceDatabase.swift'), str(ROOT / 'tool/native_tests/main.swift'), '-o', str(executable))
        print(run(str(executable)).stdout.strip())
        sample = work / 'demo.sqlite3'
        create_database(sample, dt.date(2026, 9, 5))
        print(f'Swift/SQL comparison: {compare_database(executable, sample)} fictional devices matched; original hash unchanged.')
        minimal = work / 'minimal.sqlite3'
        with sqlite3.connect(minimal) as connection:
            connection.execute('CREATE TABLE tblIDNumbers (CustomerNumber TEXT, IDNumber TEXT, Location TEXT, DeviceDescription TEXT, NextTest TEXT)')
            connection.execute('INSERT INTO tblIDNumbers VALUES (?, ?, ?, ?, ?)', ('42', '001', '', 'Minimal device', None))
        assert compare_database(executable, minimal) == 1
        print('Missing optional columns and absent customer table: passed.')
        wrong = work / 'wrong.sqlite3'
        with sqlite3.connect(wrong) as connection:
            connection.execute('CREATE TABLE unrelated (value TEXT)')
        rejected = subprocess.run([str(executable), str(wrong)], capture_output=True, text=True)
        assert rejected.returncode == 2
        print('Wrong schema rejection: passed.')
        if args.database:
            print(f'Private SQL comparison: {compare_database(executable, args.database)} devices matched; original hash unchanged.')
        classes = work / 'classes'
        classes.mkdir()
        run('javac', '-encoding', 'UTF-8', '-d', str(classes), str(ROOT / 'android/app/src/main/java/com/pezezzle/testmasterviewer/PathPolicy.java'), str(ROOT / 'tool/native_tests/PathPolicyTest.java'))
        print(run('java', '-cp', str(classes), 'PathPolicyTest').stdout.strip())
        run('swiftc', '-frontend', '-parse', *[str(path) for path in (ROOT / 'ios/Runner').glob('*.swift')])
        print('All iOS Swift files: parser accepted syntax (not an iOS type-check or build).')


if __name__ == '__main__':
    main()
