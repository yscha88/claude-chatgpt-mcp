# setup.ps1 - Windows setup for Claude ChatGPT MCP
$ErrorActionPreference = "Stop"

Write-Host "🔧 Claude ChatGPT MCP Setup (Windows)" -ForegroundColor Green

# 1) Bun 설치 확인
if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
  Write-Host "📦 Installing Bun..." -ForegroundColor Yellow
  powershell -NoProfile -Command "iwr https://bun.sh/install.ps1 -UseBasicParsing | iex"
  $env:Path = "$env:USERPROFILE\.bun\bin;$env:Path"
}

# 2) 의존성 설치
if (-not (Test-Path "node_modules")) {
  Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
  bun install
}

# 3) Claude Desktop 설정 파일 생성/병합
$ConfigDir = Join-Path $env:APPDATA "Claude"
$ConfigFile = Join-Path $ConfigDir "claude_desktop_config.json"
if (-not (Test-Path $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir | Out-Null }

$BunPath = (Get-Command bun).Source
$ProjectPath = (Get-Location).Path

# 새 MCP 블록
$mcp = @{
  mcpServers = @{
    "chatgpt-mcp" = @{
      command = "$BunPath"
      args    = @("run", "$ProjectPath/index.ts")
    }
  }
}

if (Test-Path $ConfigFile) {
  Write-Host "📋 Existing Claude config found. Backing up..." -ForegroundColor Cyan
  Copy-Item $ConfigFile "$ConfigFile.backup" -Force

  try {
    $existing = Get-Content $ConfigFile -Raw | ConvertFrom-Json
  } catch {
    $existing = @{}
  }

  if (-not $existing) { $existing = @{} }
  if (-not $existing.mcpServers) { $existing | Add-Member -NotePropertyName mcpServers -NotePropertyValue @{} }

  $existing.mcpServers."chatgpt-mcp" = $mcp.mcpServers."chatgpt-mcp"
  $existing | ConvertTo-Json -Depth 6 | Set-Content $ConfigFile -Encoding UTF8
} else {
  $mcp | ConvertTo-Json -Depth 6 | Set-Content $ConfigFile -Encoding UTF8
}

Write-Host ""
Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "  1) Claude Desktop 재시작"
Write-Host "  2) ChatGPT 데스크톱 앱이 설치/실행 중인지 확인"
Write-Host ""
Write-Host "🚀 To test, run:  powershell -ExecutionPolicy Bypass -File .\run.ps1" -ForegroundColor Green
