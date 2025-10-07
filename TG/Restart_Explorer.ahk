#Requires AutoHotkey v2.0


RestartExplorer() {
  
    ; Close Explorer
    RunWait("taskkill /f /im explorer.exe", , "Hide")

    Sleep(1000)  ; Wait 1 second for it to close

        ; Restart Explorer
    Run("explorer.exe")

}

; Call the function when script runs
RestartExplorer()