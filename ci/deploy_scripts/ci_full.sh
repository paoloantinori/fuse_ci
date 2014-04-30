#!/bin/bash

##########################################################################################################
# Description:
#
# Dependencies:
# - docker 
# - sshpass, used to avoid typing the pass everytime (not needed if you are invoking the commands manually)
# to install on Fedora/Centos/Rhel: 
# sudo yum install -y docker-io sshpass
#
# to install on MacOSX:
# sudo port install sshpass
# or
# brew install https://raw.github.com/eugeneoden/homebrew/eca9de1/Library/Formula/sshpass.rb
#
# Prerequesites:
# - run docker in case it's not already
# sudo service docker start
#
# Notes:
# - if you don't want to use docker, just assign to the ip addresses of your own boxes to environment variable
#######################################################################################################


################################################################################################
#####             Preconfiguration and helper functions. Skip if not interested.           #####
################################################################################################

# set debug mode
set -x

# configure logging to print line numbers
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'


# ulimits values needed by the processes inside the container
ulimit -u 4096
ulimit -n 4096

########## docker lab configuration


# remove old docker containers with the same names
docker stop -t 0 root  
docker stop -t 0 nexus  
docker stop -t 0 jenkins
docker stop -t 0 git

docker rm root 
docker rm nexus 
docker rm jenkins
docker rm git


# expose ports to localhost, uncomment to enable always
# EXPOSE_PORTS="-P"
if [[ x$EXPOSE_PORTS == xtrue ]] ; then EXPOSE_PORTS=-P ; fi

# halt on errors
set -e

# create your lab
docker run -d -t -i $EXPOSE_PORTS   --name root 	fuse6.1
docker run -d -t -i                 --name nexus 	blackhm/nexus
docker run -d -t -i                 --name jenkins 	pantinor/jenkins
docker run -d -t -i                 --name git      pantinor/jenkins sh -c 'service sshd start ; bash'


# assign ip addresses to env variable, despite they should be constant on the same machine across sessions
IP_ROOT=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' root)
IP_NEXUS=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' nexus)
IP_JENKINS=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' jenkins)
IP_GIT=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' git)

USERNAME_ROOT="fuse"
KARAF_SCRIPTS_VERSION="1.0.0-SNAPSHOT"

########### aliases to preconfigure ssh and scp verbose to type options

# full path of your ssh, used by the following helper aliases
SSH_PATH=$(which ssh) 
### ssh aliases to remove some of the visual clutter in the rest of the script
# alias to connect to your docker images
alias ssh="$SSH_PATH -o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR"
alias ssh2host="$SSH_PATH -o UserKnownHostsFile=/dev/null -o ConnectionAttempts=180 -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR $USERNAME_ROOT@$IP_ROOT"
alias ssh2git="$SSH_PATH -o UserKnownHostsFile=/dev/null -o ConnectionAttempts=180 -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR $USERNAME_ROOT@$IP_GIT"
# alias to connect to the ssh server exposed by JBoss Fuse. uses sshpass to script the password authentication
alias ssh2fabric="sshpass -p admin $SSH_PATH -p 8101 -o ServerAliveCountMax=100 -o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR admin@$IP_ROOT"
#alias for scp to inline flags to disable ssh warnings
alias scp="scp -o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR"


################################################################################################
#####                             Tutorial starts here                                     #####
################################################################################################

# wait for nexus server to be up, avoids "Connection reset by peer" errors
while ! curl --silent -L $IP_NEXUS:8081/nexus > /dev/null; do sleep 5s; done;

# add git server as a remote repo
cd ../../ 
# initialize remote git repo
ssh2git "git init --bare /home/fuse/fuse_scripts.git"
ssh2git "chmod a+rx -R /home/fuse/fuse_scripts.git"
# configure upstream repo
git remote remove upstream
git remote add upstream ssh://fuse@$IP_GIT/home/fuse/fuse_scripts.git

