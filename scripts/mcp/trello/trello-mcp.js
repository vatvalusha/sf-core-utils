#!/usr/bin/env node
// Node >=18, package.json -> "type": "module"
import { Tool, Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const KEY = process.env.TRELLO_API_KEY;
const TOKEN = process.env.TRELLO_TOKEN;
const API = "https://api.trello.com/1";
if (!KEY || !TOKEN) {
  console.error("Set TRELLO_API_KEY and TRELLO_TOKEN env vars");
  process.exit(1);
}

async function trello(path, opts = {}) {
  const url = new URL(API + path);
  url.searchParams.set("key", KEY);
  url.searchParams.set("token", TOKEN);
  if (opts.qs)
    for (const [k, v] of Object.entries(opts.qs)) url.searchParams.set(k, v);
  const res = await fetch(url, {
    method: opts.method || "GET",
    headers: { "Content-Type": "application/json" },
    body: opts.body ? JSON.stringify(opts.body) : undefined
  });
  if (!res.ok) throw new Error(`${res.status}: ${await res.text()}`);
  return res.json();
}

// В 0.6.x можно без capabilities
const server = new Server({ name: "trello-mcp", version: "0.1.0" });

server.addTool(
  new Tool({
    name: "trello_list_boards",
    description: "List user boards",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    },
    async *execute() {
      return await trello(`/members/me/boards`);
    }
  })
);

server.addTool(
  new Tool({
    name: "trello_list_lists",
    description: "List lists on a board",
    inputSchema: {
      type: "object",
      properties: { boardId: { type: "string" } },
      required: ["boardId"],
      additionalProperties: false
    },
    async *execute({ boardId }) {
      return await trello(`/boards/${boardId}/lists`);
    }
  })
);

server.addTool(
  new Tool({
    name: "trello_list_cards",
    description: "List cards in a list",
    inputSchema: {
      type: "object",
      properties: { listId: { type: "string" } },
      required: ["listId"],
      additionalProperties: false
    },
    async *execute({ listId }) {
      return await trello(`/lists/${listId}/cards`);
    }
  })
);

server.addTool(
  new Tool({
    name: "trello_get_card",
    description: "Get card details (attachments, checklists)",
    inputSchema: {
      type: "object",
      properties: { cardId: { type: "string" } },
      required: ["cardId"],
      additionalProperties: false
    },
    async *execute({ cardId }) {
      return await trello(`/cards/${cardId}`, {
        qs: { attachments: "true", checklists: "all" }
      });
    }
  })
);

server.addTool(
  new Tool({
    name: "trello_comment",
    description: "Add comment to a card",
    inputSchema: {
      type: "object",
      properties: { cardId: { type: "string" }, text: { type: "string" } },
      required: ["cardId", "text"],
      additionalProperties: false
    },
    async *execute({ cardId, text }) {
      return await trello(`/cards/${cardId}/actions/comments`, {
        method: "POST",
        qs: { text }
      });
    }
  })
);

server.addTool(
  new Tool({
    name: "trello_move_card",
    description: "Move card to another list",
    inputSchema: {
      type: "object",
      properties: { cardId: { type: "string" }, listId: { type: "string" } },
      required: ["cardId", "listId"],
      additionalProperties: false
    },
    async *execute({ cardId, listId }) {
      return await trello(`/cards/${cardId}`, {
        method: "PUT",
        qs: { idList: listId }
      });
    }
  })
);

// stdio transport
await server.connect(new StdioServerTransport());
