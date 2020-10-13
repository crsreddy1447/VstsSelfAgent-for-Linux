#!/bin/sh

# Install Build Tools
sudo /bin/date +%H:%M:%S > /home/$5/install.progress.txt


echo "ooooo      FULL INSTALL      ooooo" >> /home/$5/install.progress.txt

echo "Installing build-essential package" >> /home/$5/install.progress.txt
sudo apt-get -y install build-essential
sudo /bin/date +%H:%M:%S >> /home/$5/install.progress.txt

echo "Installing packaging-dev package" >> /home/$5/install.progress.txt
sudo apt-get -y install packaging-dev
sudo /bin/date +%H:%M:%S >> /home/$5/install.progress.txt

sudo -u $5 mkdir /home/$5/downloads
sudo -u $5 mkdir /home/$5/lib

# Install NodeJS, npm, and gulp

echo "Installing NodeJS package" >> /home/$5/install.progress.txt
sudo curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo /bin/date +%H:%M:%S >> /home/$5/install.progress.txt

echo "Installing npm package" >> /home/$5/install.progress.txt
sudo npm install -g npm@latest
#sudo -u $5 npm install gulp --save-dev
sudo /bin/date +%H:%M:%S >> /home/$5/install.progress.txt

echo "Installing zip package" >> /home/$5/install.progress.txt
#install zip package
sudo apt-get -y install zip
sudo /bin/date +%H:%M:%S >> /home/$5/install.progress.txt

#Install latest powershell & Az module
# Download the Microsoft repository GPG keys
wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb
# Register the Microsoft repository GPG keys
sudo dpkg -i packages-microsoft-prod.deb
# Update the list of products
sudo apt-get update
# Install PowerShell
sudo apt-get install -y powershell
#install Az module
sudo pwsh -Command Install-Module -Name Az -AllowClobber -Force -AcceptLicense
sudo pwsh -Command Import-Module -Name Az


# Install latest release of .NET Core
echo "Installing .NET" >> /home/$5/install.progress.txt
sudo -u $5 mkdir /home/$5/lib/dotnet
cd /home/$5/downloads
sudo -u $5 wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get -y install apt-transport-https
sudo apt-get -y update
sudo apt-get -y install dotnet-runtime-2.0.6
#cd /home/$5/lib/dotnet
#sudo -u $5 tar zxfv /home/$5/downloads/dotnet-ubuntu.16.04-x64.latest.tar.gz
sudo apt-get -y install apt-transport-https
sudo apt-get -y update
sudo apt-get -y install dotnet-sdk-2.2
sudo /bin/date +%H:%M:%S >> /home/$5/install.progress.txt

# Install Docker Engine and Compose
echo "Installing Docker Engine and Compose" >> /home/$5/install.progress.txt
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates
sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
sudo apt-get install -y docker-engine
sudo service docker start
sudo systemctl enable docker
sudo groupadd docker
sudo usermod -aG docker $5

COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
sudo curl -L https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sh -c "curl -L https://raw.githubusercontent.com/docker/compose/${COMPOSE_VERSION}/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose"

sudo /bin/date +%H:%M:%S >> /home/$5/install.progress.txt

# Install VSTS build agent dependencies

echo "Installing libunwind8 and libcurl3 package" >> /home/$5/install.progress.txt
sudo apt-get -y install libunwind8 libcurl3
sudo /bin/date +%H:%M:%S >> /home/$5/install.progress.txt

echo "Installing jq package" >> /home/$5/install.progress.txt
#Install jq
sudo apt-get -y install jq
sudo /bin/date +%H:%M:%S >> /home/$5/install.progress.txt

# Download VSTS build agent and required security patch

echo "Downloading VSTS Build agent package" >> /home/$5/install.progress.txt
cd /home/$5
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo $1 $3 $4 >> /home/$5/install.progress.txt
echo $VSTS_AGENT $VSTS_ACCOUNT $VSTS_POOL >> /home/$5/install.progress.txt
echo "wrongly done" >> /home/$5/install.progress.txt
#set -e

#provide the path where the agent will install and run, home for the agent
export VSTS_HOME=/home/$5
#Provide the work directoy
export VSTS_WORK=$VSTS_HOME/agent/_work

