#!/usr/bin/env node
'use strict';

/**
 * code-sniff-ai CLI
 * Thin Node wrapper around run-review.sh so the tool can be distributed via npm
 * and consumed in CI (GitHub Actions) without a hand-written .env file.
 *
 * Configuration precedence: CLI flags > environment variables > --env file (default ./.env)
 */

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const VERSION = require('../package.json').version;
const ENGINE = path.join(__dirname, '..', 'run-review.sh');

const HELP = `
code-sniff-ai v${VERSION} - AI code review for git changes

Usage:
  code-sniff-ai [options]

Review target:
  --diff <range>       Git diff range to review, e.g. "origin/main...HEAD"
                       (default: staged changes, i.e. \`git diff --cached\`)
  --target <path>      Path to the project to review (default: current directory)
  --extensions <list>  Comma-separated extensions, e.g. ".ts,.tsx,.py"
                       (or a raw regex like ".ts$|.py$")

Provider configuration:
  --provider <name>    claude | chatgpt | gemini | groq | ollama (default: claude)
  --model <model>      Model name (default depends on provider)
  --endpoint <url>     API endpoint override
  --api-key <key>      API key (or set CODE_SNIFF_API_KEY / provider-specific keys)
  --max-tokens <n>     Max output tokens (default: 4096)
  --response-path <p>  jq path to the review text, e.g. .content[0].text

Prompt:
  --prompt <text>      Review prompt (inline text)
  --prompt-file <path> Review prompt from a file

Other:
  --env <path>         Load a .env-style config file (default: ./.env if present)
  -v, --version        Print version
  -h, --help           Show this help

Examples:
  # Review staged changes with Claude
  export ANTHROPIC_API_KEY=sk-ant-...
  git add -A && code-sniff-ai

  # Review a PR diff in CI
  code-sniff-ai --provider groq --model llama-3.1-8b-instant \\
    --diff "origin/main...HEAD" --extensions ".ts,.tsx"

  # Local Ollama
  code-sniff-ai --provider ollama --model gemma2

Requires: git, jq, curl, and bash (macOS/Linux, or WSL/Git Bash on Windows).
`;

const PROVIDER_DEFAULTS = {
  claude: {
    endpoint: 'https://api.anthropic.com/v1/messages',
    model: 'claude-sonnet-4-5',
    responsePath: '.content[0].text',
    keyEnv: ['CODE_SNIFF_API_KEY', 'ANTHROPIC_API_KEY'],
  },
  chatgpt: {
    endpoint: 'https://api.openai.com/v1/chat/completions',
    model: 'gpt-4o-mini',
    responsePath: '.choices[0].message.content',
    keyEnv: ['CODE_SNIFF_API_KEY', 'OPENAI_API_KEY'],
  },
  gemini: {
    // endpoint is built after the model is known (key is embedded in the URL)
    responsePath: '.candidates[0].content.parts[0].text',
    keyEnv: ['CODE_SNIFF_API_KEY', 'GEMINI_API_KEY', 'GOOGLE_API_KEY'],
  },
  groq: {
    endpoint: 'https://api.groq.com/openai/v1/chat/completions',
    model: 'llama-3.1-8b-instant',
    responsePath: '.choices[0].message.content',
    keyEnv: ['CODE_SNIFF_API_KEY', 'GROQ_API_KEY'],
  },
  ollama: {
    endpoint: 'http://localhost:11434/api/chat',
    model: 'gemma2',
    responsePath: '.message.content',
    keyEnv: [],
  },
};

function parseArgs(argv) {
  const flags = {};
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    const next = () => {
      if (i + 1 >= argv.length) fail(`Missing value for ${arg}`);
      return argv[++i];
    };
    switch (arg) {
      case '-h': case '--help': flags.help = true; break;
      case '-v': case '--version': flags.version = true; break;
      case '--provider': flags.provider = next(); break;
      case '--model': flags.model = next(); break;
      case '--endpoint': flags.endpoint = next(); break;
      case '--api-key': case '-k': flags.apiKey = next(); break;
      case '--max-tokens': flags.maxTokens = next(); break;
      case '--response-path': flags.responsePath = next(); break;
      case '--extensions': flags.extensions = next(); break;
      case '--prompt': flags.prompt = next(); break;
      case '--prompt-file': flags.promptFile = next(); break;
      case '--target': flags.target = next(); break;
      case '--diff': flags.diff = next(); break;
      case '--env': flags.envFile = next(); break;
      default: fail(`Unknown option: ${arg}\nRun "code-sniff-ai --help" for usage.`);
    }
  }
  return flags;
}

function fail(msg) {
  console.error(`code-sniff-ai: ${msg}`);
  process.exit(1);
}

