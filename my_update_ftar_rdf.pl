#! /usr/bin/perl -w
# 
# Copyright 2009 The VOTCA Development Team (http://www.votca.org)
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

if (defined($ARGV[0])&&("$ARGV[0]" eq "--help")){
  print <<EOF;
$progname, version %version%
This script calculates ftar out of the two rdfs for the 
Simplex Method and arranges the output table in order 
of increasing magnitude of ftar.
In addition it does some magic tricks:
- do not update if one of the both rdf are undefined

Usage: $progname target_rdf cur_rdf cur_simplex outfile

NEEDS: cg.inverse.kBT

USES: readin_table saveto_table csg_get_property
EOF
  exit 0;
}

die "4 parameters are necessary\n" if ($#ARGV<3);

use CsgFunctions;
use SimplexFunctions;

my $simplex_cur_file="$ARGV[0]";
my $simplex_tmp_file="$ARGV[1]";
my $param_N="$ARGV[2]";
my $a_line_nr="$ARGV[3]";

my $ndim=$param_N+1;

my $name=csg_get_property("cg.non-bonded.name");
my $aim_rdf_file="$name.dist.tgt";

my @r_aim;
my @rdf_aim;
my @flags_aim;
(readin_table($aim_rdf_file,@r_aim,@rdf_aim,@flags_aim)) || die "$progname: error at readin_table\n";

my $cur_rdf_file="$name.dist.new";
my @r_cur;
my @rdf_cur;
my @flags_cur;
(readin_table($cur_rdf_file,@r_cur,@rdf_cur,@flags_cur)) || die "$progname: error at readin_table\n";

my @ftar_cur;
my @sig_cur;
my @eps_cur;
my @flag_cur;

my (%hash)=readin_simplex_table($simplex_cur_file,$ndim) or die "$progname: error at readin_simplex_table\n";

# Define first and last column
@ftar_cur=@{$hash{p_0}};
@sig_cur=@{$hash{p_1}};
@eps_cur=@{$hash{p_2}};
@flag_cur=@{$hash{"p_$ndim"}};

# Should never happen due to resample, but better check
die "Different grids \n" if (($r_aim[1]-$r_aim[0])!=($r_cur[1]-$r_cur[0]));
die "Different start point \n" if (($r_aim[0]-$r_cur[0]) > 0.0);

# Calculate ftar

my @w=@_;
my @drdf=@_;
my $ftar=0;
my $delta_r=csg_get_interaction_property("step");
my $max=csg_get_interaction_property("max");

for(my $i=1;$i<=$max/$delta_r;$i++) {
       $w[$i]=exp(-$r_cur[$i]/$sig_cur[$a_line_nr]);
       $drdf[$i]=($rdf_cur[$i]-$rdf_aim[$i]);
       $ftar+=$delta_r*$w[$i]*($drdf[$i]**2);
}

$ftar+=(0.5*$delta_r*$w[$max/$delta_r]*$drdf[$max/$delta_r]**2);
$ftar_cur[$a_line_nr]=$ftar;

my @args=("bash","-c","echo $ftar_cur[$a_line_nr]");
system(@args);

$flag_cur[$a_line_nr]="complete";

saveto_simplex_table($simplex_tmp_file,$param_N,@ftar_cur,%hash,@flag_cur) or die "$progname: error at saveto_simplex_table\n";