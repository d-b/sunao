//--------------------------------------------------------------
//              Sunao Shader Outline
//                      Copyright (c) 2020 揚茄子研究所
//--------------------------------------------------------------


	#include "UnityCG.cginc"
	#include "AutoLight.cginc"
	#include "Lighting.cginc"
	#include "SunaoShader_Function.cginc"

//-------------------------------------変数宣言

//----Main
	UNITY_DECLARE_TEX2D(_MainTex);
	uniform float4    _MainTex_ST;
	uniform float4    _Color;
	uniform float     _Cutout;
	uniform float     _Alpha;
	UNITY_DECLARE_TEX2D_NOSAMPLER(_AlphaMask);
	uniform float     _AlphaMaskStrength;
	uniform float     _Bright;
	uniform bool      _VertexColor;
	uniform float     _UVScrollX;
	uniform float     _UVScrollY;
	uniform float     _UVAnimation;
	uniform uint      _UVAnimX;
	uniform uint      _UVAnimY;
	uniform bool      _UVAnimOtherTex;

//----Lighting
	uniform float     _Unlit;
	uniform bool      _MonochromeLit;

//----Outline
	uniform bool      _OutLineEnable;
	uniform sampler2D _OutLineMask;
	uniform float4    _OutLineColor;
	uniform float     _OutLineSize;
	UNITY_DECLARE_TEX2D_NOSAMPLER(_OutLineTexture);
	uniform bool      _OutLineLighthing;
	uniform bool      _OutLineTexColor;
	uniform bool      _OutLineFixScale;

//----Hue Shift
	uniform bool      _HSVShiftEnable;
	UNITY_DECLARE_TEX2D_NOSAMPLER(_HSVShiftMask);
	uniform float4 		_HSVShiftMask_ST;
	uniform float 		_HSVShiftHue;
	uniform float 		_HSVShiftSat;
	uniform float 		_HSVShiftVal;
	uniform uint 		  _HSVShiftOutlineMode;

//----Stippling & Crosshatching
	uniform bool _StippleEnable;
	uniform float _StippleSize;
	uniform float _StippleAmount;
	UNITY_DECLARE_TEX2D_NOSAMPLER(_StippleMask);
	uniform float4 _StippleMask_ST;
	uniform bool _CrosshatchEnable;
	uniform float _CrosshatchAmount;
	UNITY_DECLARE_TEX2D_NOSAMPLER(_CrosshatchMask);
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

//----Other
	uniform float     _DirectionalLight;
	uniform float     _SHLight;
	uniform float     _PointLight;
	uniform bool      _LightLimitter;

	uniform bool      _EnableGammaFix;
	uniform float     _GammaR;
	uniform float     _GammaG;
	uniform float     _GammaB;

	uniform bool      _EnableBlightFix;
	uniform float     _BlightOutput;
	uniform float     _BlightOffset;

	uniform bool      _LimitterEnable;
	uniform float     _LimitterMax;


//-------------------------------------頂点シェーダ入力構造体

struct VIN {
	float4 vertex    : POSITION;
	float2 uv        : TEXCOORD;
	float3 normal    : NORMAL;
	float3 color     : COLOR;
};


//-------------------------------------頂点シェーダ出力構造体

struct VOUT {
	float4 pos       : SV_POSITION;
	float2 uv        : TEXCOORD0;
	float3 color     : TEXCOORD1;
	float  mask      : TEXCOORD2;
	float  alpha     : TEXCOORD3;
	float4 worldpos  : TEXCOORD4;
	float4 screenpos : TEXCOORD5;

	LIGHTING_COORDS(6 , 7)
	UNITY_FOG_COORDS(8)
};


//-------------------------------------頂点シェーダ