# enable temporary ssh permissions
echo "Host *" >> ~/.ssh/config
echo "UserKnownHostsFile /dev/null" >> ~/.ssh/config
echo "StrictHostKeyChecking no" >> ~/.ssh/config
# push source code
git push upstream

# remove temporary ssh permissions
sed -ie '$d' ~/.ssh/config
sed -ie '$d' ~/.ssh/config
sed -ie '$d' ~/.ssh/config

### build and deploy to Nexus
#(cd ../../ ; mvn clean deploy -DskipTests -Dmaven.test.skip -s my_settings.xml -Dip.nexus=$IP_NEXUS) 



# wait for jenkins server to be up, avoids "Connection reset by peer" errors
while ! curl --silent -L $IP_JENKINS:8080/  > /dev/null; do sleep 5s; done;



# OFFLINE_MAVEN_REPO_PATH="/opt/rh/offline_maven_repo"


# # start fuse on root node (yes, that initial backslash is required to not use the declared alias)
# ssh2host "/opt/rh/jboss-fuse-*/bin/start"


# ############################# here you are starting to interact with Fuse/Karaf

# # wait for critical components to be available before progressing with other steps
# ssh2fabric "wait-for-service -t 300000 io.fabric8.api.BootstrapComplete"


# # create a new fabric AND wait for the Fabric to be up and ready to accept the following commands
# ssh2fabric "fabric:create --clean -r localip -g localip --wait-for-provisioning" 

# # stop default broker created automatically with fabric
# #ssh2fabric "stop org.jboss.amq.mq-fabric" 

# # upload release
# scp ../offline_maven_repo/target/offline_maven_repo-*.zip $USERNAME_ROOT@$IP_ROOT:/opt/rh/
# # upload properties
# scp ../config/overridden_constants.properties $USERNAME_ROOT@$IP_ROOT:/opt/rh/


# # extract the release
# ssh2host "unzip -u -o /opt/rh/*.zip -d /opt/rh"

# # configure local maven
# ssh2fabric "fabric:profile-edit --pid io.fabric8.agent/org.ops4j.pax.url.mvn.repositories=\"file://$OFFLINE_MAVEN_REPO_PATH@snapshots@id=sample\" default"
# # important! to disable maven snapshot checksum that otherwise will block the functionality
# ssh2fabric "fabric:profile-edit --pid org.fusesource.fabric.maven/checksumPolicy=warn  default "
# ssh2fabric "fabric:profile-edit --pid org.ops4j.pax.url.mvn/checksumPolicy=warn  default "



# ssh2fabric "shell:source mvn:sample/karaf_scripts/$KARAF_SCRIPTS_VERSION/karaf/create_containers"
# ssh2fabric "shell:source mvn:sample/karaf_scripts/$KARAF_SCRIPTS_VERSION/karaf/deploy_codebase"



set +x
echo "
----------------------------------------------------
CI Quickstart
----------------------------------------------------
FABRIC ROOT: 
- ip:          $IP_ROOT
- ssh:         ssh -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o UserKnownHostsFile=/dev/null fuse@$IP_ROOT
- karaf:       sshpass -p admin ssh -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o UserKnownHostsFile=/dev/null admin@$IP_ROOT -p8101
- tail logs:   ssh -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o UserKnownHostsFile=/dev/null fuse@$IP_ROOT 'tail -F /opt/rh/jboss-fuse-*/data/log/fuse.log'

NEXUS: 
- ip:          $IP_NEXUS
- http:        http://$IP_NEXUS:8081/nexus
- user:        admin
- pass:        admin123

JENKINS: 
- ip:          $IP_JENKINS
- http:        http://$IP_JENKINS:8080/

GIT (SSH)
- ip:          $IP_GIT
- port:        22
- user:        fuse



NOTE: If you are using Docker in a VM you may need extra config to route the traffic to the containers. One way to bypass this can be setting the environment variable EXPOSE_PORTS=true before running this script and than to use 'docker ps' to discover the exposed ports on your localhost.
----------------------------------------------------

"

