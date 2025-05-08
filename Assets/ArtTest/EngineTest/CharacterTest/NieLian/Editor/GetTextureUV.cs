using System.Collections;
using System.Collections.Generic;
using UnityEngine;

#if  UNITY_EDITOR
using UnityEditor;

public class GetTextureUV : EditorWindow
{
    [MenuItem("Tools/妆容贴图UV计算")]
    public static void ShowWindow()
    {
        EditorWindow.GetWindow(typeof(GetTextureUV));
    }

    private Vector2 textureOffset = Vector2.zero;
    private Vector2 baseMapResolution = new Vector2(2048, 2048);
    private Vector2 clipMapResolution = new Vector2(512, 512);
    private Vector4 result = Vector4.zero;
    Vector4 ExecuteUV(Vector2 baseResolution,Vector2 clipResolution,Vector2 clipOffset)
    {
        Vector4 result_ST = Vector4.zero;
        result_ST.x = baseResolution.x / clipResolution.x;
        result_ST.y = baseResolution.y / clipResolution.y;

        float x_rate = clipOffset.x / baseResolution.x;
        float y_rate = clipOffset.y / baseResolution.y;
        
        Vector2 result_offset = new Vector2(x_rate,y_rate) * new Vector2(result_ST.x,result_ST.y) * new Vector2(-1,1);
        
        result_ST.z = result_offset.x;
        result_ST.w = result_offset.y;
        
        
        return result_ST;
    }
    void OnGUI()
    {
        EditorGUILayout.BeginVertical();
        baseMapResolution = EditorGUILayout.Vector2Field( "主纹理分辨率",baseMapResolution);
        EditorGUILayout.BeginHorizontal();
        clipMapResolution = EditorGUILayout.Vector2Field( "裁剪纹理分辨率",clipMapResolution);
        textureOffset = EditorGUILayout.Vector2Field( "贴图偏移",textureOffset);
        EditorGUILayout.EndHorizontal();
        if (GUILayout.Button("计算UV"))
        {
           var value = ExecuteUV(baseMapResolution,clipMapResolution,textureOffset);
           result = value;
        }

        EditorGUILayout.BeginHorizontal();
        result = EditorGUILayout.Vector4Field("结果(Tilling—Offset):",result);
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.EndVertical();
    }
}

#endif
