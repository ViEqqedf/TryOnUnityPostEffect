Shader "Custom/SimpleBlurEffect"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
    }

    CGINCLUDE
    #include "UnityCG.cginc"

    struct v2f_blur
    {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
        float2 uv2 : TEXCOORD2;
        float2 uv3 : TEXCOORD3;
        float2 uv4 : TEXCOORD4;
        //float2 uv5 : TEXCOORD5;
        //float2 uv6 : TEXCOORD6;
        //float2 uv7 : TEXCOORD7;
        //float2 uv8 : TEXCOORD8;
    };

    sampler2D _MainTex;
    //纹理的像素大小 width,heigh对应纹理的分辨率 x = 1/width, y = 1/height, z = width, w = height
    float4 _MainTex_TexelSize;
    //模糊半径
    float _BlurRadius;

    v2f_blur vert_blur(appdata_img v)
    {
        v2f_blur o;
        o.pos = UnityObjectToClipPos(v.vertex);
        o.uv = v.texcoord.xy;

        //计算uv四个角在blur半径下的uv坐标
        o.uv1 = v.texcoord.xy + _BlurRadius * _MainTex_TexelSize * float2(1, 1);
        o.uv2 = v.texcoord.xy + _BlurRadius * _MainTex_TexelSize * float2(-1, 1);
        o.uv3 = v.texcoord.xy + _BlurRadius * _MainTex_TexelSize * float2(-1, -1);
        o.uv4 = v.texcoord.xy + _BlurRadius * _MainTex_TexelSize * float2(1, -1);
        //o.uv5 = v.texcoord.xy + _BlurRadius * _MainTex_TexelSize * float2(1, 0);
        //o.uv6 = v.texcoord.xy + _BlurRadius * _MainTex_TexelSize * float2(-1, 0);
        //o.uv7 = v.texcoord.xy + _BlurRadius * _MainTex_TexelSize * float2(0, 1);
        //o.uv8 = v.texcoord.xy + _BlurRadius * _MainTex_TexelSize * float2(0, -1);

        return o;
    }

    fixed4 frag_blur(v2f_blur i) : SV_Target
    {
        fixed4 color = fixed4(0, 0, 0, 0);

        color += tex2D(_MainTex, i.uv);
        color += tex2D(_MainTex, i.uv1);
        color += tex2D(_MainTex, i.uv2);
        color += tex2D(_MainTex, i.uv3);
        color += tex2D(_MainTex, i.uv4);
        //color += tex2D(_MainTex, i.uv5);
        //color += tex2D(_MainTex, i.uv6);
        //color += tex2D(_MainTex, i.uv7);
        //color += tex2D(_MainTex, i.uv8);

        return color * 0.2;
    }

    ENDCG

    SubShader
    {
        Pass
        {
            ZTest Always
            Cull Off
            ZWrite Off
            Fog {Mode Off}

            CGPROGRAM

            #pragma vertex vert_blur
            #pragma fragment frag_blur

            ENDCG
        }
    }
}
