using System.Collections;
using UnityEngine;

/// <summary>
/// Manages camera angles for avatar viewing.
/// Supports smooth animated transitions between presets.
/// Users can also drag to orbit (handled by OrbitInput).
/// </summary>
public class CameraRig : MonoBehaviour
{
    [Header("Camera reference")]
    [SerializeField] private Camera      cam;
    [SerializeField] private Transform   pivot;     // point to orbit around (avatar centre)

    [Header("Transition")]
    [SerializeField] private float       transitionDuration = 0.5f;
    [SerializeField] private AnimationCurve easeCurve = AnimationCurve.EaseInOut(0, 0, 1, 1);

    // ── Preset definitions ────────────────────────────────────────────────────
    // (distance, yaw°, pitch°)
    private static readonly Dictionary<string, (float dist, float yaw, float pitch)> Presets
        = new()
        {
            { "front",   (3.5f,   0f, 5f)  },
            { "side",    (3.5f,  90f, 5f)  },
            { "quarter", (3.5f,  40f, 8f)  },
            { "top",     (4.0f,   0f, 70f) },
        };

    // ── Orbit drag ────────────────────────────────────────────────────────────
    private float   _yaw   = 0f;
    private float   _pitch = 5f;
    private float   _dist  = 3.5f;
    private Vector2 _lastTouch;
    private bool    _dragging;

    // ─────────────────────────────────────────────────────────────────────────
    void LateUpdate()
    {
        HandleOrbitInput();
        ApplyTransform();
    }

    // ── Public API ────────────────────────────────────────────────────────────

    public void SetPreset(string name)
    {
        if (!Presets.TryGetValue(name, out var p)) return;
        StopAllCoroutines();
        StartCoroutine(AnimateTo(p.dist, p.yaw, p.pitch));
    }

    // ── Orbit input (touch / mouse) ───────────────────────────────────────────

    void HandleOrbitInput()
    {
#if UNITY_EDITOR
        if (Input.GetMouseButtonDown(0)) { _dragging = true; _lastTouch = Input.mousePosition; }
        if (Input.GetMouseButtonUp(0))   { _dragging = false; }
        if (_dragging)
        {
            Vector2 delta = (Vector2)Input.mousePosition - _lastTouch;
            _yaw   += delta.x * 0.3f;
            _pitch  = Mathf.Clamp(_pitch - delta.y * 0.2f, -20f, 80f);
            _lastTouch = Input.mousePosition;
        }
#else
        if (Input.touchCount == 1)
        {
            var touch = Input.GetTouch(0);
            if (touch.phase == TouchPhase.Began) { _dragging = true; _lastTouch = touch.position; }
            if (touch.phase == TouchPhase.Ended) { _dragging = false; }
            if (_dragging && touch.phase == TouchPhase.Moved)
            {
                var delta = touch.position - _lastTouch;
                _yaw   += delta.x * 0.3f;
                _pitch  = Mathf.Clamp(_pitch - delta.y * 0.2f, -20f, 80f);
                _lastTouch = touch.position;
            }
        }
        // Pinch to zoom
        if (Input.touchCount == 2)
        {
            var t0 = Input.GetTouch(0);
            var t1 = Input.GetTouch(1);
            var prevDist = Vector2.Distance(t0.position - t0.deltaPosition,
                                            t1.position - t1.deltaPosition);
            var currDist = Vector2.Distance(t0.position, t1.position);
            _dist = Mathf.Clamp(_dist - (currDist - prevDist) * 0.005f, 2f, 6f);
        }
#endif
    }

    void ApplyTransform()
    {
        var rot = Quaternion.Euler(_pitch, _yaw, 0);
        if (cam != null)
        {
            cam.transform.position = pivot.position + rot * Vector3.back * _dist;
            cam.transform.LookAt(pivot.position + Vector3.up * 1.0f);
        }
    }

    IEnumerator AnimateTo(float targetDist, float targetYaw, float targetPitch)
    {
        float startDist  = _dist,  startYaw  = _yaw,  startPitch  = _pitch;
        float elapsed    = 0f;
        while (elapsed < transitionDuration)
        {
            elapsed += Time.deltaTime;
            float t  = easeCurve.Evaluate(elapsed / transitionDuration);
            _dist    = Mathf.Lerp(startDist,  targetDist,  t);
            _yaw     = Mathf.Lerp(startYaw,   targetYaw,   t);
            _pitch   = Mathf.Lerp(startPitch, targetPitch, t);
            ApplyTransform();
            yield return null;
        }
        _dist = targetDist; _yaw = targetYaw; _pitch = targetPitch;
    }
}
