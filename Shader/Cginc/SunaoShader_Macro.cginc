//--------------------------------------------------------------
//              Sunao Shader Function
//                      Copyright (c) 2022 揚茄子研究所
//--------------------------------------------------------------

#ifndef OPTIMIZED_SHADER
#define OPT_IF(x) if(x) {
#define OPT_FI }
#else
#define OPT_IF(x)
#define OPT_FI
#endif

#define WHEN_OPT(x) !defined(OPTIMIZED_SHADER) || (x)
