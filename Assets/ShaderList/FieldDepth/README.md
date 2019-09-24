# Depth of Field

# 1.简介
Depth of Field 景深效果是一个描述在空间中们可以清楚成像的距离范围，透镜将光聚到某一固定的距离，远离此点则会逐渐模糊。在Unity中，可以通过后处理的方式来实现景深的效果。
# 2.实现原理

 - 首先设置一个焦点，焦点的值必须在观察坐标系下的远近裁剪面之间。
 - 获取屏幕图像，对图像添加模糊，这里使用的是高斯模糊，保存在一个RT中。
 - 获取每个像素的深度值depth，depth小于焦点的像素使用原始清晰的图像获取Color，depth大于焦点的则使用保存好的模糊图像RT与原始清晰图像与depth距离的插值，避免模糊与清晰之间有明显的边界。

# 3.代码实现

# 4.效果图
 
![image](https://github.com/YESshowMeCode/CollectionOfUnityShader/blob/master/Assets/ShaderList/FieldDepth/FieldDepth.gif)
