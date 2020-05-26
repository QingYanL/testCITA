#!/bin/bash
DIR=./docker/release
SOURCE_DIR=`pwd`
echo "pwd travis is " "$(pwd)"
git submodule init
git submodule update

function replace_default_feature () {
    local workspacedir="${1}"
    local old_feature="${2}"
    local new_feature="${3}"
    if [ "${old_feature}" = "${new_feature}" ]; then
        return
    fi
    local before_feature='[ \t]*default[ \t]*=[ \t]*\[.*\"'
    local before_feature2='[ \t]*features[ \t]*=[ \t]*\[.*\"'
    local all_feature='[ \t]*\(features\|default\)[ \t]*=[ \t]*\[.*\"'
    local after_feature='\".*'
    find "${workspacedir}" -mindepth 2 -name "Cargo.toml" -print0 \
            | xargs -0 grep -l "^${all_feature}${old_feature}${after_feature}" \
            | while read -r cargotoml; do
        if [ -f "${cargotoml}" ]; then
            echo "[Info ] Replace [${old_feature}] by [${new_feature}] for [${cargotoml}] ..."
            sed -i "s/\(${before_feature}\)${old_feature}\(${after_feature}\)\$/\1${new_feature}\2/" "${cargotoml}"
            sed -i "s/\(${before_feature2}\)${old_feature}\(${after_feature}\)\$/\1${new_feature}\2/" "${cargotoml}"
        else
            echo "[Error] [${cargotoml}] is not a file."
        fi
    done
}

# sha256
sudo rm -rf target
sed -i "s/\"\${USE_TTY}\" \"\${CONTAINER_NAME}\"/\${USE_TTY} \${CONTAINER_NAME}/" ./env.sh
sudo ./env.sh make release

cp -r target/install $DIR/cita_secp256k1_sha3

DEFAULT_HASH="sha3hash"
DEFAULT_CRYPT="secp256k1"

# sm2
SELECT_HASH_SM2="sm3hash"
SELECT_CRYPT_SM2="sm2"
function replace_algorithm_sm2() {
    replace_default_feature "${SOURCE_DIR}" "${SELECT_HASH}" "${SELECT_HASH_SM2}"
    replace_default_feature "${SOURCE_DIR}" "${SELECT_CRYPT}" "${SELECT_CRYPT_SM2}"
}
replace_algorithm_sm2
sudo rm -rf target
sudo ./env.sh make release > /dev/null
cp -r target/install $DIR/cita_sm2_sm3


# blake2b
SELECT_HASH_Blake2b="blake2bhash"
SELECT_CRYPT_Blake2b="ed25519"

function replace_algorithm_blake2b() {
    replace_default_feature "${SOURCE_DIR}" "${DEFAULT_HASH}" "${SELECT_HASH_Blake2b}"
    replace_default_feature "${SOURCE_DIR}" "${DEFAULT_CRYPT}" "${SELECT_CRYPT_Blake2b}"
}

replace_algorithm_blake2b
sudo rm -rf target
sudo ./env.sh make release > /dev/null
cp -r target/install $DIR/cita_ed25519_blake2b

# tar.gz
cd $DIR
tar -zcf cita_secp256k1_sha3.tar.gz  cita_secp256k1_sha3
tar -zcf cita_sm2_sm3.tar.gz cita_sm2_sm3
tar -zcf cita_ed25519_blake2b.tar.gz cita_ed25519_blake2b

# build image
CITA_REPOSITORY_NAME=hhliyan/cli-test-20
cat "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
docker push "$CITA_CLI_REPOSITORY_NAME":"$TRAVIS_TAG"


docker build . --build-arg ENCRYPTION_ALG=secp256k1 --build-arg HASH_ALG=sha3 -t $CITA_REPOSITORY_NAME:$TRAVIS_TAG-secp256k1-sha3
docker push  $CITA_REPOSITORY_NAME:$TRAVIS_TAG-secp256k1-sha3

docker build . --build-arg ENCRYPTION_ALG=sm2 --build-arg HASH_ALG=sm3 -t $CITA_REPOSITORY_NAME:$TRAVIS_TAG-sm2-sm3
docker push  $CITA_REPOSITORY_NAME:$TRAVIS_TAG-sm2-sm3


docker build . --build-arg ENCRYPTION_ALG=ed25519 --build-arg HASH_ALG=blake2b -t $CITA_REPOSITORY_NAME:$TRAVIS_TAG-ed25519-blake2b
docker push  $CITA_REPOSITORY_NAME:$TRAVIS_TAG-ed25519-blake2b





