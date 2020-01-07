---
version: '2'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:5.3.1
    hostname: zookeeper
    container_name: zookeeper
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
  broker:
    image: confluentinc/cp-enterprise-kafka:5.3.1
    hostname: broker
    container_name: broker
    depends_on:
      - zookeeper
    ports:
      - 9092:9092
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://broker:29092,HOST://localhost:9092
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 100
  schema-registry:
    image: confluentinc/cp-schema-registry:5.3.1
    hostname: schema-registry
    container_name: schema-registry
    depends_on:
      - broker
    ports:
      - 8081:8081
    environment:
      SCHEMA_REGISTRY_HOST_NAME: schema-registry
      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: PLAINTEXT://broker:29092
      SCHEMA_REGISTRY_CUB_KAFKA_TIMEOUT: 300
  ksqldb-server:
    image: confluentinc/ksqldb-server:0.6.0
    hostname: ksqldb-server
    container_name: ksqldb-server
    depends_on:
      - broker
      - connect
    ports:
      - 8088:8088
    environment:
      KSQL_LISTENERS: http://0.0.0.0:8088
      KSQL_BOOTSTRAP_SERVERS: broker:29092
      KSQL_KSQL_SERVICE_ID: ksql_service
      KSQL_KSQL_LOGGING_PROCESSING_STREAM_AUTO_CREATE: "true"
      KSQL_KSQL_LOGGING_PROCESSING_TOPIC_AUTO_CREATE: "true"
      KSQL_KSQL_CONNECT_URL: http://connect:8083
      KSQL_KSQL_SCHEMA_REGISTRY_URL: http://schema-registry:8081
  ksqldb-cli:
    image: confluentinc/ksqldb-cli:0.6.0
    container_name: ksqldb-cli
    depends_on:
      - ksqldb-server
    entrypoint: /bin/sh
    tty: true
  connect:
    image: confluentinc/cp-kafka-connect:5.3.1
    hostname: connect
    container_name: connect
    depends_on:
      - broker
      - schema-registry
    ports:
      - 8083:8083
    environment:
      CONNECT_LOG4J_APPENDER_STDOUT_LAYOUT_CONVERSIONPATTERN: "[%d] %p %X{connector.context}%m (%c:%L)%n"
      CONNECT_CUB_KAFKA_TIMEOUT: 300
      CONNECT_BOOTSTRAP_SERVERS: "broker:29092"
      CONNECT_REST_ADVERTISED_HOST_NAME: 'connect'
      CONNECT_REST_PORT: 8083
      CONNECT_GROUP_ID: connect-group
      CONNECT_CONFIG_STORAGE_TOPIC: connect-group-configs
      CONNECT_OFFSET_STORAGE_TOPIC: connect-group-offsets
      CONNECT_STATUS_STORAGE_TOPIC: connect-group-status
      CONNECT_KEY_CONVERTER: io.confluent.connect.avro.AvroConverter
      CONNECT_KEY_CONVERTER_SCHEMA_REGISTRY_URL: "http://schema-registry:8081"
      CONNECT_VALUE_CONVERTER: io.confluent.connect.avro.AvroConverter
      CONNECT_VALUE_CONVERTER_SCHEMA_REGISTRY_URL: "http://schema-registry:8081"
      CONNECT_INTERNAL_KEY_CONVERTER: 'org.apache.kafka.connect.json.JsonConverter'
      CONNECT_INTERNAL_VALUE_CONVERTER: 'org.apache.kafka.connect.json.JsonConverter'
      CONNECT_LOG4J_ROOT_LOGLEVEL: 'INFO'
      CONNECT_LOG4J_LOGGERS: 'org.apache.kafka.connect.runtime.rest=WARN,org.reflections=ERROR'
      CONNECT_LOG4J_LOGGERS: 'org.apache.kafka.connect.runtime.rest=WARN,org.reflections=ERROR,org.eclipse.jetty.server=DEBUG'
      CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR: '1'
      CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR: '1'
      CONNECT_STATUS_STORAGE_REPLICATION_FACTOR: '1'
      CONNECT_PLUGIN_PATH: '/usr/share/java,/usr/share/confluent-hub-components/,/data/connect-jars'
      # External secrets configZ
      CONNECT_CONFIG_PROVIDERS: 'file'
      CONNECT_CONFIG_PROVIDERS_FILE_CLASS: 'org.apache.kafka.common.config.provider.FileConfigProvider'
    volumes:
      - ${PWD}/credentials.properties:/data/credentials.properties
    command: 
      # In the command section, $ are replaced with $ to avoid the error 'Invalid interpolation format for "command" option'
      - bash 
      - -c 
      - |
        echo "Installing connector plugins"
        # confluent-hub install --no-prompt jcustenborder/kafka-connect-twitter:0.3.33
        confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:5.3.2
        # confluent-hub install --no-prompt confluentinc/kafka-connect-syslog:latest
        confluent-hub install --no-prompt neo4j/kafka-connect-neo4j:1.0.2
        #
        echo "Launching Kafka Connect worker"
        /etc/confluent/docker/run & 
        #
        sleep infinity
         # command: 
      command: 
      # In the command section, $ are replaced with $$ to avoid the error 'Invalid interpolation format for "command" option'
      # - bash 
      # - -c 
      # - |
      #   echo "Installing connector plugins"
      #   # confluent-hub install --no-prompt jcustenborder/kafka-connect-twitter:0.3.33
      #   # confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:5.3.2
      #   # confluent-hub install --no-prompt confluentinc/kafka-connect-syslog:latest
      #   # confluent-hub install --no-prompt debezium/debezium-connector-mysql:latest
      #   # confluent-hub install --no-prompt neo4j/kafka-connect-neo4j:1.0.2
      #   #
      #   echo "Launching Kafka Connect worker"
      #   /etc/confluent/docker/run & 
      #   #
      #   sleep infinity

  postgres:
    # *-----------------------------*
    # To connect to the DB:
    #   docker exec -it postgres bash -c 'psql -U $POSTGRES_USER $POSTGRES_DB'
    # *-----------------------------*
    image: postgres:latest
    container_name: postgres
    ports: 
      - 5432:5432
    environment:
     - POSTGRES_USER=root
     - POSTGRES_DB=onboarding
     - POSTGRES_PASSWORD=h0ttestt
    volumes:
     - ./data/postgres:/docker-entrypoint-initdb.d/
  mysql:
    # *-----------------------------*
    # To connect to the DB: 
    #   docker-compose exec mysql bash -c 'mysql -u root -p$MYSQL_ROOT_PASSWORD'
    #   docker-compose exec mysql bash -c 'mysql -u root -p mysql-testdb'
    # *-----------------------------*
    image: mysql
    container_name: mysql
    environment:
      MYSQL_ROOT_PASSWORD: h0ttestt
      MYSQL_USER: root
      MYSQL_PASSWORD: h0ttestt
      MYSQL_DATABASE: mysql-testdb
  
  # sqlite:
  #   # *-----------------------------*
  #   # To connect to the DB: 
  #   #   docker-compose exec mysql bash -c 'mysql -u root -p$MYSQL_ROOT_PASSWORD'
  #   #   docker-compose exec mysql bash -c 'mysql -u root -p mysql-testdb'
  #   # *-----------------------------*
  #   image: nouchka/sqlite3
  #   container_name: sqlite
  #   environment:
  #     SQLITE_USER: mchardex
  #     SQLITE_PASSWORD: h0ttestt
  #     SQLITE_DATABASE: SQLITE-testdb

  # neo4j:
  #   image: neo4j:3.5-enterprise
  #   container_name: neo4j
  #   ports:
  #   - "7474:7474"
  #   - "7687:7687"
  #   environment:
  #     NEO4J_AUTH: neo4j/connect
  #     NEO4J_dbms_memory_heap_max__size: 8G
  #     NEO4J_ACCEPT_LICENSE_AGREEMENT: 'yes'


