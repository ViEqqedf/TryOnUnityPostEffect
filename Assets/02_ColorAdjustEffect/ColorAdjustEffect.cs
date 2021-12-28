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

    private float lastBrightness = -1;
    private float lastContrast = -1;
    private float lastSaturation = -1;

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (_Material)
        {
            if (Math.Abs(lastBrightness - brightness) > 0.02f)
            {
                _Material.SetFloat("_Brightness", brightness);
                lastBrightness = brightness;
            }

            if (Math.Abs(lastContrast - contrast) > 0.02f)
            {
                _Material.SetFloat("_Contrast", contrast);
                lastContrast = contrast;
            }

            if (Math.Abs(lastSaturation - saturation) > 0.02f)
            {
                _Material.SetFloat("_Saturation", saturation);
                lastSaturation = saturation;
            }

            Graphics.Blit(src, dest, _Material);
        }
        else
        {
            //没有材质，直接绘制，不做后效
            Graphics.Blit(src, dest);
        }
    }
}
