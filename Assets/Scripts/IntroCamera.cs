using UnityEngine;
using UnityEngine.InputSystem;

public class IntroCamera : MonoBehaviour
{
    private float mouseSensitivity = 30f;
    public Transform playerBody;

    private float xRotation = 0f;
    private float yRotation = 0f;

    private void Start()
    {
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }

    private void Update()
    {
        if (Cursor.lockState != CursorLockMode.Locked && Mouse.current.leftButton.wasPressedThisFrame)
    {
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }
        Vector2 mouseDelta = Mouse.current.delta.ReadValue() * mouseSensitivity * Time.deltaTime;
        float mouseX = mouseDelta.x;
        float mouseY = mouseDelta.y;
        
        xRotation -= mouseY;
        xRotation = Mathf.Clamp(xRotation, -90f, 90f);

        transform.localRotation = Quaternion.Euler(xRotation, 0f, 0f);
        playerBody.Rotate(Vector3.up * mouseX);
    }
}
