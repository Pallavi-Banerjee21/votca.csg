#!/bin/bash
#
# Copyright 2009-2011 The VOTCA Development Team (http://www.votca.org)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

show_help () {
  cat <<EOF
${0##*/}, version %version%
This script is a wrapper to convert a potential to gromacs

Usage: ${0##*/} [options] input output

Allowed options:
    --help       show this help
    --clean      remove all intermediate temp files
    --no-r2d     do not converts rad to degree (scale x axis with 180/3.1415)
                 for angle and dihedral
                 Note: VOTCA calcs in rad, but gromacs in degree
    --no-shift   do not shift the potential
EOF
}

clean="no"
do_shift="yes"
r2d="57.2957795"

### begin parsing options
shopt -s extglob
while [[ ${1#-} != $1 ]]; do
 if [[ ${1#--} = $1 && -n ${1:2} ]]; then
    #short opt with arguments here: o
    if [[ ${1#-[o]} != ${1} ]]; then
       set -- "${1:0:2}" "${1:2}" "${@:2}"
    else
       set -- "${1:0:2}" "-${1:2}" "${@:2}"
    fi
 fi
 case $1 in
   --r2d) #default now
    shift ;;
   --no-r2d)
    r2d=1
    shift ;;
   --clean)
    clean="yes"
    shift ;;
   --no-shift)
    do_shift="no"
    shift ;;
   -h | --help)
    show_help
    exit 0;;
  *)
   die "Unknown option '$1'";;
 esac
done
### end parsing options

[[ -z $1 || -z $2 ]] && die "${0##*/}: missing argument"
input="$1"
trunc="${1%%.*}"
[[ -f $input ]] || die "${0##*/}: Could not find input file '$input'"
output="$2"
echo "Convert $input to $output"

#special if calling from csg_call
xvgtype="$(csg_get_interaction_property bondtype)"
[[ $xvgtype = "C6" || $xvgtype = "C12" || $xvgtype = "CB" ]] && tabtype="non-bonded" || tabtype="$xvgtype"

zero=0
if [[ $tabtype = "non-bonded" ]]; then
  tablend="$(csg_get_property --allow-empty cg.inverse.gromacs.table_end)"
  mdp="$(csg_get_property cg.inverse.gromacs.mdp)"
  if [[ -f ${mdp} ]]; then
    echo "Found setting file '$mdp' now trying to check options in there"
    rlist=$(get_simulation_setting rlist)
    tabext=$(get_simulation_setting table-extension)
    # if we have all 3 numbers do this checks
    tabl=$(csg_calc "$rlist" + "$tabext")
    [[ -n $tablend  ]] &&  csg_calc "$tablend" "<" "$tabl" && \
      die "${0##*/}: Error table is shorter then what mdp file ($mdp) needs, increase cg.inverse.gromacs.table_end in setting file.\nrlist ($rlist) + tabext ($tabext) > cg.inverse.gromacs.table_end ($tablend)"
    [[ -z $tablend ]] && tablend=$(csg_calc "$rlist" + "$tabext")
  elif [[ -z $tablend ]]; then
    die "${0##*/}: cg.inverse.gromacs.table_end was not defined in xml seeting file"
  fi
elif [[ $tabtype = "bond" || $tabtype = "thermforce" ]]; then
  tablend="$(csg_get_property cg.inverse.gromacs.table_end)"
elif [[ $tabtype = "angle" ]]; then
  tablend=180
elif [[ $tabtype = "dihedral" ]]; then
  zero="-180"
  tablend=180
else
  die "${0##*/}: Unknown interaction type $tabtype"
fi

gromacs_bins="$(csg_get_property cg.inverse.gromacs.table_bins)"
comment="$(get_table_comment $input)"

if [[ $tabtype = "angle" || $tabtype = "dihedral" ]] && [[ $r2d != 1 ]]; then
  scale="$(critical mktemp ${trunc}.pot.scale.XXXXX)"
  do_external table linearop --on-x "${input}" "${scale}" "$r2d" "0"
else
  scale="${input}"
fi

smooth="$(critical mktemp ${trunc}.pot.smooth.XXXXX)"
critical csg_resample --in ${scale} --out "$smooth" --grid "${zero}:${gromacs_bins}:${tablend}" --comment "$comment"

extrapol="$(critical mktemp ${trunc}.pot.extrapol.XXXXX)"
if [[ $clean = "yes" ]]; then
  do_external potential extrapolate --clean --type "$tabtype" "${smooth}" "${extrapol}"
else
  do_external potential extrapolate --type "$tabtype" "${smooth}" "${extrapol}"
fi

if [[ $do_shift = "yes" ]]; then
  tshift="$(critical mktemp ${trunc}.pot.shift.XXXXX)"
  if [[ $tabtype = "non-bonded" || $tabtype = "thermforce" ]]; then
    do_external pot shift_nonbonded "${extrapol}" "${tshift}"
  else
    do_external pot shift_bonded "${extrapol}" "${tshift}"
  fi
else
  tshift="$extrapol"
fi

potmax="$(csg_get_property --allow-empty cg.inverse.gromacs.pot_max)"
[[ -n ${potmax} ]] && potmax="--max ${potmax}"

do_external convert_potential xvg ${potmax} --type "${xvgtype}" "${tshift}" "${output}"
if [[ $clean = "yes" ]]; then
  rm -f "${smooth}" "${extrapol}" "${tshift}" "${extrapol1}"
fi
