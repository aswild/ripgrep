#!/bin/bash

# try to use GNU Awk
if which gawk &>/dev/null; then
    AWK=gawk
else
    AWK=awk
fi

# rust doesn't give a way to dump the current target triple,
# so reconstruct it from the cfg output
# % rustc --print cfg
# debug_assertions
# target_arch="x86_64"
# target_endian="little"
# target_env="gnu"
# target_family="unix"
# target_feature="fxsr"
# target_feature="sse"
# target_feature="sse2"
# target_os="linux"
# target_pointer_width="64"
# target_vendor="unknown"
# unix

rustc --print cfg | "$AWK" -F= '
($1 == "target_arch")   {gsub(/"/, "", $2); arch=$2}
($1 == "target_vendor") {gsub(/"/, "", $2); vendor=$2}
($1 == "target_os")     {gsub(/"/, "", $2); os=$2}
($1 == "target_env")    {gsub(/"/, "", $2); env=$2}
END {print arch"-"vendor"-"os"-"env}
'
