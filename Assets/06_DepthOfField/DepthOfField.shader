// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/DepthOfField"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BlurTex ("Blur", 2D) = "white"{}
    }

    CGINCLUDE
    #include "UnityCG.cginc"

	struct v2f_blur
	{
		float4 pos : SV_POSITION;
		float2 uv  : TEXCOORD0;
		float4 uv01 : TEXCOORD1;
		float4 uv23 : TEXCOORD2;
		float4 uv45 : TEXCOORD3;
	};

    struct v2f_dof
    {
	    float4 pos : SV_POSITION;
    	float2 uv : TEXCOORD0;
    	float2 uv1 : TEXCOORD1;
    };

    sampler2D _MainTex;
    float4 _MainTex_TexelSize;
    sampler2D _BlurTex;
    sampler2D_float _CameraDepthTexture;
    float4 _offsets;
    float _focalDistance;
    float _nearBlurScale;
    float _farBlurScale;

    //高斯模糊
	v2f_blur vert_blur(appdata_img v)
	{
		v2f_blur o;
		_offsets *= _MainTex_TexelSize.xyxy;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;

		o.uv01 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1);
		o.uv23 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1) * 2.0;
		o.uv45 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1) * 3.0;

		return o;
	}

	//高斯模糊
	fixed4 frag_blur(v2f_blur i) : SV_Target
	{
		fixed4 color = fixed4(0,0,0,0);
		color += 0.40 * tex2D(_MainTex, i.uv);
		color += 0.15 * tex2D(_MainTex, i.uv01.xy);
		color += 0.15 * tex2D(_MainTex, i.uv01.zw);
		color += 0.10 * tex2D(_MainTex, i.uv23.xy);
		color += 0.10 * tex2D(_MainTex, i.uv23.zw);
		color += 0.05 * tex2D(_MainTex, i.uv45.xy);
		color += 0.05 * tex2D(_MainTex, i.uv45.zw);
		return color;
	}

	v2f_dof vert_dof(appdata_img v)
	{
		v2f_dof o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = v.texcoord.xy;
		o.uv1.xy = o.uv.xy;

		//dx中纹理坐标的起点为左上角，需要做一次反向
		#if UNITY_UV_STARTS_AT_TOP
		if(_MainTex_TexelSize.y < 0)
			o.uv.y = 1 - o.uv.y;
		#endif

		return o;
	}

    fixed4 frag_dof(v2f_dof i) : SV_Target
    {
    	//取原始清晰图片做一次uv采样
    	fixed4 original = tex2D(_MainTex, i.uv1);
    	//取模糊图片做一次uv采样
    	fixed4 blur = tex2D(_BlurTex, i.uv);
    	//取当前位置对应的深度值
    	float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
    	//将其转化到线性01空间
		depth = Linear01Depth(depth);

    	//远景处理
    	//深度小于焦点，使用原始清晰图像
    	//深度大于焦点，使用模糊图像与清晰图像的差值，通过差值避免在模糊区和清晰区之间产生明显的边界
		fixed4 final = (depth <= _focalDistance) ? original :
    		lerp(original, blur, clamp((depth - _focalDistance) * _farBlurScale, 0, 1));

    	//近景处理
    	//操作与上面相反
    	final = (depth > _focalDistance) ? final :
    		lerp(original, blur, clamp((_focalDistance - depth) * _nearBlurScale, 0, 1));

    	//规避分支的计算方式
		// float focalTest = clamp(sign(depth - _focalDistance),0,1);
		// fixed4 final = (1 - focalTest) * ori +
			// focalTest * lerp(ori, blur, clamp((depth - _focalDistance) * _farBlurScale, 0, 1));
		// final = (focalTest)* final +
			// (1 - focalTest) * lerp(ori, blur, clamp((_focalDistance - depth) * _nearBlurScale, 0, 1));

    	return final;
    }

    ENDCG

	SubShader
	{
		//pass 0: 高斯模糊
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

		//pass 1: 景深效果
		Pass
		{

			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off }
			ColorMask RGBA

			CGPROGRAM
			#pragma vertex vert_dof
			#pragma fragment frag_dof
			ENDCG
		}
	}
}
