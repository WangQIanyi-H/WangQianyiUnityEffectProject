#ifndef UNIVERSAL_LIT_INPUT_INCLUDED
#define UNIVERSAL_LIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
// #include "Assets/EngineTest/Shaders/TerrainBlendHelper.hlsl"

#if defined(_DETAIL_MULX2) || defined(_DETAIL_SCALED)
    #define _DETAIL
#endif

// NOTE: Do not ifdef the properties here as SRP batcher can not handle different layouts.
CBUFFER_START(UnityPerMaterial)
    float4 _BaseMap_ST;
    float4 _DetailAlbedoMap_ST;
    half4 _BaseColor;
    half4 _SpecColor;
    half4 _EmissionColor;
    half _Cutoff;
    half _Smoothness;
    half _Metallic;
    half _BumpScale;
    half _Parallax;
    half _OcclusionStrength;
    half _ClearCoatMask;
    half _ClearCoatSmoothness;
    half _DetailAlbedoMapScale;
    half _DetailNormalMapScale;
    half _Surface;
    half _BlendDiff;
    half _BlendToggle;
CBUFFER_END

// NOTE: Do not ifdef the properties for dots instancing, but ifdef the actual usage.
// Otherwise you might break CPU-side as property constant-buffer offsets change per variant.
// NOTE: Dots instancing is orthogonal to the constant buffer above.
#ifdef UNITY_DOTS_INSTANCING_ENABLED
    UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
    UNITY_DOTS_INSTANCED_PROP(float4, _BaseColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _SpecColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _EmissionColor)
    UNITY_DOTS_INSTANCED_PROP(float, _Cutoff)
    UNITY_DOTS_INSTANCED_PROP(float, _Smoothness)
    UNITY_DOTS_INSTANCED_PROP(float, _Metallic)
    UNITY_DOTS_INSTANCED_PROP(float, _BumpScale)
    UNITY_DOTS_INSTANCED_PROP(float, _Parallax)
    UNITY_DOTS_INSTANCED_PROP(float, _OcclusionStrength)
    UNITY_DOTS_INSTANCED_PROP(float, _ClearCoatMask)
    UNITY_DOTS_INSTANCED_PROP(float, _ClearCoatSmoothness)
    UNITY_DOTS_INSTANCED_PROP(float, _DetailAlbedoMapScale)
    UNITY_DOTS_INSTANCED_PROP(float, _DetailNormalMapScale)
    UNITY_DOTS_INSTANCED_PROP(float, _Surface)
    UNITY_DOTS_INSTANCED_PROP(float, _BlendDiff)
    UNITY_DOTS_INSTANCED_PROP(float, _BlendToggle)
    UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

    #define _BaseColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4, Metadata_BaseColor)
    #define _SpecColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4, Metadata_SpecColor)
    #define _EmissionColor          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4, Metadata_EmissionColor)
    #define _Cutoff                 UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_Cutoff)
    #define _Smoothness             UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_Smoothness)
    #define _Metallic               UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_Metallic)
    #define _BumpScale              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_BumpScale)
    #define _Parallax               UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_Parallax)
    #define _OcclusionStrength      UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_OcclusionStrength)
    #define _ClearCoatMask          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_ClearCoatMask)
    #define _ClearCoatSmoothness    UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_ClearCoatSmoothness)
    #define _DetailAlbedoMapScale   UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_DetailAlbedoMapScale)
    #define _DetailNormalMapScale   UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_DetailNormalMapScale)
    #define _Surface                UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_Surface)
    #define _BlendDiff              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_BlendDiff)
    #define _BlendToggle            UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float, Metadata_BlendToggle)
#endif

TEXTURE2D(_ParallaxMap);        SAMPLER(sampler_ParallaxMap);
TEXTURE2D(_OcclusionMap);       SAMPLER(sampler_OcclusionMap);
TEXTURE2D(_DetailMask);         SAMPLER(sampler_DetailMask);
TEXTURE2D(_DetailAlbedoMap);    SAMPLER(sampler_DetailAlbedoMap);
TEXTURE2D(_DetailNormalMap);    SAMPLER(sampler_DetailNormalMap);
TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_SpecGlossMap);       SAMPLER(sampler_SpecGlossMap);
TEXTURE2D(_ClearCoatMap);       SAMPLER(sampler_ClearCoatMap);

