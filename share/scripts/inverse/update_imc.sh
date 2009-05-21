#! /bin/bash

if [ "$1" = "--help" ]; then
   echo This script implemtents the function update
   echo for the Inverse Monte Carlo Method
   echo Usage: ${0##*/} step_nr
   echo Needs:  run_or_exit, \$source_wrapper
   exit 0
fi

[[ -n "$1" ]] || die "${0##*/}: Missing argument"


cgmap=$(csg_get_property cgmap)
topol=$(csg_get_property inverse.gromacs.topol)
traj=$(csg_get_property inverse.gromacs.traj)
solver=$(csg_get_property inverse.imc.solver)

msg "calculating statistics"
if is_done "imc_analysis"; then
  msg "IMC analysis is already done"
else
  msg "Running IMC analysis"
  run_or_exit csg_imc --do-imc --options $CSGXMLFILE --top $topol --trj $traj --cg $cgmap --begin 20
  mark_done "imc_analysis"
fi

list_groups=$(csg_property --short --file $CSGXMLFILE --path "cg.*.imc.group" --print . | sort -u)
for group in "$list_groups"; do
  # currently this is a hack! need to create combined array
  msg "solving linear equations for $group"
  do_external imcsolver $solver $group $group.pot.cur
done 
