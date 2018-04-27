#!/usr/bin/env bash
NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
MAX=10
CURRSTEP=0

COINDOWNLOADLINK=https://github.com/bifrost-actual/bifrost-coin/releases/download/v1.0.1/bifrost-1.0.1-aarch64-linux-gnu.tar.gz
COINDOWNLOADFILE=bifrost-1.0.1-aarch64-linux-gnu.tar.gz
COINREPO=https://github.com/bifrost-actual/bifrost-coin.git
COINRPCPORT=9228
COINPORT=9229
COINDAEMON=bifrostd
COINCLIENT=bifrost-cli
COINTX=bifrost-tx
COINCORE=.bifrost
COINCONFIG=bifrost.conf
COINDOWNLOADDIR=bifrostdownload


purgeOldInstallation() {
    echo "Searching and removing old masternode files and configurations"
    #kill wallet daemon
    sudo killall bifrostd > /dev/null 2>&1
    #remove old ufw port allow
    sudo ufw delete allow 9229/tcp > /dev/null 2>&1
    #remove old files
    if [ -d "~/.bifrost" ]; then
        sudo rm -rf ~/.bifrost > /dev/null 2>&1
    fi
    #remove binaries and bifrost utilities
    cd /usr/local/bin && sudo rm bifrost-cli bifrost-tx bifrostd > /dev/null 2>&1 && cd
    echo -e "${GREEN}* Done${NONE}";
}

checkForUbuntuVersion() {
   let "CURRSTEP++"
   echo
   echo "[${CURRSTEP}/${MAX}] Checking Ubuntu version..."
    if [[ `cat /etc/issue.net`  == *16.04* ]]; then
        echo -e "${GREEN}* You are running `cat /etc/issue.net` . Setup will continue.${NONE}";
    else
        echo -e "${RED}* You are not running Ubuntu 16.04.X. You are running `cat /etc/issue.net` ${NONE}";
        echo && echo "Installation cancelled" && echo;
        exit;
    fi
}

updateAndUpgrade() {
    let "CURRSTEP++"
    echo
    echo "[${CURRSTEP}/${MAX}] Runing update and upgrade. Please wait..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq -y > /dev/null 2>&1
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq > /dev/null 2>&1
    echo -e "${GREEN}* Done${NONE}";
}

setupSwap() {
    swapspace=$(free -h | grep Swap | cut -c 16-18);
    if [ $(echo "$swapspace < 1.0" | bc) -ne 0 ]; then

    echo a; else echo b; fi

    echo -e "${BOLD}"
    read -e -p "Add swap space? (Recommended for VPS that have 1GB of RAM) [Y/n] :" add_swap
    if [[ ("$add_swap" == "y" || "$add_swap" == "Y" || "$add_swap" == "") ]]; then
        swap_size="4G"
    else
        echo -e "${NONE}[3/${MAX}] Swap space not created."
    fi

    if [[ ("$add_swap" == "y" || "$add_swap" == "Y" || "$add_swap" == "") ]]; then
        echo && echo -e "${NONE}[3/${MAX}] Adding swap space...${YELLOW}"
        sudo fallocate -l $swap_size /swapfile
        sleep 2
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo -e "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab > /dev/null 2>&1
        sudo sysctl vm.swappiness=10
        sudo sysctl vm.vfs_cache_pressure=50
        echo -e "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf > /dev/null 2>&1
        echo -e "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf > /dev/null 2>&1
        echo -e "${NONE}${GREEN}* Done${NONE}";
    fi
}

