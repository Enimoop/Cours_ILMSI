using UnityEngine;

public class SkyboxParallax : MonoBehaviour
{
    public float intensity = 0.5f;
    private Vector3 lastPos;

    void Start()
    {
        lastPos = transform.position;
    }

    void Update()
    {
        Vector3 delta = transform.position - lastPos;
        float rot = RenderSettings.skybox.GetFloat("_Rotation");
        rot += delta.x * intensity;
        RenderSettings.skybox.SetFloat("_Rotation", rot + Time.deltaTime * intensity);
        lastPos = transform.position;
    }
}