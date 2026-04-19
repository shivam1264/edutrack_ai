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

load_dotenv()

app = Flask(__name__)

# Explicit CORS configuration for Flutter Web
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)

@app.before_request
def log_request_info():
    print(f"\n[REQUEST] {datetime.now().strftime('%H:%M:%S')} - {request.method} {request.url}")
    if request.is_json:
        print(f"    Payload: {request.get_json()}")

# ─── Gemini Setup (FREE API) ──────────────────────────────────────────────────
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY', '')
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    print(f"✅ Gemini configured with key: {GEMINI_API_KEY[:8]}...")
else:
    print("❌ ERROR: GEMINI_API_KEY not found in environment!")

gemini_model = None
if GEMINI_API_KEY:
    try:
        # Using gemini-flash-latest (sometimes more available than Pro in free tier)
        gemini_model = genai.GenerativeModel('gemini-flash-latest')
        print("✅ Gemini Model Linked: gemini-flash-latest")
    except Exception as e:
        print(f"❌ Error linking model: {e}")

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
    ai_status = 'ok' if gemini_model else 'missing_key'
    return jsonify({
        'status': 'ok',
        'ai_status': ai_status,
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/test-ai', methods=['GET'])
def test_ai():
    print("\n[TEST] Manual Gemini connection test...")
    if not gemini_model:
        return jsonify({'error': 'Gemini model not initialized'}), 500
    try:
        response = gemini_model.generate_content("Say 'AI is working!'")
        print(f"    [AI Response] {response.text}")
        return jsonify({'status': 'linked', 'ai_response': response.text})
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
        response = gemini_model.generate_content(f"{system_instruction}\n\n{prompt}")
        return jsonify({
            'schedule': response.text,
            'generated_by': 'gemini'
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

    if not gemini_model:
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

        content_payload = [f"{system_instruction}\n\nStudent Question: {question}"]
        
        if image_data:
            try:
                # Decode base64 to image
                img_bytes = base64.b64decode(image_data)
                img = Image.open(io.BytesIO(img_bytes))
                content_payload.append(img)
            except Exception as img_err:
                print(f"    [IMG ERROR] {img_err}")

        response = gemini_model.generate_content(content_payload)
        print(f"    [AI Response] Success")
        return jsonify({
            'answer': response.text,
            'generated_by': 'gemini'
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
    student_name = data.get('student_name', 'Student')
    weak_subjects = data.get('weak_subjects', [])
    exam_days = data.get('days_to_exam', 30)
    
    print(f"    [PLAN] Generating plan for {student_name}")

    if not gemini_model:
        return jsonify({'plan': 'Try again later for a personalized AI study plan.'})

    try:
        prompt = f"Create a {exam_days}-day study plan for {student_name}. focus: {weak_subjects}"
        response = gemini_model.generate_content(prompt)
        return jsonify({'plan': response.text})
    except Exception as e:
        return jsonify({'plan': f"Error: {str(e)}"})

# ─── AI Question Paper Generator ───────────────────────────────────────────
@app.route('/generate-quiz', methods=['POST'])
def generate_quiz():
    data = request.get_json(silent=True) or {}
    topic = data.get('topic', 'General Knowledge')
    subject = data.get('subject', 'General')
    num_questions = data.get('count', 5)
    
    system_instruction = (
        "You are an expert Teacher. Generate a high-quality quiz in valid JSON format. "
        "The response MUST be ONLY a JSON list of objects with this structure: "
        '[{"text": "Sample Question", "options": ["A", "B", "C", "D"], "correctOption": 0, "marks": 1}]'
    )
    
    prompt = f"Create {num_questions} MCQ questions for Class 9/10 students on topic: {topic} and subject: {subject}."
    
    try:
        response = gemini_model.generate_content(f"{system_instruction}\n\n{prompt}")
        # Strip potential markdown code blocks
        clean_json = response.text.replace('```json', '').replace('```', '').strip()
        return jsonify(json.loads(clean_json))
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
        response = gemini_model.generate_content(f"{system_instruction}\n\nContent: {content}")
        clean_json = response.text.replace('```json', '').replace('```', '').strip()
        return jsonify(json.loads(clean_json))
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
        response = gemini_model.generate_content(f"{system_instruction}\n\n{prompt}")
        return jsonify({'report': response.text})
    except Exception as e:
        return jsonify({'report': f"Report generation failed: {str(e)}"})

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
        response = gemini_model.generate_content(f"{system_instruction}\n\nParent Question: {query}")
        return jsonify({'answer': response.text})
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
        # Decode base64 to image
        img_bytes = base64.b64decode(image_data)
        img = Image.open(io.BytesIO(img_bytes))
        
        response = gemini_model.generate_content([system_instruction, img])
        clean_json = response.text.replace('```json', '').replace('```', '').strip()
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

        response = gemini_model.generate_content(prompt)
        return jsonify({'plan': response.text, 'subject': subject, 'topic': topic})
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

        response = gemini_model.generate_content(prompt)
        return jsonify({'report': response.text, 'student': student_name, 'month': month})
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

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    print(f"🚀 EduTrack AI Backend listening on 0.0.0.0:{port}")
    app.run(host='0.0.0.0', port=port, debug=False)
