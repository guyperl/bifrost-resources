# Manual Masternode Setup Guide - (Ubuntu)

## What you will need:
- A VPS cloud server running Ubuntu 16.04.  We recommend [Vultr](https://www.vultr.com/) as a provider.
- PuTTY or similar SSH terminal software for connecting to your remote servers [download](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html)
- Some light Linux knowledge

This guide assumes you have already set up an Ubuntu cloud server through a VPS service provider.  For instructions on creating a server, please see our [Setup Guide for Windows Cold Wallet and Linux VPS Server](https://github.com/bifrost-actual/bifrost-resources/blob/master/hot-cold-wallet-guide/hot-cold-wallet-guide.md) before proceeding.

This guide also assumes you want to manually compile your masternode wallet from source code in the [bifrost-coin code respository](https://github.com/bifrost-actual/bifrost-coin).  If this is not the case, please feel free to use our [masternode all-in-one installation script](https://github.com/bifrost-actual/bifrost-resources).  This script includes the option for compiling from source, but does the work of preparing your system and compiling the code for you.

## Preparing your system

Before we start compiling, we need to make sure you new server has all of the required software, libraries, and resources you will need.

#### Step 1 - Use the package manager upgrade the operating system to the current version.

In your console, enter the following commands, one at a time:

```
sudo apt-get -y update
sudo apt-get -y upgrade
```
A lot of text will fly by as your system updates and installs the latest versions of basic packages and libraries.  This process can take several minutes.

#### Step 2 - Install the build tools and libraries needed for your wallet

In your console, enter the following command:

```
sudo apt-get install -y build-essential libtool autotools-dev autoconf automake pkg-config libssl-dev libboost-all-dev
```

#### Step 3 - Install the bitcoin Personal Package Archive (PPA)

Bifrost requires a version of the Berkely Database library that is no longer part of base Ubuntu installations, but it is provided by the bitcoin core team.

In your console, enter the following command:

```
sudo add-apt-repository ppa:bitcoin/bitcoin
```
When asked to confirm, press the enter key to complete the installation

Then, update your package manager to download the contents of the new archive:

```
sudo apt-get update
```

#### Step 4 - Install the Berkely db v4.8 Libraries from the PPA

In your console, enter the following command:

```
sudo apt-get install -y libdb4.8-dev libdb4.8++-dev
```

#### Step 5 - (Optional) Install and configure UFW firewall

It is strongly recommended that you install a firewall that only allows traffic on the Bifrost mainnet port (9229) and the ssh terminal port (22).

In your console, enter the following commands, one at a time:

```
sudo apt-get -y install ufw
ufw allow ssh/tcp
ufw limit ssh/tcp
ufw allow 9229/tcp
ufw logging on
ufw enable
```

#### Step 6 - Install system swap space

Software compilers are notorious memory and resource hogs, so even if your server has several Gb of RAM, we still recommend installing some swap memory.  Without it, your compilation could easily crash or go very slowly.

In your console, enter the following commands, one at a time:

```
cd /mnt
sudo touch swap.img
sudo chmod 600 swap.img
sudo dd if=/dev/zero of=/mnt/swap.img bs=1024k count=2048
mkswap /mnt/swap.img
sudo swapon /mnt/swap.img
sudo echo "/mnt/swap.img none swap sw 0 0" >> /etc/fstab
cd
```

#### Step 7 - Download the Bifrost source code

Now it's time to clone the master branch of the bifrost source code to your local system.

In your console, enter the following commands, one at a time:

```
git clone https://github.com/bifrost-actual/bifrost-coin.git
cd bifrost-coin
```

#### Step 8 - Generate the automake files for your compile

In your console, enter the following commands, one at a time:

```
./autogen.sh
./configure
cd src
```

#### Step 9 - Compile the source

In your console, enter the following command:

```
make
```

This will begin the compilation process, which could run for quite a while and generate a lot of text on the screen.  You may see various compiler warnings as the compile moves forward, but these can be ignored.

#### Step 10 - Install the binaries

Once compilation is complete, there are several binaries in the src directory.  It's time to move them to a convenient location.

In your console, enter the following commands:

```
sudo make install
cd
```

#### Step 11 - Start and intentionally crash the bifrost wallet

The first time you launch the bifrost wallet, it will complain about missing information in its configuration file, and immediately quit.  This is ok, since the server creates a data directory before it quits, which we need for the next step.

In your console, enter the following command:

```
bifrostd -daemon
```

After you see the error message, press the enter key to return to the command line.

#### Step 12 - Edit the configuration file

In your console, enter the following command:

```
nano .bifrost/bifrost.conf
```

This will open the empty bifrost.conf file in the nano editor.

Add the following lines to the configuration; replacing the parts in brackets [] with your own data:


```
rpcuser=[any_username_you_want]
rpcpassword=[any_random_password_string]
rpcallowip=127.0.0.1
rpcport=9228

server=1
daemon=1
listen=1
staking=0
maxconnections=256

externalip=[your_vps_ip_address:9229]
```

To save your file, press ctrl-x and then "Y" when asked to save the modified buffer.

#### Step 13 - Start the server

In your console, enter the following command:

```
bifrostd
```

The system will report **Bifrost server starting** and start downloading the blockchain data from the network.

#### Step 14 - Create a masternode private key.

In your console, enter the following command:


```
bifrost-cli masternode genkey
```

The sever will respond with a long string...something like:

697LP8nGmqPG7yUvHpx8pu8S6Hm17PXbGvkqy7ZYNyrcmciMnZL

Copy this string to a local notepad file.  You will need this key to set up your control wallet later.

#### Step 15 - Add the private key to your server configuration.

Now that a key has been generated, add it to the configuration file.

In your console, enter the following command:

```
nano .bifrost/bifrost.conf
```

Once your editor opens, add the following lines to end of the file:

```
masternode=1
masternodeprivkey=[the_key_you_just_created]
masternodeaddr=[your_vps_server_ip_address]:9229

```

Again, close your editor with ctrl-x, then Y and enter.

#### Step 16 - Restart your server

The final step is to restart your server, so it picks up your configuration changes and starts running as a pre-enabled masternode.

In your console, enter the following commands:

```
bifrost-cli stop
bifrostd
```

Congratulations, your VPS masternode is now fully configured and running.  Take note of your private key, and your VPS server's IP address, and return to the **Prepare your local control wallet** section of the [Setup Guide for Windows Cold Wallet and Linux VPS Server](https://github.com/bifrost-actual/bifrost-resources/blob/master/hot-cold-wallet-guide/hot-cold-wallet-guide.md)

