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
	if (_StippleEnable) {
		half halftone = DotHalftone(IN.worldpos, lerp(1, 10, _StippleAmount), lerp(0, 0.015, _StippleSize));
		float alpha = lerp(1.0f, halftone, 1.0f - UNITY_SAMPLE_TEX2D(_StippleMask, IN.uv).a);
		clip(alpha * _Alpha - _Cutout);
	}

	if (_CrosshatchEnable) {
		half halftone = LineHalftone(IN.worldpos, lerp(500, 6000, _CrosshatchAmount));
		float alpha = lerp(1.0f, halftone, 1.0f - UNITY_SAMPLE_TEX2D(_CrosshatchMask, IN.uv).a);
		clip(alpha * _Alpha - _Cutout);
	}

	SHADOW_CASTER_FRAGMENT(IN)
}
