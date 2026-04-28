using UnityEngine;

public class Spawner : MonoBehaviour
{
    [SerializeField]
    private Obstacle ObstaclePrefab;

    [SerializeField]
    private Vector2 SpawnBounds;

    [SerializeField]
    private Vector2 SpawnDelay;

    private float _nextSpawn;

    [SerializeField]
    private int spawnAmount = 60;

    // Update is called once per frame
    void Update()
    {
        if(Time.time > _nextSpawn)
        {
            SpawnSphere();

            _nextSpawn = Time.time + Random.Range(SpawnDelay.x, SpawnDelay.y);

        }
    }

    private void SpawnSphere()
    {
        for (int i = 0; i < spawnAmount; i++)
		{
		    Obstacle o = Instantiate(ObstaclePrefab, transform);
		    o.transform.localPosition = new Vector3(
		        Random.Range(-SpawnBounds.x, SpawnBounds.x),
		        Random.Range(-SpawnBounds.y, SpawnBounds.y),
		        0);

		    o.Speed += Time.time * 0.1f;
		}
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.blue;

        Gizmos.DrawCube(transform.position, (Vector3)SpawnBounds);
    }
}
