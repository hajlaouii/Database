#!/bin/bash


DIR="${HOME}/generator"
USER_SCRIPT=$USER

# Fonctions ###########################################################

help_list() {
  echo "Usage:

  ${0##*/} [-h]

Options:

  -h, --help
    can I help you ?

  -i, --ip
    list ip for each container
  
  -m, --mount
    Mount the service 
   
  -d, --dump
    Create tables in bulksmsdb 

  "
}

parse_options() {
  case $@ in
    -h|help)
      help_list
      exit
     ;;
    -i|--ip)
      ip
      ;;
    -m|--mount)
      mount
      ;;
    -d|--dump)
     dump
     ;;
    *)
      echo "Unknown option: ${opt} - Run ${0##*/} -h for help.">&2
      exit 1
  esac
}


ip() {
for i in $(docker ps -q); do docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} - {{.Name}}" $i;done
}

mount() {

echo

echo "1 - Create local Volumes"
echo " - Create directorie ${DIR}/Database"
mkdir -p $DIR/Database/



echo "2 - Create docker-compose file"
echo "
version: '3'
services:
  Database:
    container_name: Database
    image: mariadb:latest
    volumes:
     - Database:/var/lib/mysql/
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: bulksmsdb
      MYSQL_USER: bulksmsusr
      MYSQL_PASSWORD: bulksmspwd
    restart: on-failure
  Frontend:
    container_name: Frontend
    image: hajlaouimahdi/frontend:latest
    restart: on-failure
  API:
    container_name: API
    image: hajlaouimahdi/api:latest
    restart: on-failure
  Backend:
    container_name: Backend
    image: hajlaouimahdi/backend:latest
    restart: on-failure
volumes:
  Database:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/Database/

   
" >$DIR/docker-compose.yml

echo "3 - Run the service "
docker-compose -f $DIR/docker-compose.yml up -d   


}


dump() {
echo "4 - dump bulksmsdb tables "
docker exec -i Database mysql -uroot -proot bulksmsdb < dump_cloud.sql
docker exec -i Database mysql -uroot -proot bulksmsdb < privileges.sql
}

# Let's Go !! parse args  ####################################################################

parse_options $@

ip
