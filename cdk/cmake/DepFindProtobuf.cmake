# Copyright (c) 2009, 2019, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2.0, as
# published by the Free Software Foundation.
#
# This program is also distributed with certain software (including
# but not limited to OpenSSL) that is licensed under separate terms,
# as designated in a particular file or component or in included license
# documentation.  The authors of MySQL hereby grant you an
# additional permission to link the program and your derivative works
# with the separately licensed software that they have included with
# MySQL.
#
# Without limiting anything contained in the foregoing, this file,
# which is part of MySQL Connector/C++, is also subject to the
# Universal FOSS Exception, version 1.0, a copy of which can be found at
# http://oss.oracle.com/licenses/universal-foss-exception.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License, version 2.0, for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA

# #############################################################################
#
# Targets:
#
# (re)build-protobuf
#
# Imported/alias targets:
#
# ext::pb-lite
# ext::pb-full
# ext::protoc  -- compiler
#
# Commands:
#
# mysqlx_protobuf_generate_cpp()
#
#

if(TARGET ext::protobuf)
  return()
endif()

message(STATUS "Setting up Protobuf.")

# Setup extrnal project that builds protobuf from  bundled sources
add_ext(protobuf google/protobuf/api.pb.h)

if(NOT PROTOBUF_FOUND)
  message(FATAL_ERROR "Can't build without protobuf support")
endif()

# import targets from the external project
# Note: The pb_ targets are created by protobuf/exports.cmake
add_ext_targets(protobuf
  LIBRARY protobuf-lite pb_libprotobuf-lite
  LIBRARY protobuf pb_libprotobuf
  EXECUTABLE protoc pb_protoc
)


# Standard PROTOBUF_GENERATE_CPP modified to our usage
function(mysqlx_protobuf_generate_cpp SRCS HDRS)
  IF(NOT ARGN)
    MESSAGE(SEND_ERROR
      "Error: MYSQLX_PROTOBUF_GENERATE_CPP() called without any proto files")
    RETURN()
  ENDIF()

  SET(srcs)
  SET(hdrs)

  FOREACH(FIL ${ARGN})
    GET_FILENAME_COMPONENT(ABS_FIL ${FIL} ABSOLUTE)
    GET_FILENAME_COMPONENT(FIL_WE ${FIL} NAME_WE)
    GET_FILENAME_COMPONENT(ABS_PATH ${ABS_FIL} PATH)

    LIST(APPEND srcs "${CMAKE_CURRENT_BINARY_DIR}/protobuf/${FIL_WE}.pb.cc")
    LIST(APPEND hdrs "${CMAKE_CURRENT_BINARY_DIR}/protobuf/${FIL_WE}.pb.h")

    ADD_CUSTOM_COMMAND(
      OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/protobuf/${FIL_WE}.pb.cc"
      "${CMAKE_CURRENT_BINARY_DIR}/protobuf/${FIL_WE}.pb.h"
      COMMAND ${CMAKE_COMMAND}
      -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/protobuf"
      COMMAND ext::protoc
      ARGS --cpp_out "${CMAKE_CURRENT_BINARY_DIR}/protobuf"
      -I ${ABS_PATH} ${ABS_FIL}

      # --proto_path=${PROTOBUF_INCLUDE_DIR}
      DEPENDS ${ABS_FIL}
      COMMENT "Running C++ protocol buffer compiler on ${FIL}"
      VERBATIM
    )
  ENDFOREACH()

  SET_SOURCE_FILES_PROPERTIES(
    ${srcs} ${hdrs}
    PROPERTIES GENERATED TRUE)

  #
  # Disable compile warnings in code generated by Protobuf
  #
  IF(UNIX)
    set_source_files_properties(${srcs}
      APPEND_STRING PROPERTY COMPILE_FLAGS "-w"
    )
  ELSEIF(MSVC)
    set_source_files_properties(${srcs}
      APPEND_STRING PROPERTY COMPILE_FLAGS
      "/W1 /wd4018 /wd4996 /wd4244 /wd4267"
    )
  ENDIF()

  SET(${SRCS} ${srcs} PARENT_SCOPE)
  SET(${HDRS} ${hdrs} PARENT_SCOPE)
endfunction(mysqlx_protobuf_generate_cpp)
