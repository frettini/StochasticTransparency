#ifndef STOCHASTICTRANSPARENCY_INCLUDED
#define STOCHASTICTRANSPARENCY_INCLUDED

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};
 
 struct v2f
{
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
};
   
half4 _Color;
sampler2D _MainTex;
float4 _MainTex_ST;

// Unlit VS ------------------------------------------------

 v2f UnlitStochasticVert (appdata v)
{
    v2f o;
    o.vertex = TransformObjectToHClip(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    return o;
}
 
// Transmittance PS ----------------------------------------
 
half4 StochasticTransmittanceFrag(v2f i) : SV_Target
{
    return _Color.a;
}

// Depth Pass PS --------------------------------------------

 // adapted from https://www.shadertoy.com/view/4djSRW
float hash13(float3 p3)
{
    p3  = frac(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}
 
half4 StochasticDepthFrag(v2f i
    , uint primitiveID : SV_PrimitiveID
    , out uint coverage : SV_Coverage
    ) : SV_Target
{
    half4 col = tex2D(_MainTex, i.uv) * _Color;
    float noise = hash13( float3( i.vertex.x, i.vertex.y, float(primitiveID)) - frac(_Time.y * float3(0.5, 1.0, 0.)));
                
    // TODO: this needs to become a parameter somehow
    int MSAA = 4;
    int BITMASK = (MSAA * MSAA - 1);
    int INVBITMASK = 255 - BITMASK;
    
    //Ri = b?iS + ?c
    uint sampleCount = clamp(col.a * MSAA + noise, 0 , MSAA);
    int mask = (INVBITMASK >> int(sampleCount + 0.5)) & BITMASK;
    int shift = (int(noise * float(MSAA)));
    int shiftedMask = (((mask << shift) & INVBITMASK) >> MSAA) ;
    coverage = (((mask<<MSAA)|mask)>>shift) & BITMASK;
    col.a = 1.0;
 
    return col;
}

// Accumulation PS ---------------------------------------

half4 StochasticAccumulationFrag(v2f i) : SV_Target
{
    half4 col = tex2D(_MainTex, i.uv) * _Color;
    return half4(col.rgb * col.a, col.a);
}

// Resolve Pass PS ---------------------------------------

// The Blit.hlsl file provides the vertex shader (Vert),
// input structure (Attributes) and output strucutre (Varyings)
#include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

TEXTURE2D_X(_Transmittance);
SAMPLER(sampler_Transmittance);
            
TEXTURE2D_X(_ST_ColorAccumulation);
SAMPLER(sampler_ST_ColorAccumulation);

TEXTURE2D_X(_CameraOpaqueTexture);
SAMPLER(sampler_CameraOpaqueTexture);

half4 StochasticResolveFrag(Varyings input) : SV_Target
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
    float4 background = SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, input.texcoord);
                
    float4 accumCol = SAMPLE_TEXTURE2D_X(_ST_ColorAccumulation, sampler_ST_ColorAccumulation, input.texcoord);
    float transmittance = SAMPLE_TEXTURE2D_X(_Transmittance, sampler_Transmittance, input.texcoord).r;
                
    // dim the background by transmittance
    background *= (transmittance);
    // coorect to filtered alpha (misses a couple things rn)
    accumCol *= (1.-transmittance);
    //blend over the filtered dimmedzz 
    float3 col = background.rgb + accumCol.rgb;
 
    return half4(col,1.);
}

#endif // STOCHASTICTRANSPARENCY_INCLUDED
