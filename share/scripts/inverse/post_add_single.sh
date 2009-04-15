#! /bin/bash

if [ "$1" = "--help" ]; then
   echo This script make all the post update with backup for single pairs 
   echo Usage: ${0##*/} step_nr
   echo Needs:  run_or_exit, \$SOURCE_WRAPPER, add_POT.pl
   exit 0
fi

add_POT=$($SOURCE_WRAPPER --direct add_POT.pl) || die "${0##*/}: $SOURCE_WRAPPER --direct add_POT.pl"

name=$($csg_get name)
tasklist=$($csg_get post_add) 
i=1
for task in $tasklist; do
  log "Doing $task for ${name}"
  mv ${name}.dpot.new ${name}.dpot.cur || die "${0##*/}: mv failed"
  cp ${name}.dpot.cur ${name}.dpot.${i} || die "${0##*/}: cp failed"
  script=$($SOURCE_WRAPPER postadd $task) || die "${0##*/}: $SOURCE_WRAPPER postadd $task failed"
  run_or_exit "csg_get=\"$csg_get\" bondtype=\"$bondbype\" $script" 
  ((i++))
done