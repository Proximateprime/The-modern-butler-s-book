// Phrase Edge Function — Groq lives here, never in the APK.
//
// Secret GROQ_API_KEY is a Supabase function secret (dashboard only).
// Never log it. Never return it in JSON, headers, or error bodies.
// This function rephrases copy. It is not a diagnosis engine.
// The Flutter client still runs phrasing_safety_gate before paint.

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions'
const GROQ_MODEL = 'llama-3.1-8b-instant'
const MAX_BODY_BYTES = 8192
const MAX_FIELD_CHARS = 2000
const MAX_OPTIONS = 12
const RATE_WINDOW_MS = 60_000
const RATE_MAX = 30

const CORS: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

const SYSTEM_PROMPT =
  'You rephrase household repair copy. The engine already decided. ' +
  'Return JSON only with keys title, why_one_line, option_labels_only. ' +
  'Optional describe_title and describe_hint may ride that same payload ' +
  'as extra display strings for the Other / describe type-in. ' +
  'Use the same option ids — never invent a fourth option or new chip id. ' +
  'Keep the Other / describe option id. Do not map typed notes onto ' +
  'another chip. Do not pick the next question. ' +
  'Do not write how-to. Do not mention gas_train, live_voltage, or sealed. ' +
  'No confidence numbers. No streaming novels. ' +
  "Do not paraphrase frozen chrome: I'll repair, Call a pro, Most likely, " +
  'Current question, Why ask this?, Continue repair, Start repair, ' +
  "Matches / OK, Doesn't match / Not OK. " +
  'If safety is stop_unplug, keep unplug, ventilate, and do not keep ' +
  'running. Confirm is not Fixed unless the engine already allows it.'

const REQUIRED_STRINGS = [
  'family',
  'energy',
  'state',
  'comfort',
  'evidence_needed',
  'last_obs',
  'why_engine',
  'safety',
] as const

const FORBIDDEN_CLIENT_KEYS = [
  'groq_api_key',
  'api_key',
  'authorization',
  'service_role',
  'GROQ_API_KEY',
]

const DEFAULT_BANNED = ['gas_train', 'live_voltage', 'sealed']

type PhrasePayload = {
  family: string
  energy: string
  state: string
  comfort: string
  evidence_needed: string
  options: string[]
  last_obs: string
  why_engine: string
  safety: string
  banned: string[]
}

type PublicPhraseJson = {
  title?: string
  why_one_line?: string
  option_labels_only?: Record<string, string>
  describe_title?: string
  describe_hint?: string
}

const rateHits = new Map<string, { count: number; resetAt: number }>()

function jsonResponse(
  status: number,
  body: Record<string, unknown>,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  })
}

function clientIp(req: Request): string {
  const forwarded = req.headers.get('x-forwarded-for')
  if (forwarded) {
    return forwarded.split(',')[0]?.trim() || 'unknown'
  }
  return req.headers.get('cf-connecting-ip') ?? 'unknown'
}

function isRateLimited(ip: string): boolean {
  const now = Date.now()
  const current = rateHits.get(ip)
  if (!current || now > current.resetAt) {
    rateHits.set(ip, { count: 1, resetAt: now + RATE_WINDOW_MS })
    return false
  }
  current.count += 1
  return current.count > RATE_MAX
}

function looksLikeGroqKey(value: string): boolean {
  return /gsk_[A-Za-z0-9]{8,}/.test(value)
}

function leaksSecret(text: string, secret: string): boolean {
  if (looksLikeGroqKey(text)) {
    return true
  }
  const trimmed = secret.trim()
  return trimmed.length > 0 && text.includes(trimmed)
}

function validatePhrasePayload(body: unknown): PhrasePayload | null {
  if (body == null || typeof body !== 'object' || Array.isArray(body)) {
    return null
  }
  const raw = body as Record<string, unknown>
  for (const key of Object.keys(raw)) {
    const lower = key.toLowerCase()
    if (
      FORBIDDEN_CLIENT_KEYS.includes(key) ||
      FORBIDDEN_CLIENT_KEYS.includes(lower)
    ) {
      return null
    }
  }
  for (const field of REQUIRED_STRINGS) {
    const value = raw[field]
    if (typeof value !== 'string' || value.length > MAX_FIELD_CHARS) {
      return null
    }
  }
  const options = raw.options
  if (
    !Array.isArray(options) ||
    options.length > MAX_OPTIONS ||
    !options.every((item) => typeof item === 'string' && item.length <= 120)
  ) {
    return null
  }
  let banned = DEFAULT_BANNED
  if (raw.banned !== undefined) {
    if (
      !Array.isArray(raw.banned) ||
      !raw.banned.every((item) => typeof item === 'string' && item.length <= 80)
    ) {
      return null
    }
    banned = raw.banned as string[]
  }
  return {
    family: raw.family as string,
    energy: raw.energy as string,
    state: raw.state as string,
    comfort: raw.comfort as string,
    evidence_needed: raw.evidence_needed as string,
    options: options as string[],
    last_obs: raw.last_obs as string,
    why_engine: raw.why_engine as string,
    safety: raw.safety as string,
    banned,
  }
}

