using UnityEngine;

/// <summary>
/// Generates a simple low-poly body from primitives.
/// Used as placeholder until the real .fbx asset is ready.
/// The AvatarController will scale the bones on this object.
///
/// Attach to an empty GameObject. Call Build() or it auto-builds in Start().
/// Replace with the real skinned mesh by swapping the prefab in BridgeReceiver.
/// </summary>
[ExecuteInEditMode]
public class ProceduralAvatar : MonoBehaviour
{
    [Header("Bones (auto-created if null)")]
    public Transform boneSpine;
    public Transform boneHips;
    public Transform boneChest;
    public Transform boneLeftArm;
    public Transform boneRightArm;
    public Transform boneLeftLeg;
    public Transform boneRightLeg;

    [Header("Material")]
    [SerializeField] private Material bodyMaterial;

    void Start() => Build();

    [ContextMenu("Rebuild")]
    public void Build()
    {
        // Clear existing children
        for (int i = transform.childCount - 1; i >= 0; i--)
            DestroyImmediate(transform.GetChild(i).gameObject);

        var mat = bodyMaterial != null
            ? bodyMaterial
            : new Material(Shader.Find("Universal Render Pipeline/Lit"));

        // Colour: warm grey matching app palette #D4D0C8
        mat.color = new Color(0.83f, 0.82f, 0.78f);

        // ── Head ──────────────────────────────────────────────────────────
        var head = CreateSphere("Head", new Vector3(0, 1.72f, 0), new Vector3(0.22f, 0.24f, 0.22f), mat);

        // ── Chest ─────────────────────────────────────────────────────────
        var chest = CreateCapsule("Chest", new Vector3(0, 1.38f, 0), new Vector3(0.32f, 0.38f, 0.22f), mat);
        boneChest = chest.transform;

        // ── Spine / waist ─────────────────────────────────────────────────
        var spine = CreateCapsule("Spine", new Vector3(0, 1.05f, 0), new Vector3(0.28f, 0.28f, 0.20f), mat);
        boneSpine = spine.transform;

        // ── Hips ──────────────────────────────────────────────────────────
        var hips = CreateCapsule("Hips", new Vector3(0, 0.82f, 0), new Vector3(0.34f, 0.22f, 0.24f), mat);
        boneHips = hips.transform;

        // ── Arms ──────────────────────────────────────────────────────────
        var lArm = CreateCapsule("ArmL", new Vector3(-0.30f, 1.32f, 0), new Vector3(0.10f, 0.36f, 0.10f), mat);
        boneLeftArm = lArm.transform;
        var rArm = CreateCapsule("ArmR", new Vector3( 0.30f, 1.32f, 0), new Vector3(0.10f, 0.36f, 0.10f), mat);
        boneRightArm = rArm.transform;

        // Forearms
        CreateCapsule("ForeArmL", new Vector3(-0.30f, 0.96f, 0), new Vector3(0.08f, 0.28f, 0.08f), mat);
        CreateCapsule("ForeArmR", new Vector3( 0.30f, 0.96f, 0), new Vector3(0.08f, 0.28f, 0.08f), mat);

        // ── Legs ──────────────────────────────────────────────────────────
        var lLeg = CreateCapsule("LegL", new Vector3(-0.12f, 0.45f, 0), new Vector3(0.14f, 0.46f, 0.14f), mat);
        boneLeftLeg = lLeg.transform;
        var rLeg = CreateCapsule("LegR", new Vector3( 0.12f, 0.45f, 0), new Vector3(0.14f, 0.46f, 0.14f), mat);
        boneRightLeg = rLeg.transform;

        // Calves
        CreateCapsule("CalfL", new Vector3(-0.12f, 0.10f, 0), new Vector3(0.11f, 0.38f, 0.11f), mat);
        CreateCapsule("CalfR", new Vector3( 0.12f, 0.10f, 0), new Vector3(0.11f, 0.38f, 0.11f), mat);

        // Feet
        CreateCube("FootL", new Vector3(-0.12f, -0.08f, 0.04f), new Vector3(0.10f, 0.07f, 0.20f), mat);
        CreateCube("FootR", new Vector3( 0.12f, -0.08f, 0.04f), new Vector3(0.10f, 0.07f, 0.20f), mat);

        // Wire up AvatarController bone references
        var ctrl = GetComponent<AvatarController>();
        if (ctrl != null)
        {
            // Use reflection to set private serialized fields
            SetField(ctrl, "boneSpine",    boneSpine);
            SetField(ctrl, "boneHips",     boneHips);
            SetField(ctrl, "boneChest",    boneChest);
            SetField(ctrl, "boneLeftArm",  boneLeftArm);
            SetField(ctrl, "boneRightArm", boneRightArm);
            SetField(ctrl, "boneLeftLeg",  boneLeftLeg);
            SetField(ctrl, "boneRightLeg", boneRightLeg);
        }
    }

    // ── Primitive helpers ─────────────────────────────────────────────────────

    private GameObject CreateSphere(string n, Vector3 pos, Vector3 scale, Material m)
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        Setup(go, n, pos, scale, m);
        return go;
    }

    private GameObject CreateCapsule(string n, Vector3 pos, Vector3 scale, Material m)
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Capsule);
        Setup(go, n, pos, scale, m);
        return go;
    }

    private GameObject CreateCube(string n, Vector3 pos, Vector3 scale, Material m)
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Cube);
        Setup(go, n, pos, scale, m);
        return go;
    }

    private void Setup(GameObject go, string n, Vector3 pos, Vector3 scale, Material m)
    {
        go.name = n;
        go.transform.SetParent(transform);
        go.transform.localPosition = pos;
        go.transform.localScale    = scale;
        go.GetComponent<Renderer>().material = m;
        Destroy(go.GetComponent<Collider>());
    }

    private static void SetField(object obj, string name, object val)
    {
        var f = obj.GetType().GetField(name,
            System.Reflection.BindingFlags.NonPublic |
            System.Reflection.BindingFlags.Instance);
        f?.SetValue(obj, val);
    }
}
