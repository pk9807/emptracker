const DataSanitizer = require('./sanitizer');
const path = require('path');
const fs = require('fs');

/**
 * ScreenAutomator Engine
 * High-precision, sanitized screen automation with natural Bezier mouse physics & visual HUD.
 */
class ScreenAutomator {
  constructor(page, options = {}) {
    this.page = page;
    this.options = {
      mouseSteps: 25,
      typingDelayMin: 40,
      typingDelayMax: 110,
      showVisualHud: true,
      ...options,
    };
    this.currentPos = { x: 100, y: 100 };
  }

  /**
   * Sleep helper
   */
  async sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  /**
   * Inject high-visibility HUD banner and animated laser mouse pointer into page
   */
  async injectVisualHUD() {
    try {
      await this.page.evaluate(() => {
        if (document.getElementById('ff-screen-automation-hud')) return;

        // Visual Mouse Cursor Pointer
        const pointer = document.createElement('div');
        pointer.id = 'ff-automation-pointer';
        pointer.style.cssText = `
          position: fixed;
          top: 0; left: 0;
          width: 22px; height: 22px;
          border-radius: 50%;
          background: radial-gradient(circle, rgba(0, 255, 170, 0.9) 0%, rgba(0, 162, 255, 0.6) 70%, transparent 100%);
          border: 2px solid #ffffff;
          box-shadow: 0 0 15px #00ffaa, 0 0 30px #00a2ff;
          pointer-events: none;
          z-index: 9999999;
          transform: translate(-50%, -50%);
          transition: transform 0.05s ease-out;
        `;
        document.body.appendChild(pointer);

        // Top Status HUD Toast
        const hud = document.createElement('div');
        hud.id = 'ff-screen-automation-hud';
        hud.style.cssText = `
          position: fixed;
          top: 14px;
          left: 50%;
          transform: translateX(-50%);
          background: rgba(10, 15, 29, 0.88);
          backdrop-filter: blur(16px);
          -webkit-backdrop-filter: blur(16px);
          color: #f1f5f9;
          padding: 10px 22px;
          border-radius: 30px;
          border: 1px solid rgba(0, 255, 170, 0.4);
          box-shadow: 0 10px 30px rgba(0,0,0,0.5), 0 0 20px rgba(0, 255, 170, 0.2);
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          font-size: 13px;
          font-weight: 600;
          letter-spacing: 0.4px;
          z-index: 9999998;
          display: flex;
          align-items: center;
          gap: 10px;
          pointer-events: none;
          transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
        `;
        hud.innerHTML = `
          <span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:#00ffaa;box-shadow:0 0 8px #00ffaa;animation:pulse 1.2s infinite;"></span>
          <span id="ff-hud-message">🤖 Screen Automation Engine Active</span>
        `;
        document.body.appendChild(hud);

        // Add pulse animation keyframe
        const style = document.createElement('style');
        style.innerHTML = `
          @keyframes pulse { 0% { transform: scale(0.9); opacity: 0.7; } 50% { transform: scale(1.3); opacity: 1; } 100% { transform: scale(0.9); opacity: 0.7; } }
          @keyframes clickRipple { 0% { width: 10px; height: 10px; opacity: 1; border-width: 3px; } 100% { width: 60px; height: 60px; opacity: 0; border-width: 1px; } }
        `;
        document.head.appendChild(style);
      });
    } catch (e) {
      // Ignored if page context is rebuilding
    }
  }

  /**
   * Updates HUD message on user's screen
   */
  async updateHUD(message) {
    const sanitizedMsg = DataSanitizer.sanitizeLog(message);
    console.log(`  [AUTOMATION HUD] 📢 ${sanitizedMsg}`);
    try {
      await this.page.evaluate((msg) => {
        const hudMsg = document.getElementById('ff-hud-message');
        if (hudMsg) hudMsg.innerText = msg;
      }, sanitizedMsg);
    } catch (e) {}
  }

