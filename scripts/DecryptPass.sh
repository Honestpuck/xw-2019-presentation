#!/bin/bash
# DecryptPass.sh
#
# Single source of truth for password decryption

SALT="9d4d316FAKEefca44b2a"
K="a82e192b17FAKEb34d385e156f97"
echo "${1}" | /usr/bin/openssl enc -pbkdf2 -d -a -A -S "$SALT" -k "$K"
