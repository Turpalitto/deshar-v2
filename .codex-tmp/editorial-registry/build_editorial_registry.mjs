import fs from "node:fs/promises";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const csvPath = "C:/dev/deshar-v2/editorial/content_review.csv";
const outputDir = "C:/АББА/.codex-tmp/editorial-registry/outputs";

const csvText = await fs.readFile(csvPath, "utf8");
const workbook = await Workbook.fromCSV(csvText, { sheetName: "Контент" });
const content = workbook.worksheets.getItem("Контент");
const instructions = workbook.worksheets.add("Инструкция");
const summary = workbook.worksheets.add("Сводка");

content.showGridLines = false;
content.freezePanes.freezeRows(1);
content.freezePanes.freezeColumns(3);
content.getRange("A1:P120").format.font = { name: "Arial", size: 10, color: "#26201A" };
content.getRange("A1:P1").format = {
  fill: "#1B6B4A",
  font: { name: "Arial", size: 10, bold: true, color: "#FFFFFF" },
  rowHeight: 30,
  verticalAlignment: "center",
  wrapText: true,
  borders: { preset: "outside", style: "thin", color: "#155239" },
};
content.getRange("A2:P120").format.borders = {
  insideHorizontal: { style: "thin", color: "#E9E2D6" },
};
content.getRange("A2:P120").format.verticalAlignment = "top";
content.getRange("D2:J120").format.wrapText = true;
content.getRange("O2:O120").format.wrapText = true;
content.getRange("K2:K500").dataValidation = {
  rule: {
    type: "list",
    values: ["draft", "in_review", "changes_requested", "approved", "rejected"],
  },
};
content.getRange("K2:K120").conditionalFormats.add("containsText", {
  text: "approved",
  format: { fill: "#D4F0E0", font: { color: "#155239", bold: true } },
});
content.getRange("K2:K120").conditionalFormats.add("containsText", {
  text: "changes_requested",
  format: { fill: "#FFF4D4", font: { color: "#7A5312", bold: true } },
});
content.getRange("K2:K120").conditionalFormats.add("containsText", {
  text: "rejected",
  format: { fill: "#FBE2E2", font: { color: "#9A2D2D", bold: true } },
});

const widths = {
  A: 31, B: 18, C: 14, D: 25, E: 28, F: 22, G: 28, H: 48,
  I: 16, J: 36, K: 20, L: 20, M: 20, N: 15, O: 42, P: 20,
};
for (const [column, width] of Object.entries(widths)) {
  content.getRange(`${column}:${column}`).format.columnWidth = width;
}
content.getRange("A2:C120").format.fill = "#F7F4EF";
content.getRange("P2:P120").format.fill = "#F0EBE2";

instructions.showGridLines = false;
instructions.getRange("A1:H1").merge();
instructions.getRange("A1").values = [["Нохчийн · редакторская проверка контента"]];
instructions.getRange("A1:H1").format = {
  fill: "#1E1510",
  font: { name: "Arial", size: 18, bold: true, color: "#F3EDE4" },
  rowHeight: 42,
  verticalAlignment: "center",
};
instructions.getRange("A3:B10").values = [
  ["Порядок", "draft → in_review → changes_requested → approved"],
  ["Правило 1", "Каждую строку проверяют два разных носителя языка."],
  ["Правило 2", "Для approved обязательны source_reference и reviewed_at (YYYY-MM-DD)."],
  ["Правило 3", "Не редактируйте content_id, content_type, unit_id и content_hash."],
  ["Правило 4", "Не утверждайте машинный перевод без контекста и источника."],
  ["Импорт", "Скачать как CSV → python tools/editorial_review.py import-approved"],
  ["Проверка", "python tools/editorial_review.py check"],
  ["Перед релизом", "python tools/editorial_review.py check-strict"],
];
instructions.getRange("A3:A10").format = {
  fill: "#D4F0E0",
  font: { bold: true, color: "#155239" },
  verticalAlignment: "top",
};
instructions.getRange("B3:B10").format = { wrapText: true, verticalAlignment: "top" };
instructions.getRange("A3:B10").format.borders = {
  insideHorizontal: { style: "thin", color: "#E9E2D6" },
  outside: { style: "thin", color: "#D7CEC0" },
};
instructions.getRange("A:A").format.columnWidth = 22;
instructions.getRange("B:B").format.columnWidth = 78;
instructions.getRange("A3:B10").format.rowHeight = 32;

summary.showGridLines = false;
summary.getRange("A1:D1").merge();
summary.getRange("A1").values = [["Состояние редакторской проверки"]];
summary.getRange("A1:D1").format = {
  fill: "#1B6B4A",
  font: { size: 16, bold: true, color: "#FFFFFF" },
  rowHeight: 38,
};
summary.getRange("A3:B8").values = [
  ["Статус", "Количество"],
  ["draft", null],
  ["in_review", null],
  ["changes_requested", null],
  ["approved", null],
  ["rejected", null],
];
summary.getRange("B4").formulas = [["=COUNTIF('Контент'!$K$2:$K$120,A4)"]];
summary.getRange("B4:B8").fillDown();
summary.getRange("A3:B3").format = {
  fill: "#1E1510",
  font: { bold: true, color: "#FFFFFF" },
};
summary.getRange("A4:B8").format.borders = {
  insideHorizontal: { style: "thin", color: "#E9E2D6" },
};
summary.getRange("A:A").format.columnWidth = 25;
summary.getRange("B:B").format.columnWidth = 16;
summary.getRange("B4:B8").format.numberFormat = "#,##0";

const inspect = await workbook.inspect({
  kind: "table",
  sheetId: "Сводка",
  range: "A1:B8",
  include: "values,formulas",
  tableMaxRows: 10,
  tableMaxCols: 4,
});
console.log(inspect.ndjson);
const errors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 100 },
  summary: "formula error scan",
});
console.log(errors.ndjson);

await fs.mkdir(outputDir, { recursive: true });
for (const [sheetName, fileName] of [
  ["Контент", "content.png"],
  ["Инструкция", "instructions.png"],
  ["Сводка", "summary.png"],
]) {
  const preview = await workbook.render({ sheetName, autoCrop: "all", scale: 1, format: "png" });
  await fs.writeFile(`${outputDir}/${fileName}`, new Uint8Array(await preview.arrayBuffer()));
}
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(`${outputDir}/Nokhchiin-content-review.xlsx`);
