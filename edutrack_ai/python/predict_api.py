import os
import sys

# Force pure-Python implementation for Protobuf
os.environ['PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION'] = 'python'

import json
from flask import Flask, request, jsonify
from flask_cors import CORS
from collections import defaultdict
from datetime import datetime, timedelta
import time
import google.generativeai as genai
from dotenv import load_dotenv
import base64
import io
from PIL import Image
from gtts import gTTS
import PyPDF2
import requests

load_dotenv()

app = Flask(__name__)

# Explicit CORS configuration for Flutter Web
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)

@app.before_request
def log_request_info():
    print(f"\n[REQUEST] {datetime.now().strftime('%H:%M:%S')} - {request.method} {request.url}")
    if request.is_json:
        print(f"    Payload: {request.get_json()}")

# ─── Groq Setup (NEW HIGH-SPEED AI) ───────────────────────────────────────────
GROQ_API_KEY = os.getenv('GROQ_API_KEY', '')
GROQ_TEXT_MODEL = "llama-3.3-70b-versatile"
GROQ_VISION_MODEL = "llama-3.2-11b-vision-preview"

def generate_with_groq(prompt, system_instruction="You are a helpful AI Assistant.", image_data=None):
    if not GROQ_API_KEY:
        return "AI Error: API Key missing."
    
    try:
        model = GROQ_VISION_MODEL if image_data else GROQ_TEXT_MODEL
        url = "https://api.groq.com/openai/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {GROQ_API_KEY}",
            "Content-Type": "application/json"
        }
        
        content_parts = [{"type": "text", "text": prompt}]
        if image_data:
            # image_data is expected as base64 string
            content_parts.append({
                "type": "image_url",
                "image_url": {"url": f"data:image/jpeg;base64,{image_data}"}
            })

        payload = {
            "model": model,
            "messages": [
                {"role": "system", "content": system_instruction},
                {"role": "user", "content": content_parts}
            ],
            "temperature": 0.5,
            "max_tokens": 2048
        }
        
        response = requests.post(url, headers=headers, json=payload, timeout=25)
        response.raise_for_status()
        return response.json()['choices'][0]['message']['content']
    except Exception as e:
        print(f"❌ Groq Error: {e}")
        return f"AI Error: {str(e)}"

if GROQ_API_KEY:
    print(f"✅ Groq configured with key: {GROQ_API_KEY[:8]}...")
else:
    print("❌ ERROR: GROQ_API_KEY not found in environment!")

# ─── Simple in-memory rate limiter ────────────────────────────────────────────
_rate_store = defaultdict(list)
RATE_LIMIT = 500  # requests per day per student

def check_rate_limit(student_id: str) -> bool:
    now = time.time()
    hour_ago = now - 3600
    _rate_store[student_id] = [t for t in _rate_store[student_id]
                                 if t > hour_ago]
    if len(_rate_store[student_id]) >= RATE_LIMIT:
        return False
    _rate_store[student_id].append(now)
    return True

