FROM postgres:14.8-alpine
COPY setup.sql /docker-entrypoint-initdb.d/
COPY setup.sh /docker-entrypoint-initdb.d/
COPY ./data /data
RUN chown -R postgres:postgres /docker-entrypoint-initdb.d/
RUN chown -R postgres:postgres /data/
EXPOSE 5432

