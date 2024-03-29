file(GLOB GMX_SOURCES modules/io/gmx*.cc)
file(GLOB NOT_GMX_SOURCES modules/io/gmx_print_version.cc modules/io/gmx_version_nb.cc)
list(REMOVE_ITEM GMX_SOURCES ${NOT_GMX_SOURCES})

file(GLOB H5MD_SOURCES modules/io/h5md*.cc)

file(GLOB IO_SOURCES modules/io/*.cc)
file(GLOB NOT_IO_SOURCES modules/io/mdp*.cc)
list(REMOVE_ITEM IO_SOURCES ${GMX_SOURCES} ${NOT_GMX_SOURCES} ${H5MD_SOURCES} ${NOT_IO_SOURCES})

option(WITH_GMX "Build gromacs reader/writer, disabling leads to reduced functionality!" ON)
if (WITH_GMX)
  foreach(LIBGMX libgmx_d libgmx libgromacs_d libgromacs)
    find_package(GROMACS COMPONENTS "${LIBGMX}")
    if (GROMACS_FOUND)
      break()
    endif(GROMACS_FOUND)
  endforeach(LIBGMX)
  if (NOT GROMACS_FOUND)
    message(FATAL_ERROR "gromacs not found,  make sure you have installed at least the gromacs-4.0.7 and it's dev package. If the gromacs module was not found above, make sure you have sourced GMXRC or set PKG_CONFIG_PATH yourself. (use option -DGROMACS_PKG_OVERWRITE=libgmx/_d for gromacs<5.0 and -DGROMACS_PKG_OVERWRITE=libgromacs/_d for gromacs>=5.0 to influence the search.")
  endif(NOT GROMACS_FOUND)
  #general to a gmx builds
  add_definitions(${GROMACS_DEFINITIONS})
  include_directories(${GROMACS_INCLUDE_DIRS})
  set(GMX ${GROMACS_VERSION})
  add_executable(gmx_print_version modules/io/gmx_print_version.cc)
  target_link_libraries(gmx_print_version ${GROMACS_LIBRARIES})
  add_custom_command(OUTPUT gmx_libs_version.h COMMAND gmx_print_version > gmx_libs_version.h DEPENDS gmx_print_version)
  list(APPEND GMX_SOURCES gmx_libs_version.h)
else(WITH_GMX)
  set(GMX)
  set(GMX_SOURCES)
  set(GROMACS_LIBRARIES)
endif(WITH_GMX)


option(WITH_H5MD "Build H5MD reader!" OFF)
if(WITH_H5MD)
  find_package(HDF5 REQUIRED COMPONENTS "CXX")
  set(H5MD true)
  include_directories (${HDF5_INCLUDE_DIRS})
else(WITH_H5MD)
  set(H5MD)
  set(H5MD_SOURCES)
  set(HDF5_LIBRARIES)
endif(WITH_H5MD)

configure_file(votca_config.h.in ${CMAKE_CURRENT_BINARY_DIR}/votca_config.h)
include_directories(${CMAKE_CURRENT_BINARY_DIR})

add_custom_target(gitversion COMMAND ${CMAKE_COMMAND}
  -DTOP_SOURCE_DIR="${CMAKE_SOURCE_DIR}"
  -DGIT_EXECUTABLE="${GIT_EXECUTABLE}"
  -DMERCURIAL_EXECUTABLE="${MERCURIAL_EXECUTABLE}"
  -P ${CMAKE_MODULE_PATH}/gitversion.cmake)
set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES gitversion.h)

file(GLOB VOTCA_SOURCES *.cc potentialfunctions/*.cc)
file(GLOB NOT_VOTCA_SOURCES version_nb.cc test.cc)
list(REMOVE_ITEM VOTCA_SOURCES ${NOT_VOTCA_SOURCES})
add_library(votca_csg ${VOTCA_SOURCES} ${GMX_SOURCES} ${H5MD_SOURCES} ${IO_SOURCES})
add_dependencies(votca_csg gitversion)
set_target_properties(votca_csg PROPERTIES SOVERSION ${SOVERSION})
target_link_libraries(votca_csg ${VOTCA_TOOLS_LIBRARIES} ${GROMACS_LIBRARIES} ${Boost_LIBRARIES} ${THREAD_LIBRARIES} ${HDF5_LIBRARIES})
install(TARGETS votca_csg LIBRARY DESTINATION ${LIB} ARCHIVE DESTINATION ${LIB})

configure_file(libvotca_csg.pc.in ${CMAKE_CURRENT_BINARY_DIR}/libvotca_csg.pc @ONLY)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libvotca_csg.pc DESTINATION ${LIB}/pkgconfig)
