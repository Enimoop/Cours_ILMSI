using UnityEngine;

public class EnterShipAnimation : MonoBehaviour
{
    public float rotationSpeed = 90f;

    private void Update()
    {
        transform.Rotate(Vector3.up, rotationSpeed * Time.deltaTime, Space.World);
    }
}
