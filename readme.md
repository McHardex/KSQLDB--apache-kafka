## #GETTING STARTED

- Kafka is a distributed streaming platform used to publish and subscribe to streams of records
- Kafka is used for fault tolerant
- kafka allow apps to process streams of records as they occur.


USE
+ building real time streaming data pipelines
    - that reliably get data between systems or applications.receiving and pushing to other systems(elastic search, neo4j, graph database).
    - that transform or react to streams of data. e,g theft transaction check


ksqldb is an event streaming database that is purposely build for stream processing applications
- Three foundational categories to building a streaming application with ksqldb
  - collections: data from different sources
  - stream processing: collection transformation, filter, aggregation and join 
  - queries: performing look ups

- stream : immutable, append-only. used for representing series of historical facts
- tables: mutable, allow for representing latest version of each value per key

docker container stop $(docker container ls -aq)

#### Connect to ksqldb-cli
docker-compose exec ksqldb-cli ksql http://ksqldb-server:8088
```

## SOURCE AND SINK CONNECTORS
==============================================================
### SOURCE CONNECTOR FOR MYSQL
==============================================================

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

==============================================================
### SOURCE CONNECTOR FOR POSTGRESQL
==============================================================

```
CREATE SOURCE CONNECTOR `jdbc-connector-postgresql` WITH(
  "connector.class"='io.confluent.connect.jdbc.JdbcSourceConnector', 
  "connection.url"='jdbc:postgresql://postgres:5432/purchase?username=root&password=h0ttestt', 
  "mode"='timestamp+incrementing', 
  "timestamp.column.name"='modified',
  "incrementing.column.name"='id',
  "validate.non.null"='true',
  "key"='user_id',
  "topic.prefix"='jdbc_'
);
```

==============================================================
### SINK CONNECTOR FOR POSTGRESQL
==============================================================
```
CREATE SINK CONNECTOR SINK_POSTGRES_LAGOS_TWEETS WITH (
  'connector.class'='io.confluent.connect.jdbc. JdbcSinkConnector', 
  'connection.url'='jdbc:postgresql://postgres:5432/postgres?username=root&password=h0ttestt', 
  'topics'='LAGOS_TWEETS', 
  'key.converter'='org.apache.kafka.connect.storage. StringConverter', 
  'auto.create'='true'
);
```

==============================================================
### SINK CONNECTOR FOR ELASTICSEARCH
=============================================================
```
CREATE SINK CONNECTOR `elasticsearch-users` WITH (
  'topics'='USERS', 
  'connector.class'='io.confluent.connect.elasticsearch.ElasticsearchSinkConnector', 
  'connection.url'='http://192.168.0.156:9200', 
  'type.name'='connect',
  'key.ignore'='true',
  'schema.ignore'='true',
  "key.converter"='org.apache.kafka.connect.storage.StringConverter'
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

- outcome

```
select * from INVOICE_TT emit changes;
select * from INVOICE_SUM_ITEM WHERE rowkey='bell';
```

==============================================================
### KSQLDB REST API
==============================================================
```
curl -X "POST" "http://localhost:8088/query" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d $'{
       "ksql": "select * from USER_S emit changes;",
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

#### Connect with external database
https://gist.github.com/MauricioMoraes/87d76577babd4e084cba70f63c04b07d