#### Connect to ksqldb-cli
```
docker-compose exec ksqldb-cli ksql http://ksqldb-server:8088
```

## SOURCE AND SINK CONNECTORS
=======================================================================================================
### SOURCE CONNECTOR FOR MYSQL
=======================================================================================================
```
CREATE SOURCE CONNECTOR `debezium-connector-mysql` WITH(
   "connector.class"='io.debezium.connector.mysql.MySqlConnector',
   "database.hostname"='mysql',
   "database.port"=3306,
   "database.user"='root',
   "database.password"='root',
   "database.server.id"=4209, 
   "database.server.name"='conn',
   "database.whitelist"='user',
   "database.history.kafka.bootstrap.servers"='broker:29092',
   "database.history.kafka.topic"='dbhistory.user_details',
   "database.allowPublicKeyRetrieval"='true',
   "include.schema.changes"='true',
   "transforms"='unwrap',
   "transforms.unwrap.type"='io.debezium.transforms.UnwrapFromEnvelope',
   "key.converter"='org.apache.kafka.connect.json.JsonConverter',
   "value.converter"='org.apache.kafka.connect.json.JsonConverter',
   "key.converter.schemas.enable"='false',
   "value.converter.schemas.enable"='false'
);
```

=======================================================================================================
### SOURCE CONNECTOR FOR POSTGRESQL
=======================================================================================================
```
CREATE SOURCE CONNECTOR `jdbc-connector-postgresql` WITH(
  "connector.class"='io.confluent.connect.jdbc.JdbcSourceConnector', 
  "connection.url"='jdbc:postgresql://postgres:5432/purchase?username=root&password=h0ttestt', 
  "mode"='bulk', 
  "topic.prefix"='jdbc_', 
  "key"='user_id'
);
```

