# Erzeugt common/decisions/FRW_decisions.txt und die Kategorien (ASCII-Skript)
$root = Split-Path -Parent $PSScriptRoot
$enc = New-Object Text.UTF8Encoding $false  # HOI4-Skriptdateien ohne BOM
New-Item -ItemType Directory -Force "$root\common\decisions\categories" | Out-Null

$buys = @(
 @{id="FRW_buy_spanish_morocco";  flag="290"; states=@("290");       seller="SPR"; cost=150},
 @{id="FRW_buy_ifni_rio_de_oro";  flag="783"; states=@("783","699"); seller="SPR"; cost=75},
 @{id="FRW_buy_spanish_guinea";   flag="297"; states=@("297");       seller="SPR"; cost=50},
 @{id="FRW_buy_portuguese_guinea";flag="296"; states=@("296");       seller="POR"; cost=75},
 @{id="FRW_buy_gambia";           flag="701"; states=@("701");       seller="ENG"; cost=50},
 @{id="FRW_buy_sierra_leone";     flag="700"; states=@("700");       seller="ENG"; cost=100},
 @{id="FRW_buy_belgian_congo";    flag="295"; states=@("295");       seller="BEL"; cost=150},
 @{id="FRW_buy_fezzan";           flag="661"; states=@("661");       seller="ITA"; cost=100}
)

$o = New-Object Text.StringBuilder
[void]$o.AppendLine("###########################################################")
[void]$o.AppendLine("# France Rework - Entscheidungen (generiert von gen_decisions.ps1)")
[void]$o.AppendLine("###########################################################")
[void]$o.AppendLine("")
[void]$o.AppendLine("FRW_colonial_purchases_cat = {")
foreach ($b in $buys) {
	$own = ($b.states | ForEach-Object { "$_ = { OR = { is_owned_by = $($b.seller) owner = { is_subject_of = $($b.seller) } } }" }) -join " "
	[void]$o.AppendLine(@"
	$($b.id) = {
		icon = generic_colonial_administration
		allowed = { original_tag = FRA }
		visible = {
			has_completed_focus = FRW_colonial_purchases
			$($b.states[0]) = { NOT = { is_owned_by = ROOT } }
		}
		available = {
			custom_trigger_tooltip = { tooltip = FRW_no_pending_offer_tt $(($buys | Where-Object { $_.seller -eq $b.seller } | ForEach-Object { "NOT = { has_country_flag = FRW_buy_$($_.flag) }" }) -join ' ') }
			$own
			$($b.seller) = { exists = yes is_subject = no }
			NOT = { has_war_with = $($b.seller) }
		}
		cost = $($b.cost)
		days_re_enable = 180
		complete_effect = {
			set_country_flag = FRW_buy_$($b.flag)
			$($b.seller) = { country_event = { id = frw.50 days = 1 } }
		}
		ai_will_do = { factor = 1 }
	}
"@)
}
[void]$o.AppendLine("}")
[void]$o.AppendLine("")
[void]$o.AppendLine((Get-Content "$PSScriptRoot\decisions_rest.txt" -Raw -Encoding UTF8))
[IO.File]::WriteAllText("$root\common\decisions\FRW_decisions.txt", $o.ToString(), $enc)
[IO.File]::WriteAllText("$root\common\decisions\categories\FRW_decision_categories.txt", (Get-Content "$PSScriptRoot\decision_categories.txt" -Raw -Encoding UTF8), $enc)
"Entscheidungen geschrieben."
