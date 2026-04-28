using UnityEngine;
using UnityEngine.SceneManagement;

public class GameOver : MonoBehaviour

{
    public void PlayAgain()
    {
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
        Score.score = 0;
    }

    public void Quit()
    {
        Application.Quit();
    }
}
