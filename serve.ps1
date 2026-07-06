# 最小の静的ファイルサーバ（ビルド不要・依存なし）
# 使い方:  powershell -ExecutionPolicy Bypass -File serve.ps1
# ブラウザで http://localhost:5501 を開く
$port = 5501
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$mime = @{
  ".html"="text/html; charset=utf-8"; ".css"="text/css; charset=utf-8";
  ".js"="text/javascript; charset=utf-8"; ".json"="application/json; charset=utf-8";
  ".webmanifest"="application/manifest+json; charset=utf-8";
  ".png"="image/png"; ".svg"="image/svg+xml"; ".ico"="image/x-icon"
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Serving $root at http://localhost:$port/"

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $path = [System.Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
  if ($path -eq "/") { $path = "/index.html" }
  $file = Join-Path $root ($path.TrimStart("/"))

  if (Test-Path $file -PathType Leaf) {
    $ext = [System.IO.Path]::GetExtension($file).ToLower()
    $ct = $mime[$ext]; if (-not $ct) { $ct = "application/octet-stream" }
    $bytes = [System.IO.File]::ReadAllBytes($file)
    $ctx.Response.ContentType = $ct
    $ctx.Response.ContentLength64 = $bytes.Length
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } else {
    $ctx.Response.StatusCode = 404
    $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $path")
    $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
  }
  $ctx.Response.OutputStream.Close()
}
