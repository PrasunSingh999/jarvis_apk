// netlify/functions/chat.js
//
// This runs on Netlify's servers, NOT in the browser — so the API key
// stays secret. It reads GROQ_API_KEY from Netlify's environment
// variables (set in the dashboard, never committed to code).
//
// Groq offers a free, no-credit-card API tier and is OpenAI-compatible,
// which is why the request/response shape below looks like the OpenAI
// chat completions format rather than Anthropic's.

exports.handler = async function (event) {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }

  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Server is missing GROQ_API_KEY. Set it in Netlify → Site settings → Environment variables.' }),
    };
  }

  let userMessage;
  let detailed = false;
  try {
    const body = JSON.parse(event.body || '{}');
    userMessage = (body.message || '').trim();
    detailed = !!body.detailed;
  } catch (e) {
    return { statusCode: 400, body: JSON.stringify({ error: 'Invalid request body.' }) };
  }

  if (!userMessage) {
    return { statusCode: 400, body: JSON.stringify({ error: 'No message provided.' }) };
  }

  // Two personas: a brief spoken-first mode for everyday voice back-and-forth,
  // and an optional "deep dive" mode for when the user wants real analysis.
  // Both are instructed to reply in whatever language the user spoke in.
  const briefPrompt =
    "You are JARVIS, a calm, witty, precise personal AI assistant in the style of the Iron Man films. " +
    "Always reply in the same language the user just wrote in — detect it from their message and match it, whatever it is. " +
    "Keep responses conversational but brief, 1 to 3 sentences, since they will be spoken aloud by text-to-speech. " +
    "Address the user as 'sir' occasionally, not every reply. No markdown, no lists, no asterisks, no headers — plain spoken sentences only.";

  const detailedPrompt =
    "You are JARVIS, a hyper-competent personal AI assistant in the style of the Iron Man films: precise, confident, " +
    "dryly witty, and genuinely useful. Always reply in the same language the user just wrote in. " +
    "The user wants a real, thorough answer this time, not a one-liner. Give a clear, well-reasoned response: " +
    "lead with the direct answer or recommendation, then the key reasoning, then note any real risks or caveats, " +
    "then concrete next steps if relevant. Write it as natural spoken paragraphs — no markdown headers, no bullet " +
    "symbols, no asterisks — since this may be read aloud by text-to-speech; use short paragraphs instead of lists.";

  try {
    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        max_tokens: detailed ? 900 : 300,
        messages: [
          {
            role: 'system',
            content: detailed ? detailedPrompt : briefPrompt,
          },
          { role: 'user', content: userMessage },
        ],
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      return { statusCode: response.status, body: JSON.stringify({ error: `Groq API error: ${errText}` }) };
    }

    const data = await response.json();
    const reply = data.choices?.[0]?.message?.content?.trim();

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ reply: reply || "I processed that, but didn't have a clear answer, sir." }),
    };
  } catch (e) {
    return { statusCode: 500, body: JSON.stringify({ error: 'Failed to reach Groq: ' + e.message }) };
  }
};
