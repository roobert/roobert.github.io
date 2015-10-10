## About


## Ubuntu Base Image

```
docker build -t dockerfile/ubuntu github.com/dockerfile/ubuntu
```

## Redis

Build and run a redis image with exposed ports 

```
docker build -t dockerfile/redis github.com/dockerfile/redis
mkdir /srv/redis
docker run --name=redis -d -v /srv/redis:/data -t dockerfile/redis
```

Test redis availability
```
docker exec -it redis redis-cli ping
```

## RabbitMQ

Build and run RabbitMQ, exposing ports so Sensu clients can connect. Data is persisted in `/srv/rabbitmq`.

```
mkdir -p /srv/rabbitmq/{log,mnesia}
docker build -t dockerfile/rabbitmq github.com/dockerfile/rabbitmq
docker run \
  --name=rabbitmq \
  -d \
  -p 5672:5672 \
  -p 15672:15672 \
  -v /srv/rabbitmq:/data/log \
  -v /srv/rabbitmq/mnesia:/data/mnesia 
  dockerfile/rabbitmq
```

Test RabbitMQ by opening a connection in a web browser to port `15672` and logging in with `guest:guest`

## Sensu

### Build Image

All Sensu services use the same runtime so build a generic `sensu-service` container:

```
docker build -t roobert/sensu-service github.com/roobert/sensu-service
```

### Server

Run a Sensu server container.

Sensu config can be loaded from /srv/sensu/server

```
mkdir /srv/sensu/server
docker run \
  --name sensu-server \
  -d \
  --link redis \
  --link rabbitmq \
  -e TRANSPORT_NAME=rabbitmq \
  -e RABBITMQ_URL=amqp://rabbitmq:5672 \
  -e REDIS_URL=redis://redis:6379 \
  -e SENSU_SERVICE=server \
  -v /srv/sensu/server:/sensu \
  roobert/sensu-service
```

Test Sensu server:
```
docker logs sensu-server
docker exec -it redis redis-cli get leader
```

### API

Run Sensu API instance. Expose port 4567 in order to use `sensu-cli`

```
docker run \
  --name sensu-api \
  -d \
  --link redis \
  --link rabbitmq \
  -p 4567:4567 \
  -e TRANSPORT_NAME=rabbitmq \
  -e RABBITMQ_URL=amqp://rabbitmq:5672 \
  -e REDIS_URL=redis://redis:6379 \
  -e API_PORT=4567 \
  -e SENSU_SERVICE=api \
  roobert/sensu-service
```

### UI

```
git clone git@github.com:sensu/uchiwa /tmp/uchiwa
( cd /tmp/uchiwa && docker build -t sensu/uchiwa . )

# create /etc/sensu/uchiwa/config.json
tee /srv/sensu/uchiwa/config.json << EOF
{
  "sensu": [
    {
      "name": "localhost",
      "host": "sensu-api",
      "port": 4567,
      "timeout": 5
    }
  ],
  "uchiwa": {
    "host": "0.0.0.0",
    "port": 3000,
    "interval": 5
  }
}
EOF

docker run \
  --name uchiwa \
  -d \
  -p 3000:3000 \
  --link sensu-api \
  --link sensu-rabbitmq \
  -v /srv/sensu/uchiwa:/config \
  sensu/uchiwa
```