function publicPhraseJson(raw: string): PublicPhraseJson | null {
  let text = raw.trim()
  if (text.startsWith('```')) {
    text = text.replace(/^```(?:json)?/, '').trim()
    if (text.endsWith('```')) {
      text = text.slice(0, -3).trim()
    }
  }
  let decoded: unknown
  try {
    decoded = JSON.parse(text)
  } catch {
    return null
  }
  if (decoded == null || typeof decoded !== 'object' || Array.isArray(decoded)) {
    return null
  }
  const obj = decoded as Record<string, unknown>
  const title = typeof obj.title === 'string' ? obj.title.trim() : ''
  const why =
    typeof obj.why_one_line === 'string' ? obj.why_one_line.trim() : ''
  const labels: Record<string, string> = {}
  const rawLabels = obj.option_labels_only
  if (rawLabels && typeof rawLabels === 'object' && !Array.isArray(rawLabels)) {
    for (const [key, value] of Object.entries(
      rawLabels as Record<string, unknown>,
    )) {
      const id = key.trim()
      const label = typeof value === 'string' ? value.trim() : ''
      if (id && label) {
        labels[id] = label
      }
    }
  }
  if (!title && !why && Object.keys(labels).length === 0) {
    return null
  }
  const describeTitle =
    typeof obj.describe_title === 'string' ? obj.describe_title.trim() : ''
  const describeHint =
    typeof obj.describe_hint === 'string' ? obj.describe_hint.trim() : ''
  const out: PublicPhraseJson = {}
  if (title) out.title = title
  if (why) out.why_one_line = why
  if (Object.keys(labels).length > 0) out.option_labels_only = labels
  if (describeTitle) out.describe_title = describeTitle
  if (describeHint) out.describe_hint = describeHint
  return out
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS })
  }
  if (req.method !== 'POST') {
    return jsonResponse(405, { error: 'method_not_allowed' })
  }

  const authorization = req.headers.get('Authorization') ?? ''
  const apikey = req.headers.get('apikey') ?? ''
  if (!authorization.startsWith('Bearer ') || authorization.length < 20) {
    return jsonResponse(401, { error: 'unauthorized' })
  }
  if (looksLikeGroqKey(authorization) || looksLikeGroqKey(apikey)) {
    return jsonResponse(401, { error: 'unauthorized' })
  }

  if (isRateLimited(clientIp(req))) {
    return jsonResponse(429, { error: 'rate_limited' })
  }

  const declaredLength = Number(req.headers.get('content-length') ?? '0')
  if (Number.isFinite(declaredLength) && declaredLength > MAX_BODY_BYTES) {
    return jsonResponse(413, { error: 'payload_too_large' })
  }

  let rawText: string
  try {
    rawText = await req.text()
  } catch {
    return jsonResponse(400, { error: 'bad_payload' })
  }
  if (rawText.length > MAX_BODY_BYTES) {
    return jsonResponse(413, { error: 'payload_too_large' })
  }

  let parsed: unknown
  try {
    parsed = JSON.parse(rawText)
  } catch {
    return jsonResponse(400, { error: 'bad_payload' })
  }

  const payload = validatePhrasePayload(parsed)
  if (!payload) {
    return jsonResponse(400, { error: 'bad_payload' })
  }

  const groqKey = (Deno.env.get('GROQ_API_KEY') ?? '').trim()
  if (!groqKey) {
    return jsonResponse(503, { error: 'unavailable' })
  }

  try {
    const groqRes = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${groqKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        temperature: 0.2,
        max_tokens: 220,
        stream: false,
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: SYSTEM_PROMPT },
          {
            role: 'user',
            content: JSON.stringify({
              family: payload.family,
              energy: payload.energy,
              state: payload.state,
              comfort: payload.comfort,
              evidence_needed: payload.evidence_needed,
              options: payload.options,
              last_obs: payload.last_obs,
              why_engine: payload.why_engine,
              safety: payload.safety,
              banned: payload.banned,
            }),
          },
        ],
      }),
    })

    if (!groqRes.ok) {
      return jsonResponse(502, { error: 'upstream' })
    }

    const groqJson: unknown = await groqRes.json()
    const content = extractContent(groqJson)
    if (!content) {
      return jsonResponse(502, { error: 'upstream' })
    }
    if (leaksSecret(content, groqKey)) {
      return jsonResponse(502, { error: 'upstream' })
    }

    const publicBody = publicPhraseJson(content)
    if (!publicBody) {
      return jsonResponse(502, { error: 'upstream' })
    }

    const serialized = JSON.stringify(publicBody)
    if (leaksSecret(serialized, groqKey)) {
      return jsonResponse(502, { error: 'upstream' })
    }

    return new Response(serialized, {
      status: 200,
      headers: { ...CORS, 'Content-Type': 'application/json' },
    })
  } catch {
    return jsonResponse(502, { error: 'upstream' })
  }
})

function extractContent(raw: unknown): string | null {
  if (raw == null || typeof raw !== 'object') {
    return null
  }
  const choices = (raw as { choices?: unknown }).choices
  if (!Array.isArray(choices) || choices.length === 0) {
    return null
  }
  const first = choices[0]
  if (first == null || typeof first !== 'object') {
    return null
  }
  const message = (first as { message?: unknown }).message
  if (message == null || typeof message !== 'object') {
    return null
  }
  const content = (message as { content?: unknown }).content
  return typeof content === 'string' && content.trim() ? content : null
}