  /**
   * Move mouse using cubic Bezier curve to simulate natural human physics
   */
  async moveToSmoothly(targetX, targetY) {
    const startX = this.currentPos.x;
    const startY = this.currentPos.y;
    const steps = this.options.mouseSteps;

    // Generate random Bezier control points
    const cp1x = startX + (targetX - startX) * 0.25 + (Math.random() - 0.5) * 50;
    const cp1y = startY + (targetY - startY) * 0.1 + (Math.random() - 0.5) * 50;
    const cp2x = startX + (targetX - startX) * 0.75 + (Math.random() - 0.5) * 30;
    const cp2y = startY + (targetY - startY) * 0.9 + (Math.random() - 0.5) * 30;

    for (let i = 1; i <= steps; i++) {
      const t = i / steps;
      // Cubic Bezier formula
      const cx =
        Math.pow(1 - t, 3) * startX +
        3 * Math.pow(1 - t, 2) * t * cp1x +
        3 * (1 - t) * Math.pow(t, 2) * cp2x +
        Math.pow(t, 3) * targetX;
      const cy =
        Math.pow(1 - t, 3) * startY +
        3 * Math.pow(1 - t, 2) * t * cp1y +
        3 * (1 - t) * Math.pow(t, 2) * cp2y +
        Math.pow(t, 3) * targetY;

      await this.page.mouse.move(cx, cy);

      // Move visual laser pointer in DOM
      try {
        await this.page.evaluate((x, y) => {
          const ptr = document.getElementById('ff-automation-pointer');
          if (ptr) {
            ptr.style.left = `${x}px`;
            ptr.style.top = `${y}px`;
          }
        }, cx, cy);
      } catch (e) {}

      await this.sleep(12);
    }

    this.currentPos = { x: targetX, y: targetY };
  }

  /**
   * Smoothly moves to coordinate and triggers a sanitized visual click ripple
   */
  async clickAt(x, y, hudMessage = null) {
    if (hudMessage) {
      await this.updateHUD(hudMessage);
    }
    await this.moveToSmoothly(x, y);

    // Trigger visual ripple in DOM
    try {
      await this.page.evaluate((cx, cy) => {
        const ripple = document.createElement('div');
        ripple.style.cssText = `
          position: fixed;
          left: ${cx}px; top: ${cy}px;
          border-radius: 50%;
          border: 2px solid #00ffaa;
          box-shadow: 0 0 15px #00ffaa;
          transform: translate(-50%, -50%);
          pointer-events: none;
          z-index: 9999999;
          animation: clickRipple 0.5s ease-out forwards;
        `;
        document.body.appendChild(ripple);
        setTimeout(() => ripple.remove(), 600);
      }, x, y);
    } catch (e) {}

    await this.page.mouse.click(x, y);
    await this.sleep(300);
  }

  /**
   * Types text with human-like randomized delays and masked logging
   */
  async typeText(text, isSecret = false, hudMessage = null) {
    const displayMsg = hudMessage || (isSecret ? `Typing password: ${DataSanitizer.maskSecret(text)}` : `Typing: ${DataSanitizer.maskEmail(text)}`);
    await this.updateHUD(displayMsg);

    for (const char of text) {
      await this.page.keyboard.type(char);
      const delay = Math.floor(
        Math.random() * (this.options.typingDelayMax - this.options.typingDelayMin) + this.options.typingDelayMin
      );
      await this.sleep(delay);
    }
  }

  /**
   * Normalized coordinate resolver (percentage based, 0.0 to 1.0)
   */
  async resolveNormalized(pctX, pctY) {
    const dims = await this.page.evaluate(() => ({
      w: window.innerWidth,
      h: window.innerHeight,
    }));
    return {
      x: Math.round(dims.w * pctX),
      y: Math.round(dims.h * pctY),
    };
  }
}

module.exports = ScreenAutomator;
