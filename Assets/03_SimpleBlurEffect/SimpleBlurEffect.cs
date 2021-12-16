using UnityEngine;
using System.Collections;

//编辑状态下也运行
[ExecuteInEditMode]
//继承自PostEffectBase
public class SimpleBlurEffect : PostEffectBase
{
    //模糊半径
    public float BlurRadius = 1.0f;
    //降低分辨率
    public int downSample = 2;
    //迭代次数
    public int iteration = 3;

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (_Material)
        {
            //申请RT，RT的分辨率按downSample降低
            RenderTexture rt1 = RenderTexture.GetTemporary(
                source.width >> downSample, source.height >> downSample,
                0, source.format);
            RenderTexture rt2 = RenderTexture.GetTemporary(
                source.width >> downSample, source.height >> downSample,
                0, source.format);

            //将原图拷贝到降低分辨率的RT上
            Graphics.Blit(source, rt1);

            for (int i = 0; i < iteration; i++)
            {
                //降分辨率，模糊处理
                _Material.SetFloat("_BlurRadius", BlurRadius);
                Graphics.Blit(rt1, rt2, _Material);
                Graphics.Blit(rt2, rt1, _Material);
            }

            //把结果拷贝到目标RT
            Graphics.Blit(rt1, destination);

            RenderTexture.ReleaseTemporary(rt1);
            RenderTexture.ReleaseTemporary(rt2);
        }
    }
}