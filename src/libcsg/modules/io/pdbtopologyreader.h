/* 
 * Copyright 2009-2011 The VOTCA Development Team (http://www.votca.org)
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

#ifndef _PDBTOPOLOGYREADER_H
#define	_PDBTOPOLOGYREADER_H

#include <string>
#include <votca/csg/topology.h>
#include <votca/csg/topologyreader.h>
#include "gmx_version_check.h"

namespace votca { namespace csg {
using namespace votca::tools;

using namespace std;
    
/**
    \brief reader for gromacs topology files

    This class encapsulates the gromacs reading functions and provides an interface to fill a topolgy class

*/
class PDBTopologyReader
    : public TopologyReader
{
public:
    PDBTopologyReader() {
        gmx::CheckVersion();
    }

    /// read a topology file
    bool ReadTopology(string file, Topology &top);

private:
};

}}

#endif	/* _PDBTOPOLOGYREADER_H */

