//--------------------------------------------------------------
//              Sunao Shader ShadowCaster
//                      Copyright (c) 2021 揚茄子研究所
//--------------------------------------------------------------


//-------------------------------------Include

	#include "UnityCG.cginc"
	#include "UnityShaderVariables.cginc"
	#include "SunaoShader_Function.cginc"

//-------------------------------------変数宣言

	uniform sampler2D _MainTex;
	uniform float4    _MainTex_ST;
	uniform float4    _Color;
	uniform float     _Cutout;
	uniform float     _Alpha;
	uniform sampler2D _AlphaMask;
	uniform float     _AlphaMaskStrength;
	uniform float     _UVScrollX;
	uniform float     _UVScrollY;
	uniform float     _UVAnimation;
	uniform uint      _UVAnimX;
	uniform uint      _UVAnimY;
	uniform bool      _UVAnimOtherTex;

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
	uniform float     _VertexColorThreshold;
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


//-------------------------------------頂点シェーダ入力構造体

struct VIN {
	float4 vertex : POSITION;
	float2 uv     : TEXCOORD0;
	float3 color  : COLOR;
};

//-------------------------------------頂点シェーダ出力構造体

struct VOUT {
	V2F_SHADOW_CASTER;
	float2 uv : TEXCOORD0;
	float4 uvanm : TEXCOORD1;
	float4 worldpos : TEXCOORD2;
	float4 screenpos : TEXCOORD3;
	float alpha : TEXCOORD4;
};

//-------------------------------------頂点シェーダ

VOUT vert (VIN v) {

	VOUT o;

//-------------------------------------頂点座標変換
	o.pos = UnityObjectToClipPos(v.vertex);
	o.worldpos = mul(unity_ObjectToWorld, v.vertex);
	o.screenpos = ComputeScreenPos(o.pos);

//-------------------------------------UV
	o.uv      = (v.uv * _MainTex_ST.xy) + _MainTex_ST.zw;

//-------------------------------------UVアニメーション
	o.uvanm   = float4(0.0f , 0.0f , 1.0f , 1.0f);

	if (_UVAnimation > 0.0f) {
		o.uvanm.zw  = 1.0f / float2(_UVAnimX , _UVAnimY);

		float2 UVAnimSpeed    = _UVAnimation * _UVAnimY;
		       UVAnimSpeed.y *= -o.uvanm.w;

		o.uvanm.xy += floor(frac(UVAnimSpeed * _Time.y) * float2(_UVAnimX , _UVAnimY));
	}

//-------------------------------------Vertex Alpha
	o.alpha = VertexAlpha(v.color, _VertexColor01, _VertexAlpha01, _VertexColorThreshold) *
						VertexAlpha(v.color, _VertexColor02, _VertexAlpha02, _VertexColorThreshold) *
						VertexAlpha(v.color, _VertexColor03, _VertexAlpha03, _VertexColorThreshold) *
						VertexAlpha(v.color, _VertexColor04, _VertexAlpha04, _VertexColorThreshold) *
						VertexAlpha(v.color, _VertexColor05, _VertexAlpha05, _VertexColorThreshold) *
						VertexAlpha(v.color, _VertexColor06, _VertexAlpha06, _VertexColorThreshold) *
						VertexAlpha(v.color, _VertexColor07, _VertexAlpha07, _VertexColorThreshold) *
						VertexAlpha(v.color, _VertexColor08, _VertexAlpha08, _VertexColorThreshold) *
						VertexAlpha(v.color, _VertexColor09, _VertexAlpha09, _VertexColorThreshold) *
						VertexAlpha(v.color, _VertexColor10, _VertexAlpha10, _VertexColorThreshold) *
						VertexAlpha(v.color, _VertexColor11, _VertexAlpha11, _VertexColorThreshold) *
						VertexAlpha(v.color, _VertexColor12, _VertexAlpha12, _VertexColorThreshold) *
						VertexAlpha(v.color, _VertexColor13, _VertexAlpha13, _VertexColorThreshold) *
						VertexAlpha(v.color, _VertexColor14, _VertexAlpha14, _VertexColorThreshold) *
						VertexAlpha(v.color, _VertexColor15, _VertexAlpha15, _VertexColorThreshold) *
						VertexAlpha(v.color, _VertexColor16, _VertexAlpha16, _VertexColorThreshold);

	TRANSFER_SHADOW_CASTER(o)

	return o;
}

//-------------------------------------フラグメントシェーダ

float4 frag (VOUT IN) : COLOR {

	float4 OUT          = (float4)1.0f;

	#if defined(TRANSPARENT) || defined(CUTOUT) || defined(ALPHA_TO_COVERAGE)
		float2 MainUV       = (IN.uv + IN.uvanm.xy) * IN.uvanm.zw;
		       MainUV      += float2(_UVScrollX , _UVScrollY) * _Time.y;
		float2 SubUV        = IN.uv;
		if (_UVAnimOtherTex) SubUV = MainUV;

	           OUT.a        = saturate(tex2D(_MainTex , MainUV).a * _Color.a * _Alpha);
	           OUT.a       *= lerp(1.0f , MonoColor(tex2D(_AlphaMask  , SubUV).rgb) , _AlphaMaskStrength);
	           OUT.a       *= IN.alpha;
	#endif

	#ifdef TRANSPARENT
		clip(OUT.a - 0.3);
	#endif

	#ifdef CUTOUT
		clip(OUT.a - _Cutout);
	#endif

	#ifdef ALPHA_TO_COVERAGE
		float2 screenUV = CalcScreenUV(IN.screenpos);
		float dither = CalcDither(screenUV.xy);
		clip(OUT.a - 0.5);
	#endif

	SHADOW_CASTER_FRAGMENT(IN)
	
	return OUT;
}
