#!/bin/bash
#
# masternode from scratch (baz 09042019)

clear

# check if we have swap
memory="$(free | grep Swap | tr -s ' ' | cut -d ' ' -f 4)"
if [ -n "$memory" ] && [ "$memory" -eq "$memory" ] 2>/dev/null; then
  if [ "$memory" -eq "0" ]; then
      # make a quick 1.5gb swap as we only need it for compilation
      dd if=/dev/zero of=/var/swap.img bs=1024k count=1500
          mkswap /var/swap.img
          swapon /var/swap.img
          echo enabled temporary swapfile..
    else
          # a suitable swap file exists
      echo swapfile not required..
  fi
else
  # if we dont understand this, you need a new linux
  echo tell your linux distribution to go get a job
  exit
fi

# install the dependencies
apt update
apt install -y build-essential autoconf automake libssl-dev libdb5.3-dev libdb5.3++-dev libboost-all-dev pkg-config libtool libevent-dev git screen zlib1g-dev

# build vestx
git clone https://github.com/vestx/vestx
cd vestx
./autogen.sh
./configure --with-incompatible-bdb --disable-tests --with-gui=no
make install
cd

# find our public ip
primaryip="$(ip route get 1 | awk '{print $NF;exit}')"
echo "paste the masternode privkey (output from 'masternode genkey') and press enter"
read -e masternodeprivkey

# write our masternode's .vestx/vestx.conf
mkdir .vestx
echo listen=1 > .vestx/vestx.conf
echo server=1 >> .vestx/vestx.conf
echo daemon=1 >> .vestx/vestx.conf
echo staking=0 >> .vestx/vestx.conf
echo rpcuser=testuser >> .vestx/vestx.conf
echo rpcpassword=testpassword >> .vestx/vestx.conf
echo rpcallowip=127.0.0.1 >> .vestx/vestx.conf
echo rpcbind=127.0.0.1 >> .vestx/vestx.conf
echo maxconnections=24 >> .vestx/vestx.conf
echo masternode=1 >> .vestx/vestx.conf
echo masternodeprivkey=$masternodeprivkey >> .vestx/vestx.conf
echo bind=$primaryip >> .vestx/vestx.conf
echo externalip=$primaryip >> .vestx/vestx.conf
echo masternodeaddr=$primaryip:20000 >> .vestx/vestx.conf

# launch daemon
vestxd
