// index.ts
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const isMac = process.platform === "darwin";
const isWin = process.platform === "win32";

async function sendToChatGPT_mac(text: string) {
  // 동적 import: mac에서만 로드되도록
  const runAppleScript = (await import("run-applescript")).default as (s: string)=>Promise<string>;
  // ChatGPT.app 활성화 후 붙여넣기 & 전송 (예: AppleScript)
  const script = `
    tell application "ChatGPT" to activate
    delay 0.2
    tell application "System Events"
      keystroke "v" using {command down}
      key code 36 -- Enter
    end tell
  `;
  // 클립보드로 텍스트 세팅
  await runAppleScript(`set the clipboard to ${JSON.stringify(text)}`);
  await runAppleScript(script);
}

async function sendToChatGPT_win(text: string) {
  // PowerShell로: ChatGPT 창 활성화(AppActivate) -> 클립보드 세팅 -> Ctrl+V -> Enter
  // 설치 경로가 기본(사용자 설치)인 경우: %LOCALAPPDATA%\Programs\ChatGPT\ChatGPT.exe
  const { spawn } = await import("node:child_process");
  const ps = spawn("powershell.exe", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", `
    Add-Type -AssemblyName System.Windows.Forms
    $null = [System.Windows.Forms.Clipboard]::SetText(${JSON.stringify(text)})
    $wshell = New-Object -ComObject wscript.shell
    # ChatGPT 창 활성화 시도(제목 일부 'ChatGPT')
    $activated = $wshell.AppActivate('ChatGPT')
    if (-not $activated) {
      # 실행 경로 시도
      $paths = @(
        "$env:LOCALAPPDATA\\Programs\\ChatGPT\\ChatGPT.exe",
        "$env:ProgramFiles\\ChatGPT\\ChatGPT\\ChatGPT.exe",
        "$env:ProgramFiles(x86)\\ChatGPT\\ChatGPT\\ChatGPT.exe"
      )
      foreach ($p in $paths) {
        if (Test-Path $p) { Start-Process $p; Start-Sleep -Milliseconds 800; break }
      }
      $wshell.AppActivate('ChatGPT') | Out-Null
    }
    Start-Sleep -Milliseconds 250
    $wshell.SendKeys('^v')
    Start-Sleep -Milliseconds 100
    $wshell.SendKeys('~')  # Enter
  `], { stdio: "ignore" });

  await new Promise<void>((resolve, reject) => {
    ps.on("exit", (code) => code === 0 ? resolve() : reject(new Error("powershell exit "+code)));
    ps.on("error", reject);
  });
}

async function sendToChatGPT(text: string) {
  if (isMac) return sendToChatGPT_mac(text);
  if (isWin) return sendToChatGPT_win(text);
  throw new Error("Unsupported platform");
}

const server = new Server(
  {
    name: "claude-chatgpt-mcp",
    version: "1.1.0"
  },
  {
    capabilities: {
      tools: {}
    }
  }
);

server.tool("send_to_chatgpt", {
  description: "ChatGPT 데스크톱 앱에 텍스트를 붙여넣고 전송",
  inputSchema: {
    type: "object",
    properties: {
      text: { type: "string" }
    },
    required: ["text"]
  },
  handler: async ({ input }) => {
    await sendToChatGPT(input.text);
    return { ok: true };
  }
});

const transport = new StdioServerTransport();
server.connect(transport);
