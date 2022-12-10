#!/bin/bash
set -euxo
WORKDIR=$(pwd)
cd "$(dirname "$0")"

if docker-compose ps | grep -E "\s+Up\s+"; then
    docker-compose stop
    docker-compose ps -a |  sed -e '1,2d' | sed -E "s/[[:space:]]{2,}/,/g" | awk -F "," '{print $1}' 
fi
    
for postgres_dir in {primary,replica1,replica2}; do

    chmod a+x ./${postgres_dir}/initdb.d/init.sh
    if [ -d ./${postgres_dir}/data ];then
        rm -rf ./${postgres_dir}/data
    fi
    mkdir ./${postgres_dir}/data
    
    if [ -d ./${postgres_dir}/log ];then
        rm -rf ./${postgres_dir}/log
    fi
    mkdir ./${postgres_dir}/log
    

done

docker-compose build --force-rm
docker-compose up -d

exit