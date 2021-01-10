//--------------------------------------------------------------
//              Sunao Shader Function
//                      Copyright (c) 2021 揚茄子研究所
//--------------------------------------------------------------

//-------------------------------------Multiply quaternions
float4 MultQuat(float4 q1, float4 q2)
{
  return float4(
    q1.w * q2.x + q1.x * q2.w + q1.z * q2.y - q1.y * q2.z,
    q1.w * q2.y + q1.y * q2.w + q1.x * q2.z - q1.z * q2.x,
    q1.w * q2.z + q1.z * q2.w + q1.y * q2.x - q1.x * q2.y,
    q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z
  );
}

//-------------------------------------Rotate by quaternion
float3 QuatRotate(float4 q, float3 v)
{
  return v + 2.0 * cross(cross(v, q.xyz) + q.w * v, q.xyz);
}

//-------------------------------------モノクロカラーに変換
float  MonoColor(float3 col) {
	return (0.2126f * col.r) + (0.7152f * col.g) + (0.0722f * col.b); //BT.709
}

//-------------------------------------SHライトの方向を取得
float3 SHLightDirection(float len[6]) {
	return normalize(float3(len[1] - len[0] , len[3] - len[2] , len[5] - len[4]));
}

//-------------------------------------明るいSHライトを取得
float3 SHLightMax(float3 col[6]) {
	float3 ocol;
	ocol =            col[0];
	ocol = max(ocol , col[1]);
	ocol = max(ocol , col[2]);
	ocol = max(ocol , col[3]);
	ocol = max(ocol , col[4]);
	ocol = max(ocol , col[5]);

	return ocol;
}

//-------------------------------------暗いSHライトを取得
float3 SHLightMin(float3 col[6]) {
	float3 ocol;
	ocol  = col[0] + col[1] + col[2] + col[3] + col[4] + col[5];
	ocol *= 0.166667f;	// 0.166667 = 1/6

	float zcol;
	zcol  = MonoColor(abs(col[1] - col[0]) + abs(col[3] - col[2]) + abs(col[5] - col[4]));
	zcol  = saturate(zcol);

	ocol  = lerp(ocol * 0.75f , ocol , zcol);

	return ocol;
}

//-------------------------------------頂点ライトの距離を計算
float4 VLightLength(float4 x , float4 y , float4 z) {
	return max((x * x) + (y * y) + (z * z) , 0.000001f);
}

//-------------------------------------頂点ライトの減衰を計算
float4 VLightAtten(float4 len) {
	float4 atten;
	atten = 1.0f / (1.0f + len * unity_4LightAtten0);
	atten = pow(atten , max(0.075f / atten , 1.0f));

	return atten;
}

//-------------------------------------トゥーンパラメータの計算
float4 Toon(uint toon , float gradient) {
	float4 otoon;
	otoon.x  = max(float(11 - toon) , 2.0f);
	otoon.y  = 1.0f / (otoon.x - 1.0f);
	otoon.z  = 0.5f /  otoon.x;
	otoon.w  = pow(1.0f + (gradient * gradient * gradient) , 10.0f);

	return otoon;
}

//-------------------------------------2つのUVトランスフォームを混合
float2 MixingTransformTex(float2 uv , float4 st0 , float4 st1) {
	return (uv * st0.xy * st1.xy) + st0.zw  + st1.zw;
}

//-------------------------------------エミッション時間変化パラメータの計算
float2 EmissionWave(uint mode , float blink , float freq , float offset) {
	float wave = 0.0f;

	if (mode == 0) wave = (1.0f - (blink * 0.5f)) + cos((_Time.y * freq + offset) * 6.283185f) * blink * 0.5f; // 6.283185 = 2π
	if (mode == 1) wave = (1.0f - blink) + (frac(_Time.y * freq + offset) * blink);
	if (mode == 2) wave = (1.0f - blink) + (1.0f - frac(_Time.y * freq + offset) * blink);
	if (mode == 3) wave = (1.0f - blink) + (step(0.5f , frac(_Time.y * freq + offset)) * blink);

	return wave;
}

//-------------------------------------ディフューズシェーディングの計算
float  DiffuseCalc(float3 normal , float3 ldir , float gradient , float width) {
	float Diffuse;
	Diffuse = ((dot(normal , ldir) - 0.5f) * (gradient + 0.000001f)) + 1.5f - width;

	return saturate(Diffuse);
}

//-------------------------------------トゥーンシェーディングの計算
float  ToonCalc(float diffuse , float4 toon) {

	float Diffuse;
	float Gradient;

	Gradient = frac((max(diffuse , 0.0000001f) + toon.z) * toon.x) - 0.5f;
	Gradient = saturate(Gradient * toon.w + 0.5f) + 0.5f;
	Gradient = (frac(Gradient) - 0.5f) * toon.y;
	Diffuse  = floor(diffuse * toon.x) * toon.y + Gradient;

	return saturate(Diffuse);
}

//-------------------------------------ライトの計算
float3 LightingCalc(float3 light , float diffuse , float3 shadecol , float shademask) {
	float3 ocol;
	ocol = lerp(light * shadecol , light, diffuse  );
	ocol = lerp(light            , ocol  , shademask);

	return ocol;
}

