#!/bin/bash

[ $# -ne 1 ] && echo "Please specify Relay external dns as parameter." && exit 1

# create env file for hostname
if [ ! -e .env ]; then
  echo "HBBR_HOSTNAME=$1" > .env
  echo "WEB_USERNAME=RustDesk" >> .env
  echo "WEB_PASSWORD=$(openssl rand -base64 8)" >>.env
fi
. ./.env

# create folders
[ ! -d hbbs ] && mkdir hbbs
[ ! -d hbbr ] && mkdir hbbr
[ ! -d webdl ] && mkdir webdl

# generate ssh key
if [ ! -e hbbs/id_ed25519 ]; then
  ssh-keygen -q -a 100 -t ed25519 -N '' -f hbbs/id_ed25519
  sed -i "/^-----BEGIN.*$/d" hbbs/id_ed25519
  sed -i "/^-----END.*$/d" hbbs/id_ed25519
  sed -i ':a;N;$!ba;s/\n//g' hbbs/id_ed25519

  sed -i "s/^[^ ]* //" hbbs/id_ed25519.pub
  sed -i "s/ .*$//" hbbs/id_ed25519.pub

  cp hbbs/id_ed25519 hbbr/id_ed25519
  cp hbbs/id_ed25519.pub hbbr/id_ed25519.pub
fi

# Add KEY to .env
grep KEY .env >/dev/null 2>&1
[ $? -ne 0 ] && echo "KEY=$(cat hbbs/id_ed25519.pub)" >> .env

# installer
mkdir -p webdl/windows
# get latest version
cd webdl/windows

latest=$(curl https://github.com/rustdesk/rustdesk/releases/latest -s -I | grep 'location:' | sed -e 's/.*location: //' | sed 's/\r$//')
rv=$(basename $latest)
url="https://github.com/rustdesk/rustdesk/releases/download/$rv/rustdesk-$rv-windows_x64.zip"
 
wget -q --spider $url 
if [ $? -eq 0 ]; then
  wget -q $url -O "rustdesk-$rv-windows_x64.zip"
fi

cd - 1>/dev/null 2>&1

sed -e "s/RELAYSERVER/$1/" -e "s/KEY/$(cat hbbs/id_ed25519.pub)/" webdl-template/README.md > webdl/README.md
for f in webdl-template/*; do
  sed -e "s/RELAYSERVER/$1/" \
      -e "s/KEY/$(cat hbbs/id_ed25519.pub)/" \
      -e "s/WEB_USERNAME/$WEB_USERNAME/" \
      -e "s/WEB_PASSWORD/$WEB_PASSWORD/" \
      -e "s/RUSTDESK_VERSION/$rv/" \
	  $f > webdl/windows/$(basename $f)
done

