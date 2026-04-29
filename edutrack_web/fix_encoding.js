const fs = require('fs');

// Read the file as a buffer, then decode as latin1 to preserve byte values
let code = fs.readFileSync('src/App.jsx', 'utf8');

// Replace specific corrupted sequences (UTF-8 bytes read as latin1)
const replacements = [
  // • bullet point (E2 80 A2)
  ['â€¢', '•'],
  // — em dash (E2 80 94)
  ['â€"', '—'],
  // ' right single quote (E2 80 99)
  ["â€™", "'"],
  // " left double quote (E2 80 9C)
  ['â€œ', '"'],
  // " right double quote (E2 80 9D)
  ['â€\x9d', '"'],
  // → right arrow (E2 86 92)
  ['â†'', '→'],
  // ✓ check mark (E2 9C 93)
  ['â€\x93', '✓'],
  // ✕ cross mark
  ['â€•', '✕'],
  // ● circle
  ['â€¢', '●'],
];

let content = code;
let count = 0;

replacements.forEach(([bad, good]) => {
  const regex = new RegExp(bad.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g');
  const before = content;
  content = content.replace(regex, good);
  if (content !== before) count++;
});

// Replace the broken emoji-as-text sequences with ASCII equivalents
// Pattern: emoji sequences that got garbled
const emojiReplacements = [
  // ✓ All Present button
  [/â‹ All Present/g, '✓ All Present'],
  [/â‹™ All Absent/g, '✗ All Absent'],
  // students • markedCount  
  [/students â€¢/g, 'students •'],
  [/â€¢ ${markedCount}/g, '• ${markedCount}'],
  // em dash in strings
  [/ â€" /g, ' — '],
  // arrows
  [/â†'/g, '→'],
  [/Sync to Mobile/g, 'Sync to Mobile'],
];

emojiReplacements.forEach(([bad, good]) => {
  content = content.replace(bad, good);
});

// Nuclear option: replace ALL problematic sequences using Buffer
// Re-read as latin1 bytes and handle multi-byte sequences
const bufContent = Buffer.from(content, 'utf8');
const finalContent = bufContent.toString('utf8');

fs.writeFileSync('src/App.jsx', content, 'utf8');
console.log('Done. Replacements made:', count);
console.log('File size:', content.length, 'chars');
