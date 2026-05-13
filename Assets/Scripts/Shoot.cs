using UnityEngine;

public class Shoot : MonoBehaviour
{

    [SerializeField] 
    private float speed;
    

    void Start()
    {
        //Destroy(gameObject);
    }

    void Update()
    {
        transform.position += new Vector3(0, 0, speed * Time.deltaTime);
    }
}