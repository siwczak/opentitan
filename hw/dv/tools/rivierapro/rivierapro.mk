####################################################################################################
## Copyright lowRISC contributors.                                                                ##
## Licensed under the Apache License, Version 2.0, see LICENSE for details.                       ##
## SPDX-License-Identifier: Apache-2.0                                                            ##
####################################################################################################
## Makefile option groups that can be enabled by test Makefile / command line.                    ##
## These are generic set of option groups that apply to all testbenches.                          ##
####################################################################################################
# Simulator too specific options
# Mandatory items to set (these are used by rules.mk):
# SIMCC       - Simulator compiler used to build / elaborate the bench
# SIMX        - Simulator executable used to run the tests

LIBCC       := vlib
GCC         := ccomp
SIMCC       := vlog
SIMX        ?= vsim

#library
LIB_OPTS := work

#gcc library name
GCC_LIB := -o
GCC_LIB += ${SV_FLIST_GEN_DIR}/c_lib
GCC_LIB += -dpi
GCC_LIB += -f ${SV_FLIST_GEN_DIR}/cpp_files.f 


# set standard build options
BUILD_OPTS  += -sv
BUILD_OPTS  += -timescale 1ns/1ps
BUILD_OPTS  += -err VCP2587 W1
BUILD_OPTS  += -dbg
BUILD_OPTS  += +incdir+$$ALDEC_PATH/vlib/uvm-1.2/src
BUILD_OPTS  += $$ALDEC_PATH/vlib/uvm-1.2/src/uvm_pkg.sv
BUILD_OPTS  += -f ${SV_FLIST_GEN_DIR}/sv_files.f 


# set standard run options
#RUN_OPTS    += -input ${SIM_SETUP}
RUN_OPTS    += -sv_seed=${SEED}
RUN_OPTS    += +access +r+w
RUN_OPTS    += -c
RUN_OPTS    += -o2
RUN_OPTS    += +UVM_VERBOSITY=${UVM_VERBOSITY}
RUN_OPTS    += +UVM_TESTNAME=${UVM_TEST}
RUN_OPTS    += +UVM_TEST_SEQ=${UVM_TEST_SEQ}
RUN_OPTS    += -l ${RUN_LOG}
RUN_OPTS    += -lib ${SV_FLIST_GEN_DIR}/work
RUN_OPTS    += -sv_lib $$ALDEC_PATH/bin/uvm_1_2_dpi
RUN_OPTS    += -sv_lib ${SV_FLIST_GEN_DIR}/c_lib
RUN_OPTS    += $(TOPS)
RUN_OPTS    += -do "run -all; endsim; quit -force"


#########################
## Tool Specific Modes ##
#########################

