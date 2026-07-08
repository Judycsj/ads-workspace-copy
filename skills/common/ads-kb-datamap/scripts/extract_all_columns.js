// Extract ALL column metadata across all pagination pages in one call.
// Run via browser_run_code (Playwright context, NOT browser_evaluate).
// Returns JSON string: { total, totalPages, columns: [...] }

async (page) => {
  const allData = [];

  // Get total count from pagination text
  const totalText = await page.locator('.ant-pagination-total-text').textContent();
  const totalMatch = totalText.match(/(\d+)/);
  const total = totalMatch ? parseInt(totalMatch[1]) : 0;
  const totalPages = Math.ceil(total / 50);

  for (let pageNum = 1; pageNum <= totalPages; pageNum++) {
    if (pageNum > 1) {
      // Click specific page number (not .ant-pagination-next which is unreliable)
      await page.locator(`.ant-pagination-item[title="${pageNum}"]`).click();
      await page.waitForTimeout(2500);
    }

    const pageData = await page.evaluate(() => {
      const data = [];
      const rows = document.querySelectorAll('.ant-table-body table .ant-table-row');
      rows.forEach(row => {
        const cells = row.querySelectorAll('td');
        if (cells.length < 7) return;
        const name = cells[1]?.textContent?.trim();
        if (!name) return;
        data.push({
          name,
          type: cells[2]?.textContent?.trim() || '',
          desc: cells[3]?.textContent?.trim() || '',
          query: cells[7]?.textContent?.trim() || cells[6]?.textContent?.trim() || ''
        });
      });
      return data;
    });

    allData.push(...pageData);
  }

  return JSON.stringify({ total, totalPages, columns: allData });
}
