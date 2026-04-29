using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.InputSystem;
using TMPro;

public class Interact : MonoBehaviour
{
    float raycastDistance = 3;

    public TMP_Text interactText;
    public Camera cam;
    void Update()
    {
        Vector2 mousePos = Mouse.current.position.ReadValue();
        Ray ray = cam.ScreenPointToRay(mousePos);
        RaycastHit hit;

        if (Physics.Raycast(ray, out hit, raycastDistance))
        {
            Transform interactable = FindTagInParents(hit.collider.transform, "Interactable");

            if (interactable != null)
            {
                interactText.text = "Appuyer sur [E]";

                if (Keyboard.current.eKey.wasPressedThisFrame)
                {
                    Debug.Log("E");
                }
            }
        }
        else
        {   
                interactText.text = "";
        }
    }
    
    Transform FindTagInParents(Transform t, string tag)
    {
        while (t != null)
        {
            if (t.CompareTag(tag)) return t;
            t = t.parent;
        }
        return null;
    }
}