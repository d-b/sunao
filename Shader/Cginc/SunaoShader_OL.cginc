//--------------------------------------------------------------
//              Sunao Shader Outline
//                      Copyright (c) 2022 揚茄子研究所
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
	UNITY_DECLARE_TEX2D(_HSVShiftMask);
	uniform float4 		_HSVShiftMask_ST;
	uniform float 		_HSVShiftHue;
	uniform float 		_HSVShiftSat;
	uniform float 		_HSVShiftVal;
	uniform uint 		  _HSVShiftOutlineMode;

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

//----Other
	uniform bool      _AlphaToMask;
	uniform float     _DirectionalLight;
	uniform float     _SHLight;
	uniform float     _PointLight;
	uniform bool      _LightLimitter;
	uniform float     _MinimumLight;

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
	float4 vertex  : POSITION;
	float2 uv      : TEXCOORD0;
	float2 uv1     : TEXCOORD1;
	float3 normal  : NORMAL;
	float3 color   : COLOR;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};


//-------------------------------------頂点シェーダ出力構造体

struct VOUT {
	float4 pos     : SV_POSITION;
	float3 wpos    : WPOSITION;
	float2 uv      : TEXCOORD0;
	float3 color   : COLOR0;
	float  alpha   : COLOR1;
	float3 light   : LIGHT0;
	float  mask    : MASK0;

	UNITY_FOG_COORDS(1)
	#ifdef PASS_FA
		UNITY_LIGHTING_COORDS(2 , 3)
	#endif

	UNITY_VERTEX_OUTPUT_STEREO
};


//----------------------------------------------------------------------
//                頂点シェーダ
//----------------------------------------------------------------------