=======================================================================================================
### SINK CONNECTOR FOR POSTGRESQL
=====================================================================================
```
CREATE SINK CONNECTOR SINK_POSTGRES_LAGOS_TWEETS WITH (
  'connector.class'='io.confluent.connect.jdbc. JdbcSinkConnector', 
  'connection.url'='jdbc:postgresql://postgres:5432/postgres?username=root&password=h0ttestt', 
  'topics'='LAGOS_TWEETS', 
  'key.converter'='org.apache.kafka.connect.storage. StringConverter', 
  'auto.create'='true'
);
```

#### Connect to postgres database
```
docker exec -it postgres psql -U root
```

#### Connect to mysql database
```
docker exec -it mysql mysql -u root -p
```

#### Set offsets
```
SET 'auto.offset.reset' = 'earliest';
```

## Queries
#### Create stream
- mysql
```
CREATE STREAM user_s (id int, user_id int, name string) WITH (VALUE_FORMAT='json', KAFKA_TOPIC='conn.user.user_details');
```

#### Re-partition stream to format properly
```
CREATE STREAM user_partition WITH (KAFKA_TOPIC='user_stream_partition', VALUE_FORMAT='json', PARTITIONS=1) as SELECT * FROM USER_S PARTITION BY user_id;
```

- postgresql
```
CREATE STREAM purchase_s WITH (VALUE_FORMAT='avro', KAFKA_TOPIC='jdbc_user_purchase');
```

#### STREAM AND STREAM JOIN;
```
CREATE STREAM invoice_ss AS SELECT u.user_id AS userid, u.name, p.item, p.purchase_cost AS cost FROM USER_PARTITION u INNER JOIN PURCHASE_S p WITHIN 8 HOURS ON u.user_id = p.user_id;
```

- MySQL
```
CREATE TABLE user_t (id int, user_id int, name string) WITH (VALUE_FORMAT='json', KAFKA_TOPIC='user_stream_partition');
```

- postgresql
```
CREATE TABLE purchase_t WITH (VALUE_FORMAT='avro', KAFKA_TOPIC='jdbc_user_purchase');
```

