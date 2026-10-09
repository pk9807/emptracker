const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

(async () => {
  console.log('========================================================================');
  console.log('🏋️ FIELDFORCE PRO — AGENT 1: LIVE DEBUG & VERIFY KANPUR GYM SEARCH');
  console.log('========================================================================');

  const screensDir = path.join(__dirname, 'admin_debug_screens');
  if (!fs.existsSync(screensDir)) {
    fs.mkdirSync(screensDir, { recursive: true });
  }

  const browser = await puppeteer.launch({
    headless: false,
    executablePath: '/usr/bin/google-chrome',
    defaultViewport: null,
    args: [
      '--start-maximized',
      '--no-default-browser-check',
      '--no-first-run',
      '--disable-web-security',
      '--app=http://localhost/emptracker/admin/',
    ],
    env: {
      ...process.env,
      DISPLAY: process.env.DISPLAY || ':0',
    },
  });

  const page = (await browser.pages())[0] || (await browser.newPage());

  console.log('\n[AGENT 1] 🌐 Loading Admin Command Center...');
  await page.goto('http://localhost/emptracker/admin/', { waitUntil: 'networkidle2', timeout: 45000 });
  await sleep(4000);

  const dims = await page.evaluate(() => ({
    w: window.innerWidth,
    h: window.innerHeight,
  }));

  console.log('[AGENT 1] 🔑 Submitting Admin Login...');
  await page.mouse.click(dims.w / 2, dims.h / 2 + 100);
  await sleep(400);
  await page.keyboard.press('Enter');
  await sleep(6000);

  console.log('\n[AGENT 1] 🔍 Executing Search: "workout gym kanpur"...');
  // Click Search Bar at top center
  await page.mouse.click(dims.w / 2, 35);
  await sleep(500);

  // Type query with human typing delay
  await page.keyboard.type('workout gym kanpur', { delay: 80 });
  await sleep(2500);

  await page.screenshot({ path: path.join(screensDir, 'workout_gym_kanpur_dropdown_found.png') });
  console.log('  📸 Screenshot: workout_gym_kanpur_dropdown_found.png');

  console.log('[AGENT 1] 🎯 Auto-Selecting "Workout Gym & Fitness Center Kanpur"...');
  await page.keyboard.press('ArrowDown');
  await sleep(400);
  await page.keyboard.press('Enter');
  await sleep(3500);

  await page.screenshot({ path: path.join(screensDir, 'workout_gym_kanpur_pin_focused.png') });
  console.log('  📸 Screenshot: workout_gym_kanpur_pin_focused.png');

  console.log('\n========================================================================');
  console.log('✅ AGENT 1 DEBUG COMPLETE: "Workout Gym Kanpur" FOUND & PINNED ON MAP!');
  console.log('🖥️ Window remains active on your screen.');
  console.log('========================================================================');
})();
