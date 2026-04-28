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

    void OnMove(InputValue value)
    {
        _movement = value.Get<Vector2>();
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