//-------------------------------------スペキュラ反射の計算
float3 SpecularCalc(float3 normal , float3 ldir , float3 view , float scale) {
	float3 hv = normalize(ldir  + view);
	float  specular;
	specular = pow(saturate(dot(hv , normal)) , (1.0f / (1.005f - scale))) * (scale * scale * scale + 0.5f);
	specular = saturate(specular * specular * specular);

	return specular;
}

//-------------------------------------GGX Anisotropic NDF
float D_GGX_Anisotropic(float at, float ab, float TdotH, float BdotH, float NdotH) {
  // Burley 2012, "Physically-Based Shading at Disney"

  // The values at and ab are perceptualRoughness^2, a2 is therefore perceptualRoughness^4
  // The dot product below computes perceptualRoughness^8. We cannot fit in fp16 without clamping
  // the roughness to too high values so we perform the dot product and the division in fp32
  float a2 = at * ab;
  float3 d = float3(ab * TdotH, at * BdotH, a2 * NdotH);
  float d2 = dot(d, d);
  float b2 = a2 / d2;
  return a2 * b2 * b2 * (1.0 / UNITY_PI);
}

//-------------------------------------GGX Anisotropic visibility function
float V_SmithGGXCorrelated_Anisotropic(float at, float ab, float TdotV, float BdotV, float TdotL, float BdotL, float NdotV, float NdotL) {
  // Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
  float lambdaV = NdotL * length(float3(at * TdotV, ab * BdotV, NdotV));
  float lambdaL = NdotV * length(float3(at * TdotL, ab * BdotL, NdotL));
  return 0.5 / (lambdaV + lambdaL);
}

//-------------------------------------GGX Anisotropic model
float3 ToonAnisoSpecularCalc(float3 normal, float3 tangent, float3 bitangent, float3 ldir, float3 view, float roughnessT, float roughnessB) {
  float3 hv = normalize(ldir + view);

  float NdotL = saturate(dot(normal, ldir));
  float NdotH = saturate(dot(normal, hv));

  float TdotH = dot(tangent, hv);
  float BdotH = dot(bitangent, hv);

  float D = D_GGX_Anisotropic(roughnessT, roughnessB, TdotH, BdotH, NdotH);

  return saturate(D * NdotL);
}

//-------------------------------------View + offset based specular
float3 ToonViewOffSpecularCalc(float3 normal, float3 ldir, float3 view, float sharpness, float offset) {
  float NdotL = dot(ldir + view, normal);
  float NdotVO = dot(view + float3(0.0, offset, 0.0), normal);

  return saturate(pow(sqrt(1.0 - NdotVO * NdotVO), sharpness) * NdotL);
}

//-------------------------------------環境マッピングの計算
float3 ReflectionCalc(float3 normal , float3 view , float scale) {
	float3 dir = reflect(-view , normal);
	float3 ocol;
	float3 refl0;
	float3 refl1;
	refl0 = DecodeHDR(UNITY_SAMPLE_TEXCUBE_LOD        (unity_SpecCube0                  , dir, (1.0f - scale) * 7.0f) , unity_SpecCube0_HDR);
	refl1 = DecodeHDR(UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube1, unity_SpecCube0 , dir, (1.0f - scale) * 7.0f) , unity_SpecCube1_HDR);
	ocol  = lerp(refl1 , refl0 , unity_SpecCube0_BoxMin.w);
	
	return ocol;
}

//-------------------------------------リムライトの計算
float  RimLightCalc(float3 normal , float3 view , float power , float gradient) {
	float orim;
	orim  = saturate(1.0f - abs(dot(view , normal)));
	orim *= orim;
	orim  = saturate(((orim - 0.5f) * gradient * gradient * gradient) + 0.5f);
	orim  = saturate(orim + ((power * 0.5f) - 0.5f) * 2.0f);

	return orim;
}

