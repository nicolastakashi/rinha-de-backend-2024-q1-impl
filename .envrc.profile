export RINHA_WARMUP_QUERY="SELECT pg_prewarm('transacoes'); SELECT pg_prewarm('clientes'); select * from transacoes limit 5; select * from clientes limit 5;"
export QUARKUS_HTTP_PORT=9000
export QUARKUS_BANNER_ENABLED=false
export QUARKUS_HTTP_IDLE_TIMEOUT=45
export QUARKUS_DATASOURCE_JDBC_URL=jdbc:postgresql://127.0.0.1:5400/rinha
export QUARKUS_DATASOURCE_JDBC_INITIAL_SIZE=10
export QUARKUS_DATASOURCE_JDBC_MIN_SIZE=10
export QUARKUS_DATASOURCE_JDBC_MAX_SIZE=10
export QUARKUS_DATASOURCE_JDBC_ACQUISITION_TIMEOUT=60
export QUARKUS_DATASOURCE_JDBC_TRANSACTION_ISOLATION_LEVEL=read-committed
export QUARKUS_TRANSACTION_MANAGER_DEFAULT_TRANSACTION_TIMEOUT=60
export QUARKUS_DATASOURCE_JDBC_BACKGROUND_VALIDATION_INTERVAL=0
export QUARKUS_DATASOURCE_USERNAME=rinha
export QUARKUS_DATASOURCE_PASSWORD=123
export QUARKUS_MICROMETER_ENABLED=false

