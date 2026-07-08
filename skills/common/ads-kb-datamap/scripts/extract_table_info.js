// Extract table-level metadata from DataMap Table Info page.
// Run via browser_evaluate on a DataMap Table Info tab.
// Returns JSON string with description, properties, and scores.

() => {
  const result = {
    description: '',
    technicalProperties: [],
    businessProperties: [],
    completeness: '',
    popularity: ''
  };

  // Extract description — multi-strategy approach for reliability.
  // The description card has class "ant-card description--*".
  // Inside it, label-value pairs use "ant-row label-text" containers,
  // with "label-key" for the label and its next sibling for the value.

  // Strategy 1: Find label-key "Description" inside the description card
  const descCard = document.querySelector('.ant-card[class*="description"]');
  if (descCard) {
    const labelKeys = descCard.querySelectorAll('[class*="label-key"]');
    for (const lk of labelKeys) {
      if (lk.textContent.trim().startsWith('Description')) {
        const valueSibling = lk.nextElementSibling;
        if (valueSibling) {
          result.description = valueSibling.textContent.trim();
          break;
        }
      }
    }
  }

  // Strategy 2: fallback — find any element whose text starts with "Description" (short text)
  if (!result.description) {
    const allEls = document.querySelectorAll('[class*="description"] *');
    for (const el of allEls) {
      const text = el.textContent?.trim();
      if (text && text.startsWith('Description') && text.length < 30) {
        const nextSibling = el.nextElementSibling;
        if (nextSibling) {
          result.description = nextSibling.textContent.trim();
          break;
        }
      }
    }
  }

  // Extract properties from all <table> elements
  // Typically: table[0] = Technical Properties, table[1] = Business Properties
  const tables = document.querySelectorAll('table');
  tables.forEach((t, idx) => {
    const rows = [];
    t.querySelectorAll('tr').forEach(r => {
      const th = r.querySelector('th');
      const td = r.querySelector('td');
      if (th && td) {
        // Handle nested th (e.g., SLA with icons/question-circle spans)
        let key = th.innerText.trim();
        if (!key) {
          // Fallback: use textContent which always returns text
          key = th.textContent.trim();
        }
        // Clean up: remove "question-circle" icon text artifacts
        key = key.replace(/question-circle/g, '').trim();

        const value = td.innerText.trim();
        if (key) {
          rows.push({ key, value });
        }
      }
    });
    if (idx === 0) {
      result.technicalProperties = rows;
    } else if (idx === 1) {
      result.businessProperties = rows;
    }
  });

  // Extract Completeness and Popularity scores from header badges
  const scoreEls = document.querySelectorAll('[class*="score"], [class*="Score"]');
  scoreEls.forEach(el => {
    const text = el.textContent.trim();
    const parentText = el.closest('[class*="item"], [class*="Item"]')?.textContent || '';
    if (parentText.includes('Completeness')) {
      result.completeness = text;
    } else if (parentText.includes('Popularity')) {
      result.popularity = text;
    }
  });

  // Fallback: try to find scores from snapshot-visible text
  if (!result.completeness || !result.popularity) {
    const allText = document.body.innerText;
    const compMatch = allText.match(/Completeness[\s\S]*?([\d.]+)/);
    const popMatch = allText.match(/Popularity[\s\S]*?([\d.]+)/);
    if (compMatch) result.completeness = compMatch[1];
    if (popMatch) result.popularity = popMatch[1];
  }

  return JSON.stringify(result);
}
