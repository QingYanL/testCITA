
#!/bin/bash
git submodule init
git submodule update

DIR=./docker/release

sudo rm -rf target

sed -i "s/\"\${USE_TTY}\" \"\${CONTAINER_NAME}\"/\${USE_TTY} \${CONTAINER_NAME}/" ./env.sh
sudo ./env.sh make release

cp -r target/install $DIR
cd $DIR
tar czvf cita_secp256k1_sha3.tar.gz cita_secp256k1_sha3
