$url = "https://raw.githubusercontent.com/emran-alhaddad/Saudi-Riyal-Font/main/fonts/regular/saudi_riyal.ttf"
$dest1 = "c:\Hansuke\Work\raheeq_main\assets\fonts\saudi_riyal.ttf"
$dest2 = "c:\Hansuke\Work\rahiq_driver\assets\fonts\saudi_riyal.ttf"

Invoke-WebRequest -Uri $url -OutFile $dest1
New-Item -ItemType Directory -Force -Path "c:\Hansuke\Work\rahiq_driver\assets\fonts" | Out-Null
Copy-Item $dest1 -Destination $dest2
