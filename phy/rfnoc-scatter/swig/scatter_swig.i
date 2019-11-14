/* -*- c++ -*- */

#define SCATTER_API
#define ETTUS_API

%include "gnuradio.i"/*			*/// the common stuff

//load generated python docstrings
%include "scatter_swig_doc.i"
//Header from gr-ettus
%include "ettus/device3.h"
%include "ettus/rfnoc_block.h"
%include "ettus/rfnoc_block_impl.h"

%{
#include "ettus/device3.h"
#include "ettus/rfnoc_block_impl.h"
#include "scatter/McFsource.h"
#include "scatter/fir129.h"
%}

%include "scatter/McFsource.h"
GR_SWIG_BLOCK_MAGIC2(scatter, McFsource);

%include "scatter/fir129.h"
GR_SWIG_BLOCK_MAGIC2(scatter, fir129);

%include "scatter/specsense2k.h"
GR_SWIG_BLOCK_MAGIC2(scatter, specsense2k);
