Shader "Custom/DiffusePerVetex"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1,1,1,1)
    }

    SubShader
    {
        Pass
        {
            Tags { "RenderType"="Opaque" }

            CGPROGRAM
            #include "Lighting.cginc"

            ENDCG
        }
    }
    FallBack "Diffuse"
}
