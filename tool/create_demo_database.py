"""Generate an explicitly fictional SQLite fixture. Never overwrite an existing file."""
import argparse
import datetime as dt
import sqlite3
from pathlib import Path


def create_database(target: Path, reference: dt.date) -> None:
    if target.exists():
        raise FileExistsError(f'Refusing to overwrite {target}')
    target.parent.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(target)
    try:
        connection.executescript('''
            CREATE TABLE tblCustomer (CustomerNumber TEXT PRIMARY KEY, Name TEXT);
            CREATE TABLE tblIDNumbers (
                CustomerNumber TEXT NOT NULL, IDNumber TEXT NOT NULL, Location TEXT,
                DeviceDescription TEXT, Manufacturer TEXT, Type TEXT, Class TEXT,
                Standard TEXT, FactoryNumber TEXT, LastTest TEXT, NextTest TEXT,
                TestInterval INTEGER, TestResult TEXT, Remark TEXT, Status INTEGER,
                User1 TEXT, User2 TEXT, User3 TEXT, SubStandard INTEGER,
                PRIMARY KEY (CustomerNumber, IDNumber)
            );
        ''')
        connection.executemany('INSERT INTO tblCustomer VALUES (?, ?)', [('0001', 'Musterbetrieb'), ('0002', 'Beispielwerkstatt')])
        rows = []
        for index in range(80):
            customer = '0001' if index < 65 else '0002'
            next_date = None if index % 17 == 0 else (reference + dt.timedelta(days=-60 if index % 9 == 0 else index * 27 - 25)).isoformat()
            rows.append((customer, f'{index:06}', ['Werkstatt', 'Küche', 'Raum 2', 'Raum 10', '', 'Gebäude A / Etage 1'][index % 6], ['Bohrmaschine', 'Ventilator', 'Monitor', 'Kaffeemaschine', 'Staubsauger'][index % 5], 'Musterhersteller', f'Modell {index % 4 + 1}', 'I', 'DEMO', f'DEMO-{index}', (reference - dt.timedelta(days=365)).isoformat(), next_date, 12, 'F' if index % 23 == 0 else 'OK', 'Fiktive Beispieldaten, nicht für Prüfentscheidungen verwenden.', 0, None, None, None, 0))
        connection.executemany('INSERT INTO tblIDNumbers VALUES (' + ','.join('?' for _ in range(19)) + ')', rows)
        connection.commit()
    finally:
        connection.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', nargs='?', type=Path, default=Path('example/demo.sqlite3'))
    parser.add_argument('--date', type=dt.date.fromisoformat, default=dt.date.today())
    args = parser.parse_args()
    create_database(args.output, args.date)
    print(f'Created 80 fictional devices: {args.output}')
