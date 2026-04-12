# Unity ↔ Flutter Bridge 集成指南

## 概述

Flutter 通过 Method Channel 调用 Unity，Unity 通过 Event Channel 回调 Flutter。

推荐使用 **flutter_unity_widget** 插件（pub.dev），它已封装好双向通信。

---

## 1. Unity 项目配置

### 1.1 导入 flutter_unity_widget 对应的 Unity package

```
https://github.com/juicycleff/flutter-unity-view-widget
```

下载 `FlutterUnityPackage.unitypackage` 并导入到 Unity 项目。

### 1.2 场景配置

1. 创建空 GameObject，命名为 **`BridgeReceiver`**（名称必须完全匹配）
2. 挂载 `BridgeReceiver.cs` 脚本
3. 在 Inspector 中分配：
   - `Male Base Prefab` → 男性占位 Avatar prefab
   - `Female Base Prefab` → 女性占位 Avatar prefab
   - `Avatar Root` → Avatar 父节点 Transform
   - `Camera Rig` → 相机控制器
   - `Lighting Profile` → 灯光配置器

### 1.3 ProceduralAvatar 占位配置（无真实资产时）

1. 创建空 GameObject → 挂载 `ProceduralAvatar.cs` + `AvatarController.cs`
2. 右键点击 Inspector → `Rebuild` → 自动生成身体几何体
3. 将此 GameObject 做成 Prefab，分别赋值给 Male/Female Prefab 插槽

---

## 2. Method Channel 规范

### Flutter → Unity（BridgeReceiver 接收）

所有调用通过 `SendMessage("BridgeReceiver", methodName, jsonString)` 触发。

| 方法名 | JSON 参数 |
|--------|-----------|
| `LoadAvatar` | `{"avatar_id": "male_base"}` |
| `ApplyBodyParams` | 见下方详细结构 |
| `SetCameraPreset` | `{"preset": "front"}` |
| `SetLightingProfile` | `{"profile": "studioMinimal"}` |
| `ExportScreenshot` | `""` (空字符串) |
| `PlayAnimation` | `{"name": "idle_breathe"}` |
| `Reset` | `""` |

### ApplyBodyParams 完整结构

```json
{
  "height_norm":    0.4,
  "weight_norm":    0.5,
  "body_fat_norm":  0.35,
  "waist_norm":     0.30,
  "hip_norm":       0.38,
  "shoulder_norm":  0.55,
  "muscle_norm":    0.22,
  "gender":         "male",
  "duration_ms":    600
}
```

所有 norm 值为 0.0–1.0。`duration_ms` 控制过渡动画时长。

---

## 3. Event Channel 规范

### Unity → Flutter

Unity 调用 `BridgeReceiver.SendToFlutter(event)` 发送 JSON 到 Flutter。

| 事件 type | 触发时机 | 额外字段 |
|-----------|----------|---------|
| `ready` | Unity 场景加载完成，Avatar 就绪 | — |
| `morphComplete` | ApplyBodyParams 动画结束 | — |
| `screenshot` | ExportScreenshot 完成 | `"screenshot": "<base64 PNG>"` |
| `error` | 任何错误 | `"error": "错误描述"` |

---

## 4. Morph Target 命名规范（真实资产）

Blender 中的 Shape Keys 名称必须与以下完全匹配：

| Shape Key | 驱动参数 | 说明 |
|-----------|----------|------|
| `belly_fat` | `body_fat_norm × 1.1` | 腹部脂肪 |
| `waist_wide` | `waist_norm` | 腰部宽度 |
| `hip_wide` | `hip_norm` | 髋部宽度 |
| `shoulder_wide` | `shoulder_norm` | 肩宽 |
| `arm_thick` | `fat × 0.6 + muscle × 0.2` | 手臂粗细 |
| `leg_thick` | `fat × 0.7 + muscle × 0.15` | 腿部粗细 |
| `muscle_def` | `muscle_norm` | 肌肉线条清晰度 |

---

## 5. Camera Preset 参数

| Preset | Distance | Yaw | Pitch | 用途 |
|--------|----------|-----|-------|------|
| `front` | 3.5 | 0° | 5° | 默认正面 |
| `side` | 3.5 | 90° | 5° | 侧面 |
| `quarter` | 3.5 | 40° | 8° | 45°斜角（最好看） |
| `top` | 4.0 | 0° | 70° | 俯视 |

---

## 6. Lighting Profile 参数

| Profile | 背景色 | 风格 | 用途 |
|---------|--------|------|------|
| `studioMinimal` | #F7F6F3 暖灰 | 柔和 | 默认，匹配 App 背景 |
| `softDaylight` | #F2F4F8 冷白 | 自然 | 前后对比 |
| `dramatic` | #EDECEB 深灰 | 戏剧 | 突出肌肉线条 |

---

## 7. 集成检查清单

- [ ] `BridgeReceiver` GameObject 命名正确
- [ ] 所有 Inspector 插槽已分配
- [ ] Unity Build Settings → Platform: iOS
- [ ] Player Settings → Bundle ID 与 Flutter 一致
- [ ] `flutter_unity_widget` 已在 pubspec.yaml 添加
- [ ] iOS podfile 已运行 `pod install`
- [ ] 真机测试：Flutter hot reload 后 Unity 视口正常显示
