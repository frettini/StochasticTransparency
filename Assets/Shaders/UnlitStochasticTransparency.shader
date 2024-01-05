// https://forum.unity.com/threads/stochastic-transparency.831115/
Shader "Custom/StochasticTransparency"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        [KeywordEnum(SV_Coverage, AlphaToMask)] _MSAA_ALPHA ("MSAA Transparency Mode", Float) = 0.0
    }
    SubShader
    {
        Pass
        {
            Tags{"LightMode" = "ST_Transmittance"}
            
            Blend Zero OneMinusSrcColor, One One
            ZWrite Off
            ZTest LEqual
            ZClip Off
            
            HLSLPROGRAM
            #pragma target 5.0
 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"
            #include "Assets/Shaders/StochasticTransparency.hlsl"           
 
            #pragma vertex UnlitStochasticVert 
            #pragma fragment StochasticTransmittanceFrag
            
            ENDHLSL
        }
        Pass
        {
            Tags{"LightMode" = "ST_DepthPass"}
        
            // here we only care about storing z
            ZWrite On
            ZClip Off
            
            HLSLPROGRAM
            #pragma target 5.0
 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"
            #include "Assets/Shaders/StochasticTransparency.hlsl"   
 
            #pragma vertex UnlitStochasticVert 
            #pragma fragment StochasticDepthFrag
 
            ENDHLSL
        }
        Pass
        {
            Tags{"LightMode" = "ST_Accumulation"}
            
            // additive blend
            Blend One One
            ZTest LEqual
            ZWrite Off
            ZClip Off
            
            HLSLPROGRAM
            #pragma target 5.0
 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"
            #include "Assets/Shaders/StochasticTransparency.hlsl"   
            
            #pragma vertex UnlitStochasticVert 
            #pragma fragment StochasticAccumulationFrag
           
            ENDHLSL
        }
        
        Pass
        {
            Tags{"LightMode" = "ResolveStochasticTransparency"}
            
            ZWrite Off 
            Cull Off
            
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/Shaders/StochasticTransparency.hlsl"   

            #pragma vertex Vert
            #pragma fragment StochasticResolveFrag
            
            ENDHLSL
        }
    }
}