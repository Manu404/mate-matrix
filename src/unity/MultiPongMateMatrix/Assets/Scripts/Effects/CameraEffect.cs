﻿using OpenPixelControl;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraEffect : PixelEffect
{
    public Texture Texture;

    public MateGrid Grid;

    [Header("Provided by " + nameof(Main))]
    public float Delay;

    [Header("Dynamic")]
    public Texture2D ResizedTexture;

    public override IEnumerator Effect(Client client, PixelStrip pixels, float delay)
    {
        // So it can modified during runtime.
        Delay = delay;

        yield return new WaitForEndOfFrame();

        ReadPixels();

        int width = ResizedTexture.width;
        int height = ResizedTexture.height;

        var pixelsList = new List<Pixel>();

        for (int i = 0; i < width * height; i++)
        {
            pixelsList.Add(new Pixel(default, default, default));
        }

        while (true)
        {
            yield return new WaitForEndOfFrame();

            ReadPixels();

            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    Color pixel = ResizedTexture.GetPixel(x, y);

                    var cratePos = new Vector2Int(
                        x / Grid.CrateSize.x,
                        Grid.CrateSize.y - y / Grid.CrateSize.y
                    );

                    int crateWidth = Grid.CrateSize.x;
                    int crateHeight = Grid.CrateSize.y;

                    var posInCrate = new Vector2Int(
                        x - crateWidth * cratePos.x,
                        y - crateHeight * cratePos.y
                    );

                    // The effective X is shifted one row on two because we zig zag down

                    int effectiveX = posInCrate.y % 2 == 0 ? posInCrate.x : crateWidth - posInCrate.x;
                    int zigZagPosInCrate = posInCrate.y * crateWidth + effectiveX;

                    int ledsPerCrate = crateWidth * crateHeight;
                    int ledsPerRow = ledsPerCrate * Grid.GridSize.x;

                    int zigZagPos = ledsPerRow * cratePos.y + cratePos.x * ledsPerCrate + zigZagPosInCrate;

                    Color.RGBToHSV(pixel, out float H, out float S, out float V);

                    pixelsList[zigZagPos] = new Pixel((byte)pixel.r, (byte)pixel.g, (byte)pixel.b);
                }
            }

            client.putPixels(pixelsList);

            yield return new WaitForSeconds(Delay);
        }
    }

    /// <summary>
    /// Read camera buffer, resize it then store it in <see cref="ResizedTexture"/>
    /// </summary>
    private void ReadPixels()
    {
        // Debug.Log("Hello!");

        int originalWidth = Texture.width;
        int originalHeight = Texture.height;

        // TODO: Don't auto-retrieve camera
        ResizedTexture = ToTexture2D(Texture, Camera.main);
        ResizedTexture.name = "[Dynamic]";

        Resources.UnloadUnusedAssets();
    }

    private Texture2D ToTexture2D(Texture texture, Camera camera)
    {
        // RenderTexture targetTexture = camera.targetTexture;
        Texture targetTexture = texture;

        int width = targetTexture.width;
        int height = targetTexture.height;

        Texture2D text2d = new Texture2D(width, height);

        RenderTexture.active = (RenderTexture)Texture;
        text2d.ReadPixels(new Rect(0, 0, width, height), 0, 0);

        text2d.Apply();

        return ResizeTexture(
            text2d,
            ImageFilterMode.Average,
            // (float)Grid.GetWidth() / Texture.width
            (float)Grid.GetHeight() / Texture.height
        );
    }

    public enum ImageFilterMode : int
    {
        Nearest = 0,
        Biliner = 1,
        Average = 2
    }

    // http://blog.collectivemass.com/2014/03/resizing-textures-in-unity/
    public static Texture2D ResizeTexture(Texture2D pSource, ImageFilterMode pFilterMode, float pScale)
    {

        //*** Variables
        int i;

        //*** Get All the source pixels
        Color[] aSourceColor = pSource.GetPixels(0);
        Vector2 vSourceSize = new Vector2(pSource.width, pSource.height);

        //*** Calculate New Size
        float xWidth = Mathf.RoundToInt((float)pSource.width * pScale);
        float xHeight = Mathf.RoundToInt((float)pSource.height * pScale);

        //*** Make New
        Texture2D oNewTex = new Texture2D((int)xWidth, (int)xHeight, TextureFormat.RGBA32, false);

        //*** Make destination array
        int xLength = (int)xWidth * (int)xHeight;
        Color[] aColor = new Color[xLength];

        Vector2 vPixelSize = new Vector2(vSourceSize.x / xWidth, vSourceSize.y / xHeight);

        //*** Loop through destination pixels and process
        Vector2 vCenter = new Vector2();
        for (i = 0; i < xLength; i++)
        {

            //*** Figure out x&y
            float xX = (float)i % xWidth;
            float xY = Mathf.Floor((float)i / xWidth);

            //*** Calculate Center
            vCenter.x = (xX / xWidth) * vSourceSize.x;
            vCenter.y = (xY / xHeight) * vSourceSize.y;

            //*** Do Based on mode
            //*** Nearest neighbour (testing)
            if (pFilterMode == ImageFilterMode.Nearest)
            {

                //*** Nearest neighbour (testing)
                vCenter.x = Mathf.Round(vCenter.x);
                vCenter.y = Mathf.Round(vCenter.y);

                //*** Calculate source index
                int xSourceIndex = (int)((vCenter.y * vSourceSize.x) + vCenter.x);

                //*** Copy Pixel
                aColor[i] = aSourceColor[xSourceIndex];
            }

            //*** Bilinear
            else if (pFilterMode == ImageFilterMode.Biliner)
            {

                //*** Get Ratios
                float xRatioX = vCenter.x - Mathf.Floor(vCenter.x);
                float xRatioY = vCenter.y - Mathf.Floor(vCenter.y);

                //*** Get Pixel index's
                int xIndexTL = (int)((Mathf.Floor(vCenter.y) * vSourceSize.x) + Mathf.Floor(vCenter.x));
                int xIndexTR = (int)((Mathf.Floor(vCenter.y) * vSourceSize.x) + Mathf.Ceil(vCenter.x));
                int xIndexBL = (int)((Mathf.Ceil(vCenter.y) * vSourceSize.x) + Mathf.Floor(vCenter.x));
                int xIndexBR = (int)((Mathf.Ceil(vCenter.y) * vSourceSize.x) + Mathf.Ceil(vCenter.x));

                //*** Calculate Color
                aColor[i] = Color.Lerp(
                    Color.Lerp(aSourceColor[xIndexTL], aSourceColor[xIndexTR], xRatioX),
                    Color.Lerp(aSourceColor[xIndexBL], aSourceColor[xIndexBR], xRatioX),
                    xRatioY
                );
            }

            //*** Average
            else if (pFilterMode == ImageFilterMode.Average)
            {

                //*** Calculate grid around point
                int xXFrom = (int)Mathf.Max(Mathf.Floor(vCenter.x - (vPixelSize.x * 0.5f)), 0);
                int xXTo = (int)Mathf.Min(Mathf.Ceil(vCenter.x + (vPixelSize.x * 0.5f)), vSourceSize.x);
                int xYFrom = (int)Mathf.Max(Mathf.Floor(vCenter.y - (vPixelSize.y * 0.5f)), 0);
                int xYTo = (int)Mathf.Min(Mathf.Ceil(vCenter.y + (vPixelSize.y * 0.5f)), vSourceSize.y);

                //*** Loop and accumulate
                Vector4 oColorTotal = new Vector4();
                Color oColorTemp = new Color();
                float xGridCount = 0;
                for (int iy = xYFrom; iy < xYTo; iy++)
                {
                    for (int ix = xXFrom; ix < xXTo; ix++)
                    {

                        //*** Get Color
                        oColorTemp += aSourceColor[(int)(((float)iy * vSourceSize.x) + ix)];

                        //*** Sum
                        xGridCount++;
                    }
                }

                //*** Average Color
                aColor[i] = oColorTemp / (float)xGridCount;
            }
        }

        //*** Set Pixels
        oNewTex.SetPixels(aColor);
        oNewTex.Apply();

        //*** Return
        return oNewTex;
    }
}
