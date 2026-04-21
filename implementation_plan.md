# Implementation Plan: Brain DNA (Dynamic Knowledge Map)

This feature introduces a revolutionary way to monitor and visualize student progress using a dynamic, biological-inspired "Knowledge Tree" (Brain DNA). It transitions the app from a simple dashboard to a "Learning Operating System".

## User Review Required

> [!IMPORTANT]
> - **Data Storage**: We will create a new collection `brain_dna` per student to track sub-topic mastery.
> - **UI Experience**: This will use advanced `CustomPainter` and animations, creating a premium "high-tech" look (Glowing Orbs, Orbital Paths).
> - **Integration**: We will hook into existing Quiz and Note services to update the DNA in real-time.

## Proposed Changes

### 1. Data Models [NEW]
#### [NEW] [knowledge_node.dart](file:///c:/ORIENTAL%20HACKTHON/edutrack_ai/lib/models/knowledge_node.dart)
- `KnowledgeNode`: Stores `id`, `name`, `subject`, `masteryScore` (0.0 - 1.0), `forgettingFactor` (auto-decrementing), and `lastActivity`.

### 2. Monitoring Service [NEW]
#### [NEW] [brain_dna_service.dart](file:///c:/ORIENTAL%20HACKTHON/edutrack_ai/lib/services/brain_dna_service.dart)
- Logic to calculate mastery based on Quiz results.
- Logic to handle "Memory Decay" (nodes fade if not visited).
- Hook into `QuizService` and `predict_api.py`.

### 3. Visualizer Component [NEW] 🎨
#### [NEW] [brain_dna_visualizer.dart](file:///c:/ORIENTAL%20HACKTHON/edutrack_ai/lib/widgets/brain_dna_visualizer.dart)
- A `CustomPainter` based widget that draws an orbital system of knowledge.
- **Mastery Colors**: Emerald Green (Master), Amber (Learning), Ruby (Struggling).
- **Pulse Effect**: AI-recommended topics will pulse subtly.

### 4. Dashboards [MODIFY]
#### [MODIFY] [student_dashboard.dart](file:///c:/ORIENTAL%20HACKTHON/edutrack_ai/lib/screens/dashboards/student_dashboard.dart)
- Add "Your Brain DNA" preview section.
- New navigation to "Knowledge Explorer" screen.

#### [MODIFY] [teacher_dashboard.dart](file:///c:/ORIENTAL%20HACKTHON/edutrack_ai/lib/screens/dashboards/teacher_dashboard.dart)
- Add "Class DNA Heatmap" to show collective strengths/weaknesses.

## Open Questions

- **Topic List**: Do we want a predefined list of topics (Algebra, Physics, etc.) or should the AI dynamically generate new nodes based on teacher's content? (I recommend a mix: dynamic topics for flexibility).
- **Interactivity**: Should clicking a node open the relevant notes/quizzes directly? (I recommend Yes).

## Verification Plan

### Automated Tests
- Unit tests for `masteryScore` calculation (e.g., 2 correct answers = +10% mastery).
- Forgetting curve validation (Score should decrease over simulated time).

### Manual Verification
- Take a Quiz -> Check if the relevant Brain DNA node changes color.
- Wait (simulated) -> Check if the node "fades" (Memory Decay).
- Open Teacher Dashboard -> Verify "Class Heatmap" reflects student data.
