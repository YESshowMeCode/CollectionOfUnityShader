using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreatAssetBundle  {

    [MenuItem ("Assets/Build AssetBundles")]     // 在Assets菜单下拓展Build AssetBundles按钮
    static void BuildAllAssetBundles ()          // 点击该按钮将执行本函数
    {
        BuildPipeline.BuildAssetBundles ("Path");   // 支持路径，如 Asset/AssetBundle
    }

}
