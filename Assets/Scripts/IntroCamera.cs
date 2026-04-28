using UnityEngine;
using UnityEngine.InputSystem;

public class IntroCamera : MonoBehaviour
{
    private float mouseSensitivity = 90f;
    public Transform playerBody;

    private float xRotation = 0f;
    private float yRotation = 0f;

    private void Start()
    {
        // Cursor.lockState = CursorLockMode.Locked;
        // Cursor.visible = false;
    }

    private void Update()
    {
        // float mouseX = Input.GetAxis("Mouse X") * mouseSensitivity * Time.deltaTime;
        // float mouseY = Input.GetAxis("Mouse Y") * mouseSensitivity * Time.deltaTime;

        // xRotation -= mouseY;
        // xRotation = Mathf.Clamp(xRotation, -90f, 90f);
        // transform.localRotation = Quaternion.Euler(xRotation, 0f, 0f);
        // playerBody.Rotate(Vector3.up * mouseX);

        // yRotation += mouseX;
        // yRotation = Mathf.Clamp(yRotation, -180f, 180f);
        // transform.localRotation = Quaternion.Euler(xRotation, yRotation, 0f);







        Vector2 mouseDelta = Mouse.current.delta.ReadValue() * mouseSensitivity * Time.deltaTime;
        float mouseX = mouseDelta.x;
        float mouseY = mouseDelta.y;
        
        xRotation -= mouseY;
        xRotation = Mathf.Clamp(xRotation, -90f, 90f);

        transform.localRotation = Quaternion.Euler(xRotation, 0f, 0f);
        playerBody.Rotate(Vector3.up * mouseX);
    }
}