# ─── Health check + Gemini Test ─────────────────────────────────────────────
@app.route('/health', methods=['GET'])
def health():
    ai_status = 'ok' if GROQ_API_KEY else 'missing_key'
    return jsonify({
        'status': 'ok',
        'ai_status': ai_status,
        'engine': 'groq-llama3',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/test-ai', methods=['GET'])
def test_ai():
    print("\n[TEST] Manual Groq connection test...")
    try:
        response_text = generate_with_groq("Say 'Groq AI is working!'")
        print(f"    [AI Response] {response_text}")
        return jsonify({'status': 'linked', 'ai_response': response_text, 'model': GROQ_MODEL})
    except Exception as e:
        print(f"    [AI Error] {str(e)}")
        return jsonify({'status': 'error', 'message': str(e)}), 500

# ─── Grade Prediction (ML) ────────────────────────────────────────────────────
@app.route('/predict', methods=['POST'])
def predict_grade():
    data = request.get_json(silent=True) or {}
    try:
        attendance = float(data.get('attendance_pct', 75))
        avg_score = float(data.get('avg_score', 65))
        submissions = float(data.get('submissions_pct', 80))
        quiz_avg = float(data.get('quiz_avg', 60))
    except (ValueError, TypeError):
        return jsonify({'error': 'Invalid input data'}), 400

    perf = (attendance * 0.3 + avg_score * 0.35 + submissions * 0.2 + quiz_avg * 0.15)
    risk = 'low' if perf >= 75 else ('medium' if perf >= 55 else 'high')
    
    if perf >= 90: grade = 'A+'
    elif perf >= 80: grade = 'A'
    elif perf >= 70: grade = 'B'
    elif perf >= 60: grade = 'C'
    elif perf >= 50: grade = 'D'
    else: grade = 'F'

    return jsonify({
        'risk_level': risk,
        'predicted_grade': grade,
        'performance_score': round(perf, 1),
    })

# ─── AI Smart Study Planner ──────────────────────────────────────────────────
@app.route('/generate-smart-schedule', methods=['POST'])
def generate_smart_schedule():
    data = request.get_json(silent=True) or {}
    subject_avg = data.get('subject_avg', {})
    avg_score = data.get('avg_score', 0)
    attendance = data.get('attendance', 0)
    
    # Logic: Identify weak subjects and prioritize them
    weak_subjects = [s for s, score in subject_avg.items() if score < 60]
    
    system_instruction = (
        "You are an AI Academic Strategist. Create a high-priority study schedule for a student. "
        "Focus on their weak subjects and balance with rest. Use Markdown tables for the schedule."
    )
    
    prompt = (
        f"Student stats: Avg Grade {avg_score}%, Attendance {attendance}%. "
        f"Weak areas: {', '.join(weak_subjects) if weak_subjects else 'None identified'}. "
        f"Provide a 7-day study roadmap focusing on improvement."
    )
    
    try:
        response_text = generate_with_groq(prompt, system_instruction=system_instruction)
        return jsonify({
            'schedule': response_text,
            'generated_by': 'groq-llama3'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ─── AI Homework Assistant ───────────────────────────────────────────────────
@app.route('/homework-help', methods=['POST'])
def homework_help():
    data = request.get_json(silent=True) or {}
    student_id = data.get('student_id', 'anon')
    question = data.get('question', '').strip()
    subject = data.get('subject', 'General')
    student_class = data.get('student_class', 8)
    show_hint_first = data.get('show_hint_first', False)
    image_data = data.get('image_data')  # Base64 string

    print(f"    [HELP] Question: {question[:50]}... | Subject: {subject} | Has Image: {image_data is not None}")

    if not question:
        return jsonify({'error': 'Question cannot be empty'}), 400

    if not check_rate_limit(student_id):
        return jsonify({'error': 'Rate limit reached'}), 429

    if not GROQ_API_KEY:
        return jsonify({'answer': _fallback_answer(question, subject), 'generated_by': 'fallback'})

    try:
        system_instruction = (
            f"You are a professional, encouraging, and highly structured AI Tutor for Class {student_class} students. "
            f"Currently helping with: **{subject}**. "
            "Your goal is to explain concepts clearly using Markdown for beautiful presentation.\n\n"
            "**Formatting Rules:**\n"
            "1. Use `### Header` for clear sections.\n"
            "2. Use `**Bold**` for key terms.\n"
            "3. Use bullet points (`-`) for steps.\n"
            "4. Include 1-2 relevant emojis (😊, 📚).\n"
            "5. **IMPORTANT**: Do NOT use dollar signs ($) for math. Use plain text or `**bold**` for equations (e.g., **x + y = 10**).\n"
            "6. If math is involved, type it clearly without symbols like LaTeX.\n\n"
            "7. **DO NOT** include generic greetings like 'Hello and Welcome' or standard introductions. Get straight to the explanation.\n\n"
            "If the student asks a question, guide them step-by-step."
        )

        response_text = generate_with_groq(
            f"Student Question: {question}", 
            system_instruction=system_instruction,
            image_data=image_data
        )
        print(f"    [AI Response] Success")
        return jsonify({
            'answer': response_text,
            'generated_by': 'groq-llama3'
        })
    except Exception as e:
        print(f"    [AI Error] {str(e)}")
        return jsonify({'answer': _fallback_answer(question, subject), 'error': str(e)})

def _fallback_answer(question, subject):
    return f"Connecting issues with AI tutor. Please check your textbook for {subject}."

# ─── Study Plan ─────────────────────────────────────────────────────────────
@app.route('/generate-study-plan', methods=['POST'])
def generate_study_plan():
    data = request.get_json(silent=True) or {}
    
    # Support both old and new formats
    student_name = data.get('student_name') or data.get('student_id', 'Student')
    weak_subjects = data.get('weak_subjects', [])
    exam_days = data.get('days_to_exam') or 30
    
    # New keys from parent dashboard
    upcoming_deadlines = data.get('upcoming_deadlines', [])
    study_hours = data.get('study_hours_per_day', 4)
    
    print(f"    [PLAN] Generating rescue plan for {student_name}")

    if not GROQ_API_KEY:
        return jsonify({'plan': 'AI Configuration missing on server.'})

    try:
        prompt = (
            f"Create a high-impact search study plan for {student_name}. "
            f"Focus on weak subjects: {', '.join(weak_subjects) if weak_subjects else 'General improvement'}. "
            f"The student can commit {study_hours} hours per day. "
            f"Upcoming deadlines: {upcoming_deadlines if upcoming_deadlines else 'None immediately'}. "
            f"Provide a structured, encouraging plan in Markdown."
        )
        response_text = generate_with_groq(prompt)
        return jsonify({'plan': response_text})
    except Exception as e:
        return jsonify({'plan': f"Error: {str(e)}"})

# ─── AI Question Paper Generator ───────────────────────────────────────────
@app.route('/generate-quiz', methods=['POST'])
def generate_quiz():
    data = request.get_json(silent=True) or {}
    topic = data.get('topic', 'General Knowledge')
    subject = data.get('subject', 'General')
    num_questions = data.get('count', 5)
    difficulty = data.get('difficulty', 'Medium')  # Easy, Medium, Hard
    q_type = data.get('type', 'MCQ')  # MCQ, Short Answer, True/False
    
    system_instruction = (
        "You are an expert Teacher. Generate a high-quality quiz in valid JSON format. "
        "The response MUST be ONLY a JSON list of objects with this structure: "
        '[{"text": "Sample Question", "options": ["A", "B", "C", "D"], "correctOption": 0, "marks": 1, "type": "mcq"}]'
        "\nFor 'Short Answer', include empty options and -1 for correctOption, set type to 'short'."
        "\nFor 'True/False', use ['True', 'False'] as options."
    )
    
    prompt = (
        f"Create {num_questions} {q_type} questions for Class 9/10 students. "
        f"Topic: {topic} | Subject: {subject} | Difficulty: {difficulty}. "
        f"Ensure the tone and complexity match the {difficulty} level."
    )
    
    try:
        response_text = generate_with_groq(prompt, system_instruction=system_instruction)
        # Strip potential markdown code blocks
        clean_json = response_text.replace('```json', '').replace('```', '').strip()
        return jsonify(json.loads(clean_json))
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ─── Auto Flashcard Generator (Swipe Study) ──────────────────────────────────
@app.route('/generate-flashcards', methods=['POST'])
def generate_flashcards():
    content = ""
    if request.is_json:
        data = request.get_json(silent=True) or {}
        content = data.get('content', '')
        file_url = data.get('file_url', '')
        
        if file_url:
            try:
                resp = requests.get(file_url)
                resp.raise_for_status()
                if 'pdf' in file_url.lower() or file_url.split('?')[0].endswith('.pdf') or 'application/pdf' in resp.headers.get('Content-Type', ''):
                    pdf_reader = PyPDF2.PdfReader(io.BytesIO(resp.content))
                    for page in pdf_reader.pages:
                        extracted = page.extract_text()
                        if extracted:
                            content += extracted + "\n"
                else:
                    content = resp.content.decode('utf-8', errors='ignore')
            except Exception as e:
                return jsonify({'error': f'Failed to fetch/parse from URL: {str(e)}'}), 400

    elif 'file' in request.files:
        file = request.files['file']
        if file.filename.lower().endswith('.pdf'):
            try:
                pdf_reader = PyPDF2.PdfReader(file)
                for page in pdf_reader.pages:
                    content += page.extract_text() + "\n"
            except Exception as e:
                return jsonify({'error': f'Failed to parse PDF: {str(e)}'}), 400
        else:
            content = file.read().decode('utf-8', errors='ignore')

    if not content.strip():
        return jsonify({'error': 'No content or file provided'}), 400

    system_instruction = (
        "You are an AI Study Assistant. Your task is to summarize the provided academic content "
        "into short, highly effective Flashcards (Question on Front, Answer on Back). "
        "Return the output STRICTLY as a JSON list of objects: [{'q': 'Short Question?', 'a': 'Short Answer'}]. "
        "Generate 5 to 10 flashcards maximum. Keep answers concise."
    )
    
    try:
        response_text = generate_with_groq(f"Content:\n{content}", system_instruction=system_instruction)
        clean_json = response_text.replace('```json', '').replace('```', '').strip()
        flashcards = json.loads(clean_json)
        return jsonify({'flashcards': flashcards})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ─── Auto Mind Map Generator (Hierarchical JSON) ───────────────────────────
@app.route('/generate-mindmap', methods=['POST'])
def generate_mindmap():
    content = ""
    if request.is_json:
        data = request.get_json(silent=True) or {}
        content = data.get('content', '')
        file_url = data.get('file_url', '')

        if file_url:
            try:
                resp = requests.get(file_url)
                resp.raise_for_status()
                if 'pdf' in file_url.lower() or file_url.split('?')[0].endswith('.pdf') or 'application/pdf' in resp.headers.get('Content-Type', ''):
                    pdf_reader = PyPDF2.PdfReader(io.BytesIO(resp.content))
                    for page in pdf_reader.pages:
                        extracted = page.extract_text()
                        if extracted:
                            content += extracted + "\n"
                else:
                    content = resp.content.decode('utf-8', errors='ignore')
            except Exception as e:
                return jsonify({'error': f'Failed to fetch/parse from URL: {str(e)}'}), 400

    elif 'file' in request.files:
        file = request.files['file']
        if file.filename.lower().endswith('.pdf'):
            try:
                pdf_reader = PyPDF2.PdfReader(file)
                for page in pdf_reader.pages:
                    content += page.extract_text() + "\n"
            except Exception as e:
                return jsonify({'error': f'Failed to parse PDF: {str(e)}'}), 400
        else:
            content = file.read().decode('utf-8', errors='ignore')

    if not content.strip():
        return jsonify({'error': 'No content or file provided'}), 400

    system_instruction = (
        "You are an AI Study Visualizer. Extract the core concepts from the given content and format it as a hierarchical JSON Mind Map. "
        "The output must EXACTLY follow this structure (max depth 3): "
        "{\"title\": \"Main Concept\", \"children\": [{\"title\": \"Subtopic 1\", \"children\": [{\"title\": \"Detail 1\"}]}]} "
        "Return ONLY the raw JSON string. Do not use Markdown formatting or code block wrappers like ```json"
    )
    
    try:
        response_text = generate_with_groq(f"Content:\n{content}", system_instruction=system_instruction)
        clean_json = response_text.replace('```json', '').replace('```', '').strip()
        mindmap_data = json.loads(clean_json)
        return jsonify({'mindmap': mindmap_data})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ─── Plagiarism & AI Detector ──────────────────────────────────────────────
@app.route('/check-originality', methods=['POST'])
def check_originality():
    data = request.get_json(silent=True) or {}
    content = data.get('content', '')
    
    if not content:
        return jsonify({'error': 'No content provided'}), 400

    system_instruction = (
        "You are an AI Forensic Analyst. Analyze the following student submission for two things: "
        "1. Probability that it was written by an AI (e.g., ChatGPT). "
        "2. General originality/plagiarism risk. "
        "Return a JSON object: {'ai_probability': 0.XX, 'originality_score': 0.XX, 'analysis': 'Concise explanation'}"
    )
    
    try:
        response_text = generate_with_groq(f"Content: {content}", system_instruction=system_instruction)
        clean_json = response_text.replace('```json', '').replace('```', '').strip()
        return jsonify(json.loads(clean_json))
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ─── Student Burnout & Mental Health Detector ──────────────────────────────
@app.route('/detect-burnout', methods=['POST'])
def detect_burnout():
    data = request.get_json(silent=True) or {}
    student_name = data.get('student_name', 'Student')
    study_hours = data.get('study_hours_per_day', 6)
    late_night_activity = data.get('late_night_active', True)
    drop_in_scores = data.get('grades_dropping', False)
    
    system_instruction = (
        "You are an empathetic AI School Counselor and Child Psychologist. "
        "Analyze the provided student data to determine if the child is experiencing academic burnout or mental stress. "
        "Return a JSON object ONLY with no markdown: {'risk_level': 'High' | 'Medium' | 'Low', 'message': 'Counselor advice for parent'}"
    )
    
    prompt = f"Student: {student_name}, Study Hours: {study_hours}/day, Active Late Night: {late_night_activity}, Grades Dropping: {drop_in_scores}."
    
    try:
        response_text = generate_with_groq(prompt, system_instruction=system_instruction)
        clean_json = response_text.replace('```json', '').replace('```', '').strip()
        return jsonify(json.loads(clean_json))
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ─── AI Voice Viva (Mock Examiner) ─────────────────────────────────────────
@app.route('/ai-viva', methods=['POST'])
def ai_viva():
    data = request.get_json(silent=True) or {}
    message = data.get('message', '')
    history = data.get('history', [])
    use_tts = data.get('use_tts', False)
    # Support both 'subject' and 'topic' from frontend
    subject = data.get('subject') or data.get('topic', 'General')
    
    print(f"    [VIVA] Conversation for {subject}")
    audio_b64 = data.get('audio_base64', '')
    
    system_instruction = (
        f"You are a strict but fair School Teacher conducting an oral viva on the topic: {subject}. "
        "The user will speak or type answers. Evaluate their answer briefly, then ask the NEXT question. "
        "Keep your reply strictly under 3 sentences. If they are wrong, explain in 1 sentence and ask an easier question."
    )
    
    formatted_prompt = f"{system_instruction}\n\n"
    for msg in history[-4:]:
        role = "Student: " if msg['role'] == 'user' else "Examiner: "
        formatted_prompt += f"{role}{msg['text']}\n"
    
    contents_to_generate = []
    
    if audio_b64:
        # User spoke audio
        audio_bytes = base64.b64decode(audio_b64)
        contents_to_generate.append({
            "mime_type": "audio/m4a", # Standard flutter recorder format
            "data": audio_bytes
        })
        formatted_prompt += f"\nStudent: [Sent Audio Answer]\nExaminer: "
    else:
        # Text based
        formatted_prompt += f"\nStudent: {message}\nExaminer: "
        
    contents_to_generate.append(formatted_prompt)
    
    try:
        response_text = generate_with_groq(
            formatted_prompt, 
            system_instruction=system_instruction,
            image_data=audio_b64 if audio_b64 else None # Groq doesn't support raw audio yet, but we'll try vision if it was an image-based question
        )
        reply_text = response_text.strip()
        
        resp_data = {'reply': reply_text}
        
        # If frontend wants spoken audio back
        if use_tts:
            tts = gTTS(text=reply_text, lang='en')
            fp = io.BytesIO()
            tts.write_to_fp(fp)
            fp.seek(0)
            audio_response_b64 = base64.b64encode(fp.read()).decode('utf-8')
            resp_data['reply_audio_base64'] = audio_response_b64
            
        return jsonify(resp_data)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ─── AI Parent Insights ────────────────────────────────────────────────────
@app.route('/parent-report', methods=['POST'])
def parent_report():
    data = request.get_json(silent=True) or {}
    student_name = data.get('name', 'Your child')
    stats = data.get('stats', {})
    
    system_instruction = (
        "You are a supportive and professional School Counselor. "
        "Write a concise, natural language progress report for a parent. "
        "Mention strengths and areas for improvement based on the data. "
        "Be encouraging but honest."
    )
    
    prompt = f"Student: {student_name}. Data: {stats}. Write a 100-word summary."
    
    try:
        response_text = generate_with_groq(prompt, system_instruction=system_instruction)
        return jsonify({'report': response_text})
    except Exception as e:
        return jsonify({'report': f"Report generation failed: {str(e)}"})

# ─── Unified Wellness (Optimization) ───────────────────────────────────────
@app.route('/get-unified-wellness', methods=['POST'])
def get_unified_wellness():
    data = request.get_json(silent=True) or {}
    student_name = data.get('name', 'Your child')
    stats = data.get('stats', {})
    
    system_instruction = (
        "You are an Elite AI School Counselor. Analyze the provided student data and provide TWO things in valid JSON format:\n"
        "1. 'report': A concise (100 word) empathetic progress report for the parent.\n"
        "2. 'burnout': A mental health risk assessment with keys 'risk_level' (High/Medium/Low) and 'message' (Counselor advice).\n"
        "Return ONLY raw JSON. No markdown."
    )
    
    prompt = f"Student: {student_name}. Stats Data: {stats}. Perform analysis."
    
    try:
        response_text = generate_with_groq(prompt, system_instruction=system_instruction)
        # Clean potential markdown
        clean_json = response_text.replace('```json', '').replace('```', '').strip()
        result = json.loads(clean_json)
        return jsonify(result)
    except Exception as e:
        print(f"    [UNIFIED AI ERROR] {str(e)}")
        # Return a safe fallback to prevent technical errors on screen
        return jsonify({
            'report': "AI insights are currently resting. Please check back in a few hours.",
            'burnout': {
                'risk_level': 'Low',
                'message': 'No immediate concerns detected (Offline Mode).'
            }
        })

# ─── Parent Chatbot ──────────────────────────────────────────────────────────
@app.route('/parent-chat', methods=['POST'])
def parent_chat():
    data = request.get_json(silent=True) or {}
    query = data.get('query', '')
    student_data = data.get('student_data', {})
    
    system_instruction = (
        "You are the EduTrack AI Campus Liaison. Answer parent questions about their child's performance. "
        f"You have access to this real-time data: {student_data}. "
        "Be helpful, reassuring, and data-driven."
    )
    
    try:
        response_text = generate_with_groq(f"Parent Question: {query}", system_instruction=system_instruction)
        return jsonify({'answer': response_text})
    except Exception as e:
        return jsonify({'answer': f"Connectivity issue: {str(e)}"})

# ─── AI Leave Document Analysis ───────────────────────────────────────────
@app.route('/analyze-leave-doc', methods=['POST'])
def analyze_leave_doc():
    data = request.get_json(silent=True) or {}
    image_data = data.get('image_data')  # Base64 string
    
    if not image_data:
        return jsonify({'error': 'No document image provided'}), 400

    system_instruction = (
        "You are an AI Registrar. Extract leave information from this document (medical certificate or note). "
        "Return ONLY a JSON object: {'start_date': 'YYYY-MM-DD', 'end_date': 'YYYY-MM-DD', 'reason': '...', 'type': 'medical'|'personal'} "
        "If dates are not found, use current date: " + datetime.now().strftime('%Y-%m-%d')
    )
    
    try:
        response_text = generate_with_groq(
            "Extract leave information from this document image.", 
            system_instruction=system_instruction,
            image_data=image_data
        )
        clean_json = response_text.replace('```json', '').replace('```', '').strip()
        return jsonify(json.loads(clean_json))
    except Exception as e:
        print(f"    [LEAVE AI ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500

# ─────────────────────────────────────────────────────────────────────────────
# AI LESSON PLAN GENERATOR
# ─────────────────────────────────────────────────────────────────────────────
@app.route('/generate-lesson-plan', methods=['POST', 'OPTIONS'])
def generate_lesson_plan():
    if request.method == 'OPTIONS':
        return '', 204
    try:
        data = request.get_json()
        subject  = data.get('subject', 'Mathematics')
        topic    = data.get('topic', 'Unknown Topic')
        duration = data.get('duration', '45 minutes')
        grade    = data.get('grade', 'Grade 8')

        prompt = f"""You are an expert school teacher. Create a detailed, professional lesson plan for:
Subject: {subject}
Topic: {topic}
Grade: {grade}
Class Duration: {duration}

Include these sections:
1. 🎯 Learning Objectives (3-4 points)
2. ⏱️ Lesson Structure with time breakdown
3. 📋 Teaching Methods & Activities
4. 📚 Resources Needed
5. ✅ Assessment Strategy
6. 📝 Homework/Follow-up

Format clearly with emojis for each section. Keep it practical and engaging."""

        response_text = generate_with_groq(prompt)
        return jsonify({'plan': response_text, 'subject': subject, 'topic': topic})
    except Exception as e:
        print(f"    [LESSON PLAN ERROR] {str(e)}")
        # Return offline template
        fallback = f"""📚 LESSON PLAN
Subject: {subject} | Topic: {topic} | Grade: {grade} | Duration: {duration}

🎯 LEARNING OBJECTIVES
1. Understand the core concept of {topic}
2. Apply the concept in practical scenarios
3. Demonstrate understanding through examples

⏱️ LESSON STRUCTURE
• Introduction (5 min): Review previous lesson
• Concept Explanation (15 min): Detailed explanation with examples  
• Guided Practice (10 min): Solve problems together
• Independent Practice (10 min): Student worksheet
• Summary & Q&A (5 min): Key takeaways

📋 TEACHING METHODS
• Direct instruction with visual aids
• Collaborative problem-solving
• Think-pair-share activities

📚 RESOURCES NEEDED
• Whiteboard/Smartboard
• Textbook (relevant chapter)
• Practice worksheet
• Visual aids/diagrams

✅ ASSESSMENT
• Quick oral quiz at end of lesson
• Homework assignment for reinforcement

📝 HOMEWORK
• 5-10 practice problems from today's topic
• Read next chapter introduction"""
        return jsonify({'plan': fallback, 'subject': subject, 'topic': topic})

# ─────────────────────────────────────────────────────────────────────────────
# AI MONTHLY REPORT GENERATOR FOR PARENTS
# ─────────────────────────────────────────────────────────────────────────────
@app.route('/generate-monthly-report', methods=['POST', 'OPTIONS'])
def generate_monthly_report():
    if request.method == 'OPTIONS':
        return '', 204
    try:
        data = request.get_json()
        student_name = data.get('studentName', 'the student')
        attendance   = data.get('attendance', '85%')
        avg_score    = data.get('avgScore', '75%')
        behavior     = data.get('behavior', 'Good')
        month        = data.get('month', datetime.now().strftime('%B %Y'))

        prompt = f"""You are an empathetic, professional school principal. Write a concise, encouraging 1-page monthly progress report for the parents of {student_name} for the month of {month}.
        
Data:
- Attendance: {attendance}
- Average Academic Score: {avg_score}
- General Behavior/Engagement: {behavior}

Format clearly:
1. 🌟 Academic Performance Summary
2. 📅 Attendance & Consistency
3. 💡 Strengths & Areas to Improve
4. 👨‍👩‍👦 Suggestions for Parents

Keep it warm, professional, and visually appealing with emojis. Do not output markdown codeblocks around the text."""

        response_text = generate_with_groq(prompt)
        return jsonify({'report': response_text, 'student': student_name, 'month': month})
    except Exception as e:
        print(f"    [MONTHLY REPORT ERROR] {str(e)}")
        fallback = f"""📄 MONTHLY PROGRESS REPORT: {student_name} ({month})

🌟 ACADEMIC PERFORMANCE
Average Score: {avg_score}
{student_name} has shown steady academic progress this month.

📅 ATTENDANCE & CONSISTENCY
Attendance: {attendance}
Regular attendance is key to success.

💡 STRENGTHS & AREAS TO IMPROVE
Behavior: {behavior}
Strengths: Active participation.
Areas to improve: Consistent revision at home.

👨‍👩‍👦 SUGGESTIONS FOR PARENTS
Please review homework daily and encourage reading reading habits. Feel free to contact teachers for specific queries.
"""
        return jsonify({'report': fallback, 'student': student_name, 'month': month})

# ─── AI Best Answer Generator (Doubt Box) ────────────────────────────────────
@app.route('/generate-best-answer', methods=['POST'])
def generate_best_answer():
    data = request.get_json(silent=True) or {}
    question = data.get('question', '').strip()
    subject = data.get('subject', 'General')
    grade = data.get('grade', 'Grade 10')
    
    print(f"    [BEST-ANSWER] Generating for {grade} | Subject: {subject}")
    
    if not question:
        return jsonify({'error': 'Question is required'}), 400

    system_instruction = (
        f"You are an Elite Academic Specialist and Expert Teacher for {grade} level. "
        f"Your task is to provide the 'BEST ANSWER' for the following {subject} question. "
        "A 'Best Answer' must be:\n"
        "1. **Highly Structured**: Use sections like 'Core Concept', 'Explanation', 'Real-world Example'.\n"
        "2. **Premium Tone**: Encouraging, professional, and very clear.\n"
        "3. **Visual**: Use Markdown tables, bold text, and lists (no LaTeX/dollar signs).\n"
        "4. **Concise but Deep**: Don't just give a 1-liner. Give a thorough explanation in 200-300 words."
    )
    
    try:
        response_text = generate_with_groq(f"Question: {question}", system_instruction=system_instruction)
        return jsonify({
            'answer': response_text.strip(),
            'model': 'groq-llama3-high-intent'
        })
    except Exception as e:
        print(f"    [BEST-ANSWER ERROR] {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    print(f"🚀 EduTrack AI Backend listening on 0.0.0.0:{port}")
    app.run(host='0.0.0.0', port=port, debug=False)
