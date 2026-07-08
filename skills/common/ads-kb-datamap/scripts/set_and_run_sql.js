// Set SQL in DataSuite Monaco editor and click Run.
// Run via browser_evaluate on DataSuite studio page.
// Before passing to browser_evaluate, replace __SQL_PLACEHOLDER__ with actual SQL.

() => {
  const sql = `__SQL_PLACEHOLDER__`;

  // Hide editor placeholder overlay
  const ph = document.querySelector('.editor-placeholder.visible');
  if (ph) ph.style.display = 'none';

  // Set SQL in Monaco editor
  const editor = window.ShopeeCDNMonacoEditor?.editor?.getEditors()?.[0];
  if (!editor) return JSON.stringify({ error: 'Monaco editor not found' });
  editor.setValue(sql);

  // Click Run button
  const runBtn = document.querySelector('button[class*="run"]') ||
    Array.from(document.querySelectorAll('button')).find(b =>
      b.textContent.trim() === 'Run' || b.querySelector('[class*="play"]')
    );
  if (runBtn) {
    runBtn.click();
    return JSON.stringify({ status: 'running' });
  }

  return JSON.stringify({ error: 'Run button not found' });
}
