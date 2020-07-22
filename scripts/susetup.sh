#!/bin/bash
# Usage template
USAGE="$(basename "$0") [-h] [-u n] [-d]
where:
    -h  show this help text
    -s  user to config
    -d  destiny"

# Defaults
while getopts 'hu:d:' OPTION; do
  case $OPTION in
   h) echo $USAGE
      exit ;;
   d) DRY_RUN=$OPTARG ;;
   u) CONFIG_USER=$OPTARG  ;;
   :) printf "missing argument for -%s\n" "$OPTARG" >&2
      echo "$USAGE" >&2
      exit 1 ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$USAGE" >&2
       exit 1 ;;
  esac
done

[[ -z $DRY_RUN ]] && FILE="/etc/sudoers" || FILE=$DRY_RUN

if [ -z $CONFIG_USER ]
then
   echo "No user specified!"
else
   echo "Setup for user ${CONFIG_USER}"
   echo "${CONFIG_USER}  ALL=(ALL:ALL) ALL" >> ${FILE}
   echo "Setup complete!"
fi
