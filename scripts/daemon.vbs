' Vision Proxy 守护启动器 — 静默启动，无窗口
' 放在 shell:startup 启动文件夹中，登录时自动运行
Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' 项目根目录
Dim scriptDir, projDir
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
projDir = fso.GetParentFolderName(scriptDir)

' 设置 OLLAMA_MODELS 环境变量（用户级 + 当前进程）
On Error Resume Next
WshShell.Environment("USER").Item("OLLAMA_MODELS") = "D:\ollama\models"
WshShell.Environment("PROCESS").Item("OLLAMA_MODELS") = "D:\ollama\models"
On Error Goto 0

' 静默启动代理（0 = 隐藏窗口，False = 不等待）
WshShell.Run "pythonw """ & projDir & "\vision_proxy_server.py""", 0, False
