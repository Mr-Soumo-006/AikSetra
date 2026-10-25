import { config } from '../config/index.js';

export interface SmsSendResult {
  success: boolean;
  messageId?: string;
  provider: string;
  statusMessage: string;
}

export class SmsService {
  public static runtimeProvider: string = config.smsGatewayProvider;
  public static runtimeFast2SmsKey: string = config.fast2smsApiKey;
  public static runtimeMsg91Key: string = config.msg91AuthKey;
  public static runtimeTwilioSid: string = config.twilioAccountSid;
  public static runtimeTwilioToken: string = config.twilioAuthToken;
  public static runtimeTwilioFrom: string = config.twilioPhoneNumber;
  public static runtimeRazorpayKeyId: string = process.env.RAZORPAY_KEY_ID || '';

  public static updateGatewayConfig(params: {
    provider?: string;
    fast2smsApiKey?: string;
    msg91AuthKey?: string;
    twilioAccountSid?: string;
    twilioAuthToken?: string;
    twilioPhoneNumber?: string;
    razorpayKeyId?: string;
  }) {
    if (params.provider) this.runtimeProvider = params.provider.toUpperCase();
    if (params.fast2smsApiKey !== undefined) {
      this.runtimeFast2SmsKey = params.fast2smsApiKey.trim();
      if (this.runtimeFast2SmsKey.length > 5) this.runtimeProvider = 'FAST2SMS';
    }
    if (params.msg91AuthKey !== undefined) {
      this.runtimeMsg91Key = params.msg91AuthKey.trim();
      if (this.runtimeMsg91Key.length > 5) this.runtimeProvider = 'MSG91';
    }
    if (params.twilioAccountSid !== undefined) this.runtimeTwilioSid = params.twilioAccountSid.trim();
    if (params.twilioAuthToken !== undefined) this.runtimeTwilioToken = params.twilioAuthToken.trim();
    if (params.twilioPhoneNumber !== undefined) this.runtimeTwilioFrom = params.twilioPhoneNumber.trim();
    if (this.runtimeTwilioSid && this.runtimeTwilioToken) this.runtimeProvider = 'TWILIO';
    if (params.razorpayKeyId !== undefined) this.runtimeRazorpayKeyId = params.razorpayKeyId.trim();
  }

  public static getGatewayStatus() {
    return {
      provider: this.runtimeProvider,
      fast2smsConfigured: this.runtimeFast2SmsKey.length > 5,
      msg91Configured: this.runtimeMsg91Key.length > 5,
      twilioConfigured: this.runtimeTwilioSid.length > 5 && this.runtimeTwilioToken.length > 5,
      razorpayConfigured: this.runtimeRazorpayKeyId.length > 5,
      razorpayKeyId: this.runtimeRazorpayKeyId,
    };
  }

  /**
   * Dispatches authentic SMS OTP to user's registered mobile number
   */
  public static async sendOtpSms(phone: string, otp: string): Promise<SmsSendResult> {
    const cleanPhone = phone.replace(/[^0-9]/g, '').slice(-10);
    const message = `Your AikSetra security verification OTP is ${otp}. Valid for 5 minutes. Do not share this OTP with anyone - NPCI/RBI.`;

    switch (this.runtimeProvider) {
      case 'FAST2SMS':
        return await this.sendViaFast2Sms(cleanPhone, otp);

      case 'MSG91':
        return await this.sendViaMsg91(cleanPhone, otp);

      case 'TWILIO':
        return await this.sendViaTwilio(cleanPhone, message);

      case 'CONSOLE':
      default:
        console.log(`\n===========================================================`);
        console.log(`🔑 [AIKSETRA OTP DISPATCH]`);
        console.log(`📱 Mobile Number:    +91 ${cleanPhone}`);
        console.log(`🔐 Verification OTP: ${otp}`);
        console.log(`⏰ Validity:         5 minutes`);
        console.log(`===========================================================\n`);
        return {
          success: true,
          messageId: `msg_${Date.now()}_${cleanPhone}`,
          provider: 'CONSOLE',
          statusMessage: `Verification OTP printed to backend terminal: ${otp}`,
        };
    }
  }

