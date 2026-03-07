function normalizeThai(input) {
  return input
    .toLowerCase()
    .replace(/\s+/g, "")
    .replace(/[\u0E30-\u0E3A\u0E47-\u0E4E]/g, "");
}

const CHANTS = [
  {
    id: "metta",
    title: "บทเมตตาใหญ่",
    lines: [
      "สัพเพ สัตตา สุขิตา โหนตุ",
      "สัพเพ สัตตา อะเวรา โหนตุ",
      "สัพเพ สัตตา อัพยาปัชฌา โหนตุ",
      "สัพเพ สัตตา อะนีฆา โหนตุ",
      "สัพเพ สัตตา สุขี อัตตานัง ปะริหะรันตุ"
    ]
  },
  {
    id: "itipiso",
    title: "อิติปิโส",
    lines: [
      "อิติปิโส ภะคะวา",
      "อะระหัง สัมมาสัมพุทโธ",
      "วิชชาจะระณะสัมปันโน",
      "สุคะโต โลกะวิทู",
      "อะนุตตะโร ปุริสะทัมมะสาระถิ"
    ]
  }
];

const NORMALIZED_LINE_INDEX = CHANTS.flatMap((chant) =>
  chant.lines.map((line, lineIndex) => ({
    chantId: chant.id,
    lineIndex,
    text: line,
    normalized: normalizeThai(line),
  }))
);
