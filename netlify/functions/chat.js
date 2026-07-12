// netlify/functions/chat.js
//
// This runs on Netlify's servers, NOT in the browser — so the API key
// stays secret. It reads GROQ_API_KEY from Netlify's environment
// variables (set in the dashboard, never committed to code).
//
// Groq offers a free, no-credit-card API tier and is OpenAI-compatible,
// which is why the request/response shape below looks like the OpenAI
// chat completions format rather than Anthropic's or xAI's.

const JARVIS_SYSTEM_PROMPT =
  "You are J.A.R.V.I.S., a calm, precise personal AI assistant, styled after the assistant from Iron Man. " +
  "Keep responses conversational but brief — 1 to 3 sentences for simple requests, since they may be spoken aloud by text-to-speech. " +
  "For genuinely complex questions, you may go longer and structure the answer clearly, but never pad with filler. " +
  "Address the user as 'sir' occasionally, but don't overdo it. No markdown, no lists, no asterisks — plain spoken sentences only. " +
  "You understand and reply fluently in any language the user writes or speaks in — always match their language. " +
  "Be proactive: offer a relevant next step when it's genuinely useful, without being asked.";

exports.handler = async function (event) {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };

  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 204, headers, body: '' };
  }

  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, headers, body: 'Method Not Allowed' };
  }

  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) {
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: 'Server is missing GROQ_API_KEY. Set it in Netlify → Site settings → Environment variables.' }),
    };
  }

  // The frontend sends the full running conversation as messages: [{role, content}, ...]
  // rather than a single message string, so JARVIS keeps context across turns.
  let history;
  try {
    const body = JSON.parse(event.body || '{}');
    history = Array.isArray(body.messages) ? body.messages : [];
  } catch (e) {
    return { statusCode: 400, headers, body: JSON.stringify({ error: 'Invalid request body.' }) };
  }

  if (history.length === 0) {
    return { statusCode: 400, headers, body: JSON.stringify({ error: 'No messages provided.' }) };
  }

  try {
    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        max_tokens: 600,
        messages: [
          { role: 'system', content: JARVIS_SYSTEM_PROMPT },
          ...history,
        ],
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      return { statusCode: response.status, headers, body: JSON.stringify({ error: `Groq API error: ${errText}` }) };
    }

    const data = await response.json();
    const reply = data.choices?.[0]?.message?.content?.trim();

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ reply: reply || "I processed that, but didn't have a clear answer, sir." }),
    };
  } catch (e) {
    return { statusCode: 500, headers, body: JSON.stringify({ error: 'Failed to reach Groq: ' + e.message }) };
  }
};