/** Parse a .env-style file (supports quoted multi-line values like PROMPT). */
function loadEnvFile(file) {
  const out = {};
  let text;
  try {
    text = fs.readFileSync(file, 'utf8');
  } catch {
    return out;
  }
  const lines = text.split(/\r?\n/);
  let key = null;
  let val = '';
  const closeValue = (raw) => {
    const q = raw[0];
    if ((q === '"' || q === "'") && raw.length > 1 && raw.endsWith(q)) {
      return raw.slice(1, -1);
    }
    return raw;
  };
  for (const line of lines) {
    if (key === null) {
      if (line.trim().startsWith('#')) continue;
      const m = line.match(/^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
      if (!m) continue;
      key = m[1];
      val = m[2];
      const q = val[0];
      const closed =
        !(q === '"' || q === "'") ||
        (val.length > 1 && val.endsWith(q) && !val.slice(0, -1).endsWith('\\' + q));
      if (closed) {
        out[key] = closeValue(val);
        key = null;
      }
    } else {
      val += '\n' + line;
      const q = val[0];
      if (val.length > 1 && val.endsWith(q) && !val.slice(0, -1).endsWith('\\' + q)) {
        out[key] = closeValue(val);
        key = null;
      }
    }
  }
  if (key !== null) out[key] = String(val);
  return out;
}

/** ".ts,.tsx,.py" -> "\.ts$|\.tsx$|\.py$" ; raw regex (contains |) passes through. */
function normalizeExtensions(ext) {
  if (!ext) return ext;
  if (ext.includes('|')) return ext;
  return ext
    .split(',')
    .map((e) => e.trim().replace(/\./g, '\\.'))
    .filter(Boolean)
    .map((e) => (e.endsWith('$') ? e : e + '$'))
    .join('|');
}

function resolveConfig(flags) {
  const fileEnv = loadEnvFile(flags.envFile || path.join(process.cwd(), '.env'));
  const get = (key) => flags[key] ?? process.env[key] ?? fileEnv[key];

  const provider = (get('provider') || 'claude').toLowerCase();
  const defaults = PROVIDER_DEFAULTS[provider];
  if (!defaults) {
    fail(`Unknown provider "${provider}". Supported: ${Object.keys(PROVIDER_DEFAULTS).join(', ')}`);
  }

  const apiKey =
    get('apiKey') ??
    defaults.keyEnv.map((k) => process.env[k]).find(Boolean) ??
    fileEnv.API_KEY;

  if (provider !== 'ollama' && !apiKey) {
    fail(
      `No API key for provider "${provider}".\n` +
        `Set --api-key, CODE_SNIFF_API_KEY, or the provider key env var` +
        (defaults.keyEnv.length ? ` (${defaults.keyEnv.slice(1).join(' / ')})` : '') +
        ', or use --provider ollama for local review.'
    );
  }

  const model = get('model') || defaults.model;
  if (!model) fail(`--model is required for provider "${provider}".`);

  let endpoint = get('endpoint') || defaults.endpoint;
  if (provider === 'gemini' && !endpoint) {
    endpoint = `https://generativelanguage.googleapis.com/v1/models/${model}:generateContent?key=${apiKey}`;
  }

  const prompt =
    flags.prompt ??
    (flags.promptFile ? fs.readFileSync(flags.promptFile, 'utf8') : undefined) ??
    fileEnv.PROMPT;

  const cfg = {
    SERVICE_PROVIDER: provider,
    MODEL: model,
    ENDPOINT: endpoint,
    API_KEY: apiKey || '',
    RESPONSE_PATH: get('responsePath') || defaults.responsePath,
    MAX_TOKENS: get('maxTokens') || '4096',
    FILE_EXTENSIONS: normalizeExtensions(get('extensions')),
    TARGET_PROJECT_PATH: get('target') || '',
    REVIEW_DIFF: flags.diff ?? get('diff') ?? '',
  };
  if (prompt) cfg.PROMPT = prompt;
  return cfg;
}

function main() {
  const flags = parseArgs(process.argv.slice(2));
  if (flags.help) {
    console.log(HELP.trim());
    return;
  }
  if (flags.version) {
    console.log(VERSION);
    return;
  }
  if (process.platform === 'win32' && !fs.existsSync('C:\\Program Files\\Git\\bin\\bash.exe')) {
    fail('bash not found. Use WSL or Git Bash on Windows.');
  }
  const cfg = resolveConfig(flags);
  const result = spawnSync('bash', [ENGINE], {
    stdio: 'inherit',
    cwd: process.cwd(),
    env: { ...process.env, ...cfg },
  });
  if (result.error) fail(result.error.message);
  process.exit(result.status ?? 1);
}

main();
