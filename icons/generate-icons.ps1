# PWAアイコン生成（Node/Python不要、.NET System.Drawing のみ使用）
# 使い方: powershell -ExecutionPolicy Bypass -File generate-icons.ps1
# 読書記録・思考メモ・ほしい/やりたい・就活選考管理の4つで
# 角丸の形・余白を揃え、色と中の絵だけ変えている。
# 読書記録は「夜に本を読む人」：夜空の色の地に満月、その前で積んだ本に腰かけて本を読む人の影。
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
function C([int]$a, [int]$r, [int]$g, [int]$b) { [System.Drawing.Color]::FromArgb($a, $r, $g, $b) }

$bg   = C 255 0x24 0x37 0x5E   # 夜空
$moon = C 255 0xFB 0xE7 0xAE   # 月と星
$ink  = C 255 0x16 0x22 0x3D   # 人と本の影(夜空より少し濃く)

# 4方向に尖った星
function Star($g, $s, $cx, $cy, $r, $brush) {
  $pts = @()
  for ($i = 0; $i -lt 8; $i++) {
    $a = [Math]::PI / 4 * $i - [Math]::PI / 2
    $rr = if ($i % 2 -eq 0) { $r } else { $r * 0.32 }
    $pts += (P ($s * ($cx + $rr * [Math]::Cos($a))) ($s * ($cy + $rr * [Math]::Sin($a))))
  }
  $g.FillPolygon($brush, [System.Drawing.PointF[]]$pts)
}
# 太さ w(アイコンの幅に対する割合)の丸い線で、点をつないで描く(人の体)
function Limb($g, $s, $w, $pts) {
  $pen = New-Object System.Drawing.Pen($ink, [single]($s * $w))
  $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  $arr = @(); for ($i = 0; $i -lt $pts.Length; $i += 2) { $arr += (P ($s * $pts[$i]) ($s * $pts[$i + 1])) }
  $g.DrawLines($pen, [System.Drawing.PointF[]]$arr)
  $pen.Dispose()
}

function Draw-Symbol($g, [single]$s) {
  $moonB = New-Object System.Drawing.SolidBrush($moon)
  $inkB  = New-Object System.Drawing.SolidBrush($ink)

  # 月のまわりの光(外に向かってうすくなる) → 満月
  $halo = New-Object System.Drawing.Drawing2D.GraphicsPath
  $halo.AddEllipse($s * 0.06, $s * 0.01, $s * 0.88, $s * 0.88)
  $hb = New-Object System.Drawing.Drawing2D.PathGradientBrush($halo)
  $hb.CenterColor = (C 70 0xFB 0xE7 0xAE)
  $hb.SurroundColors = [System.Drawing.Color[]]@((C 0 0xFB 0xE7 0xAE))
  $hb.FocusScales = (P 0.62 0.62)
  $g.FillPath($hb, $halo)
  $g.FillEllipse($moonB, $s * 0.19, $s * 0.14, $s * 0.62, $s * 0.62)

  # 星
  Star $g $s 0.165 0.205 0.045 $moonB
  Star $g $s 0.855 0.255 0.032 $moonB
  $g.FillEllipse($moonB, $s * 0.80, $s * 0.12, $s * 0.022, $s * 0.022)
  $g.FillEllipse($moonB, $s * 0.12, $s * 0.40, $s * 0.018, $s * 0.018)

  # 積んだ本(腰かけている台)
  $g.FillPath($inkB, (RoundRect ($s * 0.25) ($s * 0.775) ($s * 0.46) ($s * 0.07) ($s * 0.012)))
  $g.FillPath($inkB, (RoundRect ($s * 0.29) ($s * 0.71) ($s * 0.38) ($s * 0.068) ($s * 0.012)))

  # 本を読む人(横向き・ひざを立てて座り、本の方へ少しうつむく)
  Limb $g $s 0.105 @(0.415, 0.665,  0.392, 0.575,  0.415, 0.50)          # 背中
  Limb $g $s 0.075 @(0.43, 0.675,  0.565, 0.585,  0.60, 0.69)            # もも → すね
  $g.FillEllipse($inkB, $s * 0.39, $s * 0.355, $s * 0.118, $s * 0.118)    # 頭
  Limb $g $s 0.045 @(0.43, 0.525,  0.51, 0.595,  0.555, 0.54)            # 腕

  # 開いた本。どの大きさでも本に見えるよう、正面から見た開いた本の形を顔の方へ傾ける
  $bk = New-Object System.Drawing.Drawing2D.GraphicsPath
  $u = $s * 0.195
  $bk.AddPolygon([System.Drawing.PointF[]]@((P (-0.5 * $u) (-0.2 * $u)), (P (-0.04 * $u) (-0.08 * $u)), (P (-0.04 * $u) (0.32 * $u)), (P (-0.5 * $u) (0.22 * $u))))
  $bk.AddPolygon([System.Drawing.PointF[]]@((P (0.04 * $u) (-0.08 * $u)), (P (0.5 * $u) (-0.2 * $u)), (P (0.5 * $u) (0.22 * $u)), (P (0.04 * $u) (0.32 * $u))))
  $m = New-Object System.Drawing.Drawing2D.Matrix
  $m.Translate($s * 0.60, $s * 0.49)
  $m.Rotate(-24)
  $bk.Transform($m)
  $g.FillPath($inkB, $bk)
}

function New-Icon([int]$size, [string]$path, [bool]$square) {
  # 細かい絵なので4倍の大きさで描いてから縮め、線のふちをなめらかにする
  $k = 4
  $S = [single]($size * $k)
  $big = New-Object System.Drawing.Bitmap(($size * $k), ($size * $k))
  $g = [System.Drawing.Graphics]::FromImage($big)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

  $bgBrush = New-Object System.Drawing.SolidBrush($bg)
  if ($square) {
    # iOSのホーム画面は自分で角を丸めるので、apple-touch-icon用は四角のまま
    $g.FillRectangle($bgBrush, 0, 0, $S, $S)
  } else {
    $g.FillPath($bgBrush, (RoundRect 0 0 $S $S ([int]($S * 0.22))))
  }
  Draw-Symbol $g $S
  $g.Dispose()

  $bmp = New-Object System.Drawing.Bitmap($size, $size)
  $g2 = [System.Drawing.Graphics]::FromImage($bmp)
  $g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g2.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g2.DrawImage($big, 0, 0, $size, $size)
  $g2.Dispose()
  $big.Dispose()
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

New-Icon -size 192 -path (Join-Path $root "icon-192.png") -square $false
New-Icon -size 512 -path (Join-Path $root "icon-512.png") -square $false
New-Icon -size 180 -path (Join-Path $root "apple-touch-icon.png") -square $true
New-Icon -size 32  -path (Join-Path $root "favicon-32.png") -square $false
New-Icon -size 16  -path (Join-Path $root "favicon-16.png") -square $false

Write-Host "Icons generated in $root"
