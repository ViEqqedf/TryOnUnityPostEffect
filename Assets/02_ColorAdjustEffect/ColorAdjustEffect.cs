using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ColorAdjustEffect : PostEffectBase
{
    /// <summary>
    /// 亮度
    /// </summary>
    [Range(0.0f, 3.0f)]
    public float brightness = 1.0f;
    /// <summary>
    /// 对比度
    /// </summary>
    [Range(0.0f, 3.0f)]
    public float contrast = 1.0f;
    /// <summary>
    /// 饱和度
    /// </summary>
    [Range(0.0f, 3.0f)]
    public float saturation = 1.0f;

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (_Material)
        {
            _Material.SetFloat("_Brightness", brightness);
            _Material.SetFloat("_Contrast", contrast);
            _Material.SetFloat("_Saturation", saturation);
            
            Graphics.Blit(src, dest, _Material);
        }
        else
        {
            //没有材质，直接绘制，不做后效
            Graphics.Blit(src, dest);
        }
    }
}