#### STREAM AND TABLE
```
CREATE STREAM invoice_st AS SELECT u.user_id AS userid, u.name, p.item, p.purchase_cost AS cost FROM USER_PARTITION u INNER JOIN PURCHASE_T p ON u.rowkey = p.rowkey;
```


#### TABLE AND TABLE
```
CREATE TABLE invoice_tt AS SELECT u.user_id AS userid, u.name, p.item, p.purchase_cost AS cost FROM USER_T u INNER JOIN PURCHASE_T p ON u.rowkey = p.rowkey;
```

#### creating materialized views
```
CREATE TABLE invoice_sum_item AS SELECT item, SUM(cost) AS sum_of_items_purchased FROM INVOICE_TT GROUP BY item EMIT CHANGES;
```

### Pull Queries
```
select * from INVOICE_SUM_ITEM WHERE rowkey='bell';
```

outcome
select * from INVOICE_TT emit changes;
select * from INVOICE_SUM_ITEM WHERE rowkey='bell';

=======================================================================================================
### KSQLDB REST API
=======================================================================================================
```
curl -X "POST" "http://localhost:8088/query" \
     -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
     -d $'{
       "ksql": "select * from INVOICE_TT emit changes;",
  "streamsProperties": {
    "ksql.streams.auto.offset.reset": "earliest"
  }
}'
```





















































































### Automate script
#### Mount file inside running postgres bash file directories
- docker run --name postgres -v ${PWD}:/opt/demo -e POSTGRES_PASSWORD=h0ttestt -d postgres

#### Load script
- docker exec -it postgres psql -U postgres -f /opt/demo/script.sql

### Create csv sample test data
- curl "https://api.mockaroo.com/api/58605010?count=1000&key=25fd9c80" > "data/csv-spooldir-source.csv"


===================================================================================================
### CSV source connector
===================================================================================================
CREATE SOURCE CONNECTOR `csvSchemaSpoolDir` WITH(
  "tasks.max"=1,
  "connector.class"='com.github.jcustenborder.kafka.connect.spooldir.SpoolDirCsvSourceConnector',
  "input.file.pattern"='^.*.csv',
  "input.path"='/data/csv/source',
  "error.path"='/data/csv/error',
  "finished.path"='/data/csv/finished',
  "halt.on.error"=false,
  "topic"='spooldir-csvv',
  "csv.first.row.as.header"=true,
  "key.schema"='
  {
    "name":"com.github.jcustenborder.kafka.connect.model.Key",
    "type":"STRUCT",
    "isOptional":false,
    "fieldSchemas" : {
      "id" : {
        "type" : "INT64",
        "isOptional" : false
      }
    }
  }',
  "value.schema"='
  {
    "name" : "com.github.jcustenborder.kafka.connect.model.Value",
    "type" : "STRUCT",
    "isOptional" : false,
    "fieldSchemas" : {
      "id" : {
        "type" : "INT64",
        "isOptional" : false
      },
      "first_name" : {
        "type" : "STRING",
        "isOptional" : true
      },
      "last_name" : {
        "type" : "STRING",
        "isOptional" : true
      },
      "email" : {
        "type" : "STRING",
        "isOptional" : true
      },
      "gender" : {
        "type" : "STRING",
        "isOptional" : true
      },
      "ip_address" : {
        "type" : "STRING",
        "isOptional" : true
      },
      "last_login" : {
        "type" : "STRING",
        "isOptional" : true
      },
      "account_balance" : {
        "type" : "BIGINT",
        "isOptional" : true
      },
      "country" : {
        "type" : "STRING",
        "isOptional" : true
      },
      "favorite_color" : {
        "type" : "STRING",
        "isOptional" : true
      }
    }
  }'
);


### Blockers 
https://github.com/confluentinc/cp-docker-images/issues/770

Debezium mysql source connector
[debezium](https://rmoff.net/2019/10/23/debezium-mysql-v8-public-key-retrieval-is-not-allowed/)
ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'root';