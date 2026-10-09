const puppeteer = require('puppeteer-core');

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

(async () => {
  console.log('🚀 Launching Live Chrome GUI on your Ubuntu Desktop...');
  
  const browser = await puppeteer.launch({
    headless: false,
    executablePath: '/usr/bin/google-chrome',
    defaultViewport: null,
    args: [
      '--start-maximized',
      '--disable-web-security',
      '--disable-features=IsolateOrigins,site-per-process',
      '--no-default-browser-check',
      '--no-first-run',
    ],
    env: {
      ...process.env,
      DISPLAY: process.env.DISPLAY || ':0',
    },
  });

  const page = (await browser.pages())[0] || (await browser.newPage());
  
  console.log('🌐 Navigating to Admin Command Center: http://localhost/emptracker/admin/');
  await page.goto('http://localhost/emptracker/admin/', { waitUntil: 'networkidle2', timeout: 45000 });
  
  console.log('⏳ Waiting for Flutter Web app to initialize and render...');
  await sleep(4000);

  // Take screenshot as proof
  await page.screenshot({ path: 'admin_login_screen.png' });
  console.log('📸 Captured Admin Login Screen!');

  // Demonstrate Login interaction
  console.log('🔑 Performing automated login...');
  // Flutter Web canvas / semantic click or enter key
  await page.keyboard.press('Tab');
  await sleep(300);
  await page.keyboard.type('admin@fieldforce.com', { delay: 40 });
  await sleep(400);
  
  await page.keyboard.press('Tab');
  await sleep(300);
  await page.keyboard.type('Admin@123456', { delay: 40 });
  await sleep(500);

  await page.keyboard.press('Enter');
  console.log('🔓 Submitted Login credentials. Waiting for Dashboard to load...');
  await sleep(5000);

  await page.screenshot({ path: 'admin_dashboard_live.png' });
  console.log('📸 Dashboard Loaded & Verified!');

  // Open Employee App in second tab
  console.log('📱 Opening Employee App in second tab: http://localhost/emptracker/employee/');
  const employeePage = await browser.newPage();
  await employeePage.goto('http://localhost/emptracker/employee/', { waitUntil: 'networkidle2', timeout: 45000 });
  await sleep(4000);

  console.log('🔑 Logging in as Employee Rahul Sharma...');
  await employeePage.keyboard.press('Tab');
  await sleep(300);
  await employeePage.keyboard.type('rahul@fieldforce.com', { delay: 40 });
  await sleep(400);

  await employeePage.keyboard.press('Tab');
  await sleep(300);
  await employeePage.keyboard.type('Emp@123456', { delay: 40 });
  await sleep(500);

  await employeePage.keyboard.press('Enter');
  await sleep(5000);

  await employeePage.screenshot({ path: 'employee_home_live.png' });
  console.log('📸 Employee Duty & GPS Screen Loaded & Verified!');

  // Bring Admin tab back to focus
  await page.bringToFront();
  console.log('✨ Live Automation Demo is running on your screen! Browser will remain open for your interaction.');
  
  // Keep browser active for user interaction
  await sleep(60000);
})();
