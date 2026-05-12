// Outer Wilds/Blended/Terrain/Vertex Color 3x  —  Unity 6 URP
//
// Blending modes (per overlay):
//   0 = Height Fill  : overlay monte depuis le bas (heightmap A)
//   1 = Height Cap   : overlay descend depuis le haut
//   2 = Overlay      : blend plat, ignore la heightmap
//
// Vertex colors :  R -> poids Overlay 1
//                  G -> poids Overlay 2
//                  A -> occlusion (si _VertexOcclusion activé)

Shader "Outer Wilds/Blended/Terrain/Vertex Color 3x"
{
    Properties
    {
        [Toggle(_VERTEXOCCLUSION)] _VertexOcclusion ("Vertex Color A as Occlusion", Float) = 0

        [Header(Base Material)]
        _Color              ("Color", Color)                    = (1,1,1,1)
        _MainTex            ("Albedo (RGB)  Height (A)", 2D)    = "black" {}
        _Glossiness         ("Smoothness", Range(0,1))          = 0.5
        _GlossMapScale      ("Height Smoothness", Range(0,1))   = 0.0
        _OcclusionStrength  ("Height Occlusion", Range(0,1))    = 0.5
        _BumpScale          ("Normal Scale", Float)             = 1.0
        _BumpMap            ("Normals (RGB)", 2D)               = "bump" {}

        [Header(Overlay Material 1 (Vertex Color R))]
        [KeywordEnum(Height Fill, Height Cap, Overlay)]
        _Overlay1Mode       ("Blending Mode", Float)            = 0
        _Overlay1Color      ("Color", Color)                    = (1,1,1,1)
        _Overlay1Tex        ("Albedo (RGB)  Height (A)", 2D)    = "white" {}
        _Overlay1Blend      ("Blend", Range(0,0.999))           = 0.5
        _Overlay1Glossiness ("Smoothness", Range(0,1))          = 0.5
        _Overlay1GlossMapScale ("Height Smoothness", Range(0,1)) = 0.0
        _Overlay1OcclusionStrength ("Height Occlusion", Range(0,1)) = 0.5
        _Overlay1BumpScale  ("Normal Scale", Float)             = 1.0
        _Overlay1Bump       ("Normals (RGB)", 2D)               = "bump" {}

        [Header(Overlay Material 2 (Vertex Color G))]
        [KeywordEnum(Height Fill, Height Cap, Overlay)]
        _Overlay2Mode       ("Blending Mode", Float)            = 0
        _Overlay2Color      ("Color", Color)                    = (1,1,1,1)
        _Overlay2Tex        ("Albedo (RGB)  Height (A)", 2D)    = "white" {}
        _Overlay2Blend      ("Blend", Range(0,0.999))           = 0.5
        _Overlay2Glossiness ("Smoothness", Range(0,1))          = 0.5
        _Overlay2GlossMapScale ("Height Smoothness", Range(0,1)) = 0.0
        _Overlay2OcclusionStrength ("Height Occlusion", Range(0,1)) = 0.5
        _Overlay2BumpScale  ("Normal Scale", Float)             = 1.0
        _Overlay2Bump       ("Normals (RGB)", 2D)               = "bump" {}

        // URP internal properties (ne pas modifier)
        [HideInInspector] _Cull           ("__cull",  Float) = 2.0
        [HideInInspector] _ZWrite         ("__zw",    Float) = 1.0
        [HideInInspector] _AlphaClip      ("__clip",  Float) = 0.0
        [HideInInspector] _Surface        ("__surf",  Float) = 0.0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"     = "Opaque"
            "Queue"          = "Geometry-5"
            "UniversalMaterialType" = "Lit"
        }
        LOD 400

        // =====================================================================
        //  Shared HLSL — inclus dans chaque passe via un fichier inline
        // =====================================================================
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

        // ---- Propriétés (CBUFFER requis en URP SRP Batcher) ----------------
        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _Overlay1Tex_ST;
            float4 _Overlay2Tex_ST;
            half4  _Color;
            half   _Glossiness;
            half   _GlossMapScale;
            half   _OcclusionStrength;
            half   _BumpScale;
            half4  _Overlay1Color;
            half   _Overlay1Blend;
            half   _Overlay1Glossiness;
            half   _Overlay1GlossMapScale;
            half   _Overlay1OcclusionStrength;
            half   _Overlay1BumpScale;
            half4  _Overlay2Color;
            half   _Overlay2Blend;
            half   _Overlay2Glossiness;
            half   _Overlay2GlossMapScale;
            half   _Overlay2OcclusionStrength;
            half   _Overlay2BumpScale;
        CBUFFER_END

        TEXTURE2D(_MainTex);      SAMPLER(sampler_MainTex);
        TEXTURE2D(_BumpMap);      SAMPLER(sampler_BumpMap);
        TEXTURE2D(_Overlay1Tex);  SAMPLER(sampler_Overlay1Tex);
        TEXTURE2D(_Overlay1Bump); SAMPLER(sampler_Overlay1Bump);
        TEXTURE2D(_Overlay2Tex);  SAMPLER(sampler_Overlay2Tex);
        TEXTURE2D(_Overlay2Bump); SAMPLER(sampler_Overlay2Bump);

        // ---- Utilitaire : blend basé sur la heightmap -----------------------
        //   mode 0 = Height Fill, 1 = Height Cap, 2 = Overlay (plat)
        half ComputeHeightBlend(half baseH, half overlayH, half blend, int mode)
        {
            if (mode == 2) return blend;
            half h = lerp(baseH, overlayH, blend);
            if (mode == 0) return smoothstep(h - 0.1h, h + 0.1h, overlayH);
            return             smoothstep(h - 0.1h, h + 0.1h, baseH);
        }

        // ---- Données calculées partagées entre forward / depth-normals ------
        struct BlendedSurface
        {
            half3 albedo;
            half3 normalTS;
            half  smoothness;
            half  occlusion;
        };

        BlendedSurface ComputeSurface(float2 uvBase, float2 uvOv1, float2 uvOv2, half4 vertexColor)
        {
            // Base
            half4 baseRGBH = SAMPLE_TEXTURE2D(_MainTex,     sampler_MainTex,  uvBase) * _Color;
            half3 baseNorm  = UnpackNormalScale(
                                SAMPLE_TEXTURE2D(_BumpMap,  sampler_BumpMap,  uvBase), _BumpScale);
            half baseH      = baseRGBH.a;
            half baseSmooth = lerp(_Glossiness,        _GlossMapScale,        baseH);
            half baseOcc    = lerp(1.0h, baseH, _OcclusionStrength);

            // Overlay 1
            half4 ov1RGBH  = SAMPLE_TEXTURE2D(_Overlay1Tex,  sampler_Overlay1Tex,  uvOv1) * _Overlay1Color;
            half3 ov1Norm   = UnpackNormalScale(
                                SAMPLE_TEXTURE2D(_Overlay1Bump, sampler_Overlay1Bump, uvOv1), _Overlay1BumpScale);
            half ov1H       = ov1RGBH.a;
            half ov1Smooth  = lerp(_Overlay1Glossiness, _Overlay1GlossMapScale, ov1H);
            half ov1Occ     = lerp(1.0h, ov1H, _Overlay1OcclusionStrength);

            #if defined(_OVERLAY1MODE_OVERLAY)
                half ov1BlendW = ComputeHeightBlend(baseH, ov1H, _Overlay1Blend, 2);
            #elif defined(_OVERLAY1MODE_HEIGHT_CAP)
                half ov1BlendW = ComputeHeightBlend(baseH, ov1H, _Overlay1Blend, 1);
            #else
                half ov1BlendW = ComputeHeightBlend(baseH, ov1H, _Overlay1Blend, 0);
            #endif
            half ov1Alpha = saturate(vertexColor.r * ov1BlendW);

            // Overlay 2
            half4 ov2RGBH  = SAMPLE_TEXTURE2D(_Overlay2Tex,  sampler_Overlay2Tex,  uvOv2) * _Overlay2Color;
            half3 ov2Norm   = UnpackNormalScale(
                                SAMPLE_TEXTURE2D(_Overlay2Bump, sampler_Overlay2Bump, uvOv2), _Overlay2BumpScale);
            half ov2H       = ov2RGBH.a;
            half ov2Smooth  = lerp(_Overlay2Glossiness, _Overlay2GlossMapScale, ov2H);
            half ov2Occ     = lerp(1.0h, ov2H, _Overlay2OcclusionStrength);

            #if defined(_OVERLAY2MODE_OVERLAY)
                half ov2BlendW = ComputeHeightBlend(baseH, ov2H, _Overlay2Blend, 2);
            #elif defined(_OVERLAY2MODE_HEIGHT_CAP)
                half ov2BlendW = ComputeHeightBlend(baseH, ov2H, _Overlay2Blend, 1);
            #else
                half ov2BlendW = ComputeHeightBlend(baseH, ov2H, _Overlay2Blend, 0);
            #endif
            half ov2Alpha = saturate(vertexColor.g * ov2BlendW);

            // Combinaison base -> ov1 -> ov2
            BlendedSurface s;
            s.albedo     = lerp(lerp(baseRGBH.rgb, ov1RGBH.rgb, ov1Alpha), ov2RGBH.rgb, ov2Alpha);
            s.normalTS   = lerp(lerp(baseNorm,     ov1Norm,     ov1Alpha), ov2Norm,     ov2Alpha);
            s.smoothness = lerp(lerp(baseSmooth,   ov1Smooth,   ov1Alpha), ov2Smooth,   ov2Alpha);
            s.occlusion  = lerp(lerp(baseOcc,      ov1Occ,      ov1Alpha), ov2Occ,      ov2Alpha);

            // Occlusion vertex color (canal A)
            #if defined(_VERTEXOCCLUSION)
                s.occlusion *= vertexColor.a;
            #endif

            return s;
        }
        ENDHLSL

        // =====================================================================
        //  Passe 1 : UniversalForward  (lighting PBR complet)
        // =====================================================================
        Pass
        {
            Name "UniversalForward"
            Tags { "LightMode" = "UniversalForward" }

            Cull  [_Cull]
            ZWrite [_ZWrite]

            HLSLPROGRAM
            #pragma vertex   vert
            #pragma fragment frag

            #pragma shader_feature_local _VERTEXOCCLUSION
            #pragma shader_feature_local _OVERLAY1MODE_HEIGHT_FILL _OVERLAY1MODE_HEIGHT_CAP _OVERLAY1MODE_OVERLAY
            #pragma shader_feature_local _OVERLAY2MODE_HEIGHT_FILL _OVERLAY2MODE_HEIGHT_CAP _OVERLAY2MODE_OVERLAY

            // Features URP standard
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 uv0        : TEXCOORD0;
                float2 uv1        : TEXCOORD1;   // lightmap UV
                half4  color      : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS    : SV_POSITION;
                float2 uvBase        : TEXCOORD0;
                float2 uvOv1         : TEXCOORD1;
                float2 uvOv2         : TEXCOORD2;
                float3 positionWS    : TEXCOORD3;
                float3 normalWS      : TEXCOORD4;
                float4 tangentWS     : TEXCOORD5;   // xyz = tangent, w = sign
                float2 uvLightmap    : TEXCOORD6;
                half4  color         : COLOR;
                DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 7);
                float  fogFactor     : TEXCOORD8;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes input)
            {
                UNITY_SETUP_INSTANCE_ID(input);
                Varyings output = (Varyings)0;
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vpi = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs   vni = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionCS  = vpi.positionCS;
                output.positionWS  = vpi.positionWS;
                output.normalWS    = vni.normalWS;
                output.tangentWS   = float4(vni.tangentWS, input.tangentOS.w * GetOddNegativeScale());
                output.uvBase      = TRANSFORM_TEX(input.uv0, _MainTex);
                output.uvOv1       = TRANSFORM_TEX(input.uv0, _Overlay1Tex);
                output.uvOv2       = TRANSFORM_TEX(input.uv0, _Overlay2Tex);
                output.color       = input.color;
                output.fogFactor   = ComputeFogFactor(vpi.positionCS.z);

                OUTPUT_LIGHTMAP_UV(input.uv1, unity_LightmapST, output.staticLightmapUV);
                OUTPUT_SH(output.normalWS, output.vertexSH);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                BlendedSurface s = ComputeSurface(input.uvBase, input.uvOv1, input.uvOv2, input.color);

                // Reconstruction de la normale world-space depuis tangent-space
                float3 bitangentWS = cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w;
                float3 normalWS    = TransformTangentToWorld(s.normalTS,
                    half3x3(input.tangentWS.xyz, bitangentWS, input.normalWS));
                normalWS = NormalizeNormalPerPixel(normalWS);

                // --- InputData URP ------------------------------------------
                InputData inputData = (InputData)0;
                inputData.positionWS        = input.positionWS;
                inputData.normalWS          = normalWS;
                inputData.viewDirectionWS   = GetWorldSpaceNormalizeViewDir(input.positionWS);
                inputData.shadowCoord       = TransformWorldToShadowCoord(input.positionWS);
                inputData.fogCoord          = input.fogFactor;
                inputData.bakedGI           = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, normalWS);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                inputData.shadowMask        = SAMPLE_SHADOWMASK(input.staticLightmapUV);

                // --- SurfaceData URP ----------------------------------------
                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo      = s.albedo;
                surfaceData.metallic    = 0.0h;
                surfaceData.smoothness  = s.smoothness;
                surfaceData.normalTS    = s.normalTS;
                surfaceData.occlusion   = s.occlusion;
                surfaceData.alpha       = 1.0h;

                half4 color = UniversalFragmentPBR(inputData, surfaceData);
                color.rgb   = MixFog(color.rgb, input.fogFactor);
                return color;
            }
            ENDHLSL
        }

        // =====================================================================
        //  Passe 2 : ShadowCaster
        // =====================================================================
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull [_Cull]

            HLSLPROGRAM
            #pragma vertex   vertShadow
            #pragma fragment fragShadow
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float3 _LightDirection;
            float3 _LightPosition;

            struct AttrShadow
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            float4 vertShadow(AttrShadow input) : SV_POSITION
            {
                UNITY_SETUP_INSTANCE_ID(input);
                float3 posWS  = TransformObjectToWorld(input.positionOS.xyz);
                float3 normWS = TransformObjectToWorldNormal(input.normalOS);
                return TransformWorldToHClip(ApplyShadowBias(posWS, normWS, _LightDirection));
            }

            half4 fragShadow(float4 posCS : SV_POSITION) : SV_Target { return 0; }
            ENDHLSL
        }

        // =====================================================================
        //  Passe 3 : DepthOnly  (pré-pass de profondeur)
        // =====================================================================
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask R
            Cull [_Cull]

            HLSLPROGRAM
            #pragma vertex   vertDepth
            #pragma fragment fragDepth
            #pragma multi_compile_instancing

            struct AttrDepth
            {
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            float4 vertDepth(AttrDepth input) : SV_POSITION
            {
                UNITY_SETUP_INSTANCE_ID(input);
                return TransformObjectToHClip(input.positionOS.xyz);
            }

            half fragDepth(float4 posCS : SV_POSITION) : SV_Target { return 0; }
            ENDHLSL
        }

        // =====================================================================
        //  Passe 4 : DepthNormals  (SSAO, screen-space effects)
        // =====================================================================
        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode" = "DepthNormals" }

            ZWrite On
            Cull [_Cull]

            HLSLPROGRAM
            #pragma vertex   vertDN
            #pragma fragment fragDN

            #pragma shader_feature_local _VERTEXOCCLUSION
            #pragma shader_feature_local _OVERLAY1MODE_HEIGHT_FILL _OVERLAY1MODE_HEIGHT_CAP _OVERLAY1MODE_OVERLAY
            #pragma shader_feature_local _OVERLAY2MODE_HEIGHT_FILL _OVERLAY2MODE_HEIGHT_CAP _OVERLAY2MODE_OVERLAY
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/PackingUtils.hlsl"

            struct AttrDN
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 uv0        : TEXCOORD0;
                half4  color      : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VaryDN
            {
                float4 positionCS : SV_POSITION;
                float2 uvBase     : TEXCOORD0;
                float2 uvOv1      : TEXCOORD1;
                float2 uvOv2      : TEXCOORD2;
                float3 normalWS   : TEXCOORD3;
                float4 tangentWS  : TEXCOORD4;
                half4  color      : COLOR;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            VaryDN vertDN(AttrDN input)
            {
                UNITY_SETUP_INSTANCE_ID(input);
                VaryDN o = (VaryDN)0;
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                VertexNormalInputs vni = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                o.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                o.normalWS   = vni.normalWS;
                o.tangentWS  = float4(vni.tangentWS, input.tangentOS.w * GetOddNegativeScale());
                o.uvBase     = TRANSFORM_TEX(input.uv0, _MainTex);
                o.uvOv1      = TRANSFORM_TEX(input.uv0, _Overlay1Tex);
                o.uvOv2      = TRANSFORM_TEX(input.uv0, _Overlay2Tex);
                o.color      = input.color;
                return o;
            }

            float4 fragDN(VaryDN input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                BlendedSurface s = ComputeSurface(input.uvBase, input.uvOv1, input.uvOv2, input.color);
                float3 bitangentWS = cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w;
                float3 normalWS = NormalizeNormalPerPixel(
                    TransformTangentToWorld(s.normalTS,
                        half3x3(input.tangentWS.xyz, bitangentWS, input.normalWS)));
                return float4(PackNormalOctRectEncode(TransformWorldToViewDir(normalWS, true)), 0, 0);
            }
            ENDHLSL
        }
    }

    Fallback "Universal Render Pipeline/Lit"
}
