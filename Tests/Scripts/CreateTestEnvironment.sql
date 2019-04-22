--
--  CreateTestEnvironment.sql
--  PostgresClientKit
--
--  Copyright 2019 David Pitfield and the PostgresClientKit contributors
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--  http:--www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
--

--
-- Creates the test database and users required by the PostgresClientKit test suite.  If the
-- database or users already exist, they are dropped and re-created.
--
-- Usage:
--     psql --host=<host> --port=<port> --dbname=<dbname> --username=<superuser> < CreateTestEnvironment.sql
-- where:
--     <host> is the hostname for the Postgres server
--     <port> is the port number for the Postgres server (5432 by default)
--     <dbname> is the name of any existing database on the Postgres server
--     <superuser> is the name of the Postgres superuser

DROP DATABASE IF EXISTS postgresclientkittest;

CREATE DATABASE postgresclientkittest;

DROP USER IF EXISTS terry_postgresclientkittest;
CREATE USER terry_postgresclientkittest WITH PASSWORD 'welcome1';
GRANT ALL PRIVILEGES ON DATABASE postgresclientkittest TO terry_postgresclientkittest;

DROP USER IF EXISTS charlie_postgresclientkittest;
CREATE USER charlie_postgresclientkittest WITH PASSWORD 'welcome1';
GRANT ALL PRIVILEGES ON DATABASE postgresclientkittest TO charlie_postgresclientkittest;

DROP USER IF EXISTS mary_postgresclientkittest;
CREATE USER mary_postgresclientkittest WITH PASSWORD 'welcome1';
GRANT ALL PRIVILEGES ON DATABASE postgresclientkittest TO mary_postgresclientkittest;

-- EOF
