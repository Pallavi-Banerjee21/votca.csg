/* 
 * Copyright 2009-2013 The VOTCA Development Team (http://www.votca.org)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#include <iomanip>
#include <string>
#include <boost/filesystem/convenience.hpp> 
#include "dlpolytrajectorywriter.h"

namespace votca { namespace csg {

//void DLPOLYTrajectoryWriter::Open(string file, bool bAppend, const bool isConfig=false)
void DLPOLYTrajectoryWriter::Open(string file, bool bAppend)
{
    if (bAppend)
        throw std::runtime_error("Append to dlpoly HISTORY (trajectory) not implemented");

    boost::filesystem::path filepath(file.c_str());
    string filename;

    //string trajname="HISTORY_CG";
    //if( isConfig ) trajname="CONFIG_CG";

    if ( boost::filesystem::basename(filepath).size() == 0 ) {
      if (filepath.parent_path().string().size() == 0) {
        filename="HISTORY_CG";
        //filename=trajname;
      } else {
        filename=filepath.parent_path().string() + "/HISTORY_CG";
        //filename=filepath.parent_path().string() + "/" + trajname;
      }
    } else {
      filename=file;
    }

    _fl.open(filename.c_str());
    if(!_fl.is_open())
      throw std::ios_base::failure("Error on open dlpoly file: '" + filename + "'");
}

void DLPOLYTrajectoryWriter::Close()
{
  _fl.close();
}

//void DLPOLYTrajectoryWriter::Write(Topology *conf, const bool isConfig=false)
void DLPOLYTrajectoryWriter::Write(Topology *conf)
{
    static int step = 1;
    int mavecs=0;
    int mpbct=0;
    //double energy=0.0;

    if      (conf->HasForce()) { mavecs=2; }
    else if (conf->HasVel())   { mavecs=1; }

    if (conf->getBoxType()==BoundaryCondition::typeOrthorhombic) mpbct=2;
    if (conf->getBoxType()==BoundaryCondition::typeTriclinic)    mpbct=3;

    //if( isConfig ) {
    //_fl << "From VOTCA with love" << endl;
    //_fl << setw(10) << mavecs << setw(10) << mpbct << setw(10) << conf->BeadCount() << setw(20) << energy << endl;
    //matrix m=conf->getBox();
    //for (int i=0;i<3;i++) 
      //_fl << fixed << setprecision(10) << setw(20) << m[i][0] << setw(20) << m[i][1] << setw(20) << m[i][2] << endl;
    //}
    //else {
    if (step==1) {
      _fl << "From VOTCA with love" << endl;
      _fl << setw(10) << mavecs << setw(10) << mpbct << setw(10) << conf->BeadCount() << endl;
    }

    _fl << "timestep" << setprecision(9) << setw(10) << step << setw(10) << conf->BeadCount() << setw(10) << mavecs << setw(10) << mpbct;
    _fl << setprecision(9) << setw(12) << conf->getTime()/(double)(step) << setw(12) <<conf->getTime() << endl;

    matrix m=conf->getBox();
    for (int i=0;i<3;i++) 
      _fl << setprecision(12) << setw(20) << m[i][0] << setw(20) << m[i][1] << setw(20) << m[i][2] << endl;
    //}

    for (int i=0;i<conf->BeadCount(); i++){
      Bead *bead=conf->getBead(i);

      // AB: DL_POLY needs bead TYPE not name!

      //if( isConfig) {
      //_fl << setw(8) << left << bead->getType()->getName() << right << setw(10) << i+1 << endl;
      //}
      //else {
      _fl << setw(8) << left << bead->getType()->getName() << right << setw(10) << i+1;
      _fl << setprecision(6) << setw(12) << bead->getM() << setw(12) << bead->getQ() << setw(12) << "   0.0" << endl;
      //}

      // AB: alternative with atom NAME & fixed floating point format

      //_fl << setw(8) << left << bead->getName() << right << setw(10) << i+1;
      //_fl << fixed << setprecision(6) << setw(12) << bead->getM() << setw(12) << bead->getQ() << "   0.0" << endl;

      _fl << resetiosflags(std::ios::fixed) << setprecision(12) << setw(20) << bead->getPos().getX();
      _fl << setw(20) << bead->getPos().getY() << setw(20) << bead->getPos().getZ() << endl;

      if (mavecs>0) {
	//if (bead->HasVel()) {
        _fl << setprecision(12) << setw(20) << bead->getVel().getX() << setw(20);
        _fl << bead->getVel().getY() << setw(20) << bead->getVel().getZ() << endl;
      }
      if (mavecs>1) {
	//if (bead->HasF()) {
        _fl << setprecision(12) << setw(20) << bead->getF().getX() << setw(20);
	_fl << bead->getF().getY() << setw(20) << bead->getF().getZ() << endl;
      }
    }
    step++;
}

}}