installFirewall() {
    let "CURRSTEP++"
    echo
    echo -e "[${CURRSTEP}/${MAX}] Installing UFW Firewall and opening Bifrost port. Please wait..."
    sudo apt-get -y install ufw > /dev/null 2>&1
    sudo ufw allow OpenSSH > /dev/null 2>&1
    sudo ufw allow $COINPORT/tcp > /dev/null 2>&1
    echo "y" | sudo ufw enable > /dev/null 2>&1
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

installDependencies() {
    let "CURRSTEP++"
    echo
    echo -e "[${CURRSTEP}/${MAX}] Installing dependecies. Please wait..."
    sudo apt-get install bc git nano rpl wget python-virtualenv -qq -y > /dev/null 2>&1
    sudo apt-get install build-essential libtool automake autoconf -qq -y > /dev/null 2>&1
    sudo apt-get install autotools-dev autoconf pkg-config libssl-dev -qq -y > /dev/null 2>&1
    sudo apt-get install libgmp3-dev libevent-dev bsdmainutils libboost-all-dev -qq -y > /dev/null 2>&1
    sudo apt-get install software-properties-common python-software-properties -qq -y > /dev/null 2>&1
    sudo add-apt-repository ppa:bitcoin/bitcoin -y > /dev/null 2>&1
    sudo apt-get update -qq -y > /dev/null 2>&1
    sudo apt-get install libdb4.8-dev libdb4.8++-dev -qq -y > /dev/null 2>&1
    sudo apt-get install libminiupnpc-dev -qq -y > /dev/null 2>&1
    sudo apt-get install libzmq5 -qq -y > /dev/null 2>&1
    sudo apt-get install virtualenv -qq -y > /dev/null 2>&1
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

downloadWallet() {
    let "CURRSTEP++"
    echo
    echo -e "[${CURRSTEP}/${MAX}] Downloading wallet binaries. Please wait, this might take a while to complete..."
    cd && mkdir -p $COINDOWNLOADDIR && cd $COINDOWNLOADDIR
    wget $COINDOWNLOADLINK > /dev/null 2>&1
    tar xzf $COINDOWNLOADFILE --directory /usr/local/bin/
    mv $COINDOWNLOADFILE > /dev/null 2>&1
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

compileWallet() {
    let "CURRSTEP++"
    echo
    echo -e "${NONE}${BOLD}${PURPLE}[${CURRSTEP}/${MAX}] Compiling wallet. This can take a while.  Feel free to grab some coffee...and maybe watch a movie...${NONE}"
    cd && mkdir -p $COINDOWNLOADDIR
    git clone $COINREPO $COINDOWNLOADDIR >/dev/null 2>&1
    cd $COINDOWNLOADDIR
    ./autogen.sh > /dev/null 2>&1
    ./configure > /dev/null 2>&1
    cd src
    make > /dev/null 2>&1
    echo -e "${NONE}${GREEN}* Done${NONE}"
}

installWallet() {
    let "CURRSTEP++"
    echo
    echo -e "[${CURRSTEP}/${MAX}] Installing wallet. One moment, please..."
    strip $COINDAEMON  > /dev/null 2>&1
    strip $COINCLIENT > /dev/null 2>&1
    strip $COINTX > /dev/null 2>&1
    sudo make install  > /dev/null 2>&1
    cd
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

configureWallet() {
    let "CURRSTEP++"
    echo
    echo -e "[${CURRSTEP}/${MAX}] Configuring wallet. One moment..."
    $COINDAEMON -daemon > /dev/null 2>&1
    sleep 10
    $COINCLIENT stop > /dev/null 2>&1
    sleep 2
    mnip=$(curl --silent ipinfo.io/ip)
    rpcuser=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    rpcpass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    echo -e "rpcuser=${rpcuser}\nrpcpassword=${rpcpass}\nrpcallowedip=127.0.0.1\nlisten=1\nserver=1\ndaemon=1" > ~/$COINCORE/$COINCONFIG
    $COINDAEMON -daemon > /dev/null 2>&1
    sleep 5
    mnkey=$($COINCLIENT masternode genkey)
    $COINCLIENT stop > /dev/null 2>&1
    sleep 2
    echo -e "rpcuser=${rpcuser}\nrpcpassword=${rpcpass}\nrpcport=${COINRPCPORT}\nrpcallowip=127.0.0.1\ndaemon=1\nserver=1\nlisten=1\ntxindex=1\nlistenonion=0\nmasternode=1\nmasternodeaddr=${mnip}:${COINPORT}\nmasternodeprivkey=${mnkey}\n" > ~/$COINCORE/$COINCONFIG
    echo -e "${NONE}${GREEN}* Done${NONE}";
}

startWallet() {
    let "CURRSTEP++"
    echo
    echo -e "[${CURRSTEP}/${MAX}] Starting wallet daemon..."
    $COINDAEMON -daemon > /dev/null 2>&1
    sleep 2
    echo -e "${GREEN}* Done${NONE}";
}

cleanUp() {
    let "CURRSTEP++"
    echo
    echo -e "[${CURRSTEP}/${MAX}] Cleaning up";
    cd
    if [ -d "$COINDOWNLOADDIR" ]; then rm -rf $COINDOWNLOADDIR; fi
}

clear
cd

echo -e "-----------------------------------------------------------------------------------"
echo -e "|                                                                                 |"
echo -e "|                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM               |"
echo -e "|                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM               |"
echo -e "|                MMMMMMMMMMMMMMMMMMMMMMMMNdhhyyyyhhmNMMMMMMMMMMMMMM               |"
echo -e "|                MMMMMMMMMMMMMMMMMMdy+:.              :omMMMMMMMMMM               |"
echo -e "|                MMMMMMMMMMMMMMms:                       :dMMMMMMMM               |"
echo -e "|                MMMMMMMMMMMNs-      .-/++++/-..mmy-       yMMMMMMM               |"
echo -e "|                MMMMMMMMMNo      /hN:         yMMMM/       MMMMMMM               |"
echo -e "|                MMMMMMMMy     :yMMMd:-       :MMMMMo       NMMMMMM               |"
echo -e "|                MMMMMMN/    -hMMMMMMMy       dMMMMN.      /MMMMMMM               |"
echo -e "|                MMMMMN:    +MMMMMMMMM-      :MMMMm-      :NMMMMMMM               |"
echo -e "|                MMMMM/    oMMMMMMMMMy       dMNh/      .yMMMMMMMMM               |"
echo -e "|                MMMMh    /MMMMMMMMMN.                 oNMMMMMMMMMM               |"
echo -e "|                MMMM/    dMMMMMMMMMy                   .sMMMMMMMMM               |"
echo -e "|                MMMM-    mMMMMMMMMN.      -ssso/.        :MMMMMMMM               |"
echo -e "|                MMMM:    +MMMMMMMMs       hMMMMMMh        oMMMMMMM               |"
echo -e "|                MMMMy     -sNMMMMN.      -MMMMMMMMs       :MMMMMMM               |"
echo -e "|                MMMMM/       yMMMs       hMMMMMMMMo       oMMMMMMM               |"
echo -e "|                MMMMMMs      -MMN       :MMMMMMMMN       -NMMMMMMM               |"
echo -e "|                MMMMMMMNs:--+mMM+       mMMMMMMMd.       dMMMMMMMM               |"
echo -e "|                MMMMMMMMMMMMMMMy       sMMMMMMd+       :mMMMMMMMMM               |"
echo -e "|                MMMMMMMMMMhys+-       -oooo/:        /dMMMMMMMMMMM               |"
echo -e "|                MMMMMMMMMh                        /yNMMMMMMMMMMMMM               |"
echo -e "|                MMMMMMMMM-  -:///////::----:/+shmMMMMMMMMMMMMMMMMM               |"
echo -e "|                MMMMMMMMMmNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM               |"
echo -e "|                MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM               |"
echo -e "|                                                                                 |"
echo -e "|                       Bifrost Coin Masternode Installer                         |"
echo -e "|                                                                                 |"
echo -e "-----------------------------------------------------------------------------------"
echo -e "${BOLD}"
read -p "This script will setup your Bifrost Masternode. Do you wish to continue? (y/n)?" response
echo -e "${NONE}"

if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
echo
    purgeOldInstallation
    checkForUbuntuVersion
    updateAndUpgrade
    installFirewall
    installDependencies
    echo -e "${BOLD}"
    read -p "Use pre-compiled Bifrost binaries instead of compiling from source? (y/n)?" binaries
    echo -e "${NONE}"
    if [[ "$binaries" =~ ^([yY][eE][sS]|[yY])+$ ]];
    then
      downloadWallet
    else
      setupSwap
      compileWallet
      cd ~/$COINDOWNLOADDIR/src
      installWallet
    fi
    configureWallet
    startWallet
    cleanUp

    echo -e "================================================================================================"
    echo -e "${BOLD}The VPS side of your masternode has been installed. Save the masternode ip and${NONE}"
    echo -e "${BOLD}private key so you can use them to complete your local wallet part of the setup${NONE}".
    echo -e "================================================================================================"
    echo -e "${BOLD}Masternode IP:${NONE} ${mnip}:${COINPORT}"
    echo -e "${BOLD}Masternode Private Key:${NONE} ${mnkey}"
    echo -e "${BOLD}Continue with the cold wallet part of the setup${NONE}"
    echo -e "================================================================================================"
else
    echo && echo "Installation cancelled" && echo
fi
