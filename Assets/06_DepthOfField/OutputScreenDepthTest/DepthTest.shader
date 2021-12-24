Shader "Custom/DepthTest"
{
    CGINCLUDE
    #include "UnityCG.cginc"

    //由unity内部赋值的相机深度纹理
    sampler2D _CameraDepthTexture;
    sampler2D _MainTex;
    float4 _MainTex_TexelSize;

    struct v2f
    {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
    };

    v2f vert(appdata_img v)
    {
        v2f o;
        o.pos = UnityObjectToClipPos(v.vertex);
        o.uv.xy = v.texcoord.xy;

        return o;
    }

    fixed4 frag(v2f i) : SV_Target
    {
        float depth = 0;

        //直接根据uv坐标取该点的深度值
		#if UNITY_UV_STARTS_AT_TOP
        depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
        #else
        depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, 1 - i.uv);
        #endif
        //将深度值变为线性01空间
        depth = Linear01Depth(depth);
        return float4(depth, depth, depth, 1);
    }

    ENDCG

    SubShader
    {
        Pass
        {
            ZTest Off
            Cull Off
            ZWrite Off
            Fog{ Mode Off }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
}
