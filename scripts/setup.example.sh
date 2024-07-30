#!/bin/bash

HOST_IP=127.0.0.1    # Replace the HOST_IP address with your computer's IP address

if [ -e /data/db/.initiated ]
then
    INITIATE_MONGODB="0"
else
    INITIATE_MONGODB="1"
fi


MONGO_INITDB_ROOT_USERNAME="${MONGO_INITDB_ROOT_USERNAME:-ttlab}"
MONGO_INITDB_ROOT_PASSWORD="${MONGO_INITDB_ROOT_PASSWORD:-ttlab1234}"
CUSTOM_USER="${CUSTOM_USER:-dbuser}"
CUSTOM_PASSWORD="${CUSTOM_PASSWORD:-pass}"
CUSTOM_ROLE="${CUSTOM_ROLE:-readWrite}"
CUSTOM_DATABASE="${CUSTOM_DATABASE:-database}"

echo "**********************************************"
echo "Waiting for startup"

function initiateMongoDB () {
    echo "initiateMongoDB function start!"
    mkdir logs
    touch logs/mongo-log.log
    /usr/bin/mongod --port 27017 --bind_ip_all --replSet rs0 --journal --dbpath /data/db --fork --logpath /logs/mongo-log.log

    echo SETUP.sh time now: `date +"%T" `
    echo "db.createUser({ user: "${MONGO_INITDB_ROOT_USERNAME}", pwd: "${MONGO_INITDB_ROOT_PASSWORD}", roles: [ { role: "root", db: "admin" } ] });"
    echo $MONGO_INITDB_ROOT_USERNAME $MONGO_INITDB_ROOT_PASSWORD
    mongosh <<EOF
    use admin;
    var cfg = {
        "_id": "rs0",
        "version": 1,
        "members": [
            {
                "_id": 0,
                "host": "${HOST_IP}:27017",
                "priority": 2
            }
        ]
    };
    rs.initiate(cfg);
EOF

    echo "Create user account."
    mongosh <<EOF
    use admin;
    rs.status();
    db.createUser({ user: "${MONGO_INITDB_ROOT_USERNAME}", pwd: "${MONGO_INITDB_ROOT_PASSWORD}", roles: [ { role: "root", db: "admin" } ] });
    db.createUser(
        {
            user: "${CUSTOM_USER}",
            pwd: "${CUSTOM_PASSWORD}",
            roles: [
                { role: "${CUSTOM_ROLE}", db: "${CUSTOM_DATABASE}" }
            ]
    } );
    db.getUsers();
    db.shutdownServer();
EOF

    touch /data/db/.initiated
    /usr/bin/mongod --port 27017 --bind_ip_all --replSet rs0 --journal --dbpath /data/db --keyFile /keys/mongoKeyFile.key
    echo "initiateMongoDB function done!"
}

if [ $INITIATE_MONGODB == "1" ]
then
    echo "MongoDB is initializing" $INITIATE_MONGODB
    initiateMongoDB
else
    echo "MongoDB initialized" $INITIATE_MONGODB
    /usr/bin/mongod --port 27017 --bind_ip_all --replSet rs0 --journal --dbpath /data/db --keyFile /keys/mongoKeyFile.key
fi

echo "MongoDB is running"