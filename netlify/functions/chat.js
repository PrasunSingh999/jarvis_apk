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
  try {
    const body = JSON.parse(event.body || '{}');
    userMessage = (body.message || '').trim();
  } catch (e) {
    return { statusCode: 400, body: JSON.stringify({ error: 'Invalid request body.' }) };
  }

  if (!userMessage) {
    return { statusCode: 400, body: JSON.stringify({ error: 'No message provided.' }) };
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
        max_tokens: 300,
        messages: [
          {
            role: 'system',
            content:
              "You are JARVIS, a calm, precise personal AI assistant, styled after the assistant from Iron Man. " +
              "Keep responses conversational but brief — 1 to 3 sentences, since they'll be spoken aloud by text-to-speech. " +
              "Address the user as 'sir' occasionally, but don't overdo it. No markdown, no lists, no asterisks — plain spoken sentences only.",
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
