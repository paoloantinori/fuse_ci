#!/bin/bash

##########################################################################################################
# Description:
#
# Dependencies:
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
# - FUSE ESB Already installed
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


# halt on errors
set -e

FUSE_PATH="/data/software/redhat/FUSE/fuse_full/jboss-fuse-6.1.0.redhat-379"
DEPLOYMENT_FOLDER="/opt/rh"

########### aliases to preconfigure ssh and scp verbose to type options

# full path of your ssh, used by the following helper aliases
SSH_PATH=$(which ssh) 
### ssh aliases to remove some of the visual clutter in the rest of the script
# alias to connect to your docker images
alias ssh="$SSH_PATH -o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR"
# alias to connect to the ssh server exposed by JBoss Fuse. uses sshpass to script the password authentication
alias ssh2fabric="sshpass -p admin $SSH_PATH -p 8101 -o ServerAliveCountMax=100 -o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR admin@localhost"
#alias for scp to inline flags to disable ssh warnings
alias scp="scp -o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR"


################################################################################################
#####                             Tutorial starts here                                     #####
################################################################################################

OFFLINE_MAVEN_REPO_PATH="$DEPLOYMENT_FOLDER/offline_maven_repo"


#invoke clean script
sh clean_local.sh

# start fuse on root node (yes, that initial backslash is required to not use the declared alias)
"$FUSE_PATH/bin/start"


############################# here you are starting to interact with Fuse/Karaf

# wait for ssh server to be up, avoids "Connection reset by peer" errors
while ! ssh2fabric "echo up" ; do sleep 1s; done;

# wait for critical components to be available before progressing with other steps
ssh2fabric "wait-for-service -t 300000 io.fabric8.api.BootstrapComplete"


# create a new fabric AND wait for the Fabric to be up and ready to accept the following commands
ssh2fabric "fabric:create --clean -r localip -g localip --wait-for-provisioning" 

# stop default broker created automatically with fabric
#ssh2fabric "stop org.jboss.amq.mq-fabric" 

# create deployment folder
mkdir -p "$DEPLOYMENT_FOLDER/"
# upload release
cp -a ../offline_maven_repo/target/offline_maven_repo-*.zip "$DEPLOYMENT_FOLDER/"
# upload properties
cp -a ../config/overridden_constants.properties "$DEPLOYMENT_FOLDER/"


# extract the release
unzip -u -o "$DEPLOYMENT_FOLDER/*.zip" -d "$DEPLOYMENT_FOLDER/"

# configure local maven
ssh2fabric "fabric:profile-edit --pid io.fabric8.agent/org.ops4j.pax.url.mvn.repositories=\"file://$OFFLINE_MAVEN_REPO_PATH@snapshots@id=sample\" default"
# important! to disable maven snapshot checksum that otherwise will block the functionality
ssh2fabric "fabric:profile-edit --pid org.fusesource.fabric.maven/checksumPolicy=warn  default "
ssh2fabric "fabric:profile-edit --pid org.ops4j.pax.url.mvn/checksumPolicy=warn  default "



ssh2fabric "shell:source mvn:sample/karaf_scripts/1.0.0-SNAPSHOT/karaf/create_containers"
ssh2fabric "shell:source mvn:sample/karaf_scripts/1.0.0-SNAPSHOT/karaf/deploy_codebase"



set +x
echo "
----------------------------------------------------
CI Quickstart
----------------------------------------------------
FABRIC ROOT: 
- ip:          $IP_ROOT
- karaf:       sshpass -p admin ssh -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o UserKnownHostsFile=/dev/null admin@localhost -p8101
- tail logs:   tail -F $FUSE_PATH/data/log/fuse.log

----------------------------------------------------

"

