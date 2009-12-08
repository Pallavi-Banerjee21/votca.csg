/* 
 * Copyright 2009 The VOTCA Development Team (http://www.votca.org)
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
// 
// File:   gmxtrajectorywriter.h
// Author: victor
//
// Created on 27. Dezember 2007, 20:44
//

#ifndef _GMXTRAJECTORYWRITER_H
#define	_GMXTRAJECTORYWRITER_H

#include "topology.h"
#include "trajectorywriter.h"

namespace gmx {
   extern "C" {
        #include <statutil.h>
        #include <typedefs.h>
        #include <smalloc.h>
        #include <vec.h>
        #include <copyrite.h>
        #include <statutil.h>
        #include <tpxio.h>
    }
    // this one is needed because of bool is defined in one of the headers included by gmx
    #undef bool
}
using namespace std;

class GMXTrajectoryWriter
    : public TrajectoryWriter
{
public:
    
    void Open(string file, bool bAppend = false);
    void Close();
    void Write(Topology *conf);

    private:
        int _file;
};

#endif	/* _GMXTRAJECTORYWRITER_H */

