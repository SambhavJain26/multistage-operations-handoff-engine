#Requires -Version 5.1
<#
.SYNOPSIS
    Render a carousel to PNG for visual checking, without producing a PDF.

.DESCRIPTION
    Building a carousel is an iterative loop: change the HTML or the stylesheet,
    look at it, fix what is wrong. This renders the deck as a contact sheet of
    all slides, or a single slide at full size.

    Look at both. A contact sheet shows composition and rhythm but hides
    clipping, low contrast and misplaced annotations. A full-size slide shows
    the marks but tells you nothing about how the deck reads as a set. Most
    mistakes in the first build of this template were caught by one view after
    passing unnoticed in the other.

    Decks live in the kit root next to carousel-template.css. Anything in
    examples/ is reference and is not picked up unless named explicitly.

.EXAMPLE
    .\scripts\preview-carousel.ps1
    Contact sheet of every slide, when there is only one deck present.

.EXAMPLE
    .\scripts\preview-carousel.ps1 -Name post-04-something -Slide 5
    Slide 5 at full size, for checking a mark or a tight fit.
#>
[CmdletBinding()]
param(
    [string] $Name,
    [int]    $Slide = 0,
    [double] $Zoom  = 0.26,
    [string] $OutDir,
    [int]    $VirtualTimeBudget = 25000
)

$ErrorActionPreference = 'Stop'

$kitRoot = Split-Path -Parent $PSScriptRoot
$cssPath = Join-Path $kitRoot 'carousel-template.css'
if (-not (Test-Path $cssPath)) { throw "carousel-template.css not found next to the kit root: $kitRoot" }

if (-not $OutDir) { $OutDir = Join-Path $env:TEMP 'carousel-preview' }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

function Find-Chrome {
    $candidates = @(
        (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'),
        (Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe'),
        (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe')
    )
    foreach ($c in $candidates) { if ($c -and (Test-Path $c)) { return $c } }
    throw 'No Chrome or Edge executable found.'
}

# Resolve the deck. A named deck may live in the kit root or in examples/.
if ($Name) {
    $src = $null
    foreach ($candidate in @((Join-Path $kitRoot "$Name.html"), (Join-Path $kitRoot "examples\$Name.html"))) {
        if (Test-Path $candidate) { $src = Get-Item $candidate; break }
    }
    if (-not $src) { throw "No such carousel: $Name (looked in the kit root and examples/)" }
} else {
    $all = @(Get-ChildItem -Path $kitRoot -Filter '*.html' -File)
    if ($all.Count -eq 0) { throw "No carousel HTML in $kitRoot. Write one there, next to carousel-template.css." }
    if ($all.Count -gt 1) {
        throw ("Several decks present; pass -Name. Found: " + (($all | ForEach-Object { $_.BaseName }) -join ', '))
    }
    $src = $all[0]
}

$enc  = New-Object System.Text.UTF8Encoding($false)
$html = [System.IO.File]::ReadAllText($src.FullName, $enc)

# The stylesheet is linked relatively, which breaks once the page is copied to
# a temp directory. Point it back at the real file, whichever depth it used.
$cssUrl = 'file:///' + $cssPath.Replace([char]92, [char]47)
$html = $html.Replace('href="../carousel-template.css"', 'href="' + $cssUrl + '"')
$html = $html.Replace('href="carousel-template.css"',    'href="' + $cssUrl + '"')

$slideCount = ([regex]::Matches($html, '<section class="slide')).Count

if ($Slide -gt 0) {
    if ($Slide -gt $slideCount) { throw "Slide $Slide requested but the deck has $slideCount." }
    $zoomUsed = if ($PSBoundParameters.ContainsKey('Zoom')) { $Zoom } else { 1.0 }
    $winW = [int](1080 * $zoomUsed) + 24
    $winH = [int](1350 * $zoomUsed) + 24
    $label = "slide-$Slide"
    $override = @"
<style>
html, body { width:auto; background:#5A6068; }
body { display:block; padding:12px; width:$([int](1080 * $zoomUsed) + 12)px; }
.slide { zoom:$zoomUsed; page-break-after:auto; display:none; }
.slide:nth-of-type($Slide) { display:block; }
</style>
</head>
"@
} else {
    $zoomUsed = $Zoom
    $rows     = [math]::Ceiling($slideCount / 3)
    $winW     = 1180
    $winH     = [int]($rows * ((1350 * $zoomUsed) + 18)) + 40
    $label    = 'sheet'
    $override = @"
<style>
html, body { width:auto; background:#5A6068; }
body { display:flex; flex-wrap:wrap; gap:18px; padding:18px; width:1180px; }
.slide { zoom:$zoomUsed; page-break-after:auto; }
</style>
</head>
"@
}

$html = $html.Replace('</head>', $override)

$stamp    = Get-Date -Format 'HHmmss'
$tempHtml = Join-Path $OutDir "$($src.BaseName)-$label-$stamp.html"
$png      = Join-Path $OutDir "$($src.BaseName)-$label-$stamp.png"
[System.IO.File]::WriteAllText($tempHtml, $html, $enc)

# Invoking chrome.exe directly hands the command line to an already-running
# Chrome and returns immediately with no exit code, so nothing gets written.
# Start-Process with a throwaway profile keeps this instance separate.
$profileDir = Join-Path $env:TEMP ('carousel-preview-' + [guid]::NewGuid().ToString('N'))
$browserArgs = @(
    '--headless=new'
    '--disable-gpu'
    '--no-sandbox'
    '--hide-scrollbars'
    "--user-data-dir=$profileDir"
    "--virtual-time-budget=$VirtualTimeBudget"
    "--window-size=$winW,$winH"
    "--screenshot=$png"
    ('file:///' + $tempHtml.Replace([char]92, [char]47))
)

$proc = Start-Process -FilePath (Find-Chrome) -ArgumentList $browserArgs -NoNewWindow -Wait -PassThru
Remove-Item -Recurse -Force $profileDir -ErrorAction SilentlyContinue

if ($proc.ExitCode -ne 0 -or -not (Test-Path $png)) {
    throw "Render failed (exit $($proc.ExitCode)). Check that the webfonts could be fetched."
}

Write-Host "$($src.BaseName): $slideCount slides"
Write-Host $png
