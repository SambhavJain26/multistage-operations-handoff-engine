#Requires -Version 5.1
<#
.SYNOPSIS
    Render a carousel from HTML to an upload-ready PDF.

.DESCRIPTION
    Decks live in the kit root next to carousel-template.css. This prints them
    through headless Chrome at the page size the stylesheet declares
    (1080 x 1350) and writes the PDF to out/.

    Anything in examples/ is reference and is skipped, unless named explicitly.

    Fonts are fetched from api.fontshare.com at render time, so the machine
    needs network access. -VirtualTimeBudget exists because Chrome will
    otherwise print before the webfonts land and silently fall back to a system
    face, which does not error and is easy to miss.

.EXAMPLE
    .\scripts\render-carousel.ps1

.EXAMPLE
    .\scripts\render-carousel.ps1 -Name post-04-something
#>
[CmdletBinding()]
param(
    [string] $Name,
    [int]    $VirtualTimeBudget = 25000
)

$ErrorActionPreference = 'Stop'

$kitRoot = Split-Path -Parent $PSScriptRoot
$cssPath = Join-Path $kitRoot 'carousel-template.css'
$outDir  = Join-Path $kitRoot 'out'

if (-not (Test-Path $cssPath)) { throw "carousel-template.css not found in the kit root: $kitRoot" }
if (-not (Test-Path $outDir))  { New-Item -ItemType Directory -Path $outDir | Out-Null }

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

if ($Name) {
    $sources = @()
    foreach ($candidate in @((Join-Path $kitRoot "$Name.html"), (Join-Path $kitRoot "examples\$Name.html"))) {
        if (Test-Path $candidate) { $sources = @(Get-Item $candidate); break }
    }
    if ($sources.Count -eq 0) { throw "No such carousel: $Name" }
} else {
    $sources = @(Get-ChildItem -Path $kitRoot -Filter '*.html' -File)
    if ($sources.Count -eq 0) { throw "No carousel HTML in $kitRoot. Write one there, next to carousel-template.css." }
}

$browser    = Find-Chrome
$profileDir = Join-Path $env:TEMP ('carousel-render-' + [guid]::NewGuid().ToString('N'))
Write-Host "Renderer: $browser"

$failed = 0
foreach ($src in $sources) {
    $pdf = Join-Path $outDir ($src.BaseName + '.pdf')
    $url = 'file:///' + ($src.FullName -replace '\\', '/')

    Write-Host "Rendering $($src.Name) -> $(Split-Path -Leaf $pdf)"

    # Invoking chrome.exe directly hands the command line to an already-running
    # Chrome and returns immediately with no exit code, so the PDF never gets
    # written. Start-Process with a throwaway profile keeps this instance
    # separate and lets us actually wait for it.
    $browserArgs = @(
        '--headless=new'
        '--disable-gpu'
        '--no-sandbox'
        '--no-pdf-header-footer'
        '--run-all-compositor-stages-before-draw'
        "--user-data-dir=$profileDir"
        "--virtual-time-budget=$VirtualTimeBudget"
        "--print-to-pdf=$pdf"
        $url
    )

    $proc = Start-Process -FilePath $browser -ArgumentList $browserArgs -NoNewWindow -Wait -PassThru

    if ($proc.ExitCode -ne 0 -or -not (Test-Path $pdf)) {
        Write-Warning "FAILED: $($src.Name) (exit $($proc.ExitCode))"
        $failed++
        continue
    }

    # Verify rather than assume. A PDF far above a megabyte means the film grain
    # has regressed from a baked tile to an feTurbulence filter, which Chrome
    # rasterises per slide.
    $bytes = [System.IO.File]::ReadAllBytes($pdf)
    $txt   = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)

    # Count page objects directly. Reading /Count off the first /Type /Pages
    # node is wrong: past roughly eight pages Chrome splits the page tree into
    # intermediate nodes, and the first /Count is a subtree rather than the
    # root. An 11-page deck reported as 8 that way, which looked like lost
    # slides and was not.
    $pages = ([regex]::Matches($txt, '/Type\s*/Page(?![s])')).Count
    $box   = ([regex]::Match($txt, '/MediaBox\s*\[\s*([\d\.\- ]+)\]')).Groups[1].Value.Trim()
    $imgs  = ([regex]::Matches($txt, '/Subtype\s*/Image')).Count
    $fonts = ([regex]::Matches($txt, '/BaseFont\s*/([A-Za-z0-9\+\-]+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique).Count
    $sizeKb = [math]::Round($bytes.Length / 1KB, 1)

    $slides = ([regex]::Matches([System.IO.File]::ReadAllText($src.FullName, (New-Object System.Text.UTF8Encoding($false))), '<section class="slide')).Count
    Write-Host "  ok  $sizeKb KB | $pages pages (from $slides slides) | MediaBox $box | $imgs image | $fonts font subsets"
    if ($pages -ne $slides) { Write-Warning "  Page count does not match slide count. A slide may be overrunning its page." }
    if ($imgs -gt 1)      { Write-Warning "  $imgs image objects. Expected 1 (the grain tile). Check the grain is a baked PNG, not an feTurbulence filter." }
    if ($fonts -lt 2)     { Write-Warning "  Only $fonts font subset embedded. The webfonts probably did not load." }
    if ($sizeKb -gt 2048) { Write-Warning "  $sizeKb KB is far above the expected ~130 KB." }
}

Remove-Item -Recurse -Force $profileDir -ErrorAction SilentlyContinue

if ($failed -gt 0) { throw "$failed carousel(s) failed to render." }

Write-Host ''
Write-Host "Done. PDFs in $outDir"
Write-Host 'Upload the PDF to LinkedIn as a document post. The document title you'
Write-Host 'type on upload is displayed in the feed, so use the cover line.'
