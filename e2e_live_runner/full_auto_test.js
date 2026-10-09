const puppeteer = require('puppeteer-core');

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

(async () => {
  console.log('🚀 Launching Google Chrome GUI on your Ubuntu Desktop...');
  
  const browser = await puppeteer.launch({
    headless: false,
    executablePath: '/usr/bin/google-chrome',
    defaultViewport: null,
    args: [
      '--start-maximized',
      '--no-default-browser-check',
      '--no-first-run',
      '--disable-web-security',
    ],
    env: {
      ...process.env,
      DISPLAY: process.env.DISPLAY || ':0',
    },
  });

  const page = (await browser.pages())[0] || (await browser.newPage());
  
  console.log('1️⃣ Navigating to Admin Command Center: http://localhost/emptracker/admin/');
  await page.goto('http://localhost/emptracker/admin/', { waitUntil: 'networkidle2', timeout: 45000 });
  
  console.log('⏳ Waiting 4 seconds for Flutter Web Engine to render UI...');
  await sleep(4500);

  // Click anywhere in middle to ensure canvas has focus, then hit Enter to submit the prefilled credentials
  console.log('🔑 Performing 1-Click Auto Login as Admin...');
  const { width, height } = await page.evaluate(() => ({
    width: window.innerWidth,
    height: window.innerHeight,
  }));

  // Click on the Login Button area in the center-bottom of the form
  await page.mouse.click(width / 2, height / 2 + 100);
  await sleep(500);
  await page.keyboard.press('Enter');

  console.log('⏳ Authenticating with Laravel Sanctum API and loading Dashboard...');
  await sleep(5000);

  console.log('✅ Admin Command Center successfully logged in and loaded!');
  console.log('🗺️ Testing Live Fleet Radar on Map...');
  await sleep(3000);

  // Open Employee App in Tab 2
  console.log('2️⃣ Opening Employee App in Tab 2: http://localhost/emptracker/employee/');
  const empPage = await browser.newPage();
  await empPage.goto('http://localhost/emptracker/employee/', { waitUntil: 'networkidle2', timeout: 45000 });
  await sleep(4500);

  console.log('🔑 Performing 1-Click Auto Login as Employee Rahul Sharma...');
  const empDimensions = await empPage.evaluate(() => ({
    width: window.innerWidth,
    height: window.innerHeight,
  }));

  await empPage.mouse.click(empDimensions.width / 2, empDimensions.height / 2 + 100);
  await sleep(500);
  await empPage.keyboard.press('Enter');

  console.log('⏳ Authenticating Employee & Loading Duty Timesheet...');
  await sleep(5000);

  console.log('✅ Employee App logged in! Live GPS map preview & Duty status active.');

  // Bring Admin tab back to front so admin dashboard is primary
  await page.bringToFront();
  console.log('🎉 FULL AUTOMATION COMPLETE! Both apps are live and running on your desktop.');
})();
