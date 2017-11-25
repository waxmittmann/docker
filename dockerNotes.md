# Docker run
## Flags
-i: interactive (have input stream open)
-t: terminal  (so we have output stream open)

## Running detached
```
docker run -t -d {image}
```
will run with terminal and detached (so it doesn't auto-close because there is no process running).

Then we can get a bash using:
```
docker exec -it {container} /bin/bash
```

# Volumes
## Two types
- Docker-managed volumes that are located in the Docker part of the host file system
- bind mount volumes that are located anywhere on the host file system.

## Volume info
```
docker volume {cmd}
```

## Use cases
- share data
- inject config
- inject tools as needed  (e.g. debugging if something goes wrong)

## Injecting config
The following will create two 'config containers' that copy their config to /config; creating app containers with --volumes-from to those containers will then inject the appropriate config
```
docker run --name devConfig \
-v /config \
dockerinaction/ch4_packed_config:latest \
/bin/sh -c 'cp /development/* /config/'
docker run --name prodConfig \
-v /config \
dockerinaction/ch4_packed_config:latest \
/bin/sh -c 'cp /production/* /config/'
docker run --name devApp \
--volumes-from devConfig \
dockerinaction/ch4_polyapp
docker run --name prodApp \
--volumes-from prodConfig \
dockerinaction/ch4_polyapp
```

## Auto-deleting associated volumes from container
Run with '-v' flag, and all the volumes will be cleaned up.
DON'T do this if you wanna keep the volume, duh.

## Creating a volume and sharing it between two containers
### Create volume (note this will get silently created otherwise anyway)
```
docker volume create my-vol
```

### Create container with it mounted, bash into it, create some files
```
docker run -tid --mount source=my_vol,target=/secret ubuntu
docker exec {containerA} /bin/bash
# cd secret
# echo 'a' > a.txt
```

### Create second container with it mounted, bash into it, files will be there
```
docker run -tid --mount source=my_vol,target=/secret ubuntu
docker exec {containerB} /bin/bash
# cd secret
# ls
```

## Mount all volumes from a different containerA
```
docker run -tid --volumes-from={otherContainer} ubuntu
```

## Docker --mount versus docker -v (volume)
These will have the same effect (mount is recommended due to increased clarity):
```
$ docker run -d \
  -it \
  --name=nginxtest \
  --mount source=nginx-vol,destination=/usr/share/nginx/html,readonly \
  nginx:latest
```

```
$ docker run -d \
  -it \
  --name=nginxtest \
  -v nginx-vol:/usr/share/nginx/html:ro \
  nginx:latest
```

# Networking
## Four types
### Closed container:
No network traffic (except loopback)
Created via `--net none`

### Bridged container (default):
Are connected to docker0, so part of same virtual subnet meaning they can communicate with other containers on docker0, and with wider network via docker0.

By default, bridged containers aren't accessible from host, but 'publish' maps from a port on the host to a port on the container's interface.

Default, or created via `--net bridge`

Use `--dns {address}` to set a container's dns server (can also be set on docker daemon, in which case it applies to all containers)  

Use `-add-host=[{name}:{ip}]` to manually add hosts

#### Publishing ports (for bridged containers)
Bind container port to a dynamically-assigned port on host's interfaces:
```
docker run -p {containerPort}
```

Bind container port to a specified port on host's interfaces:
```
docker run -p {hostPort}:{containerPort}
```

Bind container port to a specified ip on host's interfaces:
```
docker run -p {ip}::{containerPort}
```

Bind container port to a specified ip and port on host's interfaces:
```
docker run -p {ip}::{hostPort}::{containerPort}
```

Using `-P` or `--publish-all` will automatically publish all ports the image reports.

`-icc=false` disables inter-container communication by default, forcing explicit dependencies to be declared, and should be used in any production setting.

### Joined container:
Containers share common network stack, rather than having their own stacks linked by docker0 (though they're still linked to the outside world by docker0).

```
--net container:{containerToJoin}
```

Reasons to use:
- when using a single loopback interface for communication between programs in different Containers
- if a program in one container has to change the network stack for a program in a different container
- when one container needs to monitor a different container's network traffic

### Open container:
No network container; full access to host's network (!)
```
--net host
```

## Linking Containers (for local service discovery)
Can link a container to a running container via `link` on create, opening ports exposed by target container. Allows 'finding' a container without needing to resort to scanning the network or using local DNS to identify other containers.

Adding link has three effects:
- creates environmental variable describing target container's end point
- link alias is added to DNS override list of new container with IP of target container
- if inter-container communication is disabled, firewall rules are automatically added to allow comms between linked containers

Usage: `--link {containerName}:{aliasName}`

It's good practice too always include dependency-checking code to validate required links when a container starts up.

Links are:
- directional (in discovery, not communication)
- non-transitive
- static

Stopping a linked container breaks the link, since ip address will be freed. This means that we will need to restart dependent containers to re-establish links if a linked container fails.

# ... skipping the Isolation chapter for now ...

# Packaging for Distribution
Use `docker commit {containerName} {newImageName}` to create new image from {containerName}. The `-a` flag sets the author, the `-m` flag adds a commit message.

Using `--entrypoint {cmd}` with `run` will run the entrypoint when run is invoked, so use that and then commit to auto-run a command on startup.

`docker export --output {file} {containerName}` will export an container's contents to a file.

`docker tag`  ...

# Building with Dockerfiles
```
docker build --tag {repository, e.g: ubuntu-git:auto} {path to Dockerfile}
```
(can use --file to specify the name of the dockerfile)

Each command creates a new layer for the final image, so combine steps into single command where possible.

## Dockerfile instructions
`FROM {image}`: the base of the new image
`MAINTAINER {maintainer}`: sets Author value in image metadata
`COPY [{source}], {dest}`: copies files (note all perms are set to root)
`VOLUME [{destPath}]`: defines mount point for volume
`RUN {cmd}`: run a command
`ENV [{variableName} "{variableValue}"]`: set environmental variable(s); these can also be used in other instructions
`LABEL {labelKey} {labelValue}`: set label kv pairs on image
`WORKDIR {dir}`: sets working directory for container
`EXPOSE [{port}]`: expose the container's ports
`ENTRYPOINT ([{shell cmd}] | {cmd}[{arg}]`: command and exec forms
`CMD [{arg}]`: argument list for entrypoint
`ONBUILD {instruction}`: executed if image is used as base for another build (after FROM, before instruction following FROM)

## Thing to check on container startup
- Presumed links (and aliases)
- Environment variables
- Network access
- Network port availability
- Root file system mount parameters (read-write or read-only)
- Volumes
- Current user

## Init process
Unix-based sytems usually use init process which starts other system services. Often useful to use (lightweight) init processes with containers.

## Content-addressable image identifier
```
FROM {imageName}@sha256:{sha}
```
will lock the image to that specific sha version

## ... skipping hardening bits for now ...

# ... skipping distribution for now ...

# ... skipping  customized registries for now ...

# Multi-container and Multi-Host environments - Declarative environments with Docker Compose

----
Updates
# User-defined networks
`--link` is deprecated!

1) Create network
```
docker network create --driver bridge isolated_nw
docker network inspect isolated_nw
```

2) Create containers on the network
```
docker run --network=isolated_nw -itd --name=c1 ubuntu
docker run --network=isolated_nw -itd --name=c2 ubuntu
```

3) Test
Show what's on the network:
```
docker network inspect isolated_nw
```

And after installing ping, this should work on either container:
```
ping c1
ping c2
```

----
# Bits and pieces
## Create postgres db and connect
(see https://hub.docker.com/_/postgres/)
docker run --name psql -e POSTGRES_PASSWORD=password -d -p 5432 postgres

psql -h 127.0.0.1 -p 32769 -U postgres

## Creating a volume and inserting / reading data from it using a container
docker volume create --name test

docker run -it --mount source=test,target=/test ubuntu:latest /bin/bash

docker cp {containerName} {file} /test

./clean.sh

docker run -it --mount source=test,target=/test ubuntu:latest

## Cleaning up
*warning: this will remove EVERYTHING (images, containers, volumes, ...); todo: Check whether we can get something less everything.*

`docker system prune -a -f`
