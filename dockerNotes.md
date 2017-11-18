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
## Volume info
```
docker volume {cmd}
```

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
