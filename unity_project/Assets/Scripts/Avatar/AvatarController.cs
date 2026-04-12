using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Controls morph targets (BlendShapes) on the avatar mesh.
///
/// Morph target names in your .fbx / .glb must match exactly:
///   belly_fat, waist_wide, hip_wide, shoulder_wide,
///   arm_thick, leg_thick, muscle_def
///
/// For the placeholder phase (no real asset), this script works with
/// a simple procedural mesh and scales bone transforms instead.
/// </summary>
[RequireComponent(typeof(Animator))]
public class AvatarController : MonoBehaviour
{
    // ── Inspector ─────────────────────────────────────────────────────────────
    [Header("Skinned mesh (for BlendShape morphs)")]
    [SerializeField] private SkinnedMeshRenderer bodyMesh;

    [Header("Fallback: bone scaling (placeholder mode)")]
    [SerializeField] private Transform boneSpine;
    [SerializeField] private Transform boneHips;
    [SerializeField] private Transform boneChest;
    [SerializeField] private Transform boneLeftArm;
    [SerializeField] private Transform boneRightArm;
    [SerializeField] private Transform boneLeftLeg;
    [SerializeField] private Transform boneRightLeg;

    private Animator    _anim;
    private MorphParams _current = MorphParams.Zero;

    // BlendShape index cache
    private Dictionary<string, int> _morphIdx = new();

    static readonly string[] MorphNames =
    {
        "belly_fat", "waist_wide", "hip_wide", "shoulder_wide",
        "arm_thick",  "leg_thick",  "muscle_def",
    };

    // ─────────────────────────────────────────────────────────────────────────
    void Awake()
    {
        _anim = GetComponent<Animator>();
        if (bodyMesh != null)
        {
            foreach (var name in MorphNames)
            {
                int idx = bodyMesh.sharedMesh.GetBlendShapeIndex(name);
                if (idx >= 0) _morphIdx[name] = idx;
            }
        }
    }

    // ── Public API ────────────────────────────────────────────────────────────

    public IEnumerator AnimateMorphs(MorphParams target, float duration)
    {
        var start   = _current;
        var elapsed = 0f;

        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            var t = Mathf.SmoothStep(0, 1, elapsed / duration);
            Apply(MorphParams.Lerp(start, target, t));
            yield return null;
        }

        Apply(target);
        _current = target;

        BridgeReceiver.SendToFlutter(new FlutterEvent { type = "morphComplete" });
    }

    public void PlayAnimation(string clipName)
    {
        if (_anim != null && _anim.HasState(0, Animator.StringToHash(clipName)))
            _anim.Play(clipName);
    }

    // ── Apply morphs ──────────────────────────────────────────────────────────

    private void Apply(MorphParams p)
    {
        if (bodyMesh != null && _morphIdx.Count > 0)
            ApplyBlendShapes(p);
        else
            ApplyBoneScaling(p);
    }

    /// Real asset path: drive BlendShape weights (0–100 scale in Unity)
    private void ApplyBlendShapes(MorphParams p)
    {
        void Set(string name, float val)
        {
            if (_morphIdx.TryGetValue(name, out var idx))
                bodyMesh.SetBlendShapeWeight(idx, val * 100f);
        }

        Set("belly_fat",    p.bellySize);
        Set("waist_wide",   p.waistWidth);
        Set("hip_wide",     p.hipWidth);
        Set("shoulder_wide",p.shoulderWidth);
        Set("arm_thick",    p.armThickness);
        Set("leg_thick",    p.legThickness);
        Set("muscle_def",   p.muscleDefinition);
    }

    /// Placeholder path: scale bones to approximate body shape
    private void ApplyBoneScaling(MorphParams p)
    {
        if (boneSpine  != null) boneSpine.localScale  = new Vector3(
            1f + p.waistWidth * 0.25f,
            1f,
            1f + p.bellySize  * 0.3f);

        if (boneHips   != null) boneHips.localScale   = new Vector3(
            1f + p.hipWidth   * 0.2f, 1f, 1f + p.hipWidth * 0.15f);

        if (boneChest  != null) boneChest.localScale  = new Vector3(
            1f + p.shoulderWidth * 0.15f, 1f, 1f + p.bellySize * 0.2f);

        void ScaleArm(Transform bone)
        {
            if (bone == null) return;
            var s = 1f + p.armThickness * 0.25f;
            bone.localScale = new Vector3(s, 1f, s);
        }
        void ScaleLeg(Transform bone)
        {
            if (bone == null) return;
            var s = 1f + p.legThickness * 0.25f;
            bone.localScale = new Vector3(s, 1f, s);
        }

        ScaleArm(boneLeftArm);  ScaleArm(boneRightArm);
        ScaleLeg(boneLeftLeg);  ScaleLeg(boneRightLeg);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MorphParams value type — all values 0.0–1.0
// ═══════════════════════════════════════════════════════════════════════════

[System.Serializable]
public struct MorphParams
{
    public float bellySize;
    public float waistWidth;
    public float hipWidth;
    public float chestWidth;
    public float shoulderWidth;
    public float armThickness;
    public float legThickness;
    public float muscleDefinition;

    public static MorphParams Zero => new MorphParams();

    public static MorphParams Lerp(MorphParams a, MorphParams b, float t) => new MorphParams
    {
        bellySize        = Mathf.Lerp(a.bellySize,        b.bellySize,        t),
        waistWidth       = Mathf.Lerp(a.waistWidth,       b.waistWidth,       t),
        hipWidth         = Mathf.Lerp(a.hipWidth,         b.hipWidth,         t),
        chestWidth       = Mathf.Lerp(a.chestWidth,       b.chestWidth,       t),
        shoulderWidth    = Mathf.Lerp(a.shoulderWidth,    b.shoulderWidth,    t),
        armThickness     = Mathf.Lerp(a.armThickness,     b.armThickness,     t),
        legThickness     = Mathf.Lerp(a.legThickness,     b.legThickness,     t),
        muscleDefinition = Mathf.Lerp(a.muscleDefinition, b.muscleDefinition, t),
    };
}
