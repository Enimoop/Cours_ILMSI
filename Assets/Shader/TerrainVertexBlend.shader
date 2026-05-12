Shader "Custom/TerrainVertexBlend"
{
    Properties
    {
        // ── Rock ──────────────────────────────────────────────────────────────
        _RockTex        ("Rock Albedo",             2D)    = "white" {}
        _RockSmoothness ("Rock Smoothness",         Range(0,1)) = 0.5

        // ── Dirt (Vertex Color R) ─────────────────────────────────────────────
        _DirtTex        ("Dirt Albedo",             2D)    = "white" {}
        _DirtSmoothness ("Dirt Smoothness",         Range(0,1)) = 0.059
        _DirtBlend      ("Dirt Blend Multiplier",   Range(0,2)) = 1.0

        // ── Grass (Vertex Color G) ────────────────────────────────────────────
        _GrassTex           ("Grass Base Albedo",       2D)    = "white" {}
        _GrassDetailTex     ("Grass Detail Albedo",     2D)    = "white" {}
        _GrassDetailStrength("Grass Detail Strength",   Range(0,1)) = 0.5
        _GrassSmoothness    ("Grass Smoothness",        Range(0,1)) = 0.0
        _GrassBlend         ("Grass Blend Multiplier",  Range(0,2)) = 1.0

        // ── Leaves (Vertex Color B) ───────────────────────────────────────────
        _LeavesTex       ("Leaves Albedo",          2D)    = "white" {}
        _LeavesSmoothness("Leaves Smoothness",      Range(0,1)) = 0.059
        _LeavesBlend     ("Leaves Blend Multiplier",Range(0,2)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        LOD 300

        // ── Forward Lit ───────────────────────────────────────────────────────
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex   vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_RockTex);        SAMPLER(sampler_RockTex);
            TEXTURE2D(_DirtTex);        SAMPLER(sampler_DirtTex);
            TEXTURE2D(_GrassTex);       SAMPLER(sampler_GrassTex);
            TEXTURE2D(_GrassDetailTex); SAMPLER(sampler_GrassDetailTex);
            TEXTURE2D(_LeavesTex);      SAMPLER(sampler_LeavesTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _RockTex_ST;
                float  _RockSmoothness;

                float4 _DirtTex_ST;
                float  _DirtSmoothness;
                float  _DirtBlend;

                float4 _GrassTex_ST;
                float4 _GrassDetailTex_ST;
                float  _GrassDetailStrength;
                float  _GrassSmoothness;
                float  _GrassBlend;

                float4 _LeavesTex_ST;
                float  _LeavesSmoothness;
                float  _LeavesBlend;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
                float4 color      : COLOR;    // R=Dirt  G=Grass  B=Leaves
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float4 color       : TEXCOORD1;
                float3 normalWS    : TEXCOORD2;
                float3 positionWS  : TEXCOORD3;
                float  fogCoord    : TEXCOORD4;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs posInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionHCS = posInputs.positionCS;
                OUT.positionWS  = posInputs.positionWS;
                OUT.normalWS    = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv          = IN.uv;
                OUT.color       = IN.color;
                OUT.fogCoord    = ComputeFogFactor(posInputs.positionCS.z);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // ── Sample textures ────────────────────────────────────────
                half4 rock = SAMPLE_TEXTURE2D(_RockTex, sampler_RockTex,
                                IN.uv * _RockTex_ST.xy + _RockTex_ST.zw);

                half4 dirt = SAMPLE_TEXTURE2D(_DirtTex, sampler_DirtTex,
                                IN.uv * _DirtTex_ST.xy + _DirtTex_ST.zw);

                half4 grassBase   = SAMPLE_TEXTURE2D(_GrassTex, sampler_GrassTex,
                                IN.uv * _GrassTex_ST.xy + _GrassTex_ST.zw);
                half4 grassDetail = SAMPLE_TEXTURE2D(_GrassDetailTex, sampler_GrassDetailTex,
                                IN.uv * _GrassDetailTex_ST.xy + _GrassDetailTex_ST.zw);
                // Multiplicative detail blend (neutral at grey 0.5)
                half4 grass = grassBase * lerp(1.0, grassDetail * 2.0, _GrassDetailStrength);

                half4 leaves = SAMPLE_TEXTURE2D(_LeavesTex, sampler_LeavesTex,
                                IN.uv * _LeavesTex_ST.xy + _LeavesTex_ST.zw);

                // ── Blend weights from vertex colors ───────────────────────
                float dirtW   = saturate(IN.color.r * _DirtBlend);
                float grassW  = saturate(IN.color.g * _GrassBlend);
                float leavesW = saturate(IN.color.b * _LeavesBlend);

                // ── Blend albedo & smoothness ──────────────────────────────
                half4 albedo     = rock;
                float smoothness = _RockSmoothness;

                albedo     = lerp(albedo,     dirt,             dirtW);
                smoothness = lerp(smoothness, _DirtSmoothness,  dirtW);

                albedo     = lerp(albedo,     grass,            grassW);
                smoothness = lerp(smoothness, _GrassSmoothness, grassW);

                albedo     = lerp(albedo,     leaves,            leavesW);
                smoothness = lerp(smoothness, _LeavesSmoothness, leavesW);

                // ── Lighting ───────────────────────────────────────────────
                InputData lightData = (InputData)0;
                lightData.positionWS              = IN.positionWS;
                lightData.normalWS                = normalize(IN.normalWS);
                lightData.viewDirectionWS         = GetWorldSpaceNormalizeViewDir(IN.positionWS);
                lightData.shadowCoord             = TransformWorldToShadowCoord(IN.positionWS);
                lightData.fogCoord                = IN.fogCoord;
                lightData.vertexLighting          = half3(0,0,0);
                lightData.bakedGI                 = half3(0,0,0);
                lightData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.positionHCS);

                SurfaceData surf = (SurfaceData)0;
                surf.albedo     = albedo.rgb;
                surf.alpha      = 1.0;
                surf.smoothness = smoothness;
                surf.occlusion  = 1.0;
                surf.specular   = half3(0,0,0);

                half4 color = UniversalFragmentPBR(lightData, surf);
                color.rgb = MixFog(color.rgb, IN.fogCoord);
                return color;
            }
            ENDHLSL
        }

        // ── Shadow Caster ─────────────────────────────────────────────────────
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex   ShadowPassVertex
            #pragma fragment ShadowPassFragment
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        // ── Depth Only ────────────────────────────────────────────────────────
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }
            ZWrite On
            ColorMask R

            HLSLPROGRAM
            #pragma vertex   DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Lit"
}
