#! /usr/bin/perl -w
#
# Copyright 2009-2012 The VOTCA Development Team (http://www.votca.org)
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

use strict;
( my $progname = $0 ) =~ s#^.*/##;
my $usage="Usage: $progname [OPTIONS] new_rdf target_rdf outfile";

while ((defined ($ARGV[0])) and ($ARGV[0] =~ /^-./))
{
  if (($ARGV[0] !~ /^--/) and (length($ARGV[0])>2)){
    $_=shift(@ARGV);
    #short opt having agruments examples fo
    if ( $_ =~ /^-[fo]/ ) {
      unshift(@ARGV,substr($_,0,2),substr($_,2));
    } else{
      unshift(@ARGV,substr($_,0,2),"-".substr($_,2));
    }
  }
  if (($ARGV[0] eq "-h") or ($ARGV[0] eq "--help")){
     print <<END;
$progname, version %version%
This script calculates Kirkwood-Buff correction as described in
P. Ganguly, D. Mukherji, C. Junghans, N. F. A. van der Vegt,
Kirkwood-Buff coarse-grained force fields for aqueous solutions,
J. Chem. Theo. Comp., in press (2012), doi:10.1021/ct3000958

In addition, it does some magic tricks:
- do not update if one of the two rdf is undefined

$usage

Allowed options:
-h, --help            Show this help message
END
    exit 0;
  }else{
    die "Unknown option '".$ARGV[0]."' !\n";
  }
}

die "3 parameters are nessary\n" if ($#ARGV<2);

use CsgFunctions;

my $pref=csg_get_property("cg.inverse.kBT");
my $int_start=csg_get_interaction_property("inverse.post_update_options.kbibi.start");
my $int_stop=csg_get_interaction_property("inverse.post_update_options.kbibi.stop");
my $ramp_factor=csg_get_interaction_property("inverse.post_update_options.kbibi.factor");

my $r_min=csg_get_interaction_property("min");
my $r_max=csg_get_interaction_property("max");

my $aim_rdf_file="$ARGV[0]";
my @r_aim;
my @rdf_aim;
my @flags_aim;
(readin_table($aim_rdf_file,@r_aim,@rdf_aim,@flags_aim)) || die "$progname: error at readin_table\n";

my $cur_rdf_file="$ARGV[1]";
my @r_cur;
my @rdf_cur;
my @flags_cur;
(readin_table($cur_rdf_file,@r_cur,@rdf_cur,@flags_cur)) || die "$progname: error at readin_table\n";

#should never happen due to resample, but better check
die "Different grids \n" if (($r_aim[1]-$r_aim[0]-$r_cur[1]+$r_cur[0])>0.0001);
die "Different start potential point \n" if (($r_aim[0]-$r_cur[0]) > 0.0001);
die "Different end potential point \n" if ( $#r_aim != $#r_cur );

die "kbibi.start is smaller than r_min\n" if ($int_start < $r_min);
die "kbibi.stop is bigger than r_max\n" if ($int_stop > $r_max);

my $value=0.0;
my $j=0;
my @intdist;
my $avg_int=0;
$intdist[0]=0;

for (my $i=1;$i<=$#r_aim;$i++){
  $intdist[$i]=$intdist[$i-1]+($rdf_cur[$i]-$rdf_aim[$i])*$r_aim[$i]*$r_aim[$i];
}

for (my $i=0;$i<=$#r_aim;$i++){
  if (($r_aim[$i]>=$int_start) && ($r_aim[$i]<=$int_stop)) {
     $avg_int+=$intdist[$i];
     $j++;
  }
}
$avg_int=$avg_int/$j;

my @dpot;
my @flag;
for (my $i=0;$i<=$#r_aim;$i++){
  if (($rdf_aim[$i] > 1e-10) && ($rdf_cur[$i] > 1e-10)) {
      $dpot[$i]=($avg_int*$ramp_factor*(1.0-($r_aim[$i]/$r_max)))*$pref;
      $flag[$i]="i";
  } else {
    $dpot[$i]=$value;
    $flag[$i]="o";
  }
  $value=$dpot[$i];
}

my $outfile="$ARGV[2]";
saveto_table($outfile,@r_aim,@dpot,@flag) || die "$progname: error at save table\n";