VSTS_AGENT=$4
VSTS_ACCOUNT=$1
VSTS_POOL=$3
VSTS_TOKEN=$2
echo $1 $3 $4 >> /home/$5/install.progress.txt
echo $VSTS_AGENT $VSTS_ACCOUNT $VSTS_POOL $VSTS_TOKEN >> /home/$5/install.progress.txt
echo "rightly done" >> /home/$5/install.progress.txt
#. env.sh
#export VSO_AGENT_IGNORE=_,MAIL,OLDPWD,PATH,PWD,VSTS_AGENT,VSTS_ACCOUNT,VSTS_TOKEN_FILE,VSTS_TOKEN,VSTS_POOL,VSTS_WORK,VSO_AGENT_IGNORE

if [ ! -e $VSTS_HOME/.configure ]; then
touch $VSTS_HOME/.configure
fi

if [ ! -e $VSTS_HOME/.token ]; then
touch $VSTS_HOME/.token
fi

if [ $(dpkg-query -W -f='${Status}' jq 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
sudo apt-get install jq
fi


if [ -n "$VSTS_AGENT_IGNORE" ]; then
  export VSO_AGENT_IGNORE=$VSO_AGENT_IGNORE,VSTS_AGENT_IGNORE,$VSTS_AGENT_IGNORE
fi

if [ -e $VSTS_HOME/agent -a ! -e $VSTS_HOME/.configure ]; then
  trap 'kill -SIGINT $!; exit 130' INT
  trap 'kill -SIGTERM $!; exit 143' TERM
  $VSTS_HOME/agent/bin/Agent.Listener run & wait $!
  exit $?
fi

if [ -z "$VSTS_ACCOUNT" ]; then
  echo 1>&2 error: missing VSTS_ACCOUNT environment variable
  exit 1
fi

if [ -z "$VSTS_TOKEN_FILE" ]; then
  if [ -z "$VSTS_TOKEN" ]; then
    echo 1>&2 error: missing VSTS_TOKEN environment variable
    exit 1
  fi
  VSTS_TOKEN_FILE=$VSTS_HOME/.token
  echo -n $2 > "$VSTS_TOKEN_FILE"
  fi
unset VSTS_TOKEN

if [ -n "$VSTS_AGENT" ]; then
  export VSTS_AGENT="$(eval echo $VSTS_AGENT)"
fi

if [ -n "$VSTS_WORK" ]; then
  export VSTS_WORK="$(eval echo $VSTS_WORK)"
  mkdir -p "$VSTS_WORK"
fi

#touch /vsts/.configure
rm -rf $VSTS_HOME/agent
mkdir $VSTS_HOME/agent
cd $VSTS_HOME/agent


cleanup() {
  if [ -e config.sh ]; then
    ./bin/Agent.Listener remove --unattended \
      --auth PAT \
      --token $(cat "$VSTS_TOKEN_FILE")
  fi
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

echo Determining matching VSTS agent...
VSTS_AGENT_RESPONSE=$(curl -LsS \
  -u user:$(cat "$VSTS_TOKEN_FILE") \
  -H 'Accept:application/json;api-version=3.0-preview' \
  "https://$VSTS_ACCOUNT.visualstudio.com/_apis/distributedtask/packages/agent?platform=linux-x64")


if echo "$VSTS_AGENT_RESPONSE" | jq . >/dev/null 2>&1; then
  VSTS_AGENT_URL=$(echo "$VSTS_AGENT_RESPONSE" \
    | jq -r '.value | map([.version.major,.version.minor,.version.patch,.downloadUrl]) | sort | .[length-1] | .[3]')
   
fi


if [ -z "$VSTS_AGENT_URL" -o "$VSTS_AGENT_URL" == "null" ]; then
  echo 1>&2 error: could not determine a matching VSTS agent - check that account \'$1\' is correct and the token is valid for that account
  exit 1
fi

echo Downloading and installing VSTS agent...
curl -LsS $VSTS_AGENT_URL | tar -xz --no-same-owner & wait $!


#source ./env.sh

./bin/Agent.Listener configure --unattended \
  --agent "${VSTS_AGENT:-$(hostname)}" \
  --url "https://$VSTS_ACCOUNT.visualstudio.com" \
  --auth PAT \
  --token $(cat "$VSTS_TOKEN_FILE") \
  --pool "${VSTS_POOL:-Default}" \
  --work "${VSTS_WORK:-_work}" \
  --replace & wait $!

#./bin/Agent.Listener run &
sudo ./svc.sh install
sudo ./svc.sh start
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "Build Agent started" >> /home/$5/vsts.install.log.txt 2>&1

#sudo chown -R $5.$5 .*

echo "ALL DONE!" >> /home/$5/install.progress.txt
sudo /bin/date +%H:%M:%S >> /home/$5/install.progress.txt
