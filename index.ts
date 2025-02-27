#!/usr/bin/env bun
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  type Tool,
} from "@modelcontextprotocol/sdk/types.js";
import { runAppleScript } from 'run-applescript';
import { run } from '@jxa/run';

// Define the ChatGPT tool
const CHATGPT_TOOL: Tool = {
  name: "chatgpt",
  description: "Interact with the ChatGPT desktop app on macOS",
  inputSchema: {
    type: "object",
    properties: {
      operation: {
        type: "string",
        description: "Operation to perform: 'ask' or 'get_conversations'",
        enum: ["ask", "get_conversations"]
      },
      prompt: {
        type: "string",
        description: "The prompt to send to ChatGPT (required for ask operation)"
      },
      conversation_id: {
        type: "string",
        description: "Optional conversation ID to continue a specific conversation"
      }
    },
    required: ["operation"]
  }
};

const server = new Server(
  {
    name: "ChatGPT MCP Tool",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Check if ChatGPT app is installed and running
async function checkChatGPTAccess(): Promise<boolean> {
  try {
    const isRunning = await runAppleScript(`
      tell application "System Events"
        return application process "ChatGPT" exists
      end tell
    `);

    if (isRunning !== "true") {
      console.log("ChatGPT app is not running, attempting to launch...");
      try {
        await runAppleScript(`
          tell application "ChatGPT" to activate
          delay 2
        `);
      } catch (activateError) {
        console.error("Error activating ChatGPT app:", activateError);
        throw new Error("Could not activate ChatGPT app. Please start it manually.");
      }
    }
    
    return true;
  } catch (error) {
    console.error("ChatGPT access check failed:", error);
    throw new Error(
      `Cannot access ChatGPT app. Please make sure ChatGPT is installed and properly configured. Error: ${error instanceof Error ? error.message : String(error)}`
    );
  }
}

// Function to send a prompt to ChatGPT
async function askChatGPT(prompt: string, conversationId?: string): Promise<string> {
  await checkChatGPTAccess();
  
  try {
    // This is a simplistic approach - actual implementation may need to be more sophisticated
    const result = await runAppleScript(`
      tell application "ChatGPT"
        activate
        delay 1
        
        tell application "System Events"
          tell process "ChatGPT"
            ${conversationId ? `
            -- Try to find and click the specified conversation
            try
              click button "${conversationId}" of group 1 of group 1 of window 1
              delay 1
            end try
            ` : ''}
            
            -- Type in the prompt
            keystroke "${prompt.replace(/"/g, '\\"')}"
            delay 0.5
            keystroke return
            delay 5  -- Wait for response, adjust as needed
            
            -- Try to get the response (this is approximate and may need adjustments)
            set responseText to ""
            try
              set responseText to value of text area 2 of group 1 of group 1 of window 1
            on error
              set responseText to "Could not retrieve the response from ChatGPT."
            end try
            
            return responseText
          end tell
        end tell
      end tell
    `);
    
    return result;
  } catch (error) {
    console.error("Error interacting with ChatGPT:", error);
    throw new Error(`Failed to get response from ChatGPT: ${error instanceof Error ? error.message : String(error)}`);
  }
}