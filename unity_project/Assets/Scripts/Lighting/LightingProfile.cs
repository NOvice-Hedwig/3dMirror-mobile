using UnityEngine;

/// <summary>
/// Applies lighting presets to match the app's minimal warm-grey aesthetic.
/// Three profiles matching the Flutter design language:
///   studioMinimal  — warm diffuse, matches #F7F6F3 background
///   softDaylight   — neutral, for before/after comparisons
///   dramatic       — strong side key, accentuates muscle definition
/// </summary>
public class LightingProfile : MonoBehaviour
{
    [Header("Lights")]
    [SerializeField] private Light keyLight;
    [SerializeField] private Light fillLight;
    [SerializeField] private Light rimLight;
    [SerializeField] private Light ambientFill;

    [Header("Background")]
    [SerializeField] private Camera renderCamera;

    // ── Preset data ───────────────────────────────────────────────────────────

    private static readonly LightingPreset StudioMinimal = new LightingPreset
    {
        bgColor        = new Color(0.97f, 0.96f, 0.95f),   // #F7F6F3
        ambientColor   = new Color(0.88f, 0.87f, 0.86f),
        keyColor       = new Color(1.00f, 0.98f, 0.95f),   keyIntensity = 1.1f,
        keyAngle       = new Vector3(35f, -30f, 0f),
        fillColor      = new Color(0.85f, 0.88f, 0.92f),   fillIntensity = 0.4f,
        fillAngle      = new Vector3(20f,  140f, 0f),
        rimColor       = new Color(1.00f, 0.98f, 0.95f),   rimIntensity  = 0.6f,
        rimAngle       = new Vector3(-20f, 180f, 0f),
    };

    private static readonly LightingPreset SoftDaylight = new LightingPreset
    {
        bgColor        = new Color(0.95f, 0.96f, 0.98f),
        ambientColor   = new Color(0.82f, 0.85f, 0.90f),
        keyColor       = new Color(0.95f, 0.97f, 1.00f),   keyIntensity = 1.0f,
        keyAngle       = new Vector3(45f, -15f, 0f),
        fillColor      = new Color(0.90f, 0.92f, 0.95f),   fillIntensity = 0.55f,
        fillAngle      = new Vector3(15f,  150f, 0f),
        rimColor       = new Color(0.80f, 0.85f, 1.00f),   rimIntensity  = 0.3f,
        rimAngle       = new Vector3(-15f, 160f, 0f),
    };

    private static readonly LightingPreset Dramatic = new LightingPreset
    {
        bgColor        = new Color(0.93f, 0.92f, 0.91f),
        ambientColor   = new Color(0.60f, 0.58f, 0.56f),
        keyColor       = new Color(1.00f, 0.98f, 0.94f),   keyIntensity = 1.6f,
        keyAngle       = new Vector3(30f, -60f, 0f),
        fillColor      = new Color(0.70f, 0.72f, 0.78f),   fillIntensity = 0.2f,
        fillAngle      = new Vector3(10f,  120f, 0f),
        rimColor       = new Color(1.00f, 0.97f, 0.90f),   rimIntensity  = 1.0f,
        rimAngle       = new Vector3(-30f, 200f, 0f),
    };

    // ── Public API ────────────────────────────────────────────────────────────

    public void Apply(string profileName)
    {
        var preset = profileName switch
        {
            "softDaylight" => SoftDaylight,
            "dramatic"     => Dramatic,
            _              => StudioMinimal,
        };
        ApplyPreset(preset);
    }

    void Start() => Apply("studioMinimal");

    // ── Internal ──────────────────────────────────────────────────────────────

    private void ApplyPreset(LightingPreset p)
    {
        RenderSettings.ambientMode  = UnityEngine.Rendering.AmbientMode.Flat;
        RenderSettings.ambientLight = p.ambientColor;

        SetLight(keyLight,  p.keyColor,  p.keyIntensity,  p.keyAngle);
        SetLight(fillLight, p.fillColor, p.fillIntensity, p.fillAngle);
        SetLight(rimLight,  p.rimColor,  p.rimIntensity,  p.rimAngle);

        if (renderCamera != null)
            renderCamera.backgroundColor = p.bgColor;
    }

    private static void SetLight(Light light, Color color, float intensity, Vector3 euler)
    {
        if (light == null) return;
        light.color     = color;
        light.intensity = intensity;
        light.transform.localEulerAngles = euler;
    }
}

// ── Data ──────────────────────────────────────────────────────────────────────

internal struct LightingPreset
{
    public Color  bgColor, ambientColor;
    public Color  keyColor;   public float keyIntensity;   public Vector3 keyAngle;
    public Color  fillColor;  public float fillIntensity;  public Vector3 fillAngle;
    public Color  rimColor;   public float rimIntensity;   public Vector3 rimAngle;
}
