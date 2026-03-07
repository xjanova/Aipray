const state = {
  listening: false,
  currentChantId: null,
  currentLine: null,
  autoScroll: true,
  simulationTimer: null,
  recognition: null,
};

const nodes = {
  chantContainer: document.getElementById("chantContainer"),
  toggleListenBtn: document.getElementById("toggleListenBtn"),
  simulateBtn: document.getElementById("simulateBtn"),
  autoScrollToggle: document.getElementById("autoScrollToggle"),
  statusText: document.getElementById("statusText"),
  chantName: document.getElementById("chantName"),
  lineIndex: document.getElementById("lineIndex"),
  liveText: document.getElementById("liveText"),
};

function renderChants() {
  nodes.chantContainer.innerHTML = CHANTS.map((chant) => `
    <article class="chant" id="chant-${chant.id}">
      <h2>${chant.title}</h2>
      ${chant.lines
        .map(
          (line, idx) =>
            `<div class="line" data-chant-id="${chant.id}" data-line-index="${idx}">${idx + 1}. ${line}</div>`
        )
        .join("")}
    </article>
  `).join("");
}

function updateStatus({ statusText, chantName, lineIndex, liveText }) {
  if (statusText) nodes.statusText.textContent = statusText;
  if (chantName !== undefined) nodes.chantName.textContent = chantName;
  if (lineIndex !== undefined) nodes.lineIndex.textContent = lineIndex;
  if (liveText !== undefined) nodes.liveText.textContent = liveText;
}

function clearHighlight() {
  document.querySelectorAll(".line.active, .line.next").forEach((line) => {
    line.classList.remove("active", "next");
  });
}

function setCurrentLine(chantId, lineIndex) {
  state.currentChantId = chantId;
  state.currentLine = lineIndex;

  document.querySelectorAll(".chant").forEach((el) => {
    el.classList.toggle("hidden", el.id !== `chant-${chantId}`);
  });

  clearHighlight();

  const activeLine = document.querySelector(
    `.line[data-chant-id="${chantId}"][data-line-index="${lineIndex}"]`
  );
  if (!activeLine) return;

  activeLine.classList.add("active");
  const nextLine = document.querySelector(
    `.line[data-chant-id="${chantId}"][data-line-index="${lineIndex + 1}"]`
  );
  if (nextLine) nextLine.classList.add("next");

  updateStatus({
    chantName: CHANTS.find((chant) => chant.id === chantId)?.title || "-",
    lineIndex: `${lineIndex + 1}`,
  });

  if (state.autoScroll) {
    activeLine.scrollIntoView({ behavior: "smooth", block: "center" });
  }
}

function findBestMatch(recognizedText) {
  const norm = normalizeThai(recognizedText);
  if (!norm) return null;

  const exact = NORMALIZED_LINE_INDEX.find((item) => norm.includes(item.normalized));
  if (exact) return exact;

  let best = null;
  let bestScore = 0;

  for (const item of NORMALIZED_LINE_INDEX) {
    let score = 0;
    for (const ch of item.normalized) {
      if (norm.includes(ch)) score += 1;
    }
    const ratio = score / item.normalized.length;
    if (ratio > bestScore) {
      bestScore = ratio;
      best = item;
    }
  }

  return bestScore >= 0.55 ? best : null;
}

function processTranscript(transcript) {
  updateStatus({ liveText: transcript });
  const best = findBestMatch(transcript);

  if (!best) {
    updateStatus({ statusText: "กำลังจับตำแหน่ง..." });
    return;
  }

  setCurrentLine(best.chantId, best.lineIndex);
  updateStatus({ statusText: "จับบทและตำแหน่งได้แล้ว" });
}

function stopSimulation() {
  if (state.simulationTimer) {
    clearInterval(state.simulationTimer);
    state.simulationTimer = null;
  }
}

function runSimulation() {
  stopSimulation();
  let script = CHANTS[0].lines.map((line) => ({ chantId: CHANTS[0].id, line }));
  script = script.concat(CHANTS[1].lines.map((line) => ({ chantId: CHANTS[1].id, line })));
  let pointer = 0;

  updateStatus({ statusText: "โหมดจำลองกำลังทำงาน" });

  state.simulationTimer = setInterval(() => {
    if (pointer >= script.length) {
      stopSimulation();
      updateStatus({ statusText: "จำลองเสร็จแล้ว" });
      return;
    }

    const current = script[pointer];
    processTranscript(current.line);
    const lineIndex = CHANTS.find((chant) => chant.id === current.chantId).lines.indexOf(current.line);
    setCurrentLine(current.chantId, lineIndex);
    pointer += 1;
  }, 1800);
}

function setupSpeechRecognition() {
  const API = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!API) {
    updateStatus({ statusText: "เบราว์เซอร์ไม่รองรับ SpeechRecognition" });
    nodes.toggleListenBtn.disabled = true;
    return;
  }

  const recognition = new API();
  recognition.lang = "th-TH";
  recognition.interimResults = true;
  recognition.continuous = true;

  recognition.onresult = (event) => {
    let transcript = "";
    for (let i = event.resultIndex; i < event.results.length; i += 1) {
      transcript += event.results[i][0].transcript;
    }
    processTranscript(transcript);
  };

  recognition.onerror = () => {
    updateStatus({ statusText: "เกิดข้อผิดพลาดในการฟังเสียง" });
  };

  recognition.onend = () => {
    if (state.listening) {
      recognition.start();
    }
  };

  state.recognition = recognition;
}

function toggleListening() {
  if (!state.recognition) return;

  if (!state.listening) {
    state.listening = true;
    state.recognition.start();
    nodes.toggleListenBtn.textContent = "⏹️ หยุดฟัง";
    updateStatus({ statusText: "กำลังฟังเสียงสด" });
    return;
  }

  state.listening = false;
  state.recognition.stop();
  nodes.toggleListenBtn.textContent = "🎙️ เริ่มฟังสด";
  updateStatus({ statusText: "หยุดการฟังแล้ว" });
}

function init() {
  renderChants();
  setupSpeechRecognition();

  nodes.toggleListenBtn.addEventListener("click", toggleListening);
  nodes.simulateBtn.addEventListener("click", runSimulation);
  nodes.autoScrollToggle.addEventListener("change", (event) => {
    state.autoScroll = event.target.checked;
  });
}

init();
