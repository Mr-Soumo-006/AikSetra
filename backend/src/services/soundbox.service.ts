import { WebSocket } from 'ws';
import type { SoundboxEvent } from '../types/index.js';

class SoundboxService {
  private clients: Set<WebSocket> = new Set();
  private sseResponses: Set<any> = new Set();
  private recentEvents: SoundboxEvent[] = [];

  public registerWsClient(ws: WebSocket): void {
    this.clients.add(ws);
    ws.on('close', () => this.clients.delete(ws));

    // Send recent events as warm-up
    ws.send(JSON.stringify({ type: 'INIT', history: this.recentEvents.slice(-5) }));
  }

  public registerSseClient(res: any): void {
    this.sseResponses.add(res);
  }

  public removeSseClient(res: any): void {
    this.sseResponses.delete(res);
  }

  public generateVoiceText(amount: number, language: 'en' | 'hi' | 'bn' | 'ta' | 'te'): string {
    const rounded = Math.round(amount);
    switch (language) {
      case 'hi':
        return `एकक्षेत्र पर ${rounded} रुपये प्राप्त हुए`;
      case 'bn':
        return `ঐকক্ষেত্রে ${rounded} টাকা পাওয়া গেছে`;
      case 'ta':
        return `ஐக்சேத்ராவில் ${rounded} ரூபாய் பெறப்பட்டது`;
      case 'te':
        return `ఐక్ క్షేత్ర లో ${rounded} రూపాయలు స్వీకరించబడ్డాయి`;
      case 'en':
      default:
        return `Received ${rounded} rupees on AikSetra`;
    }
  }

  public broadcastPayment(params: {
    merchantId: string;
    merchantName: string;
    amount: number;
    currency: string;
    payerName: string;
    payerVpa: string;
    language?: 'en' | 'hi' | 'bn' | 'ta' | 'te';
  }): SoundboxEvent {
    const lang = params.language || 'hi';
    const spokenText = this.generateVoiceText(params.amount, lang);

    const event: SoundboxEvent = {
      id: `sbx_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
      merchantId: params.merchantId,
      merchantName: params.merchantName,
      amount: params.amount,
      currency: params.currency,
      payerName: params.payerName,
      payerVpa: params.payerVpa,
      language: lang,
      spokenText,
      timestamp: new Date().toISOString(),
    };

    this.recentEvents.push(event);
    if (this.recentEvents.length > 50) this.recentEvents.shift();

    const payload = JSON.stringify({ type: 'PAYMENT_RECEIVED', data: event });

    // Broadcast to WebSockets
    for (const client of this.clients) {
      if (client.readyState === WebSocket.OPEN) {
        client.send(payload);
      }
    }

    // Broadcast to SSE
    for (const res of this.sseResponses) {
      try {
        res.write(`data: ${payload}\n\n`);
      } catch (err) {
        this.sseResponses.delete(res);
      }
    }

    return event;
  }

  public getRecentEvents(): SoundboxEvent[] {
    return this.recentEvents;
  }
}

export const soundboxService = new SoundboxService();
