docker stop $(docker ps -q)
docker rm -v $(docker ps -q -a)
