#! /bin/bash

if [ "$1" = "--help" ]; then
cat <<EOF
${0##*/}, version @version@
This script implemtents the function initialize
for the Inverse Boltzmann Method

Usage: ${0##*/}

USES: do_external csg_get_interaction_property log run_or_exit csg_resample log

NEEDS: name min max step
EOF
  exit 0
fi

check_deps "$0"

name=$(csg_get_interaction_property name)
if [ -f ../${name}.pot.in ]; then
  log "Using given table ${name}.pot.in for ${name}"
  min=$(csg_get_interaction_property min )
  max=$(csg_get_interaction_property max )
  step=$(csg_get_interaction_property step )
  run_or_exit csg_resample --in ../${name}.pot.in --out ${name}.pot.new --grid ${min}:${step}:${max}
else
  # RDF_to_POT.pl just does log g(r) + extrapolation
  log "Using intial guess from RDF for ${name}"
  run_or_exit do_external rdf pot ${name}.dist.tgt ${name}.pot.new
fi

