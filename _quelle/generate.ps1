# =====================================================================
#  France Rework - Generator
#  Liest fokus_daten.txt / ideen_daten.txt / loc_extra.yml und erzeugt:
#   common/national_focus/france.txt   (ersetzt den Vanilla-Baum)
#   common/ideas/FRW_ideas.txt
#   localisation/german|english/FRW_l_*.yml
#   KONZEPT_FOKUSBAUM.md (Dokumentation)
#  Aufruf:  powershell -ExecutionPolicy Bypass -File generate.ps1
# =====================================================================
param(
	[string]$Hoi4 = "F:\Steam\steamapps\common\Hearts of Iron IV",
	[string]$R56  = ""
)
$ErrorActionPreference = "Stop"
$src  = $PSScriptRoot
$root = Split-Path -Parent $src
$bom  = New-Object Text.UTF8Encoding $true   # nur Lokalisierung (HOI4 verlangt BOM in .yml)
$nobom = New-Object Text.UTF8Encoding $false # Skriptdateien OHNE BOM, sonst bricht HOI4 den ersten Block ab
$errors = New-Object System.Collections.Generic.List[string]
$queue = New-Object System.Collections.Generic.List[object]   # Dateien werden erst geschrieben, wenn alle Prüfungen bestanden sind
$warns  = New-Object System.Collections.Generic.List[string]

function Q([string]$s) {
	# gerade Anführungszeichen im Text -> typografische (HOI4-Loc verträgt keine inneren ")
	$out = ""; $open = $true
	foreach ($ch in $s.ToCharArray()) {
		if ($ch -eq '"') { if ($open) { $out += [char]0x201E } else { $out += [char]0x201C }; $open = -not $open }
		else { $out += $ch }
	}
	return $out
}

# ------------------------------------------------------------- Ideen
$ideas = [ordered]@{}
$cur = $null
foreach ($line in Get-Content "$src\ideen_daten.txt" -Encoding UTF8) {
	if ($line -match '^\s*#' -or $line.Trim() -eq "") { continue }
	if ($line -match '^I (\S+)\|(\S+)\|(.+)$') {
		$cur = [ordered]@{ id = $matches[1]; pic = $matches[2]; name = $matches[3]; mods = @() }
		if ($ideas.Contains($cur.id)) { $errors.Add("Idee $($cur.id) doppelt definiert") }
		$ideas[$cur.id] = $cur
	} elseif ($line -match '^M (.+)$') { $cur.mods += $matches[1].Trim() }
}

# ------------------------------------------------------------- Fokusse
$focuses = New-Object System.Collections.Generic.List[object]
$cur = $null
foreach ($line in Get-Content "$src\fokus_daten.txt" -Encoding UTF8) {
	if ($line -match '^\s*#' -or $line.Trim() -eq "") { continue }
	$tag = $line.Substring(0, $line.IndexOf(' '))
	$val = $line.Substring($line.IndexOf(' ') + 1)
	switch ($tag) {
		"F" {
			$p = $val.Split('|')
			$cur = [ordered]@{ id=$p[0]; x=[int]$p[1]; y=[int]$p[2]; days=[int]$p[3]; icon=$p[4]; branch=$p[5]; path=$p[6]; filter=$p[7];
				name=""; desc=""; pre=@(); mx=@(); avail=@(); branchif=@(); branchAll=@(); sel=@(); byp=@(); eff=@(); doc=@(); tt=""; ai=$null }
			$focuses.Add($cur)
		}
		"N"  { $cur.name = $val }
		"D"  { $cur.desc = $val }
		"P"  { $cur.pre += ,@($val.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)) }
		"X"  { $cur.mx += $val.Split(' ', [StringSplitOptions]::RemoveEmptyEntries) }
		"A"  { $cur.avail += $val }
		"B"  { $cur.branchif += $val }
		"S"  { $cur.sel += $val }
		"Y"  { $cur.byp += $val }
		"E"  { $cur.eff += $val }
		"T"  { $cur.doc += $val }
		"AI" { $cur.ai = $val }
		"TT" { if ($cur.tt) { $cur.tt = $cur.tt + "\n" + $val } else { $cur.tt = $val } }
		default { $errors.Add("Unbekannte Zeile: $line") }
	}
}
$byId = @{}
foreach ($f in $focuses) {
	if ($byId.ContainsKey($f.id)) { $errors.Add("Doppelte Fokus-ID $($f.id)") }
	$byId[$f.id] = $f
}
# Gegenseitige Ausschlüsse spiegeln
foreach ($f in $focuses) {
	foreach ($m in $f.mx) {
		if (-not $byId.ContainsKey($m)) { $errors.Add("$($f.id): Ausschluss $m existiert nicht"); continue }
		if ($byId[$m].mx -notcontains $f.id) { $byId[$m].mx += $f.id }
	}
}

