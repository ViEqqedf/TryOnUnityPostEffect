Shader "Custom/BloomEffect"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BlurTex("Blur", 2D) = "white"{}
    }

    CGINCLUDE
    #include "UnityCG.cginc"

    //用于阈值提取高亮部分
    struct v2f_threshold
    {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
    };

    //用于blur
    struct v2f_blur
    {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
        float4 uv01 : TEXCOORD1;
        float4 uv23 : TEXCOORD2;
        float4 uv45 : TEXCOORD3;
    };

    //用于bloom
    struct v2f_bloom
    {
	    float4 pos : SV_POSITION;
    	float2 uv : TEXCOORD0;
    	float2 uv1 : TEXCOORD1;
    };

    sampler2D _MainTex;
	float4 _MainTex_TexelSize;
	sampler2D _BlurTex;
	float4 _BlurTex_TexelSize;
	float4 _offsets;
	float4 _colorThreshold;
	float4 _bloomColor;
	float _bloomFactor;

    //提取高亮部分
    v2f_threshold vert_threshold(appdata_img v)
    {
        v2f_threshold o;
        o.pos = UnityWorldToClipPos(v.vertex);
        o.uv = v.texcoord.xy;

        //dx中纹理的左上角为初始坐标，需要反向处理
#if UNITY_UV_STARTS_AT_TOP
        if(_MainTex_TexelSize.y < 0)
            o.uv.y = 1 - o.uv.y;
#endif

        return o;
    }

    fixed4 frag_threshold(v2f_threshold i) : SV_Target
    {
        fixed4 color = tex2D(_MainTex, i.uv);
        //仅当color大于设置的阈值的时候才输出
        return saturate(color - _colorThreshold);
    }

    //高斯模糊
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

	//高斯模糊
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

    v2f_bloom vert_bloom(appdata_img v)
    {
	    v2f_bloom o;
    	o.pos = UnityObjectToClipPos(v.vertex);
    	o.uv.xy = v.texcoord.xy;
#if UNITY_UV_STARTS_AT_TOP
		if(_MainTex_TexelSize.y < 0)
			o.uv.y = 1 - o.uv.y;
#endif

    	return o;
    }

	fixed4 frag_bloom(v2f_bloom i) : SV_Target
    {
    	//取原始清晰图片进行uv采样
    	fixed4 original = tex2D(_MainTex, i.uv);
    	//取模糊图片进行uv采样
    	fixed4 blur = tex2D(_BlurTex, i.uv);

    	//输出 = 原始图像 + bloom权值 * blur颜色 * bloom颜色
    	fixed4 final = original + _bloomFactor * blur * _bloomColor;
    	return final;
    }

    ENDCG

	SubShader
	{
		//提取高亮
		Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off }

			CGPROGRAM
			#pragma vertex vert_threshold
			#pragma fragment frag_threshold
			ENDCG
		}

		//高斯模糊
		Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off }

			CGPROGRAM
			#pragma vertex vert_blur
			#pragma fragment frag_blur
			ENDCG
		}

		//Bloom
		Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off }

			CGPROGRAM
			#pragma vertex vert_bloom
			#pragma fragment frag_bloom
			ENDCG
		}
	}
}