TEXTURE2D(_GrassAlbedo);       SAMPLER(sampler_GrassAlbedo);
TEXTURE2D(_GrassMetallic);       SAMPLER(sampler_GrassMetallic);
TEXTURE2D(_GrassNormal);       SAMPLER(sampler_GrassNormal);

#ifdef _SPECULAR_SETUP
    #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, uv)
#else
    #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv)
#endif

half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
{
    half4 specGloss;

    #ifdef _METALLICSPECGLOSSMAP
        specGloss = half4(SAMPLE_METALLICSPECULAR(uv));
        #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            specGloss.r = albedoAlpha * _Smoothness; //CYOU shader
        #else
            specGloss.r *= _Smoothness;  //CYOU shader
        #endif
    #else // _METALLICSPECGLOSSMAP
        #if _SPECULAR_SETUP
            specGloss.rgb = _SpecColor.rgb;
        #else
            specGloss.rgb = _Metallic.rrr;
        #endif

        #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            specGloss.r = albedoAlpha * _Smoothness;//CYOU shader
        #else
            specGloss.r = _Smoothness;//CYOU shader
        #endif
    #endif

    return specGloss;
}

half SampleOcclusion(float2 uv)
{
    #ifdef _OCCLUSIONMAP
        // TODO: Controls things like these by exposing SHADER_QUALITY levels (low, medium, high)
        #if defined(SHADER_API_GLES)
            return SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
        #else
            half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
            return LerpWhiteTo(occ, _OcclusionStrength);
        #endif
    #else
        return half(1.0);
    #endif
}


// Returns clear coat parameters
// .x/.r == mask
// .y/.g == smoothness
half2 SampleClearCoat(float2 uv)
{
    #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
        half2 clearCoatMaskSmoothness = half2(_ClearCoatMask, _ClearCoatSmoothness);

        #if defined(_CLEARCOATMAP)
            clearCoatMaskSmoothness *= SAMPLE_TEXTURE2D(_ClearCoatMap, sampler_ClearCoatMap, uv).rg;
        #endif

        return clearCoatMaskSmoothness;
    #else
        return half2(0.0, 1.0);
    #endif  // _CLEARCOAT

}

void ApplyPerPixelDisplacement(half3 viewDirTS, inout float2 uv)
{
    #if defined(_PARALLAXMAP)
        uv += ParallaxMapping(TEXTURE2D_ARGS(_ParallaxMap, sampler_ParallaxMap), viewDirTS, _Parallax, uv);
    #endif
}

// Used for scaling detail albedo. Main features:
// - Depending if detailAlbedo brightens or darkens, scale magnifies effect.
// - No effect is applied if detailAlbedo is 0.5.
half3 ScaleDetailAlbedo(half3 detailAlbedo, half scale)
{
    // detailAlbedo = detailAlbedo * 2.0h - 1.0h;
    // detailAlbedo *= _DetailAlbedoMapScale;
    // detailAlbedo = detailAlbedo * 0.5h + 0.5h;
    // return detailAlbedo * 2.0f;

    // A bit more optimized
    return half(2.0) * detailAlbedo * scale - scale + half(1.0);
}

half3 ApplyDetailAlbedo(float2 detailUv, half3 albedo, half detailMask)
{
    #if defined(_DETAIL)
        half3 detailAlbedo = SAMPLE_TEXTURE2D(_DetailAlbedoMap, sampler_DetailAlbedoMap, detailUv).rgb;

        // In order to have same performance as builtin, we do scaling only if scale is not 1.0 (Scaled version has 6 additional instructions)
        #if defined(_DETAIL_SCALED)
            detailAlbedo = ScaleDetailAlbedo(detailAlbedo, _DetailAlbedoMapScale);
        #else
            detailAlbedo = half(2.0) * detailAlbedo;
        #endif

        return albedo * LerpWhiteTo(detailAlbedo, detailMask);
    #else
        return albedo;
    #endif
}

