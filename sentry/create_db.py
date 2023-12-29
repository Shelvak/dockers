from psycopg2 import connect
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

import os

try:
    conn = connect(
        user=os.environ['SENTRY_DB_USER'],
        host=os.environ['SENTRY_POSTGRES_HOST'],
        password=os.environ['SENTRY_DB_PASSWORD'],
        database='postgres',
    )
    conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)

    conn.cursor().execute('CREATE DATABASE ' + os.environ['SENTRY_DB_NAME'])
    conn.close()
    print "DB Creada"
except Exception as exc:
    print "Bombita: {}".format(exc)
