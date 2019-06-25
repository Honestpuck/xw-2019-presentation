#!/bin/bash
# DecryptUser.sh
#
# Single source of truth for user name decryption

# Alternative format for DecryptString function
local SALT="a885933FAKEfe90b7f5d"
local K="50ac513183FAKE76a03bf6f24b9e"
echo "${1}" | /usr/bin/openssl enc -pbkdf2 -d -a -A -S "$SALT" -k "$K"