//-------------------------------------RGB to HSV
float3 RGB2HSV(float3 c) {
  half4 K = half4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  half4 p = lerp(half4(c.bg, K.wz), half4(c.gb, K.xy), step(c.b, c.g));
  half4 q = lerp(half4(p.xyw, c.r), half4(c.r, p.yzx), step(p.x, c.r));

  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

//-------------------------------------HSV to RGB
float3 HSV2RGB(float3 c) {
  half4 K = half4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

//-------------------------------------Adjust a colour by HSV offset
float3 HSVAdjust(float3 color, float3 adjustment) {
  float3 hsv = RGB2HSV(color);
  hsv.x += fmod(adjustment.x, 360);
  hsv.y = saturate(hsv.y * adjustment.y);
  hsv.z *= adjustment.z;
  return HSV2RGB(hsv);
}

//-------------------------------------Linear to SRGB
float LIN2SRGB(float color) {
    if (color > 0.0031308)
        return 1.055 * (pow(color, (1.0 / 2.4))) - 0.055;
    else
        return 12.92 * color;
}

//-------------------------------------RGB linear to SRGB
float3 LIN2SRGB(float3 color) {
  return float3(LIN2SRGB(color.r), LIN2SRGB(color.g), LIN2SRGB(color.b));
}

//-------------------------------------Vertex colour based alpha
float VertexAlpha(float3 color, float3 comperand, float alpha, float threshold) {
	if (min(length(color), length(comperand)) > 0.0) {
		return lerp(1.0, alpha, step(threshold, 1.0 - length(color - LIN2SRGB(comperand))));
	} else {
		return 1.0;
	}
}

//-------------------------------------Stereo correct UV by screen position
float2 CalcScreenUV(half4 screenPos) {
    float2 uv = screenPos / (screenPos.w + 0.0000000001); //0.0x1 Stops division by 0 warning in console.
    #if UNITY_SINGLE_PASS_STEREO
        uv.xy *= float2(_ScreenParams.x * 2, _ScreenParams.y);
    #else
        uv.xy *= _ScreenParams.xy;
    #endif

    return uv;
}

//-------------------------------------Dithering pattern
inline float Dither8x8Bayer( int x, int y ) {
    const float dither[ 64 ] = {
    1, 49, 13, 61,  4, 52, 16, 64,
    33, 17, 45, 29, 36, 20, 48, 32,
    9, 57,  5, 53, 12, 60,  8, 56,
    41, 25, 37, 21, 44, 28, 40, 24,
    3, 51, 15, 63,  2, 50, 14, 62,
    35, 19, 47, 31, 34, 18, 46, 30,
    11, 59,  7, 55, 10, 58,  6, 54,
    43, 27, 39, 23, 42, 26, 38, 22};
    int r = y * 8 + x;
    return dither[r] / 64;
}

//-------------------------------------Dithering value by screen position
float CalcDither(float2 screenPos) {
    float dither = Dither8x8Bayer(fmod(screenPos.x, 8), fmod(screenPos.y, 8));
    return dither;
}

//-------------------------------------Rotate on specified axis by specified angle
float4x4 RotationMatrix(float3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return float4x4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                    0.0,                                0.0,                                0.0,                                1.0);
}

//-------------------------------------Calculate corrected view direction to avoid poles
float3 CalcViewDir(float3 worldPos) {
	float3 camDir = normalize(mul(UNITY_MATRIX_V, float4(0, 1, 0, 0)).xyz);
	float3 viewDir = normalize(_WorldSpaceCameraPos - worldPos);
	if (dot(camDir, float3(0.0f, 0.0f, 1.0f)) >= 0.8f) {
		float val = (dot(camDir, float3(0.0f, 0.0f, 1.0f)) - 0.8f)/0.2f;
		float3 target = mul(RotationMatrix(float3(1.0f, 0.0, 0), UNITY_PI * 0.5), viewDir);
		return lerp(viewDir, target, smoothstep(0.0, 0.5, val));
	}
	if (dot(camDir, float3(0.0f, 0.0f, -1.0f)) >= 0.8f) {
		float val = (dot(camDir, float3(0.0f, 0.0f, -1.0f)) - 0.8f)/0.2f;
		float3 target = mul(RotationMatrix(float3(1.0f, 0.0, 0), -UNITY_PI * 0.5), viewDir);
		return lerp(viewDir, target, smoothstep(0.0, 0.5, val));
	}
	return viewDir;
}

//-------------------------------------True when rendering mirror copy
bool IsInMirror() {
	return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
}

//-------------------------------------3-space to spherical coordinates
float2 SphereUV(float3 coords) {
	float3 nc = normalize(coords);
	float lat = acos(nc.y);
	float lon = atan2(nc.z, nc.x);
	float2 coord = 1.0 - (float2(lon, lat) * float2(1.0/UNITY_PI, 1.0/UNITY_PI));
	return (coord + float4(0, 1-unity_StereoEyeIndex,1,1.0).xy) * float4(0, 1-unity_StereoEyeIndex,1,1.0).zw;
}

//-------------------------------------Apply rotation to UV
float2 RotateUV(float2 uv, float rotation) {
	float mid = 0.5;
	return float2(
		cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
		cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
	);
}

//-------------------------------------Stipple based halftones
float DotHalftone(float4 worldPos, float halftoneDotAmount, float scalar) {
	float2 uv = SphereUV(CalcViewDir(worldPos));
	uv.xy *= halftoneDotAmount;
	float2 nearest = 2 * frac(100 * uv) - 1;
	float dist = length(nearest);
	float dotSize = 100 * scalar;
	float dotMask = step(dotSize, dist);

	return lerp(1, 1-dotMask, smoothstep(0, 0.4, 1/distance(worldPos, _WorldSpaceCameraPos)));;
}

//-------------------------------------Crosshatch based halftones
float LineHalftone(float4 worldPos, float scalar) {
	float2 uv = SphereUV(CalcViewDir(worldPos));
	uv = RotateUV(uv, -0.785398);
	uv.x = sin(uv.x * scalar);

	float2 steppedUV = smoothstep(0,0.2,uv.x);
	float lineMask = lerp(1, steppedUV, smoothstep(0, 0.4, 1/distance(worldPos, _WorldSpaceCameraPos)));

	return saturate(lineMask);
}
