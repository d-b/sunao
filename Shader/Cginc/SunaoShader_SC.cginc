//--------------------------------------------------------------
//              Sunao Shader ShadowCaster
//                      Copyright (c) 2020 揚茄子研究所
//--------------------------------------------------------------


	#include "UnityCG.cginc"
	#include "UnityShaderVariables.cginc"
	#include "SunaoShader_Function.cginc"

	uniform float _Alpha;
	uniform float _Cutout;

//----Stippling & Crosshatching
	uniform bool _StippleEnable;
	uniform float _StippleSize;
	uniform float _StippleAmount;
	UNITY_DECLARE_TEX2D(_StippleMask);
	uniform float4 _StippleMask_ST;
	uniform bool _CrosshatchEnable;
	uniform float _CrosshatchAmount;
	UNITY_DECLARE_TEX2D(_CrosshatchMask);
	uniform float4 _CrosshatchMask_ST;

//----Vertex Color Alpha
	uniform float3    _VertexColor01;
	uniform float     _VertexAlpha01;
	uniform float3    _VertexColor02;
	uniform float     _VertexAlpha02;
	uniform float3    _VertexColor03;
	uniform float     _VertexAlpha03;
	uniform float3    _VertexColor04;
	uniform float     _VertexAlpha04;
	uniform float3    _VertexColor05;
	uniform float     _VertexAlpha05;
	uniform float3    _VertexColor06;
	uniform float     _VertexAlpha06;
	uniform float3    _VertexColor07;
	uniform float     _VertexAlpha07;
	uniform float3    _VertexColor08;
	uniform float     _VertexAlpha08;
	uniform float3    _VertexColor09;
	uniform float     _VertexAlpha09;
	uniform float3    _VertexColor10;
	uniform float     _VertexAlpha10;
	uniform float3    _VertexColor11;
	uniform float     _VertexAlpha11;
	uniform float3    _VertexColor12;
	uniform float     _VertexAlpha12;
	uniform float3    _VertexColor13;
	uniform float     _VertexAlpha13;
	uniform float3    _VertexColor14;
	uniform float     _VertexAlpha14;
	uniform float3    _VertexColor15;
	uniform float     _VertexAlpha15;
	uniform float3    _VertexColor16;
	uniform float     _VertexAlpha16;


struct VIN {
	float4 vertex : POSITION;
	float2 uv     : TEXCOORD0;
	float3 color  : COLOR;
};


struct VOUT {
	V2F_SHADOW_CASTER;
	float2 uv : TEXCOORD1;
	float4 worldpos : TEXCOORD2;
	float4 screenpos : TEXCOORD3;
	float alpha : TEXCOORD4;
};


VOUT vert (VIN v) {
	VOUT o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.uv;
	o.worldpos = mul(unity_ObjectToWorld, v.vertex);
	o.screenpos = ComputeScreenPos(o.pos);
	o.alpha = VertexAlpha(v.color, _VertexColor01, _VertexAlpha01) *
						VertexAlpha(v.color, _VertexColor02, _VertexAlpha02) *
						VertexAlpha(v.color, _VertexColor03, _VertexAlpha03) *
						VertexAlpha(v.color, _VertexColor04, _VertexAlpha04) *
						VertexAlpha(v.color, _VertexColor05, _VertexAlpha05) *
						VertexAlpha(v.color, _VertexColor06, _VertexAlpha06) *
						VertexAlpha(v.color, _VertexColor07, _VertexAlpha07) *
						VertexAlpha(v.color, _VertexColor08, _VertexAlpha08) *
						VertexAlpha(v.color, _VertexColor09, _VertexAlpha09) *
						VertexAlpha(v.color, _VertexColor10, _VertexAlpha10) *
						VertexAlpha(v.color, _VertexColor11, _VertexAlpha11) *
						VertexAlpha(v.color, _VertexColor12, _VertexAlpha12) *
						VertexAlpha(v.color, _VertexColor13, _VertexAlpha13) *
						VertexAlpha(v.color, _VertexColor14, _VertexAlpha14) *
						VertexAlpha(v.color, _VertexColor15, _VertexAlpha15) *
						VertexAlpha(v.color, _VertexColor16, _VertexAlpha16);

	TRANSFER_SHADOW_CASTER(o)

	return o;
}


float4 frag (VOUT IN) : COLOR {
	float alpha = _Alpha;

//----Stippling & crosshatching
	half dot_halftone = DotHalftone(IN.worldpos, lerp(1.0f, 10.0f, _StippleAmount), lerp(0.0f, 0.015f, _StippleSize));
	half line_halftone = LineHalftone(IN.worldpos, lerp(0.0f, 4000.0f, _CrosshatchAmount));
	float4 stipple_mask = UNITY_SAMPLE_TEX2D(_StippleMask, TRANSFORM_TEX(IN.uv, _StippleMask));
	float4 crosshatch_mask = UNITY_SAMPLE_TEX2D(_CrosshatchMask, TRANSFORM_TEX(IN.uv, _CrosshatchMask));

	if (_StippleEnable) {
		alpha *= lerp(1.0f, dot_halftone, 1.0f - stipple_mask.a);
	}

	if (_CrosshatchEnable) {
		alpha *= lerp(1.0f, line_halftone, 1.0f - crosshatch_mask.a);
	}

//----Vertex Color Alpha
	alpha *= IN.alpha;

//-------------------------------------カットアウト
	#ifdef CUTOUT
		clip(alpha - _Cutout);
	#endif

//-------------------------------------AlphaToCoverage
	#ifdef ALPHA_TO_COVERAGE
		float2 screenUV = CalcScreenUV(IN.screenpos);
		float dither = CalcDither(screenUV.xy);
		clip(alpha - 0.5);
	#endif

	SHADOW_CASTER_FRAGMENT(IN)
}
