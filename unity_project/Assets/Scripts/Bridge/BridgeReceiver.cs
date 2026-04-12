using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

/// <summary>
/// 3D Mirror — BridgeReceiver
///
/// Receives commands from Flutter via Unity's SendMessage mechanism.
/// Attach this MonoBehaviour to a GameObject named exactly "BridgeReceiver"
/// in your main scene.
///
/// Flutter → Unity:  MethodChannel → native plugin → SendMessage("BridgeReceiver", methodName, jsonArgs)
/// Unity → Flutter:  EventChannel  → UnityBridgePlugin.SendEvent(jsonPayload)
/// </summary>
public class BridgeReceiver : MonoBehaviour
{
    // ── Singleton ────────────────────────────────────────────────────────────
    public static BridgeReceiver Instance { get; private set; }

    // ── Inspector refs ────────────────────────────────────────────────────────
    [Header("Avatar")]
    [SerializeField] private GameObject   maleBasePrefab;
    [SerializeField] private GameObject   femaleBasePrefab;
    [SerializeField] private Transform    avatarRoot;

    [Header("Camera")]
    [SerializeField] private CameraRig    cameraRig;

    [Header("Lighting")]
    [SerializeField] private LightingProfile lightingProfile;

    // ── State ─────────────────────────────────────────────────────────────────
    private GameObject    _currentAvatar;
    private AvatarController _avatarCtrl;

    // ─────────────────────────────────────────────────────────────────────────
    void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
        DontDestroyOnLoad(gameObject);
    }

    void Start()
    {
        // Signal Flutter that Unity is ready
        SendToFlutter(new FlutterEvent { type = "ready" });
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Flutter → Unity entry points (called via SendMessage)
    // Method names must match _Methods constants in unity_bridge.dart exactly
    // ═════════════════════════════════════════════════════════════════════════

    /// LoadAvatar({"avatar_id": "male_base"})
    public void LoadAvatar(string json)
    {
        var args     = JsonUtility.FromJson<LoadAvatarArgs>(json);
        var prefab   = args.avatar_id.StartsWith("female") ? femaleBasePrefab : maleBasePrefab;

        if (_currentAvatar != null) Destroy(_currentAvatar);
        _currentAvatar = Instantiate(prefab, avatarRoot);
        _avatarCtrl    = _currentAvatar.GetComponent<AvatarController>();

        if (_avatarCtrl == null)
            _avatarCtrl = _currentAvatar.AddComponent<AvatarController>();

        SendToFlutter(new FlutterEvent { type = "ready" });
    }

    /// ApplyBodyParams({...morph values, duration_ms: 600})
    public void ApplyBodyParams(string json)
    {
        var args = JsonUtility.FromJson<BodyParamArgs>(json);
        if (_avatarCtrl == null) return;

        var p = new MorphParams
        {
            bellySize       = args.body_fat_norm * 1.1f,
            waistWidth      = args.waist_norm,
            hipWidth        = args.hip_norm,
            shoulderWidth   = args.shoulder_norm,
            muscleDefinition= args.muscle_norm,
            armThickness    = Mathf.Clamp01(args.body_fat_norm * 0.6f + args.muscle_norm * 0.2f),
            legThickness    = Mathf.Clamp01(args.body_fat_norm * 0.7f + args.muscle_norm * 0.15f),
        };

        float duration = args.duration_ms / 1000f;
        StartCoroutine(_avatarCtrl.AnimateMorphs(p, duration));
    }

    /// SetCameraPreset({"preset": "front"})
    public void SetCameraPreset(string json)
    {
        var args = JsonUtility.FromJson<CameraArgs>(json);
        cameraRig?.SetPreset(args.preset);
    }

    /// SetLightingProfile({"profile": "studioMinimal"})
    public void SetLightingProfile(string json)
    {
        var args = JsonUtility.FromJson<LightingArgs>(json);
        lightingProfile?.Apply(args.profile);
    }

    /// ExportScreenshot (no args)
    public void ExportScreenshot(string _)
    {
        StartCoroutine(CaptureAndSend());
    }

    /// PlayAnimation({"name": "idle_breathe"})
    public void PlayAnimation(string json)
    {
        var args = JsonUtility.FromJson<AnimationArgs>(json);
        _avatarCtrl?.PlayAnimation(args.name);
    }

    /// Reset (no args)
    public void Reset(string _)
    {
        if (_avatarCtrl != null)
            StartCoroutine(_avatarCtrl.AnimateMorphs(MorphParams.Zero, 0.4f));
        cameraRig?.SetPreset("front");
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Unity → Flutter
    // ═════════════════════════════════════════════════════════════════════════

    private IEnumerator CaptureAndSend()
    {
        yield return new WaitForEndOfFrame();

        var tex = ScreenCapture.CaptureScreenshotAsTexture();
        var png = tex.EncodeToPNG();
        Destroy(tex);

        var b64 = Convert.ToBase64String(png);
        SendToFlutter(new FlutterEvent { type = "screenshot", screenshot = b64 });
    }

    public static void SendToFlutter(FlutterEvent evt)
    {
        var json = JsonUtility.ToJson(evt);
        // The actual send mechanism depends on the Flutter-Unity plugin you use.
        // Option A: flutter_unity_widget plugin
        //   UnityMessageManager.Instance.SendMessageToFlutter(json);
        // Option B: custom native plugin via EventChannel
        //   NativeBridge.SendToFlutter(json);
        // For now, log so you can verify during integration:
        Debug.Log($"[BridgeReceiver → Flutter] {json}");
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// Serializable argument structs
// ═══════════════════════════════════════════════════════════════════════════

[Serializable] public class LoadAvatarArgs   { public string avatar_id; }
[Serializable] public class CameraArgs       { public string preset; }
[Serializable] public class LightingArgs     { public string profile; }
[Serializable] public class AnimationArgs    { public string name; }

[Serializable]
public class BodyParamArgs
{
    public float height_norm;
    public float weight_norm;
    public float body_fat_norm;
    public float waist_norm;
    public float hip_norm;
    public float shoulder_norm;
    public float muscle_norm;
    public string gender;
    public int    duration_ms = 600;
}

[Serializable]
public class FlutterEvent
{
    public string type;
    public string screenshot;  // base64 PNG, only for screenshot events
    public string error;
}
