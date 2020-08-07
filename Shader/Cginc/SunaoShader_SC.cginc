//--------------------------------------------------------------
//              Sunao Shader ShadowCaster
//                      Copyright (c) 2021 揚茄子研究所
//--------------------------------------------------------------


	#include "UnityCG.cginc"
	#include "UnityShaderVariables.cginc"
	#include "SunaoShader_Function.cginc"

	uniform float _Alpha;
	uniform float _Cutout;

struct VIN {
	float4 vertex : POSITION;
	float2 uv     : TEXCOORD0;
};


struct VOUT {
	V2F_SHADOW_CASTER;
	float2 uv : TEXCOORD1;
	float4 worldpos : TEXCOORD2;
};


VOUT vert (VIN v) {
	VOUT o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.uv;
	o.worldpos = mul(unity_ObjectToWorld, v.vertex);
	TRANSFER_SHADOW_CASTER(o)

	return o;
}


float4 frag (VOUT IN) : COLOR {
	half alpha = DotHalftone(IN.worldpos, 10, 0.0075);
	clip(alpha * _Alpha - _Cutout);
	SHADOW_CASTER_FRAGMENT(IN)
}
