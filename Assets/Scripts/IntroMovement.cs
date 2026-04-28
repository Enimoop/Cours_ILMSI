using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;

public class IntroMovement : MonoBehaviour
{
    public CharacterController controller;
    public float Speed = 10f;
    public float gravity = -9.81f;
    public float jumpHeight = 1.5f;

    private Vector2 _movement;
    private float _verticalVelocity;

    void OnMove(InputValue value)
    {
        _movement = value.Get<Vector2>();
    }

    private void Update()
    {
        // Gravité
        if (controller.isGrounded && _verticalVelocity < 0f)
            _verticalVelocity = -2f;
        else
            _verticalVelocity += gravity * Time.deltaTime;

        // Déplacement relatif à la direction du joueur
        Vector3 move = transform.right * _movement.x + transform.forward * _movement.y;
        move.y = 0f;

        controller.Move((move * Speed + Vector3.up * _verticalVelocity) * Time.deltaTime);
    }

}