# ------------------------------------------------------------- Ast-Layout (automatisch nebeneinander)
$branchOrder = "Politik","Wirtschaft","Heer","Marine","Luftwaffe","Diplomatie","Kolonialreich","Iberien","Gesellschaft","Verwaltung","Geheim","Exil"
$cursor = 0
$row1 = "Politik","Wirtschaft","Heer","Marine","Luftwaffe","Diplomatie","Verwaltung","Exil"
# zweite Reihe: Ast -> (Anker-Ast, x-Versatz im Anker, y-Versatz)
$row2 = [ordered]@{ "Kolonialreich" = @("Wirtschaft", 0, 14); "Gesellschaft" = @("Marine", 0, 10) }
$bstart = @{}
foreach ($b in $branchOrder) {
	$l = @($focuses | Where-Object { $_.branch -eq $b })
	if ($l.Count -eq 0) { continue }
	$minx = ($l | ForEach-Object { $_.x } | Measure-Object -Minimum).Minimum
	$maxx = ($l | ForEach-Object { $_.x } | Measure-Object -Maximum).Maximum
	if ($row1 -contains $b) {
		foreach ($f in $l) { $f.x = $f.x - $minx + $cursor }
		$bstart[$b] = $cursor
		$cursor += ($maxx - $minx) + 3
	}
}
foreach ($b in $row2.Keys) {
	$l = @($focuses | Where-Object { $_.branch -eq $b }); if ($l.Count -eq 0) { continue }
	$a = $row2[$b]; $minx = ($l | ForEach-Object { $_.x } | Measure-Object -Minimum).Minimum
	foreach ($f in $l) { $f.x = $f.x - $minx + $bstart[$a[0]] + $a[1]; $f.y = $f.y + $a[2] }
}
function SameLayerOk($a, $b) {
	# geheimer Ast und Pétain/Orléans/Napoleon sind nie gleichzeitig sichtbar (allow_branch)
	# CGT ersetzt Thorez/Pivert, Déat ersetzt Blum/Reynaud (allow_branch blendet die anderen aus)
	$rep = @{ "Geheim (CGT)" = @("Kommunistisch (Thorez)","Kommunistisch (Pivert)"); "Geheim (Déat)" = @("Demokratisch (Blum)","Demokratisch (Reynaud)"); "Geheim (Déat RNP)" = @("Demokratisch"); "Faschistisch (La Rocque)" = @("Faschistisch (Doriot)") }
	foreach ($k in $rep.Keys) { if (($a.path -eq $k -and $rep[$k] -contains $b.path) -or ($b.path -eq $k -and $rep[$k] -contains $a.path)) { return $true } }
	$alt = "Blockfrei (Pétain)","Blockfrei (Orléans)","Blockfrei (Napoleonisch)","Blockfrei (Legitimist)"
	return ((($a.path -like "Geheim (Kapit*" -or $a.path -like "Geheim (Alpen)" -or $a.path -like "Geheim (Iberien)" -or $a.path -like "Geheim (Inseln)") -and $alt -contains $b.path) -or (($b.path -like "Geheim (Kapit*" -or $b.path -like "Geheim (Alpen)" -or $b.path -like "Geheim (Iberien)" -or $b.path -like "Geheim (Inseln)") -and $alt -contains $a.path))
}
foreach ($f in $focuses) { if ($branchOrder -notcontains $f.branch) { $errors.Add("$($f.id): unbekannter Ast $($f.branch)") } }
# ------------------------------------------------------------- Prüfungen
$gfx = New-Object System.Collections.Generic.HashSet[string]
Get-ChildItem "$Hoi4\interface","$root\interface" -Filter *.gfx -ErrorAction SilentlyContinue | ForEach-Object {
	$raw = [IO.File]::ReadAllText($_.FullName); foreach ($m in [regex]::Matches($raw, 'name\s*=\s*"?(GFX_\w+)')) { [void]$gfx.Add($m.Groups[1].Value) }
}
$validDays = 35, 50, 70, 120
$pos = @{}
foreach ($f in $focuses) {
	$k = "$($f.x),$($f.y)"
	if ($pos.ContainsKey($k) -and -not (SameLayerOk $byId[$pos[$k]] $f)) { $errors.Add("Koordinate $k doppelt: $($pos[$k]) / $($f.id)") } elseif (-not $pos.ContainsKey($k)) { $pos[$k] = $f.id }
	if (-not $gfx.Contains($f.icon)) { $warns.Add("$($f.id): Icon $($f.icon) nicht in Vanilla gefunden") }
	if ($f.days -notin $validDays) { $errors.Add("$($f.id): ungültige Dauer $($f.days) (erlaubt: $($validDays -join "/") Tage)") }
	if ($f.name -eq "" -or $f.desc -eq "") { $errors.Add("$($f.id): Name/Beschreibung fehlt") }
	foreach ($grp in $f.pre) { foreach ($p in $grp) {
		if (-not $byId.ContainsKey($p)) { $errors.Add("$($f.id): Voraussetzung $p existiert nicht") }
		elseif ($byId[$p].y -ge $f.y) { $errors.Add("$($f.id): Voraussetzung $p liegt nicht oberhalb") }
	} }
	foreach ($e in $f.eff) {
		if ($e -match '^(idea|timed) (\S+)') { if (-not $ideas.Contains($matches[2])) { $errors.Add("$($f.id): Idee $($matches[2]) nicht definiert") } }
		if ($e -match '^swap \S+ (FRW_\S+)') { if (-not $ideas.Contains($matches[1])) { $errors.Add("$($f.id): Idee $($matches[1]) nicht definiert") } }
	}
}
foreach ($f in $focuses) { foreach ($x in $f.mx) { if (-not $byId.ContainsKey($x)) { $errors.Add("$($f.id): ausgeschlossener Fokus $x existiert nicht") } } }
$evIds = New-Object System.Collections.Generic.HashSet[string]
Get-ChildItem "$root\events" -Filter *.txt -ErrorAction SilentlyContinue | ForEach-Object { foreach ($m in [regex]::Matches([IO.File]::ReadAllText($_.FullName), '(?m)^\s*id\s*=\s*([\w\.]+)')) { [void]$evIds.Add($m.Groups[1].Value) } }
$catRaw = [IO.File]::ReadAllText("$src\decision_categories.txt")
$catIds = New-Object System.Collections.Generic.HashSet[string]
foreach ($m in [regex]::Matches($catRaw, '(?m)^(\w+)\s*=\s*\{')) { [void]$catIds.Add($m.Groups[1].Value) }
foreach ($m in [regex]::Matches([IO.File]::ReadAllText("$root\common\decisions\categories\FRW_decision_categories.txt"), '(?m)^(\w+)\s*=\s*\{')) { [void]$catIds.Add($m.Groups[1].Value) }
foreach ($f in $focuses) {
	foreach ($e in $f.eff) {
		foreach ($m in [regex]::Matches($e, '(?:^(?:event|news) |^event_to \S+ |\bid = )(frw[\w]*\.\d+)')) { if (-not $evIds.Contains($m.Groups[1].Value)) { $errors.Add("$($f.id): Event $($m.Groups[1].Value) existiert nicht") } }
		if ($e -match '^dec (\S+)') { if (-not $catIds.Contains($matches[1]) -and $matches[1] -notlike 'FRA_*' -and $matches[1] -notin 'political_actions','economy_decisions','operations') { $warns.Add("$($f.id): Entscheidungskategorie $($matches[1]) nicht in FRW-Kategorien gefunden") } }
	}
}
# Flaggen: jeder kosmetische Tag braucht gfx/flags, medium und small
$ctags = New-Object System.Collections.Generic.HashSet[string]
Get-ChildItem "$root\common","$root\events" -Recurse -Filter *.txt -ErrorAction SilentlyContinue | ForEach-Object { foreach ($m in [regex]::Matches([IO.File]::ReadAllText($_.FullName), 'set_cosmetic_tag = (FRW_\w+)')) { [void]$ctags.Add($m.Groups[1].Value) } }
foreach ($f in $focuses) { foreach ($e in $f.eff) { if ($e -match '^cosmetic (FRW_\S+)') { [void]$ctags.Add($matches[1]) } } }
foreach ($c in $ctags) { foreach ($sub in "", "medium\", "small\") { if (-not (Test-Path "$root\gfx\flags\$sub$c.tga")) { $errors.Add("Flagge fehlt: gfx\flags\$sub$c.tga") } } }
foreach ($r in ($focuses | Group-Object { $_.y })) {
	$xs = @($r.Group | Sort-Object { $_.x })
	for ($k = 1; $k -lt $xs.Count; $k++) { if ($xs[$k].x - $xs[$k-1].x -lt 2 -and -not (SameLayerOk $xs[$k] $xs[$k-1])) { $errors.Add("Zu eng (Abstand < 2): $($xs[$k-1].id) / $($xs[$k].id)") } }
}
foreach ($f in $focuses) { foreach ($grp in $f.pre) { foreach ($p in $grp) { if (-not $byId.ContainsKey($p)) { continue }; $a = $byId[$p]
	foreach ($o in $focuses) { if ($o.id -eq $f.id -or $o.id -eq $p -or (SameLayerOk $o $f)) { continue }
		if ($o.y -gt $a.y -and $o.y -lt $f.y) { $tt = ($o.y - $a.y) / ($f.y - $a.y); $lx = $a.x + ($f.x - $a.x) * $tt
			if ([math]::Abs($lx - $o.x) -lt 0.6) { $errors.Add("Linie $p -> $($f.id) läuft durch $($o.id)") } } } } } }
$solid = "civ","mil","dock","infra","rslot","pp","cp","stab","ws","axp","nxp","fxp","idea","timed","tech","doct","claim","core","pop","leader","politics","politics_elect","cosmetic","manpower","equip","swap","rmidea","build","resource","vassal","union","demand","wargoal"
foreach ($f in $focuses) {
	$ok = $false; foreach ($e in $f.eff) { if ($solid -contains $e.Split(' ')[0]) { $ok = $true } }
	if (-not $ok) { $errors.Add("$($f.id): kein garantierter Effekt (nur bedingte/Tooltip-Effekte)") }
}foreach ($i in $ideas.Values) { if (-not $gfx.Contains("GFX_idea_$($i.pic)")) { $warns.Add("Idee $($i.id): Bild GFX_idea_$($i.pic) nicht gefunden") } }

# ------------------------------------------------------------- Makros
$days2cost = @{ 35 = "5"; 50 = "7.143"; 70 = "10"; 120 = "17.143" }   # HOI4 rechnet in Wochen (7 Tage): 50 Tage = 7.143, 120 Tage = 17.143 Wochen (3 Nachkommastellen)
$catNames = @{ industry="Industrie"; electronics="Elektronik"; infantry_weapons="Infanteriewaffen"; artillery="Artillerie"; armor="Panzer";
	support_tech="Unterstützungskompanien"; air_equipment="Flugzeuge"; nuclear="Kernforschung"; rocketry="Raketen/Strahltriebwerke";
	radar_tech="Radar"; cat_mechanized_equipment="Mechanisierung"; cat_heavy_armor="Schwere Panzer"; light_air="Leichte Flugzeuge";
	medium_air="Mittlere Flugzeuge"; heavy_air="Schwere Flugzeuge"; bb_tech="Schlachtschiffe"; ca_tech="Kreuzer"; ss_tech="U-Boote";
	cv_tech="Flugzeugträger"; marine_tech="Marineinfanterie"; naval_equipment="Marine-Ausrüstung"; mountaineers_tech="Gebirgsjäger";
	para_tech="Fallschirmjäger"; land_doctrine="Heeresdoktrin"; naval_doctrine="Marinedoktrin"; air_doctrine="Luftdoktrin";
	special_forces_doctrine="Spezialkräfte-Doktrin" }
$ideoNames = @{ democratic="Demokratie"; communism="Kommunismus"; fascism="Faschismus"; neutrality="Blockfrei" }

function Build-Random([string]$type, [int]$n, [bool]$coastal) {
	$lim = "is_core_of = ROOT"; if ($coastal) { $lim += " is_coastal = yes" }
	$s = ""
	for ($i = 0; $i -lt $n; $i++) {
		$s += "`t`t`trandom_owned_controlled_state = {`r`n`t`t`t`tlimit = { $lim }`r`n`t`t`t`tadd_extra_state_shared_building_slots = 1`r`n`t`t`t`tadd_building_construction = { type = $type level = 1 instant_build = yes }`r`n`t`t`t}`r`n"
	}
	return $s
}

function Expand($f, [string]$e) {
	$t = "`t`t`t"
	$a = $e.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
	switch ($a[0]) {
		"civ"  { return @((Build-Random "industrial_complex" ([int]$a[1]) $false), "+$($a[1]) Zivilfabrik(en) in zufälligen Kernstaaten (inkl. Bauplatz)") }
		"mil"  { return @((Build-Random "arms_factory" ([int]$a[1]) $false), "+$($a[1]) Militärfabrik(en) in zufälligen Kernstaaten (inkl. Bauplatz)") }
		"dock" { return @((Build-Random "dockyard" ([int]$a[1]) $true), "+$($a[1]) Werft(en) in zufälligen Küsten-Kernstaaten (inkl. Bauplatz)") }
		"infra" {
			$s = ""
			for ($i = 0; $i -lt [int]$a[1]; $i++) { $s += "${t}random_owned_controlled_state = {`r`n${t}`tlimit = { is_core_of = ROOT infrastructure < 5 }`r`n${t}`tadd_building_construction = { type = infrastructure level = 1 instant_build = yes }`r`n${t}}`r`n" }
			return @($s, "+1 Infrastruktur in $($a[1]) zufälligen Kernstaaten")
		}
		"rslot" { return @("${t}add_research_slot = 1`r`n", "+1 Forschungsplatz") }
		"pp"    { return @("${t}add_political_power = $($a[1])`r`n", "+$($a[1]) politische Macht") }
		"cp"    { return @("${t}add_command_power = $($a[1])`r`n", "+$($a[1]) Kommandomacht") }
		"stab"  { $v=[double]::Parse($a[1],[Globalization.CultureInfo]::InvariantCulture); return @("${t}add_stability = $($a[1])`r`n", ("{0:+0;-0} % Stabilität" -f ($v*100))) }
		"ws"    { $v=[double]::Parse($a[1],[Globalization.CultureInfo]::InvariantCulture); return @("${t}add_war_support = $($a[1])`r`n", ("{0:+0;-0} % Kriegsunterstützung" -f ($v*100))) }
		"axp"   { return @("${t}army_experience = $($a[1])`r`n", "+$($a[1]) Heereserfahrung") }
		"nxp"   { return @("${t}navy_experience = $($a[1])`r`n", "+$($a[1]) Marineerfahrung") }
		"fxp"   { return @("${t}air_experience = $($a[1])`r`n", "+$($a[1]) Lufterfahrung") }
		"idea"  {
			if ($a.Count -gt 2) { return @("${t}if = { limit = { NOT = { has_idea = $($a[2]) } } add_ideas = $($a[1]) }`r`n", "Nationalgeist: **$($ideas[$a[1]].name)** (nicht, wenn schon die verbesserte Stufe **$($ideas[$a[2]].name)** vorhanden ist)") }
			return @("${t}add_ideas = $($a[1])`r`n", "Nationalgeist: **$($ideas[$a[1]].name)**")
		}
		"rmidea" { return @("${t}if = { limit = { has_idea = $($a[1]) } remove_ideas = $($a[1]) }`r`n", "Entfernt Vanilla-Geist $($a[1]) (falls vorhanden)") }
		"swap" {
			$s = "${t}if = { limit = { has_idea = $($a[1]) } swap_ideas = { remove_idea = $($a[1]) add_idea = $($a[2]) } }`r`n"
			if ($a[2] -like "FRW_*") { $s += "${t}else = { add_ideas = $($a[2]) }`r`n" }
			$n2 = if ($ideas.Contains($a[2])) { $ideas[$a[2]].name } else { $a[2] }
			return @($s, "Ersetzt $($a[1]) durch **$n2**")
		}
		"timed" { return @("${t}add_timed_idea = { idea = $($a[1]) days = $($a[2]) }`r`n", "Zeitlicher Geist ($($a[2]) Tage): **$($ideas[$a[1]].name)**") }
		"tech"  {
			$bonus = [double]::Parse($a[2],[Globalization.CultureInfo]::InvariantCulture)
			return @("${t}add_tech_bonus = { name = $($f.id) bonus = $($a[2]) uses = $($a[3]) category = $($a[1]) }`r`n", ("Forschungsbonus {0}: +{1} % ({2}x)" -f $catNames[$a[1]], ($bonus*100), $a[3]))
		}
		"doct"  {
			$r = [double]::Parse($a[2],[Globalization.CultureInfo]::InvariantCulture)
			return @("${t}add_doctrine_cost_reduction = { name = $($f.id) cost_reduction = $($a[2]) uses = $($a[3]) category = $($a[1]) }`r`n", ("{0}: -{1} % Kosten ({2}x)" -f $catNames[$a[1]], ($r*100), $a[3]))
		}
		"claim" { $s=""; foreach ($x in $a[1..($a.Count-1)]) { $s += "${t}add_state_claim = $x`r`n" }; return @($s, "Anspruch auf Staaten: $($a[1..($a.Count-1)] -join ', ')") }
		"core"  { $s=""; foreach ($x in $a[1..($a.Count-1)]) { $s += "${t}add_state_core = $x`r`n" }; return @($s, "Kerngebiet auf Staaten: $($a[1..($a.Count-1)] -join ', ')") }
		"pop"   { $v=[double]::Parse($a[2],[Globalization.CultureInfo]::InvariantCulture); return @("${t}add_popularity = { ideology = $($a[1]) popularity = $($a[2]) }`r`n", ("+{0} % Popularität {1}" -f ($v*100), $ideoNames[$a[1]])) }
		"leader" { return @("${t}FRW_leader_$($a[1]) = yes`r`n", "Neuer Anführer: $($a[1])") }
		"politics" { return @("${t}add_popularity = { ideology = $($a[1]) popularity = 0.15 }`r`n${t}set_politics = { ruling_party = $($a[1]) elections_allowed = no }`r`n", "Regierungswechsel zu **$($ideoNames[$a[1]])** (+15 % Popularität, keine Wahlen)") }
		"politics_elect" { return @("${t}add_popularity = { ideology = $($a[1]) popularity = 0.2 }`r`n${t}set_politics = { ruling_party = $($a[1]) elections_allowed = yes }`r`n", "Regierungswechsel zu **$($ideoNames[$a[1]])** mit Wahlen (+20 % Popularität)") }
		"cosmetic" { return @("${t}if = { limit = { NOT = { has_country_flag = FRW_nation_formed } } set_cosmetic_tag = $($a[1]) }`r`n", "Staatsform/Flagge: **$($a[1])** (nicht, wenn Frankreich schon eine Nation gegründet hat)") }
		"event" { return @("${t}country_event = { id = $($a[1]) }`r`n", "Event $($a[1])") }
		"news"  { return @("${t}news_event = { id = $($a[1]) hours = 6 }`r`n", "Weltnachricht $($a[1])") }
		"event_to" { return @("${t}$($a[1]) = { country_event = { id = $($a[2]) days = 1 } }`r`n", "Event $($a[2]) an $($a[1])") }
		"dec"   { return @("${t}unlock_decision_category_tooltip = $($a[1])`r`n", "Schaltet Entscheidungen frei: $($a[1])") }
		"wargoal" {
			$gen = ""; if ($a.Count -gt 3) { $gen = " generator = { $($a[3..($a.Count-1)] -join ' ') }" }
			return @("${t}if = { limit = { $($a[2]) = { exists = yes } NOT = { has_wargoal_against = $($a[2]) } NOT = { has_war_with = $($a[2]) } } create_wargoal = { type = $($a[1]) target = $($a[2])$gen } }`r`n", "Kriegsziel ($($a[1])) gegen $($a[2])$(if($gen){' – Staaten '+($a[3..($a.Count-1)] -join ', ')})")
		}
		"opinion" { return @("${t}if = { limit = { $($a[1]) = { exists = yes } } add_opinion_modifier = { target = $($a[1]) modifier = $($a[2]) } $($a[1]) = { add_opinion_modifier = { target = ROOT modifier = $($a[2]) } } }`r`n", "Gegenseitige Meinung mit $($a[1]) verbessert") }
		"guarantee" { $s=""; foreach ($x in $a[1..($a.Count-1)]) { $s += "${t}if = { limit = { $x = { exists = yes } } give_guarantee = $x }`r`n" }; return @($s, "Garantie für $($a[1..($a.Count-1)] -join ', ')") }
		"build" {
			$st=$a[1]; $type=$a[2]; $lvl=$a[3]
			$slot = if ($type -in "industrial_complex","arms_factory","dockyard") { "add_extra_state_shared_building_slots = $lvl " } else { "" }
			$tn = @{ industrial_complex="Zivilfabrik"; arms_factory="Militärfabrik"; dockyard="Werft"; infrastructure="Infrastruktur"; air_base="Luftwaffenbasis"; anti_air_building="Flak" }[$type]
			$lim = if ($type -eq "dockyard") { "is_core_of = ROOT is_coastal = yes" } else { "is_core_of = ROOT" }
			return @("${t}if = { limit = { owns_state = $st } $st = { ${slot}add_building_construction = { type = $type level = $lvl instant_build = yes } } }`r`n${t}else_if = { limit = { $st = { owner = { is_subject_of = ROOT } } } $st = { ${slot}add_building_construction = { type = $type level = $lvl instant_build = yes } } }`r`n${t}else = { random_owned_controlled_state = { limit = { $lim } ${slot}add_building_construction = { type = $type level = $lvl instant_build = yes } } }`r`n", "+$lvl $tn in Staat $st (oder bei einem Satelliten dort; sonst in einem zufälligen Kernstaat)")
		}
		"union" { return @("${t}$($a[1]) = { country_event = { id = frw.70 days = 1 } }`r`n", "Anschluss-Forderung an $($a[1]) (Event: Annahme = Annexion; Ablehnung = Kriegsziel möglich, außer Frankreich ist demokratisch)") }
		"demand" {
			$s = ""; foreach ($x in $a[2..($a.Count-1)]) { $s += "${t}set_country_flag = FRW_demand_$x`r`n" }
			$s += "${t}$($a[1]) = { country_event = { id = frw.71 days = 1 } }`r`n"
			return @($s, "Gebietsforderung an $($a[1]): Staaten $($a[2..($a.Count-1)] -join ', ') (Ablehnung = Kriegsziel möglich, außer Frankreich ist demokratisch)")
		}
		"vassal" { return @("${t}$($a[1]) = { country_event = { id = frw.75 days = 1 } }`r`n", "Schutzherrschafts-Forderung an $($a[1]) (Event: Annahme = Marionette Frankreichs; Chance steigt mit Frankreichs Heeresstärke im Vergleich und guter Beziehung. Ablehnung = Kriegsziel möglich, außer Frankreich ist demokratisch)") }
		"invite" {
			$s = ""; foreach ($x in $a[1..($a.Count-1)]) { $s += "${t}if = { limit = { is_faction_leader = yes $x = { exists = yes is_in_faction = no NOT = { has_war_with = ROOT } } } $x = { country_event = { id = frw.16 days = 1 } } }`r`n" }
			return @($s, "Bündniseinladung an $($a[1..($a.Count-1)] -join ', ')")
		}		"resource" { return @("${t}if = { limit = { owns_state = $($a[1]) } $($a[1]) = { add_resource = { type = $($a[2]) amount = $($a[3]) } } }`r`n${t}else = { random_owned_controlled_state = { limit = { is_core_of = ROOT } add_resource = { type = $($a[2]) amount = $($a[3]) } } }`r`n", "+$($a[3]) $($a[2]) in Staat $($a[1]) (sonst in einem zufälligen Kernstaat)") }
		"equip"    { return @("${t}add_equipment_to_stockpile = { type = $($a[1]) amount = $($a[2]) }`r`n", "+$($a[2]) $($a[1])") }
		"manpower" { return @("${t}add_manpower = $($a[1])`r`n", "+$($a[1]) Mannstärke") }
		default {
			if ($e.StartsWith("!")) { if ($f.tt) { return @("${t}hidden_effect = { $($e.Substring(1)) }`r`n", $null) } else { return @("$t$($e.Substring(1))`r`n", $null) } }
			$errors.Add("$($f.id): unbekanntes Makro '$e'"); return @("", $null)
		}
	}
}

# ------------------------------------------------------------- Fokusbaum schreiben
$filterMap = @{ POLITICAL="FOCUS_FILTER_POLITICAL"; INDUSTRY="FOCUS_FILTER_INDUSTRY"; RESEARCH="FOCUS_FILTER_RESEARCH"; STABILITY="FOCUS_FILTER_STABILITY";
	WAR_SUPPORT="FOCUS_FILTER_WAR_SUPPORT"; MANPOWER="FOCUS_FILTER_MANPOWER"; ANNEXATION="FOCUS_FILTER_ANNEXATION"; ARMY_XP="FOCUS_FILTER_ARMY_XP";
	NAVY_XP="FOCUS_FILTER_NAVY_XP"; AIR_XP="FOCUS_FILTER_AIR_XP" }
$ideoRoots = "FRW_defend_the_republic","FRW_workers_popular_front","FRW_national_renewal","FRW_above_the_parties"
function NotOthers($me) { $o = @($ideoRoots | Where-Object { $_ -ne $me } | ForEach-Object { "has_completed_focus = $_" }); return "NOT = { OR = { $($o -join ' ') } }" }
$scDefs = @(
	@("FRW_shortcut_democratic", "FRW_defend_the_republic", (NotOthers "FRW_defend_the_republic")),
	@("FRW_shortcut_communist", "FRW_workers_popular_front", (NotOthers "FRW_workers_popular_front")),
	@("FRW_shortcut_fascist", "FRW_national_renewal", (NotOthers "FRW_national_renewal")),
	@("FRW_shortcut_nonaligned", "FRW_above_the_parties", (NotOthers "FRW_above_the_parties")),
	@("FRW_shortcut_secret", "FRW_secret_captain", "has_country_flag = FRW_secret_alpine"),
	@("FRW_shortcut_economy", "FRW_devalue_the_franc", ""),
	@("FRW_shortcut_military", ($focuses | Where-Object { $_.branch -eq "Heer" -and $_.pre.Count -eq 0 } | Select-Object -First 1).id, ""),
	@("FRW_shortcut_diplomacy", "FRW_quai_d_orsay", ""),
	@("FRW_shortcut_colonies", ($focuses | Where-Object { $_.branch -eq "Kolonialreich" -and $_.pre.Count -eq 0 } | Select-Object -First 1).id, "")
)
$shortcuts = ""
foreach ($d in $scDefs) {
	if (-not $byId.ContainsKey($d[1])) { $errors.Add("Shortcut-Ziel $($d[1]) fehlt"); continue }
	$shortcuts += "`tshortcut = {`r`n`t`tname = $($d[0])`r`n`t`ttarget = $($d[1])`r`n`t`tscroll_wheel_factor = 0.75`r`n"
	if ($d[2]) { $shortcuts += "`t`ttrigger = { $($d[2]) }`r`n" }
	$shortcuts += "`t}`r`n"
}
$sb = New-Object Text.StringBuilder
[void]$sb.AppendLine("###########################################################")
[void]$sb.AppendLine("# France Rework - Nationalfokusbaum Frankreich")
[void]$sb.AppendLine("# GENERIERT von _quelle/generate.ps1 - nicht direkt bearbeiten!")
[void]$sb.AppendLine("###########################################################")
[void]$sb.AppendLine("focus_tree = {`r`n`tid = french_focus`r`n`r`n`tcountry = {`r`n`t`tfactor = 0`r`n`t`tmodifier = {`r`n`t`t`tadd = 10`r`n`t`t`ttag = FRA`r`n`t`t}`r`n`t}`r`n`r`n`tdefault = no`r`n`r`n`tinitial_show_position = { x = 19 y = 0 }`r`n`tcontinuous_focus_position = { x = 50 y = 2700 }`r`n")
[void]$sb.AppendLine($shortcuts)
# allow_branch wird in HOI4 PRO FOKUS ausgewertet - Kinder eines ausgeblendeten Fokus bleiben sonst sichtbar.
# Daher: eigene Bedingungen + alle Bedingungen, die ALLE Voraussetzungen gemeinsam haben, werden vererbt.
foreach ($f in $focuses) { if ($f.mx.Count -gt 0) { $f.branchif += "NOT = { OR = { $(($f.mx | ForEach-Object { "has_completed_focus = $_" }) -join ' ') } }" } }
$condMap = @{}
foreach ($f in ($focuses | Sort-Object { $_.y })) {
	$list = New-Object System.Collections.Generic.List[string]
	foreach ($c in $f.branchif) { if (-not $list.Contains($c)) { $list.Add($c) } }
	$common = $null
	foreach ($grp in $f.pre) { foreach ($p in $grp) {
		if (-not $condMap.ContainsKey($p)) { continue }
		$pc = $condMap[$p]
		if ($null -eq $common) { $common = New-Object System.Collections.Generic.List[string]; foreach ($c in $pc) { $common.Add($c) } }
		else { $keep = New-Object System.Collections.Generic.List[string]; foreach ($c in $common) { if ($pc.Contains($c)) { $keep.Add($c) } }; $common = $keep }
	} }
	if ($null -ne $common) { foreach ($c in $common) { if (-not $list.Contains($c)) { $list.Add($c) } } }
	$condMap[$f.id] = $list
	$f.branchAll = @($list.ToArray())
}
foreach ($f in $focuses) {
	$f.docEff = @()
	$body = ""
	foreach ($e in $f.eff) { $r = Expand $f $e; $body += $r[0]; if ($r[1]) { $f.docEff += $r[1] } }
	$f.docEff += $f.doc
	[void]$sb.AppendLine("`tfocus = {")
	[void]$sb.AppendLine("`t`tid = $($f.id)")
	[void]$sb.AppendLine("`t`ticon = $($f.icon)")
	[void]$sb.AppendLine("`t`tx = $($f.x)")
	[void]$sb.AppendLine("`t`ty = $($f.y)")
	[void]$sb.AppendLine("`t`tcost = $($days2cost[$f.days])")
	foreach ($grp in $f.pre) { [void]$sb.AppendLine("`t`tprerequisite = { $(($grp | ForEach-Object { "focus = $_" }) -join ' ') }") }
	if ($f.mx.Count -gt 0) { [void]$sb.AppendLine("`t`tmutually_exclusive = { $(($f.mx | ForEach-Object { "focus = $_" }) -join ' ') }") }
	if (@($f.branchAll).Count -gt 0) { [void]$sb.AppendLine("`t`tallow_branch = {"); foreach ($bi in $f.branchAll) { [void]$sb.AppendLine("`t`t`t$bi") }; [void]$sb.AppendLine("`t`t}") }
	if ($f.avail.Count -gt 0) { [void]$sb.AppendLine("`t`tavailable = {"); foreach ($av in $f.avail) { [void]$sb.AppendLine("`t`t`t$av") }; [void]$sb.AppendLine("`t`t}") }
	if (@($f.sel).Count -gt 0) { [void]$sb.AppendLine("`t`tselect_effect = {"); foreach ($se in $f.sel) { [void]$sb.AppendLine("`t`t`t$se") }; [void]$sb.AppendLine("`t`t}") }
	if ($f.byp.Count -gt 0) { [void]$sb.AppendLine("`t`tbypass = {"); foreach ($by in $f.byp) { [void]$sb.AppendLine("`t`t`t$by") }; [void]$sb.AppendLine("`t`t}") }
	[void]$sb.AppendLine("`t`tcancel_if_invalid = yes")
	[void]$sb.AppendLine("`t`tcontinue_if_invalid = no")
	[void]$sb.AppendLine("`t`tavailable_if_capitulated = $(if ($f.branch -eq 'Exil') { 'yes' } else { 'no' })")
	[void]$sb.AppendLine("`t`tsearch_filters = { $($filterMap[$f.filter]) }")
	$ai = if ($f.ai) { $f.ai } elseif ($f.path -like "Demokratisch*") { 3 } elseif ($f.branch -eq "Politik") { 1 } else { 2 }
	if ("$ai".StartsWith("!")) { [void]$sb.AppendLine("`t`tai_will_do = { $("$ai".Substring(1)) }") } else { [void]$sb.AppendLine("`t`tai_will_do = { factor = $ai }") }
	[void]$sb.AppendLine("`t`tcompletion_reward = {")
	if ($f.tt) { [void]$sb.AppendLine("`t`t`tcustom_effect_tooltip = $($f.id)_tt") }
	[void]$sb.Append($body)
	if ($f.mx.Count -gt 0) { [void]$sb.AppendLine("`t`t`thidden_effect = { mark_focus_tree_layout_dirty = yes }") }
	[void]$sb.AppendLine("`t`t`thidden_effect = { FRW_idle_reset = yes set_country_flag = FRW_fc_$($f.id) }")
	[void]$sb.AppendLine("`t`t}")
	[void]$sb.AppendLine("`t}")
}
[void]$sb.AppendLine("}")
New-Item -ItemType Directory -Force "$root\common\national_focus","$root\common\ideas","$root\localisation\german","$root\localisation\english" | Out-Null
$queue.Add(@("$root\common\national_focus\france.txt", $sb.ToString(), $nobom))
# ------------------------------------------------------------- Scripted Trigger: laeuft gerade ein Fokus?
$st = New-Object Text.StringBuilder
[void]$st.AppendLine("# GENERIERT von _quelle/generate.ps1")
[void]$st.AppendLine("# yes = irgendein Fokus des Baums hat Fortschritt, ist aber noch nicht abgeschlossen")
[void]$st.AppendLine("FRW_focus_in_progress = {`r`n`tOR = {")
foreach ($f in $focuses) { [void]$st.AppendLine("`t`tAND = { focus_progress = { focus = $($f.id) progress > 0 } NOT = { has_completed_focus = $($f.id) } }") }
[void]$st.AppendLine("`t}`r`n}")
New-Item -ItemType Directory -Force "$root\common\scripted_triggers" | Out-Null
$queue.Add(@("$root\common\scripted_triggers\FRW_scripted_triggers.txt", $st.ToString(), $nobom))
# ------------------------------------------------------------- Ideen schreiben
$sb = New-Object Text.StringBuilder
[void]$sb.AppendLine("# GENERIERT von _quelle/generate.ps1`r`nideas = {`r`n`tcountry = {")
foreach ($i in $ideas.Values) {
	[void]$sb.AppendLine("`t`t$($i.id) = {`r`n`t`t`tpicture = $($i.pic)`r`n`t`t`tallowed = { always = no }`r`n`t`t`tremoval_cost = -1`r`n`t`t`tmodifier = {")
	foreach ($m in $i.mods) { [void]$sb.AppendLine("`t`t`t`t$m") }
	[void]$sb.AppendLine("`t`t`t}`r`n`t`t}")
}
[void]$sb.AppendLine("`t}`r`n}")
$queue.Add(@("$root\common\ideas\FRW_ideas.txt", $sb.ToString(), $nobom))
# ------------------------------------------------------------- Lokalisierung
$loc = New-Object Text.StringBuilder
[void]$loc.AppendLine(" # ---------- Fokusse (generiert) ----------")
foreach ($f in $focuses) {
	[void]$loc.AppendLine(" $($f.id):0 `"$(Q $f.name)`"")
	[void]$loc.AppendLine(" $($f.id)_desc:0 `"$(Q $f.desc)`"")
	if ($f.tt) { [void]$loc.AppendLine(" $($f.id)_tt:0 `"$(Q $f.tt)`"") }
}
[void]$loc.AppendLine(" # ---------- Ideen (generiert) ----------")
foreach ($i in $ideas.Values) { [void]$loc.AppendLine(" $($i.id):0 `"$(Q $i.name)`"") }
$extra = Get-Content "$src\loc_extra.yml" -Raw -Encoding UTF8
$allLoc = $loc.ToString() + $extra
$seen = @{}
foreach ($m in [regex]::Matches($allLoc, '(?m)^ ([\w\.\-]+):\d? ')) { $k = $m.Groups[1].Value; if ($seen.ContainsKey($k)) { $errors.Add("Lokalisierung: Schlüssel $k doppelt") } else { $seen[$k] = 1 } }
foreach ($f in $focuses) { if ($f.tt -and -not $seen.ContainsKey("$($f.id)_tt")) { $errors.Add("$($f.id): Tooltip-Schlüssel fehlt") } }
# ------------------------------------------------------------- Sprachen
# Englisch ist die Vorlage. _quelle\translations\<sprache>.yml enthält übersetzte Schlüssel;
# was dort fehlt, bleibt englisch (so sieht niemand rohe Schlüssel).
$langs = "english", "german", "french", "spanish", "russian", "polish", "braz_por", "japanese", "simp_chinese"
$master = $loc.ToString() + $extra
$locRx = '(?m)^ ([\w\.\-]+):(\d?) "(.*)"([ \t]*\r?)$'
$masterText = @{}
foreach ($m in [regex]::Matches($master, $locRx)) { $masterText[$m.Groups[1].Value] = $m.Groups[3].Value }
function TokenSig([string]$t) { return "{0}|{1}|{2}|{3}" -f ([regex]::Matches($t, '§[A-Za-z!]')).Count, ([regex]::Matches($t, '\$')).Count, ([regex]::Matches($t, '\[')).Count, ([regex]::Matches($t, '\\n')).Count }
$basis = @{}
$bf = "$src\translations\_english_basis.yml"
if (Test-Path $bf) { foreach ($m in [regex]::Matches([IO.File]::ReadAllText($bf), $locRx)) { $basis[$m.Groups[1].Value] = $m.Groups[3].Value } }
$stale = @($masterText.Keys | Where-Object { $basis.ContainsKey($_) -and $basis[$_] -ne $masterText[$_] })
$new = @($masterText.Keys | Where-Object { -not $basis.ContainsKey($_) })
if ($basis.Count) { if ($stale.Count) { $warns.Add("Übersetzungen veraltet (englischer Text geändert): " + ($stale -join ", ")) }; if ($new.Count) { $warns.Add("Noch nicht übersetzt (neu, englisch als Ersatz): $($new.Count) Schlüssel") } }
# Vanilla-Texte, die die Mod ersetzt (z. B. "French Republic"): _quelle\replace_names.txt, Zeilen sprache|schlüssel|text
$replNames = @{}
if (Test-Path "$src\replace_names.txt") { foreach ($l in [IO.File]::ReadAllLines("$src\replace_names.txt")) { if ($l -match '^(\w+)\|(\S+)\|(.*)$') { $replNames[$matches[1]] = [string]$replNames[$matches[1]] + " $($matches[2]):0 `"$($matches[3])`"`r`n" } } }
$langStats = @()
foreach ($lang in $langs) {
	$tr = @{}
	$tf = "$src\translations\$lang.yml"
	if (Test-Path $tf) {
		foreach ($m in [regex]::Matches([IO.File]::ReadAllText($tf), $locRx)) {
			$k = $m.Groups[1].Value; $v = $m.Groups[3].Value
			if (-not $masterText.ContainsKey($k)) { $warns.Add("Übersetzung $lang`: Schlüssel $k gibt es im Englischen nicht mehr") ; continue }
			if ($v -match '(?<!\\)"') { $errors.Add("Übersetzung $lang`: $k enthält ein gerades Anführungszeichen") ; continue }
			if ((TokenSig $v) -ne (TokenSig $masterText[$k])) { $warns.Add("Übersetzung $lang`: $k – Formatcodes (§, $, [, \n) weichen vom Englischen ab") }
			$tr[$k] = $v
		}
	}
	$out = [regex]::Replace($master, $locRx, { param($m) if ($tr.ContainsKey($m.Groups[1].Value)) { " " + $m.Groups[1].Value + ":" + $m.Groups[2].Value + " `"" + $tr[$m.Groups[1].Value] + "`"" + $m.Groups[4].Value } else { $m.Value } })
	$queue.Add(@("$root\localisation\$lang\FRW_l_$lang.yml", ("l_${lang}:`r`n" + $out), $bom))
	$queue.Add(@("$root\localisation\$lang\replace\FRW_replace_l_$lang.yml", ("l_${lang}:`r`n" + $replNames[$lang]), $bom))
	$langStats += "{0} {1}/{2}" -f $lang, $tr.Count, $masterText.Count
}

# ------------------------------------------------------------- Flaggen
# Die Flaggen liegen fest in gfx/flags (nur Vanilla-Grafiken und eigene Bilder,
# keine Dateien aus anderen Mods). Der Generator kopiert KEINE Flaggen mehr.
$flagLog = @(
	"| FRW_EMPIRE | Vanilla FRA-Tricolore + eigenes Emblem (goldenes N im Lorbeerkranz) |",
	"| FRW_GRANDEMPIRE | Kaiserstandarte Napoleons: N im Lorbeer, goldene Bienen, Goldrand (eigene Zeichnung) |",
	"| FRW_KINGDOM | Vanilla FRA_neutrality (Lilien) |",
	"| FRW_ETAT | Vanilla FRA_fascism (Francisque) |",
	"| FRW_NATIONAL | Tricolore mit PPF-Emblem (eigene Zeichnung) |",
	"| FRW_SOCREP | Vanilla FRA_communism |",
	"| FRW_COMMUNE | Rote Fahne der Pariser Kommune (eigene Zeichnung) |",
	"| FRW_UNION | Vanilla FRA_FREE_democratic (Lothringerkreuz) |",
	"| FRW_FRUK | Vanilla FRA_democratic + ENG_democratic als Kanton |",
	"| FRW_EUROPE | Flagge der Paneuropa-Union 1923 (eigene Zeichnung) |",
	"| FRW_FRANCIA | Koenigliches Banner Frankreichs, azur mit goldenen Lilien (aus Vanilla FRA_neutrality umgefaerbt) |",
	"| FRW_LATIN | Vanilla SPQR_UNIFIED_* |",
	"| FRW_EURAFRICA | Eigene Zeichnung (Europa-Blau/Afrika-Gruen, Paneuropa-Scheibe) |",
	"| FRW_BURGUNDY | Burgunderkreuz (eigene Zeichnung) |",
	"| FRW_WESTUNION | Westunion 1948: fuenf goldene Ringe auf Blau (eigene Zeichnung) |",
	"| FRW_CORSAIR | Eigenes Bild des Mod-Autors |",
	"| FRW_ETERNAL | Bild des Mod-Autors (unteres Emblem neu gezeichnet) |"
)

# ------------------------------------------------------------- Dokumentation
$md = New-Object Text.StringBuilder
[void]$md.AppendLine("# France Rework – Konzept & Fokusdokumentation")
[void]$md.AppendLine("")
[void]$md.AppendLine("*Automatisch erzeugt aus ``_quelle/fokus_daten.txt``. Anzahl Fokusse: **$($focuses.Count)**.*")
[void]$md.AppendLine("")
[void]$md.AppendLine("Dauer: HOI4 rechnet Fokuskosten in Wochen (1 = 7 Tage). 35 Tage = 5, 50 Tage = 7.143, 70 Tage = 10, 120 Tage = 17.143.")
[void]$md.AppendLine("")
[void]$md.AppendLine("## Übersicht")
[void]$md.AppendLine("")
[void]$md.AppendLine("| Ast | Fokusse | 35 T | 50 T | 70 T | 120 T | Summe Tage |")
[void]$md.AppendLine("|---|---:|---:|---:|---:|---:|---:|")
foreach ($b in $branchOrder) {
	$l = @($focuses | Where-Object { $_.branch -eq $b })
	[void]$md.AppendLine("| $b | $($l.Count) | $(@($l | ? { $_.days -eq 35 }).Count) | $(@($l | ? { $_.days -eq 50 }).Count) | $(@($l | ? { $_.days -eq 70 }).Count) | $(@($l | ? { $_.days -eq 120 }).Count) | $(($l | ForEach-Object { $_.days } | Measure-Object -Sum).Sum) |")
}
[void]$md.AppendLine("| **Gesamt** | **$($focuses.Count)** | **$(@($focuses | ? { $_.days -eq 35 }).Count)** | **$(@($focuses | ? { $_.days -eq 50 }).Count)** | **$(@($focuses | ? { $_.days -eq 70 }).Count)** | **$(@($focuses | ? { $_.days -eq 120 }).Count)** | **$(($focuses | ForEach-Object { $_.days } | Measure-Object -Sum).Sum)** |")
[void]$md.AppendLine("")
$paths = $focuses | Where-Object { $_.branch -eq "Politik" } | Group-Object { $_.path }
[void]$md.AppendLine("### Politische Pfade")
[void]$md.AppendLine("")
foreach ($g in $paths) { [void]$md.AppendLine("- **$($g.Name)**: $($g.Count) Fokusse") }
[void]$md.AppendLine("")
foreach ($b in $branchOrder) {
	[void]$md.AppendLine("## Ast: $b")
	[void]$md.AppendLine("")
	[void]$md.AppendLine("| Fokus | Voraussetzungen | Dauer | Effekte | Pfad |")
	[void]$md.AppendLine("|---|---|---|---|---|")
	foreach ($f in ($focuses | Where-Object { $_.branch -eq $b } | Sort-Object { $_.y }, { $_.x })) {
		$pre = if ($f.pre.Count) { ($f.pre | ForEach-Object { ($_ | ForEach-Object { $byId[$_].name }) -join " **oder** " }) -join " **und** " } else { "–" }
		if ($f.mx.Count) { $pre += "<br>*schließt aus:* " + (($f.mx | ForEach-Object { $byId[$_].name }) -join ", ") }
		if ($f.avail.Count) { $pre += "<br>*Bedingung:* ``" + ($f.avail -join " ") + "``" }
		$eff = ($f.docEff -join "<br>").Replace("|", "/")
		[void]$md.AppendLine("| **$($f.name)**<br>``$($f.id)``<br>$($f.desc.Replace('|','/')) | $pre | $($f.days) T | $eff | $($f.path) |")
	}
	[void]$md.AppendLine("")
}
[void]$md.AppendLine("## Nationalgeister")
[void]$md.AppendLine("")
[void]$md.AppendLine("| ID | Name | Modifikatoren |")
[void]$md.AppendLine("|---|---|")
foreach ($i in $ideas.Values) { [void]$md.AppendLine("| ``$($i.id)`` | $($i.name) | $($i.mods -join '<br>') |") }
[void]$md.AppendLine("")
[void]$md.AppendLine("## Flaggen")
[void]$md.AppendLine("")
[void]$md.AppendLine("| Kosmetischer Tag | Quelle |")
[void]$md.AppendLine("|---|---|")
foreach ($l in $flagLog) { [void]$md.AppendLine($l) }
$queue.Add(@("$root\FOKUSBAUM_DOKUMENTATION.md", $md.ToString(), $bom))
# ------------------------------------------------------------- Bericht
"Fokusse: $($focuses.Count)  Ideen: $($ideas.Count)"
foreach ($b in $branchOrder) { "  {0,-14} {1}" -f $b, @($focuses | Where-Object { $_.branch -eq $b }).Count }
if ($warns.Count) { "WARNUNGEN:"; $warns | ForEach-Object { "  $_" } }
$readme = "$root\README_KONZEPT.md"
if (Test-Path $readme) {
	$st = New-Object Text.StringBuilder
	[void]$st.AppendLine("<!-- AUTO:STATS (generate.ps1 - nicht von Hand ändern) -->")
	[void]$st.AppendLine("| Kennzahl | Wert |")
	[void]$st.AppendLine("|---|---:|")
	[void]$st.AppendLine("| Fokusse gesamt | $($focuses.Count) |")
	foreach ($d in $validDays) { [void]$st.AppendLine("| Fokusse mit $d Tagen | $(@($focuses | ? { $_.days -eq $d }).Count) |") }
	foreach ($b in $branchOrder) { $c = @($focuses | ? { $_.branch -eq $b }).Count; if ($c) { [void]$st.AppendLine("| Ast $b | $c |") } }
	[void]$st.AppendLine("| Pfadgruppen im Politik-Ast (inkl. Ideologie-Stämme und geheime) | $(@($focuses | ? { $_.branch -eq 'Politik' -and $_.path -ne 'Alle' } | Group-Object { $_.path }).Count) |")
	[void]$st.AppendLine("| Nationalgeister (aus ideen_daten) | $($ideas.Count) |")
	[void]$st.AppendLine("| Events (IDs in events/) | $($evIds.Count) |")
	[void]$st.AppendLine("| Entscheidungskategorien | $($catIds.Count) |")
	[void]$st.Append("<!-- /AUTO:STATS -->")
	$rm = [IO.File]::ReadAllText($readme)
	if ($rm -match '(?s)<!-- AUTO:STATS.*?<!-- /AUTO:STATS -->') { $rm = [regex]::Replace($rm, '(?s)<!-- AUTO:STATS.*?<!-- /AUTO:STATS -->', $st.ToString().Replace('$', '$$')) ; $queue.Add(@($readme, $rm, $nobom)) }
}
if ($errors.Count) { "FEHLER (es wurde NICHTS geschrieben):"; $errors | ForEach-Object { "  $_" }; exit 1 }
foreach ($q in $queue) { New-Item -ItemType Directory -Force (Split-Path -Parent ([string]$q[0])) | Out-Null; [IO.File]::WriteAllText([string]$q[0], [string]$q[1], [Text.Encoding]$q[2]) }
"Übersetzt (Schlüssel): " + ($langStats -join ", ")
"Keine Fehler. $($queue.Count) Dateien geschrieben."
