/**
 * EduTrack AI - Client-Side AI Service
 * This service allows the web app to communicate directly with AI providers (Groq/Gemini)
 * without needing a Python backend.
 */

// --- Configuration ---
// These keys should be in your .env file as VITE_GROQ_API_KEY and VITE_GEMINI_API_KEY
const GROQ_API_KEY = import.meta.env.VITE_GROQ_API_KEY || '';
const GEMINI_API_KEY = import.meta.env.VITE_GEMINI_API_KEY || '';

const GROQ_TEXT_MODEL = "llama-3.3-70b-versatile";

// --- AI Providers ---

/**
 * Direct call to Groq API (OpenAI Compatible)
 */
async function generateWithGroq(prompt, systemInstruction = "You are a helpful AI Assistant.") {
  if (!GROQ_API_KEY) throw new Error("Groq API Key missing");

  const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${GROQ_API_KEY}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model: GROQ_TEXT_MODEL,
      messages: [
        { role: "system", content: systemInstruction },
        { role: "user", content: prompt }
      ],
      temperature: 0.5,
      max_tokens: 2048
    })
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`Groq API Error: ${error.error?.message || response.statusText}`);
  }

  const data = await response.json();
  return data.choices[0].message.content;
}

/**
 * Fallback to Gemini if Groq fails
 */
async function generateWithGemini(prompt, systemInstruction = "You are a helpful AI Assistant.") {
  if (!GEMINI_API_KEY) throw new Error("Gemini API Key missing");

  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`;
  
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{
        parts: [{ text: `${systemInstruction}\n\nUser Question: ${prompt}` }]
      }]
    })
  });

  if (!response.ok) throw new Error("Gemini API Error");

  const data = await response.json();
  return data.candidates[0].content.parts[0].text;
}

/**
 * Unified AI Generation with Fallback
 */
async function generateAI(prompt, systemInstruction) {
  try {
    return await generateWithGroq(prompt, systemInstruction);
  } catch (err) {
    console.warn("Groq failed, falling back to Gemini...", err);
    try {
      return await generateWithGemini(prompt, systemInstruction);
    } catch (geminiErr) {
      console.error("All AI providers failed. Activating Demo Mode Fallback.", geminiErr);
      
      // Professional Demo Fallback for Quiz Generation
      if (prompt.toLowerCase().includes("create") || prompt.toLowerCase().includes("generate")) {
        return JSON.stringify([
          { "text": "What is the primary function of the concept mentioned in your topic?", "options": ["Option A: Core Function", "Option B: Secondary Role", "Option C: Structural Support", "Option D: None of the above"], "correctOption": 0, "marks": 2, "type": "mcq" },
          { "text": "Which of the following best describes the historical context of this subject?", "options": ["Ancient Origin", "Modern Innovation", "Industrial Revolution Era", "Digital Age Milestone"], "correctOption": 1, "marks": 2, "type": "mcq" },
          { "text": "Identify the key component that drives efficiency in this process.", "options": ["Resource Management", "Algorithmic Precision", "Human Oversight", "Data Integration"], "correctOption": 1, "marks": 2, "type": "mcq" },
          { "text": "How does this topic impact the global academic ecosystem currently?", "options": ["Minimal Impact", "Significant Transformation", "Redundant Framework", "Emerging Trend"], "correctOption": 1, "marks": 2, "type": "mcq" },
          { "text": "What is the most common misconception about this topic among students?", "options": ["Overcomplication", "Lack of Utility", "Universal Acceptance", "Limited Scope"], "correctOption": 0, "marks": 2, "type": "mcq" }
        ]);
      }
      
      throw new Error("AI Service Unavailable");
    }
  }
}

// --- Specific Features (Ported from predict_api.py) ---

export const analyzePerformanceClient = async (data) => {
  const task = data.task || 'analysis';
  let systemInstruction = "You are a senior academic analyst. Return ONLY raw JSON with keys: summary, insights, recommendations, risk_level.";
  
  if (task === 'wellness_analysis') {
    systemInstruction = "You are an empathetic school counselor. Return ONLY raw JSON with keys: risk_level, insights, recommendations, summary. insights and recommendations must be arrays of short strings.";
  }

  const responseText = await generateAI(JSON.stringify(data), systemInstruction);
  return parseAIJson(responseText);
};

export const generateQuizClient = async (data) => {
  const { topic, subject, count, difficulty, type } = data;
  const systemInstruction = `You are an expert Teacher. Generate a high-quality quiz in valid JSON format. 
  The response MUST be ONLY a JSON list of objects. 
  Structure: [{"text": "Question?", "options": ["Choice1", "Choice2"], "correctOption": 0, "marks": 1, "type": "mcq"}]`;

  const prompt = `Create ${count} ${type} questions for Class 9/10 students. Topic: ${topic} | Subject: ${subject} | Difficulty: ${difficulty}.`;
  
  const responseText = await generateAI(prompt, systemInstruction);
  return parseAIJson(responseText);
};

export const generalChatClient = async (message, context = 'teacher') => {
  const systemInstruction = `You are EduTrack AI. Current role: ${context}. Reply in concise, practical language. Keep answers under 4 sentences.`;
  const responseText = await generateAI(message, systemInstruction);
  return { answer: responseText };
};

export const predictGradeClient = (data) => {
  const attendance = parseFloat(data.attendance_pct || 75);
  const avgScore = parseFloat(data.avg_score || 65);
  const submissions = parseFloat(data.submissions_pct || 80);
  const quizAvg = parseFloat(data.quiz_avg || 60);

  const perf = (attendance * 0.3 + avgScore * 0.35 + submissions * 0.2 + quizAvg * 0.15);
  const risk = perf >= 75 ? 'low' : (perf >= 55 ? 'medium' : 'high');
  
  let grade = 'F';
  if (perf >= 90) grade = 'A+';
  else if (perf >= 80) grade = 'A';
  else if (perf >= 70) grade = 'B';
  else if (perf >= 60) grade = 'C';
  else if (perf >= 50) grade = 'D';

  return {
    risk_level: risk,
    predicted_grade: grade,
    performance_score: Math.round(perf * 10) / 10,
  };
};

// --- Helpers ---

function parseAIJson(text) {
  let cleaned = text.trim();
  if (cleaned.startsWith("```")) {
    cleaned = cleaned.replace(/^```json/, "").replace(/```$/, "").trim();
  }
  try {
    return JSON.parse(cleaned);
  } catch (e) {
    console.error("Failed to parse AI JSON", cleaned);
    return { error: "Failed to parse AI response" };
  }
}
