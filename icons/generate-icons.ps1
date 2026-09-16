# PWAアイコン生成（Node/Python不要、.NET System.Drawing のみ使用）
# 使い方: powershell -ExecutionPolicy Bypass -File generate-icons.ps1
# 読書記録・思考メモ・ほしい/やりたい・就活選考管理の4つで
# 角丸の形・余白・記号の太さを揃え、色と中の記号だけ変えている。
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

function P([single]$x, [single]$y) { New-Object System.Drawing.PointF($x, $y) }

function RoundRect($x, $y, $w, $h, $r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $r * 2
  $p.AddArc($x, $y, $d, $d, 180, 90)
  $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $p.CloseFigure()
  return $p
}

$bg = [System.Drawing.Color]::FromArgb(255, 0x5B, 0x8F, 0xC9)   # --accent
$fg = [System.Drawing.Color]::FromArgb(255, 0xFF, 0xFF, 0xFF)

function Draw-Symbol($g, $size, $brush, $bgBrush) {
  # 開いた本。中央（背）が沈み、外側のページが持ち上がる形にすると本に見える
  $left = @(
    (P ($size * 0.155) ($size * 0.305)), (P ($size * 0.465) ($size * 0.365)),
    (P ($size * 0.465) ($size * 0.755)), (P ($size * 0.155) ($size * 0.695))
  )
  $right = @(
    (P ($size * 0.535) ($size * 0.365)), (P ($size * 0.845) ($size * 0.305)),
    (P ($size * 0.845) ($size * 0.695)), (P ($size * 0.535) ($size * 0.755))
  )
  $g.FillPolygon($brush, [System.Drawing.PointF[]]$left)
  $g.FillPolygon($brush, [System.Drawing.PointF[]]$right)
}

function New-Icon([int]$size, [string]$path, [bool]$square) {
  $bmp = New-Object System.Drawing.Bitmap($size, $size)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

  $bgBrush = New-Object System.Drawing.SolidBrush($bg)
  if ($square) {
    # iOSのホーム画面は自分で角を丸めるので、apple-touch-icon用は四角のまま
    $g.FillRectangle($bgBrush, 0, 0, $size, $size)
  } else {
    $g.FillPath($bgBrush, (RoundRect 0 0 $size $size ([int]($size * 0.22))))
  }

  $fgBrush = New-Object System.Drawing.SolidBrush($fg)
  Draw-Symbol $g ([single]$size) $fgBrush $bgBrush

  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose()
  $bmp.Dispose()
}

New-Icon -size 192 -path (Join-Path $root "icon-192.png") -square $false
New-Icon -size 512 -path (Join-Path $root "icon-512.png") -square $false
New-Icon -size 180 -path (Join-Path $root "apple-touch-icon.png") -square $true
New-Icon -size 32  -path (Join-Path $root "favicon-32.png") -square $false
New-Icon -size 16  -path (Join-Path $root "favicon-16.png") -square $false

Write-Host "Icons generated in $root"
