//--------------------------------------------------------------
//              Sunao Shader ShadowCaster
//                      Copyright (c) 2020 揚茄子研究所
//--------------------------------------------------------------


	#include "UnityCG.cginc"
	#include "UnityShaderVariables.cginc"
	#include "SunaoShader_Function.cginc"

	uniform float _Alpha;
	uniform float _Cutout;
	uniform bool _StippleEnable;
	uniform float _StippleSize;
	uniform float _StippleAmount;
	UNITY_DECLARE_TEX2D(_StippleMask);
	uniform float4 _StippleMask_ST;
	uniform bool _CrosshatchEnable;
	uniform float _CrosshatchAmount;
	UNITY_DECLARE_TEX2D(_CrosshatchMask);
	uniform float4 _CrosshatchMask_ST;

struct VIN {
	float4 vertex : POSITION;
	float2 uv     : TEXCOORD0;
};


struct VOUT {
	V2F_SHADOW_CASTER;
	float2 uv : TEXCOORD1;
	float4 worldpos : TEXCOORD2;
	float4 screenpos : TEXCOORD3;
};


VOUT vert (VIN v) {
	VOUT o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.uv;
	o.worldpos = mul(unity_ObjectToWorld, v.vertex);
	o.screenpos = ComputeScreenPos(o.pos);
	TRANSFER_SHADOW_CASTER(o)

	return o;
}


float4 frag (VOUT IN) : COLOR {
	float alpha = _Alpha;
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
