const puppeteer = require('puppeteer-core');

(async () => {
  try {
    const browser = await puppeteer.launch({
      executablePath: '/usr/bin/google-chrome',
      headless: 'new',
      args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu']
    });
    const page = await browser.newPage();
    await page.setViewport({ width: 1440, height: 950 });

    page.on('console', msg => console.log('[ADMIN CONSOLE]', msg.type(), msg.text()));
    page.on('pageerror', err => console.log('[ADMIN PAGE ERROR]', err.message));
    page.on('requestfailed', req => console.log('[ADMIN REQ FAILED]', req.url(), req.failure()?.errorText));

    console.log('Navigating to http://localhost/emptracker/admin/ ...');
    await page.goto('http://localhost/emptracker/admin/', { waitUntil: 'domcontentloaded' });
    await new Promise(r => setTimeout(r, 4000));

    await page.screenshot({ path: '/var/www/html/emptracker/admin_login_screen.png' });
    console.log('Saved admin_login_screen.png');

    // Find and click login button
    console.log('Clicking login...');
    // Flutter web rendered canvas/elements
    // In Flutter web with html/canvaskit renderer, let's trigger autologin or click
    await page.goto('http://localhost/emptracker/admin/?autologin=1', { waitUntil: 'domcontentloaded' });
    await new Promise(r => setTimeout(r, 6000));

    await page.screenshot({ path: '/var/www/html/emptracker/admin_after_login.png' });
    console.log('Saved admin_after_login.png');

    await browser.close();
  } catch (err) {
    console.error('Test error:', err);
    process.exit(1);
  }
})();
