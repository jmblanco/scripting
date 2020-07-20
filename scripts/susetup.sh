#!/bin/bash
# Usage template
usage="$(basename "$0") [-h] [-u n] [-d]
where:
    -h  show this help text
    -s  user to config"

# Defaults
USER=`whoami`
DRY_RUN=0

while getopts ':h:u:d' option; do
  case "$option" in
    h) echo "$usage"
       exit ;;
    d) DRY_RUN=1 ;;
    u) USER=$OPTARG ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1 ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1 ;;
  esac
done
FILE="";
if [ $DRY_RUN -eq 0 ]
then
   # FILE="/etc/sudoers"
   FILE="/tmp/example"
else
   FILE="/tmp/example-dryrun"
fi

echo "Setup for user ${USER}"
echo "${USER}  ALL=(ALL:ALL) ALL" >> ${FILE}
echo "Setup complete!"