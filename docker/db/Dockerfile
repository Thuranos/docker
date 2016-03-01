FROM mysql:5.5

COPY db-scripts/1-SCHEMA.sql /docker-entrypoint-initdb.d/
COPY db-scripts/2-PRIVILEGES.sql /docker-entrypoint-initdb.d/
