
#!/bin/bash
git submodule init
git submodule update

releaseSha256="/var/release/cita_secp256k1_sha3"

sudo rm -rf $releaseSha256
sudo rm -rf target

sed -i "s/\"\${USE_TTY}\" \"\${CONTAINER_NAME}\"/\${USE_TTY} \${CONTAINER_NAME}/" ./env.sh
sudo ./env.sh make release

cp -r target/install $releaseSha256
cd $releaseSha256
tar czvf cita_secp256k1_sha3.tar.gz cita_secp256k1_sha3
