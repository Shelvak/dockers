# Docker-Compose

## Pgadmin
`chmod 0600 volumes/pgadmin/pgpassfile && chown 5050:5050 volumes/pgadmin/pgpassfile`


## SETUP
- Install [Docker](https://docs.docker.com/engine/installation/) version  >= 17.03.X
- Install [Docker-compose](https://docs.docker.com/compose/install/) version >= 1.13.X
- Adding user to docker group => `sudo gpasswd -a $USER docker`
- disable postgresql and redis if running locally

```bash
sudo systemctl stop postgresql.service
sudo systemctl stop redis-server.service
```

- Run:
```bash
docker-compose pull --parallel

# Init database
docker-compose up -d postgres
./run_in_service.sh postgres /initialize.sh

# Init Default VHost and perms in rabbit
docker-compose up -d rabbit
./run_in_service.sh rabbit /initialize.sh

# Little Note in some cases redis container doesn't recognize volumes permissions
# so you have to force a 777 chmod ¡¡¡EXCEPT THE VOLUME rabbit!!!
sudo chmod 777 -R volumes/logs

# Init everything else
docker-compose up   # Will take a few to run all the migrations
```
### Sentry
- Ones sentry finish with all the migrations you have to visit http://localhost:9000
- username: docker
- password: docker
- Click on Accept (for docker default settings)
- Enjoy

### RabbitMQ
- For Web Interface visit http://localhost:15672/
- username: docker
- password: docker


### Torrents
- Must link/create `./volumes/Torrents/` for downloads & samba share
- `./volumes/Torrents/.transmission-daemon` lives transmission folder
- `./volumes/Torrents/.flexget` lives flexget config

# Running containers
After the setup you'll only have to run `docker-compose up [-d]` # -d is for dettached mode (background)

### Running commands inside containers
This run the _command with  params_ inside the container and exit.
```bash
./run_in_service.sh CONTAINER COMAND WITH PARAMS
```
### Testing things inside containers
This will attach you to the container with a bash shell
```bash
./attach.sh CONTAINER
```
