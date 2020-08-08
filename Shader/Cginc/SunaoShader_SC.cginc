//--------------------------------------------------------------
//              Sunao Shader ShadowCaster
//                      Copyright (c) 2021 揚茄子研究所
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
	uniform bool _CrosshatchEnable;
	uniform float _CrosshatchAmount;
	UNITY_DECLARE_TEX2D(_CrosshatchMask);

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
	half dot_halftone = DotHalftone(IN.worldpos, lerp(1.0f, 10.0f, _StippleAmount), lerp(0.0f, 0.015f, _StippleSize));
	half line_halftone = LineHalftone(IN.worldpos, lerp(0.0f, 4000.0f, _CrosshatchAmount));
	float4 stipple_mask = UNITY_SAMPLE_TEX2D(_StippleMask, IN.uv);
	float4 crosshatch_mask = UNITY_SAMPLE_TEX2D(_CrosshatchMask, IN.uv);

	if (_StippleEnable) {
		float alpha = lerp(1.0f, dot_halftone, 1.0f - stipple_mask.a);
		clip(alpha * _Alpha - _Cutout);
	}

	if (_CrosshatchEnable) {
		float alpha = lerp(1.0f, line_halftone, 1.0f - crosshatch_mask.a);
		clip(alpha * _Alpha - _Cutout);
	}

	SHADOW_CASTER_FRAGMENT(IN)
}
