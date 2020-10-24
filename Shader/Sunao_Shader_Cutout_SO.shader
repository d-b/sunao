//--------------------------------------------------------------
//              Sunao Shader    Ver 1.4.2
//
//                      Copyright (c) 2021 揚茄子研究所
//                              Twitter : @SUNAO_VRC
//                              VRChat  : SUNAO_
//
// This software is released under the MIT License.
// see LICENSE or http://suna.ooo/agenasulab/ss/LICENSE
//--------------------------------------------------------------

Shader "Sunao Shader/[Stencil Outline]/Cutout" {


	Properties {
		[SToggle]
		_OptimizerEnable   ("Enable Optimizer"  				, int) = 0

		[NoScaleOffset]
		_MainTex           ("Main Texture"              , 2D) = "white" {}
		_Color             ("Color"                     , Color) = (1,1,1,1)
		_Alpha             ("Alpha"                     , Range( 0.0,  2.0)) = 1.0
		_Cutout            ("Cutout"                    , Range( 0.0,  1.0)) = 0.5

		[Normal]
		_BumpMap           ("Normal Map"                , 2D) = "bump" {}
		[NoScaleOffset]
		_OcclusionMap      ("Occlusion"                 , 2D) = "white" {}
		[NoScaleOffset]
		_AlphaMask         ("Alpha Mask"                , 2D) = "white" {}

		_Bright            ("Brightness"                , Range( 0.0,  1.0)) = 1.0
		_BumpScale         ("Normal Map Scale"          , Range(-2.0,  2.0)) = 1.0
		_OcclusionStrength ("Occlusion Strength"        , Range( 0.0,  1.0)) = 1.0
		[Enum(SH Light, 0 , Main Texture , 1 , Final Color , 2)]
		_OcclusionMode     ("Occlusion Mode    "        , int) = 0
		_AlphaMaskStrength ("Alpha Mask Strength"       , Range( 0.0,  1.0)) = 1.0
		[SToggle]
		_VertexColor       ("Use Vertex Color"          , int) = 0

		_UVScrollX         ("Scroll X"                  , Range(-10.0, 10.0)) = 0.0
		_UVScrollY         ("Scroll Y"                  , Range(-10.0, 10.0)) = 0.0
		_UVAnimation       ("Animation Speed"           , Range(  0.0, 10.0)) = 0.0
		_UVAnimX           ("Animation X Size"          , int) = 1
		_UVAnimY           ("Animation Y Size"          , int) = 1
		[SToggle]
		_UVAnimOtherTex    ("Animation Other Maps"      , int) = 1


		[SToggle]
		_DecalEnable       ("Enable Decal"              , int) = 0
		_DecalTex          ("Decal Texture"             , 2D) = "white" {}
		_DecalColor        ("Decal Color"               , Color) = (1,1,1,1)
		_DecalPosX         ("Position X"                , Range( 0.0, 1.0)) = 0.5
		_DecalPosY         ("Position Y"                , Range( 0.0, 1.0)) = 0.5
		_DecalSizeX        ("Size X"                    , Range( 0.0, 1.0)) = 0.5
		_DecalSizeY        ("Size Y"                    , Range( 0.0, 1.0)) = 0.5
		_DecalRotation     ("Rotation"                  , Range(-180.0, 180.0)) = 0.0

		[Enum(Override , 0 , Add , 1 , Multiply , 2 , Multiply(Mono) , 3)]
		_DecalMode         ("Decal Mode"                , int) = 0
		[Enum(Normal , 0 , Fixed , 1 , Mirror1 , 2 , Mirror2 , 3 , Copy(Mirror) , 4 , Copy(Fixed) , 5)]
		_DecalMirror       ("Decal Mirror Mode"         , int) = 0

		_DecalScrollX      ("Scroll X"                  , Range(-10.0, 10.0)) = 0.0
		_DecalScrollY      ("Scroll Y"                  , Range(-10.0, 10.0)) = 0.0
		_DecalAnimation    ("Animation Speed"           , Range(  0.0, 10.0)) = 0.0
		_DecalAnimX        ("Animation X Size"          , int) = 1
		_DecalAnimY        ("Animation Y Size"          , int) = 1


		_StencilNumb       ("Stencil Number"            , int) = 2
		[Enum(NotEqual , 6 , Equal , 3 , Less , 2 , LessEqual , 4 , Greater , 5 , GreaterEqual , 7)]
		_StencilCompMode   ("Stencil Compare Mode"      , int) = 6


		[NoScaleOffset]
		_ShadeMask         ("Shade Mask"                , 2D) = "white" {}
		_Shade             ("Shade Strength"            , Range( 0.0,  1.0)) = 0.3
		_ShadeWidth        ("Shade Width"               , Range( 0.0,  2.0)) = 0.75
		_ShadeGradient     ("Shade Gradient"            , Range( 0.0,  2.0)) = 0.75
		_ShadeColor        ("Shade Color"               , Range( 0.0,  1.0)) = 0.5
		_CustomShadeColor  ("Custom Shade Color"        , Color) = (0,0,0,0)

		[SToggle]
		_ToonEnable        ("Enable Toon Shading"       , int) = 0
		[IntRange]
		_Toon              ("Toon"                      , Range( 0.0,  9.0)) = 9.0
		_ToonSharpness     ("Toon Sharpness"            , Range( 0.0,  1.0)) = 1.0

		[NoScaleOffset]
		_LightMask         ("Lighting Boost Mask"       , 2D) = "black" {}
		_LightBoost        ("Lighting Boost"            , Range( 1.0,  5.0)) = 3.0
		_Unlit             ("Unlighting"                , Range( 0.0,  1.0)) = 0.0
		[SToggle]
		_MonochromeLit     ("Monochrome Lighting"       , int) = 0


		[SToggle]
		_MirrorControlEnable ("Enable Mirror Control" , int) = 0
		_RealCopyAlpha	   ("Real Copy Alpha"           , Range( 0.0,  1.0)) = 1.0
		_MirrorCopyAlpha	 ("Mirror Copy Alpha"         , Range( 0.0,  1.0)) = 1.0


		[SToggle]
		_HSVShiftEnable    ("Enable HSV Shift"          , int) = 0
		_HSVShiftMask      ("HSV Shift Mask"            , 2D) = "white" {}
		_HSVShiftHue  		 ("Hue Shift"                 , Range( 0.0,  1.0)) = 0.0
		_HSVShiftSat	  	 ("Sat Shift"                 , Range( 0.0,  3.0)) = 1.0
		_HSVShiftVal	  	 ("Val Shift"                 , Range( 0.0,  3.0)) = 1.0
		[Enum(None , 0 , Mask , 1 , All , 2)]
		_HSVShiftBaseMode	("Base Mode"   								, int) = 1
		[Enum(None , 0 , Mask , 1 , All , 2)]
		_HSVShiftShadeMode	("Shade Mode"   						, int) = 0
		[Enum(None , 0 , Mask , 1 , All , 2)]
		_HSVShiftEmissionMode	("Emission Mode" 					, int) = 0
		[Enum(None , 0 , Mask , 1 , All , 2)]
		_HSVShiftOutlineMode ("Outline Mode"        		, int) = 0
		[Enum(None , 0 , Mask , 1 , All , 2)]
		_HSVShiftRimMode ("Rim Mode"        						, int) = 0
		[Enum(None , 0 , Mask , 1 , All , 2)]
		_HSVShiftParallaxMode ("Parallax Mode"					, int) = 0
		[Enum(None , 0 , Mask , 1 , All , 2)]
		_HSVShiftStippleMode ("Stipple Mode"     				, int) = 0
		[Enum(None , 0 , Mask , 1 , All , 2)]
		_HSVShiftCrosshatchMode ("Crosshatch Mode"			, int) = 0


		[SToggle]
		_StippleEnable     ("Enable Stippling"          , int) = 0
		_StippleMask       ("Stipple Mask"              , 2D) = "white" {}
		_StippleTexture    ("Stipple Texture"           , 2D) = "black" {}
		_StippleEmissionMap ("Stipple Emission Mask"    , 2D) = "black" {}
		_StippleSize  		 ("Stipple Size"              , Range( 0.0,  1.0)) = 0.5
		_StippleAmount		 ("Stipple Amount"            , Range( 0.0,  1.0)) = 0.5
		[Enum(Uniform , 0 , Wave , 1)]
		_StippleMode       ("Stipple Mode"              , int) = 1
		_StippleAnimation  ("Stipple Animation"         , Range(0.0, 1.0)) = 0.0
		_StippleSpeed      ("Stipple Speed"             , Range(0.0, 50.0)) = 1.0
		_StippleFrequency  ("Stipple Frequency"         , Range(0.0, 200.0)) = 30.0
		[SToggle]
		_StippleDisableOutline ("Stipple Disable Outline", int) = 1
		[SToggle]
		_CrosshatchEnable  ("Enable Crosshatching"      , int) = 0
		_CrosshatchMask    ("Crosshatch Mask"           , 2D) = "white" {}
		_CrosshatchTexture ("Crosshatch Texture"        , 2D) = "black" {}
		_CrosshatchEmissionMap ("Crosshatch Emission Mask", 2D) = "black" {}
		_CrosshatchAmount  ("Crosshatch Amount"         , Range( 0.0,  1.0)) = 0.5


		_VertexColorThreshold ("Vertex Alpha 1", Range(0.0,  1.0)) = 0.9999
		_VertexColor01  	 ("Vertex Color 1"            , Color) = (0,0,0)
		_VertexAlpha01  	 ("Vertex Alpha 1"            , Range(0.0,  1.0)) = 1.0
		_VertexColor02  	 ("Vertex Color 2"            , Color) = (0,0,0)
		_VertexAlpha02  	 ("Vertex Alpha 2"            , Range(0.0,  1.0)) = 1.0
		_VertexColor03  	 ("Vertex Color 3"            , Color) = (0,0,0)
		_VertexAlpha03  	 ("Vertex Alpha 3"            , Range(0.0,  1.0)) = 1.0
		_VertexColor04  	 ("Vertex Color 4"            , Color) = (0,0,0)
		_VertexAlpha04  	 ("Vertex Alpha 4"            , Range(0.0,  1.0)) = 1.0
		_VertexColor05  	 ("Vertex Color 5"            , Color) = (0,0,0)
		_VertexAlpha05  	 ("Vertex Alpha 5"            , Range(0.0,  1.0)) = 1.0
		_VertexColor06  	 ("Vertex Color 6"            , Color) = (0,0,0)
		_VertexAlpha06  	 ("Vertex Alpha 6"            , Range(0.0,  1.0)) = 1.0
		_VertexColor07  	 ("Vertex Color 7"            , Color) = (0,0,0)
		_VertexAlpha07  	 ("Vertex Alpha 7"            , Range(0.0,  1.0)) = 1.0
		_VertexColor08  	 ("Vertex Color 8"            , Color) = (0,0,0)
		_VertexAlpha08  	 ("Vertex Alpha 8"            , Range(0.0,  1.0)) = 1.0
		_VertexColor09  	 ("Vertex Color 9"            , Color) = (0,0,0)
		_VertexAlpha09  	 ("Vertex Alpha 9"            , Range(0.0,  1.0)) = 1.0
		_VertexColor10  	 ("Vertex Color 10"            , Color) = (0,0,0)
		_VertexAlpha10  	 ("Vertex Alpha 10"            , Range(0.0,  1.0)) = 1.0
		_VertexColor11  	 ("Vertex Color 11"            , Color) = (0,0,0)
		_VertexAlpha11  	 ("Vertex Alpha 11"            , Range(0.0,  1.0)) = 1.0
		_VertexColor12  	 ("Vertex Color 12"            , Color) = (0,0,0)
		_VertexAlpha12  	 ("Vertex Alpha 12"            , Range(0.0,  1.0)) = 1.0
		_VertexColor13  	 ("Vertex Color 13"            , Color) = (0,0,0)
		_VertexAlpha13  	 ("Vertex Alpha 13"            , Range(0.0,  1.0)) = 1.0
		_VertexColor14  	 ("Vertex Color 14"            , Color) = (0,0,0)
		_VertexAlpha14  	 ("Vertex Alpha 14"            , Range(0.0,  1.0)) = 1.0
		_VertexColor15  	 ("Vertex Color 15"            , Color) = (0,0,0)
		_VertexAlpha15  	 ("Vertex Alpha 15"            , Range(0.0,  1.0)) = 1.0
		_VertexColor16  	 ("Vertex Color 16"            , Color) = (0,0,0)
		_VertexAlpha16  	 ("Vertex Alpha 16"            , Range(0.0,  1.0)) = 1.0


		[SToggle]
		_OutLineEnable     ("Enable Outline"            , int) = 0
		[NoScaleOffset]
		_OutLineMask       ("Outline Mask"              , 2D) = "white" {}
		_OutLineColor      ("Outline Color"             , Color) = (0,0,0,1)
		_OutLineSize       ("Outline Scale"             , Range( 0.0,  1.0)) = 0.1
		[SToggle]
		_OutLineLighthing  ("Use Light Color"           , int) = 1
		[SToggle]
		_OutLineTexColor   ("Use Main Texture"          , int) = 0
		[NoScaleOffset]
		_OutLineTexture    ("Outline Texture"           , 2D) = "white" {}
		[SToggle]
		_OutLineFixScale   ("x10 Scale"                 , int) = 0


		[SToggle]
		_EmissionEnable    ("Enable Emission"           , int) = 0
		_EmissionMap       ("Emission Mask"             , 2D) = "white" {}
		[HDR]
		_EmissionColor     ("Emission Color"            , Color) = (1,1,1)
		_Emission          ("Emission Intensity"        , Range( 0.0,  2.0)) = 1.0

		_EmissionMap2      ("2nd Emission Mask"         , 2D) = "white" {}
		[Enum(Add , 0 ,Multiply , 1 , Minus , 2)]
		_EmissionMode      ("Emission Mode"             , int) = 0
		_EmissionBlink     ("Blink"                     , Range( 0.0,  1.0)) = 0.0
		_EmissionFrequency ("Frequency"                 , Range( 0.0,  5.0)) = 1.0
		[Enum(Sine , 0 , Saw , 1 , SawR , 2 , Square , 3)]
		_EmissionWaveform  ("Waveform"                  , int) = 0
		_EmissionScrX      ("Scroll X"                  , Range(-10.0, 10.0)) = 0.0
		_EmissionScrY      ("Scroll Y"                  , Range(-10.0, 10.0)) = 0.0
		_EmissionAnimation ("Animation Speed"           , Range(  0.0, 10.0)) = 0.0
		_EmissionAnimX     ("Animation X Size"          , int) = 1
		_EmissionAnimY     ("Animation Y Size"          , int) = 1

		[SToggle]
		_EmissionLighting  ("Use Lighting"              , int) = 0
		[SToggle]
		_IgnoreTexAlphaE   ("Ignore Texture Alpha"      , int) = 0
		_EmissionInTheDark ("Only in the Dark"          , Range(  0.0,  1.0)) = 0.0


		[SToggle]
		_ParallaxEnable    ("Enable Parallax Emission"  , int) = 0
		_ParallaxMap       ("Parallax Emission Texture" , 2D) = "white" {}
		[HDR]
		_ParallaxColor     ("Emission Color"            , Color) = (1,1,1)
		_ParallaxEmission  ("Emission Intensity"        , Range( 0.0,  2.0)) = 1.0
		_ParallaxDepth     ("Parallax Depth"            , Range( 0.0,  1.0)) = 1.0

		_ParallaxDepthMap  ("Parallax Depth Mask"       , 2D) = "black" {}
		_ParallaxMap2      ("2nd Parallax Emission Mask", 2D) = "white" {}
		[Enum(Add , 0 ,Multiply , 1 , Minus , 2)]
		_ParallaxMode      ("Emission Mode"             , int) = 0
		_ParallaxBlink     ("Blink"                     , Range( 0.0,  1.0)) = 0.0
		_ParallaxFrequency ("Frequency"                 , Range( 0.0,  5.0)) = 1.0
		[Enum(Sine , 0 , Saw , 1 , SawR , 2 , Square , 3)]
		_ParallaxWaveform  ("Waveform"                  , int) = 0
		_ParallaxPhaseOfs  ("Phase Offset"              , Range( 0.0,   1.0)) = 0.0
		_ParallaxScrX      ("Scroll X"                  , Range(-10.0, 10.0)) = 0.0
		_ParallaxScrY      ("Scroll Y"                  , Range(-10.0, 10.0)) = 0.0
		_ParallaxAnimation ("Animation Speed"           , Range(  0.0, 10.0)) = 0.0
		_ParallaxAnimX     ("Animation X Size"          , int) = 1
		_ParallaxAnimY     ("Animation Y Size"          , int) = 1

		[SToggle]
		_ParallaxLighting  ("Use Lighting"              , int) = 0
		[SToggle]
		_IgnoreTexAlphaPE  ("Ignore Texture Alpha"      , int) = 0
		_ParallaxInTheDark ("Only in the Dark"          , Range(  0.0,  1.0)) = 0.0


		[SToggle]
		_ReflectionEnable  ("Enable Reflection"         , int) = 0
		[NoScaleOffset]
		_MetallicGlossMap  ("Reflection Mask"           , 2D) = "white" {}
		_GlossColor        ("Reflection Color"          , Color) = (1,1,1,1)
		_Specular          ("Specular Intensity"        , Range( 0.0,  2.0)) = 1.0
		_Metallic          ("Metallic"                  , Range( 0.0,  1.0)) = 0.5
		_GlossMapScale     ("Smoothness"                , Range( 0.0,  1.0)) = 0.75
		[NoScaleOffset]
		_MatCap            ("MatCap Texture"            , 2D) = "black" {}
		_MatCapColor       ("MatCap Color"              , Color) = (1,1,1,1)
		[SToggle]
		_MatCapMaskEnable  ("Use Reflection Mask"       , int) = 1
		[NoScaleOffset]
		_MatCapMask        ("MatCap Mask"               , 2D) = "white" {}
		_MatCapStrength    ("MatCap Strength"           , Range( 0.0,  2.0)) = 1.0
		[SToggle]
		_ToonGlossEnable   ("Enable Toon Reflection"    , int) = 0
		[IntRange]
		_ToonGloss         ("Toon"                      , Range( 0.0,  9.0)) = 9.0
		[SToggle]
		_SpecularTexColor  ("Tex Color for Specular"    , int) = 0
		[SToggle]
		_MetallicTexColor  ("Tex Color for Metallic"    , int) = 1
		[SToggle]
		_MatCapTexColor    ("Tex Color for MatCap"      , int) = 0
		[SToggle]
		_SpecularSH        ("SH Light Specular"         , int) = 1
		[SToggle]
		_SpecularMask      ("Use Mask for Specular"     , int) = 1
		[Enum(None , 0 , RealTime , 1 , SH , 2 , Both , 3)]
		_ReflectLit        ("Light Color for Reflection", int) = 3
		[Enum(None , 0 , RealTime , 1 , SH , 2 , Both , 3)]
		_MatCapLit         ("Light Color for MatCap"    , int) = 3
		[SToggle]
		_IgnoreTexAlphaR   ("Ignore Texture Alpha"      , int) = 0


		[SToggle]
		_RimLitEnable      ("Enable Rim Light"          , int) = 0
		[NoScaleOffset]
		_RimLitMask        ("Rim Light Mask"            , 2D) = "white" {}
		[HDR]
		_RimLitColor       ("Rim Light Color"           , Color) = (1,1,1,1)
		_RimLit            ("Rim Lighting"              , Range( 0.0,  2.0)) = 1.0
		_RimLitGradient    ("Rim Light Gradient"        , Range( 0.0,  2.0)) = 1.0
		[SToggle]
		_RimLitLighthing   ("Use Light Color"           , int) = 1
		[SToggle]
		_RimLitTexColor    ("Use Main Texture"          , int) = 0
		[Enum(Add , 0 , Multiply , 1 , Minus , 2)]
		_RimLitMode        ("Rim Light Mode"            , int) = 0
		[SToggle]
		_IgnoreTexAlphaRL  ("Ignore Texture Alpha"      , int) = 0


		[Enum(Off , 0 , Back , 2 , Front , 1)]
		_Culling           ("Culling"                   , int) = 0

		[SToggle]
		_EnableZWrite      ("Enable Z Write"            , int) = 1

		_DirectionalLight  ("Directional Light"         , Range( 0.0,  2.0)) = 1.0
		_SHLight           ("SH Light"                  , Range( 0.0,  2.0)) = 1.0
		_PointLight        ("Point Light"               , Range( 0.0,  2.0)) = 1.0
		[SToggle]
		_LightLimitter     ("Light Limitter"            , int) = 1
		_MinimumLight      ("Minimum Light Limit"       , Range( 0.0,  1.0)) = 0.0
		[Enum(Add , 0 , Max , 4)]
		_BlendOperation    ("ForwardAdd Blend Mode"     , int) = 4

		[SToggle]
		_EnableGammaFix    ("Enable Gamma Fix"          , int) = 0
		_GammaR            ("R Gamma"                   , Range( 0.0,  5.0)) = 1.0
		_GammaG            ("G Gamma"                   , Range( 0.0,  5.0)) = 1.0
		_GammaB            ("B Gamma"                   , Range( 0.0,  5.0)) = 1.0

		[SToggle]
		_EnableBlightFix   ("Enable Brightness Fix"     , int) = 0
		_BlightOutput      ("Output Brightness"         , Range( 0.0,  5.0)) = 1.0
		_BlightOffset      ("Brightness Offset"         , Range(-5.0,  5.0)) = 0.0

		[SToggle]
		_LimitterEnable    ("Enable Limitter"           , int) = 0
		_LimitterMax       ("Limitter Max"              , Range( 0.0,  5.0)) = 1.0


		[HideInInspector] _MainFO          ("Main FO"           , int) = 0
		[HideInInspector] _DecalFO         ("Decal FO"          , int) = 0
		[HideInInspector] _ShadingFO       ("Shading FO"        , int) = 0
		[HideInInspector] _OutlineFO       ("Outline FO"        , int) = 0
		[HideInInspector] _EmissionFO      ("Emission FO"       , int) = 0
		[HideInInspector] _ParallaxFO      ("Parallax FO"       , int) = 0
		[HideInInspector] _ReflectionFO    ("Reflection FO"     , int) = 0
		[HideInInspector] _RimLightingFO   ("Rim Lighting FO"   , int) = 0
		[HideInInspector] _VertexAlphaFO   ("Vertex Alpha FO"   , int) = 0
		[HideInInspector] _OtherSettingsFO ("Other Settings FO" , int) = 0

		[HideInInspector] _SunaoShaderType ("ShaderType"        , int) = 5

		[HideInInspector] _VersionH        ("Version H"         , int) = 1
		[HideInInspector] _VersionM        ("Version M"         , int) = 4
		[HideInInspector] _VersionL        ("Version L"         , int) = 2

	}



	SubShader {

		LOD 0

		Tags {
			"IgnoreProjector" = "True"
			"RenderType"      = "TransparentCutout"
			"Queue"           = "AlphaTest"
		}


		Pass {
			Tags {
				"LightMode"  = "ForwardBase"
			}

			Cull [_Culling]
			ZWrite [_EnableZWrite]

			Stencil {
				Ref  [_StencilNumb]
				Comp Always
				Pass Replace
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma target 4.5

			#define PASS_FB
			#define CUTOUT

			#include "./cginc/SunaoShader_Core.cginc"

			ENDCG
		}


		Pass {
			Tags {
				"LightMode"  = "ForwardBase"
			}

			Cull Front
			ZWrite [_EnableZWrite]

			Stencil {
				Ref  [_StencilNumb]
				Comp NotEqual
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma target 4.5

			#define PASS_OL_FB
			#define CUTOUT

			#include "./cginc/SunaoShader_OL.cginc"

			ENDCG
		}


		Pass {
			Tags {
				"LightMode"  = "ForwardAdd"
			}

			Cull [_Culling]
			BlendOp [_BlendOperation]
			Blend One One
			ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdadd
			#pragma multi_compile_fog
			#pragma target 4.5

			#define PASS_FA
			#define CUTOUT

			#include "./cginc/SunaoShader_Core.cginc"

			ENDCG
		}


		Pass {
			Tags {
				"LightMode"  = "ForwardAdd"
			}

			Cull Front
			BlendOp [_BlendOperation]
			Blend One One
			ZWrite Off

			Stencil {
				Ref  [_StencilNumb]
				Comp NotEqual
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdadd
			#pragma multi_compile_fog
			#pragma target 4.5

			#define PASS_OL_FA
			#define CUTOUT

			#include "./cginc/SunaoShader_OL.cginc"

			ENDCG
		}


		Pass {
			Tags {
				"LightMode" = "ShadowCaster"
			}

			ZWrite On
			ZTest LEqual

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#pragma target 4.5

			#define PASS_SC
			#define CUTOUT

			#include "./cginc/SunaoShader_SC.cginc"

			ENDCG
		}
	}

	FallBack "Transparent/Cutout/Diffuse"

	CustomEditor "SunaoShader.GUI"
}
