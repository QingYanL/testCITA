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

cd $DIR
tar czf cita_sm2_sm3.tar.gz cita_sm2_sm3