VOUT vert (VIN v) {

	VOUT o;

	UNITY_INITIALIZE_OUTPUT(VOUT , o);
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

//-------------------------------------UV
	o.uv      = (v.uv * _MainTex_ST.xy) + _MainTex_ST.zw;

	if (_UVAnimOtherTex) {
		float4 UVScr  = float4(0.0f , 0.0f , 1.0f , 1.0f);
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

//-------------------------------------アウトラインマスク
	o.mask    = MonoColor(tex2Dlod(_OutLineMask , float4(o.uv , 0.0f , 0.0f)).rgb) * saturate(_OutLineSize * 10000.0f);

//-------------------------------------頂点座標変換
	if (_OutLineEnable) {
		float3 VertexAdd;
		VertexAdd     = v.normal.xyz * GetScale(_OutLineSize , _OutLineFixScale);
		VertexAdd    *= o.mask;
		v.vertex.xyz += VertexAdd;
	} else {
		v.vertex.xyz  = (float3)0.0f;
	}

	o.pos     = UnityObjectToClipPos(v.vertex);
	o.wpos    = mul(unity_ObjectToWorld , v.vertex).xyz;

//-------------------------------------カラー
	o.color   = _OutLineColor.rgb;

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

	if (_OutLineTexColor) {
		if (_VertexColor) o.color *= v.color;
		                  o.color *= _Bright;
	}

//-------------------------------------ライティング
	o.light   = (float3)0.0f;

	if (_OutLineLighthing) {

		#ifdef PASS_OL_FB
			o.light  =                  ShadeSH9(float4(-1.0f ,  0.0f ,  0.0f , 1.0f));
			o.light  = max(o.light , ShadeSH9(float4( 1.0f ,  0.0f ,  0.0f , 1.0f)));
			o.light  = max(o.light , ShadeSH9(float4( 0.0f , -1.0f ,  0.0f , 1.0f)));
			o.light  = max(o.light , ShadeSH9(float4( 0.0f ,  1.0f ,  0.0f , 1.0f)));
			o.light  = max(o.light , ShadeSH9(float4( 0.0f ,  0.0f , -1.0f , 1.0f)));
			o.light  = max(o.light , ShadeSH9(float4( 0.0f ,  0.0f ,  1.0f , 1.0f)));
			o.light *= _SHLight;

			o.light += _LightColor0 * _DirectionalLight;

			#if VERTEXLIGHT_ON
				float4 VLDirX = unity_4LightPosX0 - o.wpos.x;
				float4 VLDirY = unity_4LightPosY0 - o.wpos.y;
				float4 VLDirZ = unity_4LightPosZ0 - o.wpos.z;

				float4 VLLength = VLightLength(VLDirX , VLDirY , VLDirZ);

				float4 VLAtten  = VLightAtten(VLLength) * _PointLight;
				       VLAtten  *= 0.5f;
				       o.light += unity_LightColor[0].rgb * VLAtten.x;
				       o.light += unity_LightColor[1].rgb * VLAtten.y;
				       o.light += unity_LightColor[2].rgb * VLAtten.z;
				       o.light += unity_LightColor[3].rgb * VLAtten.w;
			#endif

			o.light = max(o.light , _MinimumLight);
		#endif
	}

//-------------------------------------ポイントライト
	#ifdef PASS_FA
		UNITY_TRANSFER_LIGHTING(o , v.uv1);
	#endif

//-------------------------------------フォグ
	UNITY_TRANSFER_FOG(o,o.pos);

	return o;
}


//----------------------------------------------------------------------
//                フラグメントシェーダ
//----------------------------------------------------------------------

float4 frag (VOUT IN) : COLOR {

//-------------------------------------カラー計算
	float4 OUT       = UNITY_SAMPLE_TEX2D_SAMPLER(_OutLineTexture , _MainTex , IN.uv);
	       OUT.rgb  *= IN.color;
	if (_OutLineTexColor) OUT.rgb *= UNITY_SAMPLE_TEX2D(_MainTex , IN.uv);

	if (_HSVShiftEnable) {
		float3 hsvadj_masked = float3(1.0, 1.0, 1.0);
		float3 hsvadj_unmasked = float3(_HSVShiftHue, _HSVShiftSat, _HSVShiftVal);
		float4 hsvshift_mask = UNITY_SAMPLE_TEX2D(_HSVShiftMask, TRANSFORM_TEX(IN.uv, _HSVShiftMask));
		hsvadj_masked.x = lerp(1.0f, _HSVShiftHue, hsvshift_mask.r);
		hsvadj_masked.y = lerp(1.0f, _HSVShiftSat, hsvshift_mask.g);
		hsvadj_masked.z = lerp(1.0f, _HSVShiftVal, hsvshift_mask.b);

		if (_HSVShiftOutlineMode == 1) OUT.rgb = HSVAdjust(OUT.rgb, hsvadj_masked);
		if (_HSVShiftOutlineMode == 2) OUT.rgb = HSVAdjust(OUT.rgb, hsvadj_unmasked);
	}

	#if defined(TRANSPARENT) || defined(CUTOUT) || defined(ALPHA_TO_COVERAGE)
		OUT.a        = saturate(UNITY_SAMPLE_TEX2D(_MainTex , IN.uv).a * _Color.a * _Alpha);
		OUT.a       *= lerp(1.0f , MonoColor(UNITY_SAMPLE_TEX2D_SAMPLER(_AlphaMask , _MainTex , IN.uv).rgb) , _AlphaMaskStrength);
	#endif

//----Apply vertex alpha
	OUT.a *= IN.alpha;

//-------------------------------------カットアウト
	#ifdef CUTOUT
		clip(OUT.a - _Cutout);
		if (_AlphaToMask) {
			OUT.a = saturate((OUT.a - _Cutout) * 10.0f);
		} else {
			OUT.a = 1.0f;
		}
	#endif

	clip(IN.mask - 0.1f);

//-------------------------------------ライティング
	float3 Lighting  = (float3)1.0f;

	#ifdef PASS_OL_FB
		if (_OutLineLighthing) Lighting = IN.light;
	#endif
	#ifdef PASS_OL_FA
		if (_OutLineLighthing) {
			UNITY_LIGHT_ATTENUATION(Atten , IN , IN.wpos);
			Lighting  = _LightColor0 * _PointLight * Atten * 0.6f;
		}
	#endif

	if (_LightLimitter) {
		float  MaxLight = 1.0f;
		       MaxLight = max(MaxLight , Lighting.r);
		       MaxLight = max(MaxLight , Lighting.g);
		       MaxLight = max(MaxLight , Lighting.b);
		       MaxLight = min(MaxLight , 1.25f);
		       Lighting = saturate(Lighting / MaxLight);
	}
	if (_MonochromeLit) Lighting = MonoColor(Lighting);
	float  LightPower   = saturate(MonoColor(Lighting));

	OUT.rgb         *= Lighting;

//-------------------------------------ガンマ修正
	if (_EnableGammaFix) {
		_GammaR  = max(_GammaR , 0.00001f);
		_GammaG  = max(_GammaG , 0.00001f);
		_GammaB  = max(_GammaB , 0.00001f);

		OUT.r    = pow(OUT.r , 1.0f / (1.0f / _GammaR));
		OUT.g    = pow(OUT.g , 1.0f / (1.0f / _GammaG));
		OUT.b    = pow(OUT.b , 1.0f / (1.0f / _GammaB));
	}

//-------------------------------------明度修正
	if (_EnableBlightFix) {
		OUT.rgb *= _BlightOutput;
		OUT.rgb  = max(OUT.rgb + _BlightOffset , 0.0f);
	}

//-------------------------------------出力リミッタ
	if (_LimitterEnable) {
		OUT.rgb  = min(OUT.rgb , _LimitterMax);
	}

//-------------------------------------BlendOpの代用
	#ifdef PASS_OL_FA
		float OutAlpha = saturate(MonoColor(OUT.rgb));
		#ifndef TRANSPARENT
	       OUT.a    = OutAlpha;
		#endif
		#ifdef TRANSPARENT
	       OUT.rgb *= OUT.a;
	       OUT.a    = OutAlpha * pow(OUT.a , 1.8f);
		#endif
	#endif

//-------------------------------------フォグ
	UNITY_APPLY_FOG(IN.fogCoord, OUT);


	return OUT;
}
