using UnityEngine;

public class Obstacle : MonoBehaviour
{
    [SerializeField]
    public float Speed;

    [SerializeField]
    private float DestroyDistance;

    [SerializeField]
    private int Damages;

    // Update is called once per frame
    void Update()
    {
        transform.position += new Vector3(0, 0, -Speed * Time.deltaTime);

        if (transform.position.z < DestroyDistance)
        {
            Destroy(gameObject);
        }
    }

    public int Explode()
    {
        Destroy(gameObject);
        return Damages;
    }
}