VOUT vert (VIN v) {

	VOUT o;

//----UV
	o.uv    = (v.uv * _MainTex_ST.xy) + _MainTex_ST.zw;

	if (_UVAnimOtherTex) {
		float4 UVScr = float4(0.0f , 0.0f , 1.0f , 1.0f);

		float4 UVAnim = float4(0.0f , 0.0f , 1.0f , 1.0f);

		if (_UVAnimation > 0.0f) {
			UVAnim.zw  = 1.0f / float2(_UVAnimX , _UVAnimY);

			float2 UVAnimSpeed    = _UVAnimation * _UVAnimY;
			       UVAnimSpeed.y *= -UVAnim.w;

			UVAnim.xy += floor(frac(UVAnimSpeed * _Time.y) * float2(_UVAnimX , _UVAnimY));
		}

		o.uv  = (o.uv + UVAnim.xy) * UVAnim.zw;
		o.uv += float2(_UVScrollX , _UVScrollY) * _Time.y;
	}

//----アウトラインマスク
	o.mask  = MonoColor(tex2Dlod(_OutLineMask , float4(o.uv , 0.0f , 0.0f)).rgb);

//----頂点座標変換
	float4 outv = (float4)0.0f;
	if (_OutLineEnable) {

		float4 fixscale;
		fixscale.x  = length(float3(unity_ObjectToWorld[0].x , unity_ObjectToWorld[1].x , unity_ObjectToWorld[2].x));
		fixscale.y  = length(float3(unity_ObjectToWorld[0].y , unity_ObjectToWorld[1].y , unity_ObjectToWorld[2].y));
		fixscale.z  = length(float3(unity_ObjectToWorld[0].z , unity_ObjectToWorld[1].z , unity_ObjectToWorld[2].z));
		fixscale.w  = 1.0f;
		fixscale    = 0.01f / fixscale;

		if (_OutLineFixScale) fixscale *= 10.0f;

		outv  = v.vertex;
		outv += float4(v.normal , 0) * fixscale * _OutLineSize * o.mask;
	}
	o.pos   = UnityObjectToClipPos(outv);
	float3 PosW = mul(unity_ObjectToWorld , v.vertex).xyz;
	o.worldpos = mul(unity_ObjectToWorld, outv);
	o.screenpos = ComputeScreenPos(o.pos);

//----カラー & ライティング
	o.color = _OutLineColor.rgb;

//-------------------------------------vertex alpha
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

	if (_OutLineTexColor) {
		if (_VertexColor) o.color *= v.color;
		                  o.color *= _Bright;
	}

	if (_OutLineLighthing) {
		float3 Lighting = (float3)0.0f;

		#ifdef PASS_OL_FB
			Lighting  =                ShadeSH9(float4(-1.0f ,  0.0f ,  0.0f , 1.0f));
			Lighting  = max(Lighting , ShadeSH9(float4( 1.0f ,  0.0f ,  0.0f , 1.0f)));
			Lighting  = max(Lighting , ShadeSH9(float4( 0.0f , -1.0f ,  0.0f , 1.0f)));
			Lighting  = max(Lighting , ShadeSH9(float4( 0.0f ,  1.0f ,  0.0f , 1.0f)));
			Lighting  = max(Lighting , ShadeSH9(float4( 0.0f ,  0.0f , -1.0f , 1.0f)));
			Lighting  = max(Lighting , ShadeSH9(float4( 0.0f ,  0.0f ,  1.0f , 1.0f)));
			Lighting *= _SHLight;

			#if VERTEXLIGHT_ON

				float4 VLDirX = unity_4LightPosX0 - PosW.x;
				float4 VLDirY = unity_4LightPosY0 - PosW.y;
				float4 VLDirZ = unity_4LightPosZ0 - PosW.z;

				float4 VLLength = VLightLength(VLDirX , VLDirY , VLDirZ);

				float4 VLAtten  = VLightAtten(VLLength) * _PointLight;
				Lighting += unity_LightColor[0].rgb * VLAtten.x * 0.6f;
				Lighting += unity_LightColor[1].rgb * VLAtten.y * 0.6f;
				Lighting += unity_LightColor[2].rgb * VLAtten.z * 0.6f;
				Lighting += unity_LightColor[3].rgb * VLAtten.w * 0.6f;

			#endif
		#endif

		#ifdef PASS_OL_FB
			Lighting += _LightColor0 * _DirectionalLight;
		#endif
		#ifdef PASS_OL_FA
			Lighting += _LightColor0 * _PointLight * 0.6f;
		#endif

		if (_LightLimitter) Lighting = saturate(Lighting);
		if (_MonochromeLit) Lighting = MonoColor(Lighting);

		o.color *=  Lighting;
	}

//----ポイントライト
	TRANSFER_VERTEX_TO_FRAGMENT(o);

//----フォグ
	UNITY_TRANSFER_FOG(o,o.pos);


	return o;
}


//-------------------------------------フラグメントシェーダ

