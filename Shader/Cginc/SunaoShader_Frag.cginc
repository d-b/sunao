//--------------------------------------------------------------
//              Sunao Shader Fragment
//                      Copyright (c) 2022 揚茄子研究所
//--------------------------------------------------------------


float4 frag (VOUT IN , bool IsFrontFace : SV_IsFrontFace) : COLOR {

//----ワールド座標
	float3 WorldPos     = mul(unity_ObjectToWorld , IN.vertex).xyz;

//----カメラ視点方向
	float3 View         = normalize(IN.campos - WorldPos);

//----面の裏表
	float  Facing       = (float)IsFrontFace;

//-------------------------------------メインカラー
	float4 OUT          = float4(0.0f , 0.0f , 0.0f , 1.0f);

	float2 MainUV       = (IN.uv + IN.uvanm.xy) * IN.uvanm.zw;
	       MainUV      += float2(_UVScrollX , _UVScrollY) * _Time.y;
	float2 SubUV        = IN.uv;
	if (_UVAnimOtherTex) SubUV = MainUV;
	float2 NormalUV     = SubUV;

	#if defined(TRANSPARENT) || defined(CUTOUT) || defined(ALPHA_TO_COVERAGE)
	       OUT.a        = saturate(UNITY_SAMPLE_TEX2D(_MainTex , MainUV).a * _Color.a * _Alpha);
	       OUT.a       *= lerp(1.0f , MonoColor(UNITY_SAMPLE_TEX2D_SAMPLER(_AlphaMask  , _MainTex , SubUV).rgb) , _AlphaMaskStrength);
	#endif

	float3 Color        = UNITY_SAMPLE_TEX2D(_MainTex , MainUV).rgb;
	       Color        = Color * _Color.rgb * _Bright * IN.color;

	float4 ALColor      = float4(0.0f , 0.0f , 0.0f , 1.0f);

//----Tangent map application
	#if WHEN_OPT(PROP_TAN_ENABLE == 1)
	OPT_IF(_TanEnable)
		if (_TanMode == 0) {
			float3 TanMap = UNITY_SAMPLE_TEX2D_SAMPLER(_TanMap, _MainTex, TRANSFORM_TEX(SubUV, _TanMap));
			float3x3 TBN = transpose(float3x3(IN.tangent.xyz, cross(IN.tangent.xyz, IN.normal), IN.normal));
			IN.tangent = float4(mul(TBN, float3(TanMap.rg, 0)), IN.tangent.w);
			IN.bitan = cross(UnityObjectToWorldNormal(IN.normal) , UnityObjectToWorldDir(IN.tangent.xyz)) * IN.tangent.w * unity_WorldTransformParams.w;
			NormalUV = RotateUV(NormalUV, TanMap.b * 2.0 * UNITY_PI);
		}
		else if (_TanMode == 1) {
			float3 TanMap = UNITY_SAMPLE_TEX2D_SAMPLER(_TanMap, _MainTex, TRANSFORM_TEX(SubUV, _TanMap));
			float4 rotation = float4(IN.normal * sin(TanMap.r * UNITY_PI), cos(TanMap.r * UNITY_PI));
			IN.tangent = float4(QuatRotate(rotation, IN.tangent.xyz), IN.tangent.w);
			IN.bitan = cross(UnityObjectToWorldNormal(IN.normal) , UnityObjectToWorldDir(IN.tangent.xyz)) * IN.tangent.w * unity_WorldTransformParams.w;
			NormalUV = RotateUV(NormalUV, TanMap.g * 2.0 * UNITY_PI);
		}
	OPT_FI
	#endif

//----HSV adjustments
	#if WHEN_OPT(PROP_HSV_SHIFT_ENABLE == 1)
	float3 hsvadj_masked = float3(0.0, 1.0, 1.0);
	float3 hsvadj_unmasked = float3(_HSVShiftHue, _HSVShiftSat, _HSVShiftVal);
	OPT_IF(_HSVShiftEnable)
		float4 hsvshift_mask = UNITY_SAMPLE_TEX2D(_HSVShiftMask, TRANSFORM_TEX(SubUV, _HSVShiftMask));
		hsvadj_masked.x = lerp(0.0f, _HSVShiftHue, hsvshift_mask.r);
		hsvadj_masked.y = lerp(1.0f, _HSVShiftSat, hsvshift_mask.g);
		hsvadj_masked.z = lerp(1.0f, _HSVShiftVal, hsvshift_mask.b);

		if (_HSVShiftBaseMode == 1) Color.rgb = HSVAdjust(Color.rgb, hsvadj_masked);
		if (_HSVShiftBaseMode == 2) Color.rgb = HSVAdjust(Color.rgb, hsvadj_unmasked);
		if (_HSVShiftShadeMode == 1) _CustomShadeColor.rgb = HSVAdjust(_CustomShadeColor.rgb, hsvadj_masked);
		if (_HSVShiftShadeMode == 2) _CustomShadeColor.rgb = HSVAdjust(_CustomShadeColor.rgb, hsvadj_unmasked);
		if (_HSVShiftSpecularMode == 1) _ToonSpecColor.rgb = HSVAdjust(_ToonSpecColor.rgb, hsvadj_masked);
		if (_HSVShiftSpecularMode == 2) _ToonSpecColor.rgb = HSVAdjust(_ToonSpecColor.rgb, hsvadj_unmasked);
		if (_HSVShiftRimMode == 1) _RimLitColor.rgb = HSVAdjust(_RimLitColor.rgb, hsvadj_masked);
		if (_HSVShiftRimMode == 2) _RimLitColor.rgb = HSVAdjust(_RimLitColor.rgb, hsvadj_unmasked);
	OPT_FI
	#endif

//----AudioLink
	#if WHEN_OPT(PROP_AL_ENABLE == 1)
	OPT_IF(_ALEnable)
		if (AudioLinkIsAvailable()) {
			#if WHEN_OPT(PROP_AL_CHANNEL < 4)
			OPT_IF(_ALChannel < 4)
				float4 ALMask = UNITY_SAMPLE_TEX2D(_ALMask, TRANSFORM_TEX(SubUV, _ALMask));
				float4 Texture = UNITY_SAMPLE_TEX2D_SAMPLER(_ALTexture, _ALMask, TRANSFORM_TEX(SubUV, _ALMask));

				float Mask = 0.0;
				switch (_ALChannel) {
					case 0: Mask = ALMask.r; break;
					case 1: Mask = ALMask.g; break;
					case 2: Mask = ALMask.b; break;
					case 3: Mask = ALMask.a; break;
				}

				float Audio = AudioLinkData(int2(0, _ALChannel)).x;

				float Bar = smoothstep((1 - Audio), (1 - Audio) + 0.01, Mask);
				float Alpha = lerp(Bar, Mask, Texture.a);

				ALColor.rgb = Texture.rgb * Alpha * Audio;
			OPT_FI
			#endif

			#if WHEN_OPT(PROP_AL_CHANNEL == 4)
			OPT_IF(_ALChannel == 4)
				float4 ALMask = UNITY_SAMPLE_TEX2D(_ALMask, TRANSFORM_TEX(SubUV, _ALMask));
				float4 BassTexture = UNITY_SAMPLE_TEX2D_SAMPLER(_ALBassTexture, _ALMask, TRANSFORM_TEX(SubUV, _ALMask));
				float4 LowMidsTexture = UNITY_SAMPLE_TEX2D_SAMPLER(_ALLowMidsTexture, _ALMask, TRANSFORM_TEX(SubUV, _ALMask));
				float4 HighMidsTexture = UNITY_SAMPLE_TEX2D_SAMPLER(_ALHighMidsTexture, _ALMask, TRANSFORM_TEX(SubUV, _ALMask));
				float4 TrebleTexture = UNITY_SAMPLE_TEX2D_SAMPLER(_ALTrebleTexture, _ALMask, TRANSFORM_TEX(SubUV, _ALMask));

				float AudioBass = AudioLinkData(ALPASS_AUDIOBASS).x;
				float AudioLowMids = AudioLinkData(ALPASS_AUDIOLOWMIDS).x;
				float AudioHighMids = AudioLinkData(ALPASS_AUDIOHIGHMIDS).x;
				float AudioTreble = AudioLinkData(ALPASS_AUDIOTREBLE).x;

				float BassBar = smoothstep((1 - AudioBass), (1 - AudioBass) + 0.01, ALMask.r);
				float LowMidsBar = smoothstep((1 - AudioLowMids), (1 - AudioLowMids) + 0.01, ALMask.g);
				float HighMidsBar = smoothstep((1 - AudioHighMids), (1 - AudioHighMids) + 0.01, ALMask.b);
				float TrebleBar = smoothstep((1 - AudioTreble), (1 - AudioTreble) + 0.01, ALMask.a);

				float BassAlpha = lerp(BassBar, ALMask.r, BassTexture.a);
				float LowMidsAlpha = lerp(LowMidsBar, ALMask.g, LowMidsTexture.a);
				float HighMidsAlpha = lerp(HighMidsBar, ALMask.b, HighMidsTexture.a);
				float TrebleAlpha = lerp(TrebleBar, ALMask.a, TrebleTexture.a);

				ALColor.rgb = BassTexture.rgb * BassAlpha * AudioBass
										+ LowMidsTexture.rgb * LowMidsAlpha * AudioLowMids
										+ HighMidsTexture.rgb * HighMidsAlpha * AudioHighMids
										+ TrebleTexture.rgb * TrebleAlpha * AudioTreble;
			OPT_FI
			#endif

			#if WHEN_OPT(PROP_HSV_SHIFT_ENABLE == 1)
			OPT_IF(_HSVShiftEnable)
				if (_HSVShiftAudioLinkMode == 1) ALColor.rgb = HSVAdjust(ALColor.rgb, hsvadj_masked);
				if (_HSVShiftAudioLinkMode == 2) ALColor.rgb = HSVAdjust(ALColor.rgb, hsvadj_unmasked);
			OPT_FI
			#endif

			#if WHEN_OPT(PROP_AL_ALBEDO_ENABLE == 1)
			OPT_IF(_ALAlbedoEnable)
				Color.rgb = saturate(Color.rgb + ALColor.rgb * _ALAlbedoOpacity);
			OPT_FI
			#endif
		}
	OPT_FI
	#endif

//-------------------------------------サブテクスチャ
	#if WHEN_OPT(PROP_SUB_TEX_ENABLE == 1)
	OPT_IF(_SubTexEnable)
		float4 SubTex    = UNITY_SAMPLE_TEX2D_SAMPLER(_SubTex , _MainTex , MainUV);
		       SubTex   *= _SubColor;
		       SubTex.a *= _SubTexBlend;
		if (_SubTexBlendMode == 1) SubTex.rgb *= Color.rgb;
		if (_SubTexBlendMode == 2) SubTex.rgb  = saturate(Color.rgb + SubTex.rgb);
		if (_SubTexBlendMode == 3) SubTex.rgb  = saturate(Color.rgb - SubTex.rgb);

		#if WHEN_OPT(PROP_HSV_SHIFT_ENABLE == 1)
		OPT_IF(_HSVShiftEnable)
			if (_HSVShiftSubTexMode == 1) SubTex.rgb = HSVAdjust(SubTex.rgb, hsvadj_masked);
			if (_HSVShiftSubTexMode == 2) SubTex.rgb = HSVAdjust(SubTex.rgb, hsvadj_unmasked);
		OPT_FI
		#endif

		if (_SubTexCulling   == 1) SubTex.a   *=        Facing;
		if (_SubTexCulling   == 2) SubTex.a   *= 1.0f - Facing;
		       Color.rgb = lerp(Color.rgb , SubTex.rgb , SubTex.a);
		       OUT.a     = saturate(OUT.a + SubTex.a);
	OPT_FI
	#endif

//----デカール
	float4 DecalColor   = float4(0.0f , 0.0f , 0.0f , 1.0f);
	#if WHEN_OPT(PROP_DECAL_ENABLE == 1)
	OPT_IF(_DecalEnable)

		float2   DecalUV       = (float2)0.0f;
		float2x2 DecalRot      = float2x2(IN.decal.z, -IN.decal.w, IN.decal.w, IN.decal.z);

		if  (_DecalMirror <  4) {
			DecalUV    = IN.uv   - float2(_DecalPosX , _DecalPosY) + IN.decal2.zw;
		} else {
			DecalUV.x  = 0.5f + (floor(_DecalPosX + 0.5f) - 0.5f) * abs(2.0f * IN.uv.x -1.0f);
			DecalUV.y  = IN.uv.y;
			DecalUV    = DecalUV - float2(_DecalPosX , _DecalPosY) + IN.decal2.zw;
		}

		if ((_DecalMirror == 1) | (_DecalMirror == 3)) {
			DecalUV    = lerp(DecalUV , float2(-DecalUV.x , DecalUV.y) , saturate(IN.tangent.w));
			DecalUV.x += IN.decal2.z * saturate(IN.tangent.w) * 2.0f;
		}
		if  (_DecalMirror == 5) {
			DecalUV    = lerp(DecalUV , float2(-DecalUV.x , DecalUV.y) , floor(IN.uv.x + 0.5f));
			DecalUV.x += IN.decal2.z * floor(IN.uv.x + 0.5f) * 2.0f;
		}

		         DecalUV       = mul(DecalRot, DecalUV - IN.decal2.zw) + IN.decal2.zw;
		         DecalUV      *= IN.decal.xy;

		float2   DecalScrUV    = (DecalUV + IN.decanm.xy) * IN.decanm.zw;
		         DecalScrUV   += float2(_DecalScrollX , _DecalScrollY) * _Time.y;

		         DecalColor    = tex2Dbias(_DecalTex  , float4(DecalScrUV , 0.0f , IN.decal2.x * IN.decal2.y - 1.0f)) * _DecalColor;
		         DecalColor.a *= saturate((0.5f - abs(DecalUV.x - 0.5f)) * 1000.0f) * saturate((0.5f - abs(DecalUV.y - 0.5f)) * 1000.0f);

		if (_DecalMirror == 2) DecalColor.a = DecalColor.a * (1.0f - saturate(IN.tangent.w));
		if (_DecalMirror == 3) DecalColor.a = DecalColor.a *         saturate(IN.tangent.w);

		#if WHEN_OPT(PROP_HSV_SHIFT_ENABLE == 1)
		OPT_IF(_HSVShiftEnable)
			if (_HSVShiftDecalMode == 1) DecalColor.rgb = HSVAdjust(DecalColor.rgb, hsvadj_masked);
			if (_HSVShiftDecalMode == 2) DecalColor.rgb = HSVAdjust(DecalColor.rgb, hsvadj_unmasked);
		OPT_FI
		#endif

		#ifdef TRANSPARENT
			if ((_DecalMode == 0) | (_DecalMode == 5)) {
				Color        = lerp(Color , lerp(DecalColor.rgb , Color , OUT.a) , DecalColor.a);
			}
			if  (_DecalMode == 1) {
				Color        = lerp(Color ,                       Color * OUT.a  , DecalColor.a);
				DecalColor.a = MonoColor(DecalColor.rgb) * DecalColor.a;
			}
			if ((_DecalMode == 2) | (_DecalMode == 3)) {
				DecalColor.a = DecalColor.a * OUT.a;
			}
			if  (_DecalMode == 4) {
				DecalColor.a = MonoColor(DecalColor.rgb) * DecalColor.a * _DecalEmission;
			}
		#endif

		         OUT.a         = max(OUT.a , DecalColor.a);

		if ((_DecalMode == 0) | (_DecalMode == 5)) {
			Color = lerp(Color ,          DecalColor.rgb , DecalColor.a);
		}
		if  (_DecalMode == 1) {
			Color = saturate(    Color  + DecalColor.rgb * DecalColor.a);
		}
		if  (_DecalMode == 2) {
			Color = lerp(Color , Color  * DecalColor.rgb , DecalColor.a);
		}
		if  (_DecalMode == 3) {
			float DecalMixCol = saturate(max(Color.r , max(Color.g , Color.b)) + _DecalBright);
			Color = lerp(Color , DecalMixCol * DecalColor.rgb , DecalColor.a);
		}
		if ((_DecalMode == 4) | (_DecalMode == 5)) {
			DecalColor.rgb = DecalColor.rgb * DecalColor.a;
		}

	OPT_FI
	#endif

//----オクルージョン
	if (_OcclusionMode == 1) Color *= lerp(1.0f , UNITY_SAMPLE_TEX2D_SAMPLER(_OcclusionMap , _MainTex , SubUV).rgb , _OcclusionStrength);

//----Apply vertex alpha
	OUT.a *= IN.alpha;

// Mirror control
	#if WHEN_OPT(PROP_MIRROR_CONTROL_ENABLE == 1)
	OPT_IF(_MirrorControlEnable)
		if (IsInMirror()) OUT.a *= _MirrorCopyAlpha;
		else OUT.a *= _RealCopyAlpha;
	OPT_FI
	#endif

//-------------------------------------カットアウト
	#ifdef CUTOUT
	       clip(OUT.a - _Cutout);
	       if (_AlphaToMask) OUT.a = saturate((OUT.a - _Cutout) * 10.0f);
	#endif

//-------------------------------------AlphaToCoverage
	#ifdef ALPHA_TO_COVERAGE
		float2 screenUV = CalcScreenUV(IN.scrpos);
		float dither = CalcDither(screenUV.xy);
		OUT.a = OUT.a - (dither * (1.0 - OUT.a) * 0.15);
	#endif

//-------------------------------------ノーマルマップ
	float3 Normal       = UnityObjectToWorldNormal(IN.normal     );
	float3 tanW         = UnityObjectToWorldDir   (IN.tangent.xyz);

	float3 tan_sx       = float3(tanW.x , IN.bitan.x , Normal.x);
	float3 tan_sy       = float3(tanW.y , IN.bitan.y , Normal.y);
	float3 tan_sz       = float3(tanW.z , IN.bitan.z , Normal.z);

	float2 NormalMapUV  = MixingTransformTex(SubUV , _MainTex_ST , _BumpMap_ST);
	float3 NormalMap    = normalize(UnpackScaleNormal(tex2D(_BumpMap , NormalMapUV) , _BumpScale));
	       Normal.x     = dot(tan_sx , NormalMap);
	       Normal.y     = dot(tan_sy , NormalMap);
	       Normal.z     = dot(tan_sz , NormalMap);

	       Normal       = lerp(-Normal , Normal , Facing);

//-------------------------------------Bitangent
	float3 Bitangent		= cross(Normal, tanW) * IN.tangent.w * unity_WorldTransformParams.w;

//-------------------------------------シェーディング
	float3 ShadeMask    = UNITY_SAMPLE_TEX2D_SAMPLER(_ShadeMask , _MainTex , SubUV).rgb * _Shade;
	float3 LightBoost   = 1.0f + (UNITY_SAMPLE_TEX2D_SAMPLER(_LightMask , _MainTex , SubUV).rgb * (_LightBoost - 1.0f));

//----ディフューズ
	float  Diffuse      = DiffuseCalc(Normal , IN.ldir , _ShadeGradient , _ShadeWidth);

	#ifdef PASS_FB
		float  SHDiffuse    = DiffuseCalc(Normal , IN.shdir , _ShadeGradient , _ShadeWidth);

		float4 VLDiffuse    = IN.vldirX * Normal.x;
		       VLDiffuse   += IN.vldirY * Normal.y;
		       VLDiffuse   += IN.vldirZ * Normal.z;
		       VLDiffuse    = max((float4)0.0f , VLDiffuse * IN.vlcorr);
	#endif

//----トゥーンシェーディング
	#if WHEN_OPT(PROP_TOON_ENABLE == 1)
	OPT_IF(_ToonEnable)
		Diffuse   = ToonCalc(Diffuse , IN.toon);
		#ifdef PASS_FB
			SHDiffuse = ToonCalc(SHDiffuse , IN.toon);
			VLDiffuse = ToonCalc(VLDiffuse , IN.toon);
		#endif
	OPT_FI
	#endif

//----影の色
	float3 ShadeColor   = saturate(Color * 3.0f - 1.5f) * _ShadeColor;
	       ShadeColor   = lerp(ShadeColor , _CustomShadeColor.rgb , _CustomShadeColor.a);

//-------------------------------------ライティング
	float3 LightBase    = (float3)0.0f;
	float3 VLightBase   = (float3)0.0f;
	float3 SHLightBase  = (float3)0.0f;

	#ifdef PASS_FB
		       LightBase    = _LightColor0 * _DirectionalLight;
		float3 VLight0      = unity_LightColor[0].rgb * IN.vlatn.x * 0.5f;
		float3 VLight1      = unity_LightColor[1].rgb * IN.vlatn.y * 0.5f;
		float3 VLight2      = unity_LightColor[2].rgb * IN.vlatn.z * 0.5f;
		float3 VLight3      = unity_LightColor[3].rgb * IN.vlatn.w * 0.5f;
		       VLightBase   = saturate(VLight0 + VLight1 + VLight2 + VLight3);
		       SHLightBase  = IN.shmax;
	#endif
	#ifdef PASS_FA
		       UNITY_LIGHT_ATTENUATION(Atten , IN , IN.wpos);
			   LightBase    = _LightColor0 * _PointLight * Atten * 0.6f;
	#endif

//----モノクロライティング
	#if WHEN_OPT(PROP_MONOCHROME_LIT == 1)
	OPT_IF(_MonochromeLit)
		LightBase  = MonoColor(LightBase);
		#ifdef PASS_FB
			VLight0     = MonoColor(VLight0);
			VLight1     = MonoColor(VLight1);
			VLight2     = MonoColor(VLight2);
			VLight3     = MonoColor(VLight3);
			VLightBase  = MonoColor(VLightBase);
		#endif
	OPT_FI
	#endif

//----ライト反映
	float3 Lighting     = LightBase;

	float3 DiffColor    = LightingCalc(Lighting , Diffuse , ShadeColor , ShadeMask);

	#ifdef PASS_FB
		float3 SHDiffColor  = LightingCalc(SHLightBase , SHDiffuse , ShadeColor , ShadeMask);
		       SHDiffColor  = saturate(SHDiffColor - IN.shmin) + IN.shmin;
		if (_OcclusionMode == 0) SHDiffColor *= lerp(1.0f , UNITY_SAMPLE_TEX2D_SAMPLER(_OcclusionMap , _MainTex , SubUV).rgb , _OcclusionStrength);

		float3 VL4Diff[4];
		       VL4Diff[0]   = LightingCalc(VLight0 , VLDiffuse.x , ShadeColor , ShadeMask);
		       VL4Diff[1]   = LightingCalc(VLight1 , VLDiffuse.y , ShadeColor , ShadeMask);
		       VL4Diff[2]   = LightingCalc(VLight2 , VLDiffuse.z , ShadeColor , ShadeMask);
		       VL4Diff[3]   = LightingCalc(VLight3 , VLDiffuse.w , ShadeColor , ShadeMask);
		float3 VLDiffColor  = saturate(VL4Diff[0] + VL4Diff[1] + VL4Diff[2] + VL4Diff[3]);

		       Lighting     = (DiffColor + SHDiffColor + VLDiffColor) * LightBoost;
	#endif
	#ifdef PASS_FA
		       Lighting     = DiffColor * LightBoost;
	#endif

	if (_LightLimitter) {
		float  MaxLight     = 1.0f;
		       MaxLight     = max(MaxLight , Lighting.r);
		       MaxLight     = max(MaxLight , Lighting.g);
		       MaxLight     = max(MaxLight , Lighting.b);
		       MaxLight     = min(MaxLight , 1.25f);
		       Lighting     = saturate(Lighting / MaxLight);
		       LightBase    = min(  LightBase , 2.5f);
		       VLightBase   = min( VLightBase , 2.5f);
		       SHLightBase  = min(SHLightBase , 2.5f);
	}

	float  LightPower = 0.0f;
	#ifdef PASS_FA
		       LightPower   = saturate(Lighting);
	#endif

//-------------------------------------エミッション
	float3 Emission     = (float3)0.0f;

	#if WHEN_OPT(PROP_EMISSION_ENABLE == 1)
	OPT_IF(_EmissionEnable)
		       Emission    = _Emission * _EmissionColor.rgb;
		       Emission   *= tex2D(_EmissionMap  , IN.euv.xy).rgb * tex2D(_EmissionMap  , IN.euv.xy).a * IN.eprm.x;
		       Emission   *= tex2D(_EmissionMap2 , IN.euv.zw).rgb * tex2D(_EmissionMap2 , IN.euv.zw).a;

    #if WHEN_OPT(PROP_HSV_SHIFT_ENABLE == 1)
    OPT_IF(_HSVShiftEnable)
			if (_HSVShiftEmissionMode == 1) Emission.rgb = HSVAdjust(Emission.rgb, hsvadj_masked);
			if (_HSVShiftEmissionMode == 2) Emission.rgb = HSVAdjust(Emission.rgb, hsvadj_unmasked);
		OPT_FI
		#endif

		#if WHEN_OPT(PROP_AL_ENABLE == 1 && PROP_AL_EMISSION_ENABLE == 1)
		OPT_IF(_ALEnable && _ALEmissionEnable)
			Emission.rgb += _Emission * ALColor.rgb * _ALEmissionIntensity;
		OPT_FI
		#endif

		if (_EmissionLighting) {
			#ifdef PASS_FB
				Emission   *= saturate(MonoColor(LightBase) + MonoColor(SHLightBase) + MonoColor(VLightBase));
			#endif
			#ifdef PASS_FA
				Emission   *= saturate(MonoColor(LightBase));
			#endif
		}
		#ifdef PASS_FA
			Emission *= LightPower;
		#endif

	OPT_FI
	#endif

//-------------------------------------視差エミッション
	float3 Parallax     = (float3)0.0f;

	#if WHEN_OPT(PROP_PARALLAX_ENABLE == 1)
	OPT_IF(_ParallaxEnable)
		float  Height      = (1.0f - MonoColor(UNITY_SAMPLE_TEX2D_SAMPLER(_ParallaxDepthMap , _MainTex , IN.pduv).rgb)) * _ParallaxDepth;
		float2 ParallaxUV  = IN.peuv.xy;
		       ParallaxUV -= normalize(IN.pview).xz * Height * _ParallaxMap_ST.xy;
		       Parallax    = _ParallaxEmission * _ParallaxColor.rgb;
		       Parallax   *= tex2D(_ParallaxMap  , ParallaxUV).rgb * tex2D(_ParallaxMap  , ParallaxUV).a * IN.peprm.x;
		       Parallax   *= tex2D(_ParallaxMap2 , IN.peuv.zw).rgb * tex2D(_ParallaxMap2 , IN.peuv.zw).a;

    #if WHEN_OPT(PROP_HSV_SHIFT_ENABLE == 1)
    OPT_IF(_HSVShiftEnable)
			if (_HSVShiftParallaxMode == 1) Parallax.rgb = HSVAdjust(Parallax.rgb, hsvadj_masked);
			if (_HSVShiftParallaxMode == 2) Parallax.rgb = HSVAdjust(Parallax.rgb, hsvadj_unmasked);
		OPT_FI
		#endif

		if (_ParallaxLighting) {
			#ifdef PASS_FB
				Parallax   *= saturate(MonoColor(LightBase) + MonoColor(SHLightBase) + MonoColor(VLightBase));
			#endif
			#ifdef PASS_FA
				Parallax   *= saturate(MonoColor(LightBase));
			#endif
		}
		#ifdef PASS_FA
			Parallax *= LightPower;
		#endif
	OPT_FI
	#endif

//-------------------------------------リフレクション
	float  Smoothness   = 0.0f;
	float3 ToonSpec      = (float3)0.0f;
	float3 ToonSpecMask  = (float3)0.0f;
	float3 ToonSpecColor = (float3)0.0f;
	float3 SpecularMask = (float3)0.0f;
	float3 ReflectMask  = (float3)0.0f;
	float  MatCapSmooth = 0.0f;
	float3 MatCapMask   = (float3)0.0f;
	float3 Specular     = (float3)0.0f;
	float3 Reflection   = (float3)0.0f;
	float3 MatCapture   = (float3)0.0f;

	#if WHEN_OPT(PROP_TOON_SPEC_ENABLE == 1)
	OPT_IF(_ToonSpecEnable)
		ToonSpecMask = UNITY_SAMPLE_TEX2D_SAMPLER(_ToonSpecMask, _MainTex, TRANSFORM_TEX(SubUV, _ToonSpecMask));
		ToonSpecColor = lerp(_ToonSpecColor, Color, _ToonSpecMetallic);

		#if WHEN_OPT(PROP_TOON_SPEC_MODE == 0)
		OPT_IF(_ToonSpecMode == 0)
			float3 RLToonSpec = ToonAnisoSpecularCalc(Normal, tanW, Bitangent, IN.ldir, View, _ToonSpecRoughnessT, _ToonSpecRoughnessB) * LightBase;

			#ifdef PASS_FB
				float3 SHToonSpec = ToonAnisoSpecularCalc(Normal, tanW, Bitangent, IN.shdir, View, _ToonSpecRoughnessT, _ToonSpecRoughnessB) * IN.shmax;
				float3 VL0ToonSpec = ToonAnisoSpecularCalc(Normal, tanW, Bitangent, float3(IN.vldirX.x, IN.vldirY.x, IN.vldirZ.x), View, _ToonSpecRoughnessT, _ToonSpecRoughnessB) * VLight0;
				float3 VL1ToonSpec = ToonAnisoSpecularCalc(Normal, tanW, Bitangent, float3(IN.vldirX.y, IN.vldirY.y, IN.vldirZ.y), View, _ToonSpecRoughnessT, _ToonSpecRoughnessB) * VLight1;
				float3 VL2ToonSpec = ToonAnisoSpecularCalc(Normal, tanW, Bitangent, float3(IN.vldirX.z, IN.vldirY.z, IN.vldirZ.z), View, _ToonSpecRoughnessT, _ToonSpecRoughnessB) * VLight2;
				float3 VL3ToonSpec = ToonAnisoSpecularCalc(Normal, tanW, Bitangent, float3(IN.vldirX.w, IN.vldirY.w, IN.vldirZ.w), View, _ToonSpecRoughnessT, _ToonSpecRoughnessB) * VLight3;

				ToonSpec = (RLToonSpec + SHToonSpec + VL0ToonSpec + VL1ToonSpec + VL2ToonSpec + VL3ToonSpec) * _ToonSpecIntensity * ToonSpecColor;
			#endif
			#ifdef PASS_FA
				ToonSpec = RLToonSpec * _ToonSpecIntensity * ToonSpecColor;
			#endif
		OPT_FI
		#endif

		#if WHEN_OPT(PROP_TOON_SPEC_MODE == 1)
		OPT_IF(_ToonSpecMode == 1)
			float3 RLToonSpec = ToonViewOffSpecularCalc(Normal, IN.ldir, View, _ToonSpecSharpness, _ToonSpecOffset) * LightBase;

			#ifdef PASS_FB
				float3 SHToonSpec = ToonViewOffSpecularCalc(Normal, IN.shdir, View, _ToonSpecSharpness, _ToonSpecOffset) * IN.shmax;
				float3 VL0ToonSpec = ToonViewOffSpecularCalc(Normal, float3(IN.vldirX.x, IN.vldirY.x, IN.vldirZ.x), View, _ToonSpecSharpness, _ToonSpecOffset) * VLight0;
				float3 VL1ToonSpec = ToonViewOffSpecularCalc(Normal, float3(IN.vldirX.y, IN.vldirY.y, IN.vldirZ.y), View, _ToonSpecSharpness, _ToonSpecOffset) * VLight1;
				float3 VL2ToonSpec = ToonViewOffSpecularCalc(Normal, float3(IN.vldirX.z, IN.vldirY.z, IN.vldirZ.z), View, _ToonSpecSharpness, _ToonSpecOffset) * VLight2;
				float3 VL3ToonSpec = ToonViewOffSpecularCalc(Normal, float3(IN.vldirX.w, IN.vldirY.w, IN.vldirZ.w), View, _ToonSpecSharpness, _ToonSpecOffset) * VLight3;

				ToonSpec = (RLToonSpec + SHToonSpec + VL0ToonSpec + VL1ToonSpec + VL2ToonSpec + VL3ToonSpec) * _ToonSpecIntensity * ToonSpecColor;
			#endif
			#ifdef PASS_FA
				ToonSpec = RLToonSpec * _ToonSpecIntensity * ToonSpecColor;
			#endif
		OPT_FI
		#endif
	OPT_FI
	#endif

	#if WHEN_OPT(PROP_TOON_SPEC_ENABLE == 1)
	OPT_IF(_ToonSpecEnable)
		ToonSpecMask = UNITY_SAMPLE_TEX2D_SAMPLER(_ToonSpecMask, _MainTex, TRANSFORM_TEX(SubUV, _ToonSpecMask));
	OPT_FI
	#endif

	#if WHEN_OPT(PROP_REFLECTION_ENABLE == 1)
	OPT_IF(_ReflectionEnable)
//----スペキュラ反射
		       Smoothness   = tex2D(_MetallicGlossMap , SubUV).a * _GlossMapScale;
		       SpecularMask = tex2D(_MetallicGlossMap , SubUV).rgb;
		       SpecularMask = lerp(1.0f , SpecularMask , _SpecularMask);

		float3 RLSpecular   = SpecularCalc(Normal , IN.ldir , View , Smoothness);
		float3 SHSpecular   = (float3)0.0f;
		float  SpecularInt  = _Specular * ((Smoothness * Smoothness * Smoothness) + 0.25f);

		#ifdef PASS_FB
			if (_SpecularSH) SHSpecular = SpecularCalc(Normal , IN.shdir , View , Smoothness);
		#endif
		       RLSpecular  *= SpecularInt;
		       SHSpecular  *= SpecularInt;

//----トゥーンスペキュラ
		if (_ToonGlossEnable) {
		       RLSpecular   = ToonCalc(RLSpecular , Toon(_ToonGloss , 0.75f));
		       SHSpecular   = ToonCalc(SHSpecular , Toon(_ToonGloss , 0.75f));
		}
//----
		       Specular     = RLSpecular * LightBase + SHSpecular * SHLightBase;

//----環境マッピング
		       ReflectMask  = tex2D(_MetallicGlossMap , SubUV).rgb;
		       Reflection   = ReflectionCalc(WorldPos , Normal , View , Smoothness);

		if (_ReflectLit == 1) Reflection *= saturate(  LightBase + VLightBase);
		if (_ReflectLit == 2) Reflection *= saturate(SHLightBase);
		if (_ReflectLit == 3) Reflection *= saturate(  LightBase + SHLightBase + VLightBase);

//----マットキャップ
		       MatCapSmooth = UNITY_SAMPLE_TEX2D_SAMPLER(_MatCapMask , _MainTex , IN.uv).a;
		       MatCapMask   = UNITY_SAMPLE_TEX2D_SAMPLER(_MatCapMask , _MainTex , IN.uv).rgb;
		       MatCapSmooth = lerp(MatCapSmooth , tex2D(_MetallicGlossMap , SubUV).a , _MatCapMaskEnable);
		       MatCapMask   = lerp(MatCapMask   , ReflectMask                        , _MatCapMaskEnable);

		float3 MatCapV      = normalize(IN.vfront - View * dot(View, IN.vfront));
		float3 MatCapH      = normalize(cross(View , MatCapV));

		float2 MatCapUV     = float2(dot(MatCapH , Normal), dot(MatCapV , Normal)) * 0.5f + 0.5f;
		       MatCapture   = tex2Dbias(_MatCap , float4(MatCapUV , 0.0f , 3.0f * (1.0f - MatCapSmooth))).rgb * _MatCapStrength;

		if (_MatCapLit == 1) MatCapture *= saturate(  LightBase + VLightBase);
		if (_MatCapLit == 2) MatCapture *= saturate(SHLightBase);
		if (_MatCapLit == 3) MatCapture *= saturate(  LightBase + SHLightBase + VLightBase);

//----
	       Specular     = Specular   * SpecularMask * _GlossColor;
	       Reflection   = Reflection * SpecularMask * _GlossColor;
	       MatCapture   = MatCapture * MatCapMask   * _MatCapColor;

		#ifdef PASS_FA
			Reflection *= LightPower;
			MatCapture *= LightPower;
		#endif

		if (_SpecularTexColor ) Specular   *= Color;
		if (_MetallicTexColor ) Reflection *= Color;
		if (_MatCapTexColor   ) MatCapture *= Color;

	OPT_FI
	#endif

//-------------------------------------リムライティング
	float3 RimLight     = (float3)0.0f;
	#if WHEN_OPT(PROP_RIM_LIT_ENABLE == 1)
	OPT_IF(_RimLitEnable)
		       RimLight  = RimLightCalc(Normal , View , _RimLit , _RimLitGradient);
		       RimLight *= _RimLitColor.rgb * _RimLitColor.a * UNITY_SAMPLE_TEX2D_SAMPLER(_RimLitMask , _MainTex , SubUV).rgb;
		if (_RimLitTexColor ) RimLight *= Color;
		if (_RimLitLighthing) {
		       RimLight *= saturate(LightBase + SHLightBase + VLightBase);
		}
		#ifdef PASS_FA
			RimLight *= Lighting;
		#endif
	OPT_FI
	#endif

//-------------------------------------最終カラー計算
	       OUT.rgb      = Color * Lighting;
	       OUT.rgb      = lerp(OUT.rgb , Color , _Unlit);
	       OUT.rgb      = lerp(OUT.rgb , Reflection , _Metallic * ReflectMask);
	       OUT.rgb     += ToonSpec * ToonSpecMask.r;
	       OUT.rgb     += Specular;
	       OUT.rgb     += MatCapture;

//----リムライティング混合
	#if WHEN_OPT(PROP_RIM_LIT_ENABLE == 1)
	OPT_IF(_RimLitEnable)
		if (_RimLitMode == 0) OUT.rgb += RimLight;
		if (_RimLitMode == 1) OUT.rgb *= RimLight;
		if (_RimLitMode == 2) OUT.rgb  = saturate(OUT.rgb - RimLight);
	OPT_FI
	#endif

//----デカールエミッション混合
	if (_DecalEnable) {
		#ifdef PASS_FA
			if ((_DecalMode == 4) | (_DecalMode == 5)) DecalColor.rgb *= LightPower;
		#endif
		if (_DecalMode == 4) OUT.rgb += DecalColor.rgb * _DecalEmission;
		if (_DecalMode == 5) OUT.rgb += DecalColor.rgb * _DecalEmission;
	}

//----エミッション混合
	#if WHEN_OPT(PROP_EMISSION_ENABLE == 1)
	OPT_IF(_EmissionEnable)

		float EmissionRev   = MonoColor(LightBase);
		#ifdef PASS_FB
			EmissionRev += MonoColor(SHLightBase) + MonoColor(VLightBase);
		#endif

		      EmissionRev   = 1.0f - pow(saturate(EmissionRev) , 0.44964029f);
		      EmissionRev   = saturate((EmissionRev - _EmissionInTheDark + 0.1f) * 10.0f);
		      Emission     *= EmissionRev;

		if (_EmissionMode == 0) OUT.rgb += Emission;
		if (_EmissionMode == 1) {
			OUT.rgb *= saturate(1.0f - Emission);
			OUT.rgb += (lerp(Color , Reflection , (_Metallic * ReflectMask)) + ((Specular + MatCapture) * SpecularMask)) * Emission;
		}
		if (_EmissionMode == 2) OUT.rgb  = saturate(OUT.rgb - Emission);
	OPT_FI
	#endif

//----視差エミッション混合
	#if WHEN_OPT(PROP_PARALLAX_ENABLE == 1)
	OPT_IF(_ParallaxEnable)

		float ParallaxRev   = MonoColor(LightBase);
		#ifdef PASS_FB
			ParallaxRev += MonoColor(SHLightBase) + MonoColor(VLightBase);
		#endif

		      ParallaxRev   = 1.0f - pow(saturate(ParallaxRev) , 0.44964029f);
		      ParallaxRev   = saturate((ParallaxRev - _ParallaxInTheDark + 0.1f) * 10.0f);
		      Parallax     *= ParallaxRev;

		if (_ParallaxMode == 0) OUT.rgb += Parallax;
		if (_ParallaxMode == 1) {
			OUT.rgb *= saturate(1.0f - Parallax);
			OUT.rgb += (lerp(Color , Reflection , (_Metallic * ReflectMask)) + ((Specular + MatCapture) * SpecularMask)) * Parallax;
		}
		if (_ParallaxMode == 2) OUT.rgb  = saturate(OUT.rgb - Parallax);
	OPT_FI
	#endif

//----オクルージョンマスク
	if (_OcclusionMode == 2) OUT.rgb *= lerp(1.0f , UNITY_SAMPLE_TEX2D_SAMPLER(_OcclusionMap , _MainTex , SubUV).rgb , _OcclusionStrength);

//----エミッションのテクスチャアルファ無視
	#ifdef TRANSPARENT

		if (_EmissionEnable & _IgnoreTexAlphaE) {
			float EmissionAlpha    = MonoColor(Emission);
			OUT.a = saturate(OUT.a + EmissionAlpha  );
		}

//----視差エミッションのテクスチャアルファ無視
		if (_ParallaxEnable & _IgnoreTexAlphaPE) {
			float ParallaxAlpha    = MonoColor(Parallax);
			OUT.a = saturate(OUT.a + ParallaxAlpha  );
		}

//----リフレクションのテクスチャアルファ無視
		if (_ReflectionEnable & _IgnoreTexAlphaR) {
			float ReflectionAlpha  = 0.0f;
			      ReflectionAlpha += MonoColor(Reflection) * ReflectMask * _Metallic;
			      ReflectionAlpha += MonoColor(Specular)   * SpecularMask;
			      ReflectionAlpha += MonoColor(MatCapture) * ReflectMask;
			OUT.a = saturate(OUT.a + ReflectionAlpha);
		}

//----リムライトのテクスチャアルファ無視
		if (_RimLitEnable & _IgnoreTexAlphaRL) {
			float RimLightAlpha    = MonoColor(RimLight);
			OUT.a = saturate(OUT.a + RimLightAlpha  );
		}

	#endif

//-------------------------------------出力オプション
//----ガンマ修正
	if (_EnableGammaFix) {
		_GammaR = max(_GammaR , 0.00001f);
		_GammaG = max(_GammaG , 0.00001f);
		_GammaB = max(_GammaB , 0.00001f);

	       OUT.r    = pow(OUT.r , 1.0f / (1.0f / _GammaR));
	       OUT.g    = pow(OUT.g , 1.0f / (1.0f / _GammaG));
	       OUT.b    = pow(OUT.b , 1.0f / (1.0f / _GammaB));
	}

//----明度修正
	if (_EnableBlightFix) {
	       OUT.rgb *= _BlightOutput;
	       OUT.rgb  = max(OUT.rgb + _BlightOffset , 0.0f);
	}

//----出力リミッタ
	if (_LimitterEnable) {
	       OUT.rgb  = min(OUT.rgb , _LimitterMax);
	}

//----BlendOpの代用
	#ifdef PASS_FA
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
