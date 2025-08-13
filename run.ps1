# run.ps1 - Windows runner for Claude ChatGPT MCP
$ErrorActionPreference = "Stop"

Write-Host "🚀 Claude ChatGPT MCP Server (Windows)" -ForegroundColor Green

if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
  Write-Host "❌ Bun is not installed." -ForegroundColor Red
  Write-Host "   Install with: powershell -NoProfile -Command ""iwr https://bun.sh/install.ps1 -UseBasicParsing | iex"""
  exit 1
}

# 의존성 설치(최초 실행 대비)
if (-not (Test-Path "node_modules")) {
  Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
  bun install
}

Write-Host ""
Write-Host "📋 Configuration Info:" -ForegroundColor Green
Write-Host ("   Current user: {0}" -f $env:USERNAME)
Write-Host ("   Bun path: {0}" -f (Get-Command bun).Source)
Write-Host ("   Project path: {0}" -f (Get-Location).Path)
Write-Host ""
Write-Host "🎯 Starting MCP Server... (Ctrl+C to stop)" -ForegroundColor Green
Write-Host ""

bun run index.ts
