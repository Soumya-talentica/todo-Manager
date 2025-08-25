const nodemailer = require('nodemailer');

function createTransport() {
  const {
    SMTP_HOST,
    SMTP_PORT,
    SMTP_USER,
    SMTP_PASS,
    SMTP_SECURE
  } = process.env;

  if (!SMTP_HOST || !SMTP_PORT) {
    throw new Error('SMTP_HOST and SMTP_PORT must be set for email alerts');
  }

  return nodemailer.createTransport({
    host: SMTP_HOST,
    port: Number(SMTP_PORT),
    secure: String(SMTP_SECURE || '').toLowerCase() === 'true',
    auth: SMTP_USER && SMTP_PASS ? { user: SMTP_USER, pass: SMTP_PASS } : undefined
  });
}

async function sendAlertEmail({ subject, html }) {
  const { ALERT_FROM, ALERT_TO } = process.env;
  if (!ALERT_FROM || !ALERT_TO) {
    throw new Error('ALERT_FROM and ALERT_TO must be set for email alerts');
  }
  const transport = createTransport();
  const info = await transport.sendMail({ from: ALERT_FROM, to: ALERT_TO, subject, html });
  return info.messageId;
}

module.exports = { sendAlertEmail };

