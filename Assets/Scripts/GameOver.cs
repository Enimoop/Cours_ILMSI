using UnityEngine;
using UnityEngine.SceneManagement;

public class GameOver : MonoBehaviour

{
    [SerializeField]
    private GameObject Spawner;

    public void PlayAgain()
    {
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
        Score.score = 0;
        Spawner.SetActive(true);
    }

    public void Quit()
    {
        Application.Quit();
    }
}
