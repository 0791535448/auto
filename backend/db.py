"""
SQLite database layer that mimics the subset of the mysql.connector API
used by app.py, so the rest of the codebase stays unchanged.

Supports:
  - connect() -> Connection
  - conn.cursor(dictionary=True|False)
  - cursor.execute(sql, params) with %s placeholders
  - cursor.lastrowid, fetchone(), fetchall(), close()
  - conn.commit(), conn.rollback(), conn.close()
"""

import os
import sqlite3
from datetime import date, datetime

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.getenv('DB_PATH', os.path.join(BASE_DIR, 'ict_automation.db'))
SCHEMA_PATH = os.path.join(BASE_DIR, 'schema_sqlite.sql')


class Error(Exception):
    """Compatibility alias for mysql.connector.Error."""


def _convert_param(value):
    if isinstance(value, datetime):
        return value.strftime('%Y-%m-%d %H:%M:%S')
    if isinstance(value, date):
        return value.strftime('%Y-%m-%d')
    return value


def _convert_params(params):
    if params is None:
        return None
    if isinstance(params, (list, tuple)):
        return tuple(_convert_param(p) for p in params)
    return _convert_param(params)


def _translate_sql(sql):
    # mysql.connector uses %s placeholders; sqlite3 uses ?
    return sql.replace('%s', '?')


class Cursor:
    def __init__(self, conn, dictionary=False):
        self._cur = conn.cursor()
        self._dictionary = dictionary
        self._columns = None

    def execute(self, sql, params=None):
        sql = _translate_sql(sql)
        if params is None:
            self._cur.execute(sql)
        else:
            self._cur.execute(sql, _convert_params(params))
        if self._dictionary and self._cur.description:
            self._columns = [d[0] for d in self._cur.description]
        return self

    def executemany(self, sql, seq_of_params):
        self._cur.executemany(
            _translate_sql(sql),
            [tuple(_convert_param(p) for p in params) for params in seq_of_params],
        )
        return self

    def _row_to_dict(self, row):
        if row is None:
            return None
        return dict(zip(self._columns, row))

    def fetchone(self):
        row = self._cur.fetchone()
        return self._row_to_dict(row) if self._dictionary else row

    def fetchall(self):
        rows = self._cur.fetchall()
        if self._dictionary:
            return [self._row_to_dict(r) for r in rows]
        return rows

    @property
    def lastrowid(self):
        return self._cur.lastrowid

    @property
    def rowcount(self):
        return self._cur.rowcount

    def close(self):
        self._cur.close()


class Connection:
    def __init__(self, path=DB_PATH):
        self._conn = sqlite3.connect(path, check_same_thread=False)
        self._conn.execute('PRAGMA foreign_keys = ON')

    def cursor(self, dictionary=False):
        return Cursor(self._conn, dictionary=dictionary)

    def commit(self):
        self._conn.commit()

    def rollback(self):
        self._conn.rollback()

    def close(self):
        self._conn.close()


def connect(path=DB_PATH):
    return Connection(path)


def init_db(path=DB_PATH):
    """Create all tables and seed data on first run."""
    conn = sqlite3.connect(path)
    try:
        cur = conn.cursor()
        cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='users'")
        if cur.fetchone():
            return  # already initialized
        with open(SCHEMA_PATH, 'r', encoding='utf-8') as f:
            conn.executescript(f.read())
        conn.commit()
    finally:
        conn.close()
