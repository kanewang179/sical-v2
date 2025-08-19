import nodemailer from 'nodemailer';

interface EmailOptions {
  email: string;
  subject: string;
  message: string;
}

/**
 * 发送电子邮件
 * @param {Object} options - 邮件选项
 */
const sendEmail = async (options: EmailOptions): Promise<any> => {
  // 创建测试账号（开发环境）或使用配置的SMTP服务（生产环境）
  let transporter;
  
  if (process.env['NODE_ENV'] === 'development') {
    // 使用ethereal.email创建测试账号
    const testAccount = await nodemailer.createTestAccount();
    
    transporter = nodemailer.createTransport({
      host: 'smtp.ethereal.email',
      port: 587,
      secure: false,
      auth: {
        user: testAccount.user,
        pass: testAccount.pass
      }
    });
  } else {
    // 生产环境使用配置的SMTP服务
    transporter = nodemailer.createTransport({
      host: process.env['SMTP_HOST'],
      port: parseInt(process.env['SMTP_PORT'] || '587'),
      secure: process.env['SMTP_SECURE'] === 'true',
      auth: {
        user: process.env['SMTP_EMAIL'],
        pass: process.env['SMTP_PASSWORD']
      }
    });
  }

  // 邮件选项
  const mailOptions = {
    from: `${process.env['FROM_NAME']} <${process.env['FROM_EMAIL']}>`,
    to: options.email,
    subject: options.subject,
    text: options.message
  };

  // 发送邮件
  const info = await transporter.sendMail(mailOptions);

  // 如果是开发环境，记录测试URL
  if (process.env['NODE_ENV'] === 'development') {
    console.log('预览URL: %s', nodemailer.getTestMessageUrl(info));
  }

  return info;
};

export default sendEmail;