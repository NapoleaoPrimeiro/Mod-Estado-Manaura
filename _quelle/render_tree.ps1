# Zeichnet einen HOI4-Fokusbaum als PNG (HOI4-Raster: 1 x = 96 px, 1 y = 130 px)
# und meldet Überlappungen. Aufruf: render_tree.ps1 -File <focus.txt> -Out <png> [-Loc <yml>]
param([string]$File, [string]$Out, [string]$Loc = "", [double]$Scale = 0.5)
Add-Type -AssemblyName System.Drawing
$text = [IO.File]::ReadAllText($File)
$text = [regex]::Replace($text, '(?m)#.*$', '')

function Get-Blocks([string]$s, [string]$key) {
	# Inhalte aller "key = { ... }" auf oberster Ebene von $s (ein Durchlauf)
	$res = New-Object System.Collections.Generic.List[string]
	$depth = 0; $start = -1
	foreach ($m in [regex]::Matches($s, "(?<![\w])$key\s*=\s*\{|\{|\}")) {
		if ($m.Value -eq '{') { $depth++ }
		elseif ($m.Value -eq '}') { $depth--; if ($depth -eq 0 -and $start -ge 0) { $res.Add($s.Substring($start, $m.Index - $start)); $start = -1 } }
		else { if ($depth -eq 0) { $start = $m.Index + $m.Length }; $depth++ }
	}
	return ,$res
}function Top([string]$s, [string]$key) {
	# Wert eines einfachen Schlüssels auf oberster Ebene
	$depth = 0
	foreach ($m in [regex]::Matches($s, "(\{|\}|(?<![\w])$key\s*=\s*([\w\.\-]+))")) {
		if ($m.Value -eq '{') { $depth++ } elseif ($m.Value -eq '}') { $depth-- } elseif ($depth -eq 0) { return $m.Groups[2].Value }
	}
	return $null
}
$tree = (Get-Blocks $text "focus_tree")[0]
$foc = @{}; $order = @()
foreach ($b in (Get-Blocks $tree "focus")) {
	$id = Top $b "id"
	$pre = @(); foreach ($p in (Get-Blocks $b "prerequisite")) { foreach ($m in [regex]::Matches($p, 'focus\s*=\s*(\w+)')) { $pre += $m.Groups[1].Value } }
	$mx = @(); foreach ($p in (Get-Blocks $b "mutually_exclusive")) { foreach ($m in [regex]::Matches($p, 'focus\s*=\s*(\w+)')) { $mx += $m.Groups[1].Value } }
	$foc[$id] = @{ id = $id; x = [int](Top $b "x"); y = [int](Top $b "y"); rel = (Top $b "relative_position_id"); pre = $pre; mx = $mx }
	$order += $id
}
# relative Positionen auflösen
function Abs($id, $seen) {
	$f = $foc[$id]; if ($f.done) { return }
	if ($f.rel -and $foc.ContainsKey($f.rel) -and -not $seen.Contains($id)) { [void]$seen.Add($id); Abs $f.rel $seen; $f.x += $foc[$f.rel].x; $f.y += $foc[$f.rel].y }
	$f.done = $true
}
foreach ($id in $order) { Abs $id (New-Object System.Collections.Generic.HashSet[string]) }
$names = @{}
if ($Loc -and (Test-Path $Loc)) { foreach ($l in [IO.File]::ReadAllLines($Loc)) { if ($l -match '^\s*(\w+):\d*\s*"(.*)"') { $names[$matches[1]] = $matches[2] } } }

# Statistik: horizontale Abstände benachbarter Fokusse in derselben Zeile
$rows = $foc.Values | Group-Object { $_.y }
$gaps = @{}
foreach ($r in $rows) { $xs = @($r.Group | ForEach-Object { $_.x } | Sort-Object); for ($i = 1; $i -lt $xs.Count; $i++) { $gaps[$xs[$i] - $xs[$i-1]]++ } }
"Fokusse: $($foc.Count)"; foreach ($r2 in ($foc.Values | Group-Object { $_.y })) { $xs = @($r2.Group | Sort-Object { $_.x }); for ($k = 1; $k -lt $xs.Count; $k++) { if ($xs[$k].x - $xs[$k-1].x -lt 2) { "  ZU ENG: $($xs[$k-1].id) / $($xs[$k].id) (y=$($r2.Name))" } } }
"Abstand gleiche Zeile -> Anzahl: " + (($gaps.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name):$($_.Value)" }) -join "  ")
# Linien, die durch fremde Fokusse laufen
$cross = 0
foreach ($f in $foc.Values) { foreach ($p in $f.pre) { if (-not $foc.ContainsKey($p)) { continue }; $a = $foc[$p]
	foreach ($o in $foc.Values) { if ($o.id -eq $f.id -or $o.id -eq $p) { continue }
		if ($o.y -gt $a.y -and $o.y -lt $f.y) {
			$t = ($o.y - $a.y) / ($f.y - $a.y); $lx = $a.x + ($f.x - $a.x) * $t
			if ([math]::Abs($lx - $o.x) -lt 0.6) { $cross++; if ($cross -le 40) { "  Linie $p -> $($f.id) läuft durch $($o.id)" } }
		} } } }
"Linien durch fremde Fokusse: $cross"

# Zeichnen
$minx = ($foc.Values | ForEach-Object { $_.x } | Measure-Object -Minimum).Minimum; $maxx = ($foc.Values | ForEach-Object { $_.x } | Measure-Object -Maximum).Maximum
$maxy = ($foc.Values | ForEach-Object { $_.y } | Measure-Object -Maximum).Maximum
$W = [int](($maxx - $minx + 2) * 96 * $Scale); $H = [int](($maxy + 2) * 130 * $Scale)
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp); $g.Clear([System.Drawing.Color]::FromArgb(40, 44, 40)); $g.SmoothingMode = 'AntiAlias'
$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(200, 200, 160)), 2
$mxPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::Red), 2
$font = New-Object System.Drawing.Font "Arial", ([float](9 * $Scale * 1.6))
function PX($f) { return @((($f.x - $minx + 1) * 96 * $Scale), (($f.y + 0.6) * 130 * $Scale)) }
foreach ($f in $foc.Values) { $b = PX $f; foreach ($p in $f.pre) { if ($foc.ContainsKey($p)) { $a = PX $foc[$p]; $g.DrawLine($pen, [float]$a[0], [float]$a[1], [float]$b[0], [float]$b[1]) } } }
foreach ($f in $foc.Values) { $b = PX $f
	$g.FillRectangle([System.Drawing.Brushes]::SteelBlue, [float]($b[0] - 30 * $Scale), [float]($b[1] - 30 * $Scale), [float](60 * $Scale), [float](55 * $Scale))
	$n = if ($names.ContainsKey($f.id)) { $names[$f.id] } else { $f.id }
	$rect = New-Object System.Drawing.RectangleF ([float]($b[0] - 70 * $Scale)), ([float]($b[1] + 27 * $Scale)), ([float](140 * $Scale)), ([float](40 * $Scale))
	$g.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(120, 0, 0, 0))), $rect)
	$g.DrawString($n, $font, [System.Drawing.Brushes]::White, $rect)
}
$bmp.Save($Out)
"Bild: $Out ($W x $H)"