half3 ApplyDetailNormal(float2 detailUv, half3 normalTS, half detailMask)
{
    #if defined(_DETAIL)
        #if BUMP_SCALE_NOT_SUPPORTED
            half3 detailNormalTS = UnpackNormal(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUv));
        #else
            half3 detailNormalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUv), _DetailNormalMapScale);
        #endif

        // With UNITY_NO_DXT5nm unpacked vector is not normalized for BlendNormalRNM
        // For visual consistancy we going to do in all cases
        detailNormalTS = normalize(detailNormalTS);

        return lerp(normalTS, BlendNormalRNM(normalTS, detailNormalTS), detailMask); // todo: detailMask should lerp the angle of the quaternion rotation, not the normals
    #else
        return normalTS;
    #endif
}
half3 SampleEmission_CYShader(float2 uv, half3 emissionColor, TEXTURE2D_PARAM(emissionMap, sampler_emissionMap))
{
    #ifndef _EMISSION
        return 0;
    #else
        return SAMPLE_TEXTURE2D(emissionMap, sampler_emissionMap, uv).a * emissionColor;
    #endif
}


inline void InitializeStandardLitSurfaceData(float2 uv, float VertexColor, out SurfaceData outSurfaceData)
{
    //CYShader 添加參數頂點色
    
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
    
    #if defined(_VERTEXCOLORGRASS)
        half2 grassuv = uv * 5;
        half4 grassalbedo = SAMPLE_TEXTURE2D(_GrassAlbedo, sampler_GrassAlbedo, grassuv); //CYShader
        albedoAlpha.rgb = albedoAlpha.rgb * VertexColor + grassalbedo.xyz * (1 - VertexColor);
    #else
        albedoAlpha.rgb = albedoAlpha.rgb;
    #endif
    half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

    

    #if _SPECULAR_SETUP
        outSurfaceData.metallic = half(1.0);
        outSurfaceData.specular = specGloss.rgb;
    #else
        outSurfaceData.metallic = specGloss.g;
        outSurfaceData.specular = half3(0.0, 0.0, 0.0);
    #endif
    //CYShader normal&smooth START
    #if defined(_VERTEXCOLORGRASS)
        half grassSmooth = SAMPLE_TEXTURE2D(_GrassMetallic, sampler_GrassMetallic, grassuv).r;
        outSurfaceData.smoothness = specGloss.r * VertexColor + grassSmooth * (1 - VertexColor);
        half3 grassnormal = SampleNormal(grassuv, TEXTURE2D_ARGS(_GrassNormal, sampler_GrassNormal), _BumpScale);
        half3 mainnormal = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
        outSurfaceData.normalTS = mainnormal * VertexColor + grassnormal * (1 - VertexColor);
    #else
        outSurfaceData.smoothness = specGloss.r;
        outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    #endif
    //CYShader normal&smooth END

    //outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    outSurfaceData.occlusion = SampleOcclusion(uv);
    outSurfaceData.emission = SampleEmission_CYShader(uv, _EmissionColor.rgb * outSurfaceData.albedo, TEXTURE2D_ARGS(_MetallicGlossMap, sampler_MetallicGlossMap));

    #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
        half2 clearCoat = SampleClearCoat(uv);
        outSurfaceData.clearCoatMask = clearCoat.r;
        outSurfaceData.clearCoatSmoothness = clearCoat.g;
    #else
        outSurfaceData.clearCoatMask = half(0.0);
        outSurfaceData.clearCoatSmoothness = half(0.0);
    #endif

    #if defined(_DETAIL)
        half detailMask = SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, uv).a;
        float2 detailUv = uv * _DetailAlbedoMap_ST.xy + _DetailAlbedoMap_ST.zw;
        outSurfaceData.albedo = ApplyDetailAlbedo(detailUv, outSurfaceData.albedo, detailMask);
        outSurfaceData.normalTS = ApplyDetailNormal(detailUv, outSurfaceData.normalTS, detailMask);
    #endif
}

#endif // UNIVERSAL_INPUT_SURFACE_PBR_INCLUDED