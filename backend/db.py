"""
Database layer with two dialects:

- MySQL/TiDB: used when DB_HOST is set (mysql-connector-python, native API).
- SQLite:     fallback for local dev (custom shim mimicking mysql.connector).

Both expose: connect() -> connection with cursor(dictionary=True),
commit(), rollback(), close(), cursor.lastrowid.
"""

import os
import sqlite3
from datetime import date, datetime

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.getenv('DB_PATH', os.path.join(BASE_DIR, 'ict_automation.db'))
SCHEMA_SQLITE = os.path.join(BASE_DIR, 'schema_sqlite.sql')
SCHEMA_MYSQL = os.path.normpath(os.path.join(BASE_DIR, '..', 'database', 'schema_tidb.sql'))

DB_HOST = os.getenv('DB_HOST')
DB_PORT = int(os.getenv('DB_PORT', '4000'))
DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD', '')
DB_NAME = os.getenv('DB_NAME', 'ict_automation')

USE_MYSQL = bool(DB_HOST)
DIALECT = 'mysql' if USE_MYSQL else 'sqlite'

if USE_MYSQL:
    import mysql.connector
    from mysql.connector import Error as Error

    def _mysql_kwargs(database=True):
        kwargs = {
            'host': DB_HOST,
            'port': DB_PORT,
            'user': DB_USER,
            'password': DB_PASSWORD,
            'connection_timeout': 30,
        }
        if database:
            kwargs['database'] = DB_NAME
        return kwargs

    def connect(**_):
        return mysql.connector.connect(**_mysql_kwargs())

    def _init_mysql():
        # Ensure the database exists, then create tables if missing.
        conn = mysql.connector.connect(**_mysql_kwargs(database=False))
        try:
            cur = conn.cursor()
            cur.execute(f"CREATE DATABASE IF NOT EXISTS `{DB_NAME}`")
            conn.commit()
            cur.close()
        finally:
            conn.close()

        conn = connect()
        try:
            cur = conn.cursor()
            cur.execute(
                "SELECT COUNT(*) FROM information_schema.TABLES "
                "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = 'users'",
                (DB_NAME,),
            )
            if cur.fetchone()[0]:
                return
            with open(SCHEMA_MYSQL, 'r', encoding='utf-8') as f:
                script = f.read()
            for stmt in script.split(';'):
                stmt = stmt.strip()
                if stmt:
                    cur.execute(stmt)
            conn.commit()
            cur.close()
        finally:
            conn.close()

    def init_db():
        _init_mysql()

else:
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
            with open(SCHEMA_SQLITE, 'r', encoding='utf-8') as f:
                conn.executescript(f.read())
            conn.commit()
        finally:
            conn.close()
