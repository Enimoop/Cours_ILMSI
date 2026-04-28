using System.Diagnostics;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;

public class Player : MonoBehaviour
{
    [SerializeField]
    private float Speed = 10f;

    [SerializeField]
    private float SpeedDecrease = 0.9f;

    [SerializeField]
    private Rigidbody Body;

    private Vector2 _movement;

    [SerializeField]
    private int HP = 10;

    [SerializeField]
    private Slider HPSlider;

    [SerializeField]
    private GameObject GameOverScreen;

    [SerializeField] private Transform CameraTransform;
    [SerializeField] private float TiltAngle = 10f;
    [SerializeField] private float TiltSpeed = 5f;
    private float _currentTilt;

    void OnMove(InputValue value)
    {
        _movement = value.Get<Vector2>();
    }

    private void Update()
    {
        float target = -_movement.x * TiltAngle;
        _currentTilt += (target - _currentTilt) * Time.deltaTime * TiltSpeed;
        CameraTransform.localEulerAngles = new Vector3(0f, 0f, _currentTilt);
    }

    private void FixedUpdate()
    {
        if(_movement.magnitude > 0)
        {
            Body.AddForce((Vector3)_movement * Speed, ForceMode.Impulse);
        }
    }

    private void OnTriggerEnter(Collider other)
    {
        Obstacle o = other.GetComponent<Obstacle>();
        if(o != null)
        {
            int damages = o.Explode();
            HP -= damages;
            HPSlider.value = HP;
            if (HP <= 0)
            {
                enabled = false;
                GameOverScreen.SetActive(true);
            }
        }
    }
}