  private static async sendViaFast2Sms(phone: string, otp: string): Promise<SmsSendResult> {
    const apiKey = this.runtimeFast2SmsKey || config.fast2smsApiKey;
    if (!apiKey || apiKey.trim().length === 0 || apiKey.includes('replace_')) {
      console.warn(`⚠️ [SMS GATEWAY]: FAST2SMS_API_KEY is not configured in .env. Dispatched OTP to terminal console for +91 ${phone}.`);
      console.log(`\n===========================================================`);
      console.log(`🔑 [AIKSETRA OTP DISPATCH]`);
      console.log(`📱 Mobile Number:    +91 ${phone}`);
      console.log(`🔐 Verification OTP: ${otp}`);
      console.log(`⏰ Validity:         5 minutes`);
      console.log(`ℹ️ Note: Logged to console because FAST2SMS_API_KEY is empty in .env`);
      console.log(`===========================================================\n`);
      return {
        success: true,
        messageId: `dev_otp_${Date.now()}_${phone}`,
        provider: 'CONSOLE',
        statusMessage: `Verification OTP printed to backend terminal: ${otp}`,
      };
    }
    try {
      const response = await fetch('https://www.fast2sms.com/dev/bulkV2', {
        method: 'POST',
        headers: {
          authorization: apiKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          route: 'otp',
          variables_values: otp,
          numbers: phone,
        }),
      });
      const data: any = await response.json();
      return {
        success: data.return === true,
        messageId: data.request_id,
        provider: 'FAST2SMS',
        statusMessage: data.message ? data.message[0] : 'Dispatched via Fast2SMS',
      };
    } catch (err: any) {
      console.error('[Fast2SMS Error]', err);
      return { success: false, provider: 'FAST2SMS', statusMessage: err.message };
    }
  }

  private static async sendViaMsg91(phone: string, otp: string): Promise<SmsSendResult> {
    const authKey = this.runtimeMsg91Key || config.msg91AuthKey;
    if (!authKey || authKey.trim().length === 0 || authKey.includes('replace_')) {
      console.warn(`⚠️ [SMS GATEWAY]: MSG91_AUTH_KEY is not configured. Dispatched OTP to terminal console for +91 ${phone}.`);
      console.log(`\n===========================================================`);
      console.log(`🔑 [AIKSETRA OTP DISPATCH]`);
      console.log(`📱 Mobile Number:    +91 ${phone}`);
      console.log(`🔐 Verification OTP: ${otp}`);
      console.log(`⏰ Validity:         5 minutes`);
      console.log(`===========================================================\n`);
      return {
        success: true,
        messageId: `dev_otp_${Date.now()}_${phone}`,
        provider: 'CONSOLE',
        statusMessage: `Verification OTP printed to backend terminal: ${otp}`,
      };
    }
    try {
      const url = `https://control.msg91.com/api/v5/otp?template_id=default&mobile=91${phone}&authkey=${authKey}&otp=${otp}`;
      const response = await fetch(url, { method: 'POST' });
      const data: any = await response.json();
      return {
        success: data.type === 'success',
        messageId: data.message,
        provider: 'MSG91',
        statusMessage: 'Dispatched via MSG91',
      };
    } catch (err: any) {
      console.error('[MSG91 Error]', err);
      return { success: false, provider: 'MSG91', statusMessage: err.message };
    }
  }

  private static async sendViaTwilio(phone: string, body: string): Promise<SmsSendResult> {
    const sid = this.runtimeTwilioSid || config.twilioAccountSid;
    const token = this.runtimeTwilioToken || config.twilioAuthToken;
    const fromPhone = this.runtimeTwilioFrom || config.twilioPhoneNumber;
    if (!sid || !token || !fromPhone || sid.includes('replace_')) {
      console.warn(`⚠️ [SMS GATEWAY]: Twilio credentials are not configured. Dispatched OTP to terminal console for +91 ${phone}.`);
      console.log(`\n===========================================================`);
      console.log(`🔑 [AIKSETRA OTP DISPATCH]`);
      console.log(`📱 Mobile Number:    +91 ${phone}`);
      console.log(`🔐 Message:          ${body}`);
      console.log(`===========================================================\n`);
      return {
        success: true,
        messageId: `dev_otp_${Date.now()}_${phone}`,
        provider: 'CONSOLE',
        statusMessage: `Verification message printed to backend terminal`,
      };
    }
    try {
      const endpoint = `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`;
      const authHeader = 'Basic ' + Buffer.from(`${sid}:${token}`).toString('base64');
      const params = new URLSearchParams({
        To: `+91${phone}`,
        From: fromPhone,
        Body: body,
      });

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          Authorization: authHeader,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params.toString(),
      });
      const data: any = await response.json();
      return {
        success: !data.error_code && response.status < 400,
        messageId: data.sid,
        provider: 'TWILIO',
        statusMessage: data.status || 'Dispatched via Twilio',
      };
    } catch (err: any) {
      console.error('[Twilio Error]', err);
      return { success: false, provider: 'TWILIO', statusMessage: err.message };
    }
  }
}
