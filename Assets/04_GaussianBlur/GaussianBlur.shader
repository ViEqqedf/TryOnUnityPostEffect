Shader "Custom/GaussianBlur"
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
        float4 uv01 : TEXCOORD1;
        float4 uv23 : TEXCOORD2;
        float4 uv45 : TEXCOORD3;
    };

    sampler2D _MainTex;
    float4 _MainTex_TexelSize;
    // 横向or纵向blur
    float4 _offsets;

    v2f_blur vert_blur(appdata_img v)
    {
        v2f_blur o;
        o.pos = UnityObjectToClipPos(v.vertex);
        o.uv = v.texcoord.xy;

    	//偏移，或者说方差
        _offsets *= _MainTex_TexelSize.xyxy;

		//由于uv可以存储4个值，所以一个uv保存两个vector坐标
		//_offsets.xyxy * float4(1,1,-1,-1)可能表示(0,1,0,-1)，表示像素上下两个坐标
		//也可能是(1,0,-1,0)，表示像素左右两个像素点的坐标，下面*2.0，*3.0同理
        o.uv01 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1);
        o.uv23 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1) * 2.0;
        o.uv45 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1) * 3.0;

        return o;
    }


	//fragment shader
	fixed4 frag_blur(v2f_blur i) : SV_Target
	{
		fixed4 color = fixed4(0,0,0,0);
		//将像素本身以及像素左右（或者上下，取决于vertex shader传进来的uv坐标）像素值的加权平均
		//高斯核随便写的，只要保证核的总和=1，亮度不会被衰减就好
		color += 0.4 * tex2D(_MainTex, i.uv);
		color += 0.15 * tex2D(_MainTex, i.uv01.xy);
		color += 0.15 * tex2D(_MainTex, i.uv01.zw);
		color += 0.10 * tex2D(_MainTex, i.uv23.xy);
		color += 0.10 * tex2D(_MainTex, i.uv23.zw);
		color += 0.05 * tex2D(_MainTex, i.uv45.xy);
		color += 0.05 * tex2D(_MainTex, i.uv45.zw);
		return color;
	}

	ENDCG

	//开始SubShader
	SubShader
	{
		//开始一个Pass
		Pass
		{
			//后处理效果一般都是这几个状态
			ZTest Always
			Cull Off
			ZWrite Off
			Fog{ Mode Off }

			//使用上面定义的vertex和fragment shader
			CGPROGRAM
			#pragma vertex vert_blur
			#pragma fragment frag_blur
			ENDCG
		}
	}
}