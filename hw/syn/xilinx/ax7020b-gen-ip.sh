#!/usr/bin/env bash

export PROJECT="VX_afu_wrap"
export TOP_LEVEL_ENTITY=$PROJECT
export SRC_FILE=$PROJECT.sv
export FPU_IP=1
export DEVICE="xc7z020clg400-2"
export JOBS=10

export RTL_DIR="../../rtl"
export THIRD_PARTY_DIR="../../../third_party"
export SCRIPT_DIR="/storage/repos/HWDev/samples/vortex/hw/scripts"
export SRC_DIR="../../syn/xilinx/dut"
export AFU_DIR="$RTL_DIR/afu/xrt"

export FPU_INCLUDE="-I$RTL_DIR/fpu"
export FPU_INCLUDE+=" -J$THIRD_PARTY_DIR/cvfpu/src/common_cells/include"
export FPU_INCLUDE+=" -J$THIRD_PARTY_DIR/cvfpu/src/common_cells/src"
export FPU_INCLUDE+=" -J$THIRD_PARTY_DIR/cvfpu/src/fpu_div_sqrt_mvp/hdl"
export FPU_INCLUDE+=" -J$THIRD_PARTY_DIR/cvfpu/src"

export RTL_INCLUDE="-I$RTL_DIR"
export RTL_INCLUDE+=" -I$RTL_DIR/libs"
export RTL_INCLUDE+=" -I$RTL_DIR/interfaces"
export RTL_INCLUDE+=" -I$RTL_DIR/core"
export RTL_INCLUDE+=" -I$RTL_DIR/mem"
export RTL_INCLUDE+=" -I$RTL_DIR/cache"
export RTL_INCLUDE+=" -I$AFU_DIR"
export RTL_INCLUDE+=" $FPU_INCLUDE"

export CONFIGS=""
export CONFIGS+=" -DNUM_CORES=2"
export CONFIGS+=" -DNUM_WARPS=2"
export CONFIGS+=" -DNUM_THREADS=2"
export CONFIGS+=" -DL2_ENABLE"
export CONFIGS+=" -DNDEBUG"
#export CONFIGS+=" -DFPU_FPNEW" # Some source can't be added to compilation order
#                                 cause in project.tcl `create_fileset` instructions were not added
export CONFIGS+=" -DVIVADO"
export CONFIGS+=" -DSYNTHESIS"

vivado -mode batch -source ../../scripts/xilinx_ip_gen.tcl -tclargs ip/ax7020b
 
$SCRIPT_DIR/gen_sources.sh \
    $CONFIGS $RTL_INCLUDE -T$TOP_LEVEL_ENTITY -P -Cproject_1/src -Oproject_1/sources.txt

MAX_JOBS=4 TOOL_DIR=$SCRIPT_DIR vivado \
    -mode batch \
    -source $SRC_DIR/project.tcl \
    -tclargs $TOP_LEVEL_ENTITY $DEVICE project_1/sources.txt $SRC_DIR/project_ax7020b.xdc
