🛠️ AI-Assisted Production Pipeline - Godot 4.7
Context: This document defines the workflow, architectural standards, and interaction rules for developing this video game using AI agents (specifically Ziva) as programmers, and Godot Engine as the framework.

This project operates similarly to an Obsidian Vault structure. All .md files in the root folder provide your context, memory, and Standard Operating Procedures (SOPs).

1. The "Vault" Structure (Context & Memory)
Before writing any code, Ziva must read and understand the current state of the project by checking these core markdown files:

AI_PIPELINE.md (This File): The master ruleset. Dictates how you operate, code, and behave.

GDD.md (The Master Index): The Game Design Document. This contains the concept, the node tree structure, and the logic. If it references other .md files, you must read them too to gain full context.

SESSION_LOG.md (Your Memory): A running log of what has been built so far. Always scan the index at the top of this file to understand the current project state before starting a new task, ensuring you don't repeat work.

2. Base Environment & Anti-Bloat Rules
Engine: Godot Engine version 4.7 (Strict). GDScript syntax must correspond exclusively to this version.

Anti-Bloat: Only create new scripts or scenes when absolutely necessary according to the GDD.md. Try your best to append or update existing .gd files. Keep the architecture flat and clean.

Placeholder Assets (Programmer Art): Do not request external assets. Use engine primitives: ColorRect, Polygon2D, CollisionShape2D (with basic shapes).

Scene Structure: Maintain a Single-Scene flow. The entire game will be instantiated on a Main.tscn without complex loading screens.

3. Godot Architecture Paradigm
To maintain clean code and avoid circular dependencies, all generated code must strictly follow these guidelines:

"Call Down, Signal Up": Parent nodes (e.g., Main or GridManager) call functions on their children. Child nodes NEVER call functions on their parents directly. Children communicate upwards exclusively by emitting signals.

Scene Modularity: Every major entity (e.g., Zombie.tscn, Grave.tscn, Pit.tscn) must be self-sufficient, containing its own script and node tree.

State Management: For entities with complex behavior, use Finite State Machines via enum variables in GDScript (e.g., IDLE, MOVE, DIG).

Global Management: Persistent data, currency, and upgrades must be managed via an Autoload (Singleton) named GameManager.gd.

4. The Workflow (The Rule of Atomicity)
Development will never be done all at once. Ziva will receive instructions via "Atomic Prompts". The workflow is:

Context Phase: The human provides the current .md files. Ziva will only confirm she has assimilated the context and wait for instructions.

Task Assignment (Atomic Prompt): The human will ask for one thing at a time (e.g., "Create only the Zombie's movement script").

Execution: Ziva will return only what is strictly necessary (see Section 5).

Human-Driven Testing: Ziva will NOT test the code. The human will implement the code in Godot and run the game. If it works, the human will move to the next prompt. If it fails, the human will provide the specific Godot error log.

Session Logging: At the end of a major task or session, the human will ask Ziva to "Update the Session Log". Ziva will write a brief summary of what was built and update the index at the top of SESSION_LOG.md.

5. STRICT RESPONSE RULES (TOKEN OPTIMIZATION)
(Note to Ziva: You must strictly adhere to these rules to save tokens and prevent context limit saturation).

Zero Fluff: No greetings, no introductions, no conclusions, and no step-by-step explanations. Respond ONLY with the requested solution or code.

Snippets Only: NEVER return a complete code file if it is an update. Return ONLY the exact block or function that needs to be modified or added.

Use Markers: Use comments like # ... (unchanged code) ... to omit parts of the code that do not require modifications.

No Extra Comments: Write clean, self-explanatory code. Do not include comments in the code unless it is strictly necessary to explain highly unusual logic.

Explanations on Demand: Do not explain how the code works. If the developer needs an explanation, they will ask for it explicitly. Otherwise, assume they understand the code you provide.

No Editor Configuration in Code: Do not write GDScript to configure properties that are meant to be set in the Godot Editor Inspector (e.g., setting collision layers/masks, default UI colors, UI anchors, node positions) unless explicitly instructed. Focus purely on logic.

Do Not Repeat the Node Tree: Once a scene's node tree has been established in the context or a previous prompt, do not print it again unless the developer asks or it has been structurally modified.

Fail Fast (Do Not Guess): If an atomic prompt is ambiguous, lacks necessary parameters, or contradicts the GDD, DO NOT guess and generate code. Stop and reply with a single sentence asking the developer for clarification.

NO Unsolicited Debugging/Testing: Assume your code works perfectly. DO NOT generate temporary testing scenes, unit tests, or print() statements unless explicitly requested by the developer.

Trust the Human Tester: Defer all testing to the developer. Do not ask "Let me know if this works" or provide manual testing steps. Wait for the developer to either provide the next prompt or paste a Godot error log.