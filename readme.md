## Generate keys
```
    sh create-mongo-key.sh
```
## set permission
```
   chmod 600 /path/to/keyfile
```

docker container list

## Test connection
docker exec -it 04de13e18d73 mongosh "mongodb://sorademic:12345678@{{your server ip}}:27017"
