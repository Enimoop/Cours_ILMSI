using UnityEngine;
using TMPro;

public class Score : MonoBehaviour
{
    [SerializeField]
    public static float score = 0;

    [SerializeField]
    private TMP_Text scoreText;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        score += Time.deltaTime * 10;
        scoreText.text = ((int)score).ToString();
    }
}
