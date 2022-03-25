//--------------------------------------------------------------
//              Sunao Shader ShadowCaster
//                      Copyright (c) 2022 揚茄子研究所
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
	uniform bool      _OutLineEnable;
	uniform sampler2D _OutLineMask;
	uniform float     _OutLineSize;
	uniform bool      _OutLineFixScale;
	uniform uint      _Culling;

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
	float4 vertex      : POSITION;
	float2 uv          : TEXCOORD0;
	float3 normal      : NORMAL;
	float3 color       : COLOR;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

//-------------------------------------頂点シェーダ出力構造体

struct VOUT {
	float2 uv          : TEXCOORD0;
	float4 uvanm       : TEXCOORD1;
	float  vadd        : VERTEXADD;
	float  alpha       : TEXCOORD3;

	V2F_SHADOW_CASTER;

	UNITY_VERTEX_OUTPUT_STEREO
};

//-------------------------------------頂点シェーダ

VOUT vert (VIN v) {

	VOUT o;

	UNITY_INITIALIZE_OUTPUT(VOUT , o);
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

//----視線
	float3 CamPos;
	#ifdef USING_STEREO_MATRICES
		CamPos = (unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]) * 0.5f;
	#else
		CamPos = _WorldSpaceCameraPos;
	#endif

	float3 View   = CamPos - mul(unity_ObjectToWorld , v.vertex).xyz;

//----面の裏表
	float  Facing = saturate(saturate(1.0f - dot(v.normal , View)) * 10.0f - 0.5f);

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

//-------------------------------------頂点座標計算
	o.vadd = 0.0f;
	if (_OutLineEnable) {
		float  OutlineScale  = GetScale(_OutLineSize , _OutLineFixScale);
		       OutlineScale *= MonoColor(tex2Dlod(_OutLineMask , float4(o.uv , 0.0f , 0.0f)).rgb);
		       OutlineScale *= Facing;
		       v.vertex.xyz += v.normal * OutlineScale;
		       o.vadd        = saturate(OutlineScale * 10000.0f);
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

float4 frag (VOUT IN , bool IsFrontFace : SV_IsFrontFace) : COLOR {

//----面の裏表
	float  Facing = (float)IsFrontFace;

//-------------------------------------メイン
	float4 OUT    = (float4)1.0f;

	#if defined(TRANSPARENT) || defined(CUTOUT)
		float2 MainUV       = (IN.uv + IN.uvanm.xy) * IN.uvanm.zw;
		       MainUV      += float2(_UVScrollX , _UVScrollY) * _Time.y;
		float2 SubUV        = IN.uv;
		if (_UVAnimOtherTex) SubUV = MainUV;

	           OUT.a        = saturate(tex2D(_MainTex , MainUV).a * _Color.a * _Alpha);
	           OUT.a       *= lerp(1.0f , MonoColor(tex2D(_AlphaMask  , SubUV).rgb) , _AlphaMaskStrength);
	           OUT.a       *= IN.alpha;
	#endif

	float  Alpha  = OUT.a;

	if (_Culling == 2) Alpha *= saturate(IN.vadd +         Facing );
	if (_Culling == 1) Alpha *= saturate(IN.vadd + (1.0f - Facing));

	#ifdef TRANSPARENT
		Alpha -= 0.3f;
	#endif

	#ifdef CUTOUT
		Alpha -= _Cutout;
	#endif

	clip(Alpha - 0.0001f);


	SHADOW_CASTER_FRAGMENT(IN)

	return OUT;
}
