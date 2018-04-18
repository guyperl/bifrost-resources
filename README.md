# Bifrost Coin Resources
Want to create a masternode and need some help? This is the place where you will find resources to help you get up and running.

If you have any questions or problems, you can join us on **[discord](https://discord.gg/zQMrU3s)** where we are happy to help you with anything we can.

## Masternode Requirements (Linux)
- Minimum RAM - 1024 Mb
- Recommended Storage - 25 Gb
- Operating System - Ubuntu 16.04

  These servers are available from [Vultr](https://www.vultr.com/) for $5.00/mo

## Guides
- **[Setup Guide for Windows Cold Wallet and Linux VPS Server](./hot-cold-wallet-guide/hot-cold-wallet-guide.md)**
- **[VPS Masternode Manual Setup](./linux-masternode-setup.md)**

## Scripts
- **[Masternode all-in-one installation script](./masternode-install-script.sh)**

  __Instructions for using script (assumes you have already acquired a VPS):__
    - Connect to your VPS server as the root user
    - Type the following command to download the script:
    
      ```wget "https://github.com/bifrost-actual/bifrost-resources/blob/master/masternode-install-script.sh"```
    - Next, type the following command to allow execution of the downloaded script:
    
      ```chmod +x masternode-install-script.sh```
    - Finally, start your installation with the following command:
    
      ```./masternode-install-script.sh```
      
      The script will evaluate your server, install required dependencies, and either install compiled binaries or download the Bifrost source files and compile them for you.
  It will then create a default configuration, generate a private key, and print the server's information out for you to use when setting up your cold (control) wallet.
  