float4 frag (VOUT IN) : COLOR {

//----カラー計算
	float4 OUT          = float4(0.0f , 0.0f , 0.0f , 1.0f);

	if (_HSVShiftEnable) {
		float3 hsvadj_masked = float3(1.0, 1.0, 1.0);
		float3 hsvadj_unmasked = float3(_HSVShiftHue, _HSVShiftSat, _HSVShiftVal);
		float4 hsvshift_mask = UNITY_SAMPLE_TEX2D_SAMPLER(_HSVShiftMask, _MainTex, TRANSFORM_TEX(IN.uv, _HSVShiftMask));
		hsvadj_masked.x = lerp(1.0f, _HSVShiftHue, hsvshift_mask.r);
		hsvadj_masked.y = lerp(1.0f, _HSVShiftSat, hsvshift_mask.g);
		hsvadj_masked.z = lerp(1.0f, _HSVShiftVal, hsvshift_mask.b);

		if (_HSVShiftOutlineMode == 1) IN.color.rgb = HSVAdjust(IN.color.rgb, hsvadj_masked);
		if (_HSVShiftOutlineMode == 2) IN.color.rgb = HSVAdjust(IN.color.rgb, hsvadj_unmasked);
	}

	OUT.rgb = UNITY_SAMPLE_TEX2D_SAMPLER(_OutLineTexture , _MainTex , IN.uv) * IN.color;

	#ifdef PASS_OL_FA
		if (_OutLineLighthing) OUT.rgb *= LIGHT_ATTENUATION(IN);
	#endif

	if (_OutLineTexColor) {
	       OUT.rgb     *= UNITY_SAMPLE_TEX2D(_MainTex , IN.uv);
	}

	#if defined(TRANSPARENT) || defined(CUTOUT) || defined(ALPHA_TO_COVERAGE)
		OUT.a     = saturate(UNITY_SAMPLE_TEX2D(_MainTex , IN.uv).a * _Color.a * _Alpha);
		OUT.a    *= lerp(1.0f , MonoColor(UNITY_SAMPLE_TEX2D_SAMPLER(_AlphaMask , _MainTex , IN.uv).rgb) , _AlphaMaskStrength);
	#endif

//----Stippling & crosshatching
	half dot_halftone = DotHalftone(IN.worldpos, lerp(1.0f, 10.0f, _StippleAmount), lerp(0.0f, 0.015f, _StippleSize));
	half line_halftone = LineHalftone(IN.worldpos, lerp(0.0f, 4000.0f, _CrosshatchAmount));
	float4 stipple_mask = UNITY_SAMPLE_TEX2D_SAMPLER(_StippleMask, _MainTex, TRANSFORM_TEX(IN.uv, _StippleMask));
	float4 crosshatch_mask = UNITY_SAMPLE_TEX2D_SAMPLER(_CrosshatchMask, _MainTex, TRANSFORM_TEX(IN.uv, _CrosshatchMask));

	if (_StippleEnable) {
		OUT.a *= lerp(1.0f, dot_halftone, 1.0f - stipple_mask.a);
	}

	if (_CrosshatchEnable) {
		OUT.a *= lerp(1.0f, line_halftone, 1.0f - crosshatch_mask.a);
	}

//----Vertex Color Alpha
	OUT.a *= IN.alpha;

//----カットアウト

	#ifdef CUTOUT
		clip(OUT.a - _Cutout);
		OUT.a = 1.0f;
	#endif

//----AlphaToCoverage
	#ifdef ALPHA_TO_COVERAGE
		float2 screenUV = CalcScreenUV(IN.screenpos);
		float dither = CalcDither(screenUV.xy);
		OUT.a = OUT.a - (dither * (1.0 - OUT.a) * 0.15);
	#endif

	clip(IN.mask - 0.2f);

//----ガンマ修正
	if (_EnableGammaFix) {
		_GammaR = max(_GammaR , 0.00001f);
		_GammaG = max(_GammaG , 0.00001f);
		_GammaB = max(_GammaB , 0.00001f);

	       OUT.r        = pow(OUT.r , 1.0f / (1.0f / _GammaR));
	       OUT.g        = pow(OUT.g , 1.0f / (1.0f / _GammaG));
	       OUT.b        = pow(OUT.b , 1.0f / (1.0f / _GammaB));
	}

//----明度修正
	if (_EnableBlightFix) {
	       OUT.rgb     *= _BlightOutput;
	       OUT.rgb      = max(OUT.rgb + _BlightOffset , 0.0f);
	}

//----出力リミッタ
	if (_LimitterEnable) {
	       OUT.rgb      = min(OUT.rgb , _LimitterMax);
	}

//----フォグ
	UNITY_APPLY_FOG(IN.fogCoord, OUT);


	return OUT;
}
